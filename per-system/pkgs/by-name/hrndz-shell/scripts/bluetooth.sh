# bluetooth: the Bluetooth panel's actions, ported from Omarchy's
# omarchy-bluetooth-power and omarchy-bluetooth-device.
#   bluetooth power on|off|toggle|is-on
#   bluetooth pair|connect|disconnect|forget <address>
#
# Power is the rfkill soft block, not BlueZ's Powered: BlueZ never persists
# Powered, while systemd-rfkill saves and restores the block across reboots.
# With AutoEnable at its default, bluetoothd powers the adapter up once the
# block is gone. A seatless session (desktop-vnc) gets no uaccess ACL on
# /dev/rfkill, so there it falls back to Powered, which does not persist.

controllers() {
  timeout 2s bluetoothctl list 2>/dev/null | awk '{ print $2 }'
}

# Any controller counts: the block covers every radio at once.
powered() {
  local controller
  for controller in $(controllers); do
    [[ $(timeout 2s bluetoothctl show "$controller" 2>/dev/null) == *"Powered: yes"* ]] && return 0
  done
  return 1
}

# One deadline around the whole wait: each probe can sit on its own timeout
# when D-Bus is wedged.
wait_powered() {
  local deadline=$((SECONDS + 2))
  while :; do
    powered && return 0
    ((SECONDS < deadline)) || return 1
    sleep 0.2
  done
}

block() {
  rfkill block bluetooth 2>/dev/null || timeout 5s bluetoothctl power off >/dev/null
}

power_on() {
  rfkill unblock bluetooth 2>/dev/null || true
  wait_powered && return 0
  # bluetoothd does not auto-enable an adapter powered down without a block.
  timeout 5s bluetoothctl power on >/dev/null 2>&1 || true
  wait_powered && return 0
  echo "bluetooth: adapter did not come up" >&2
  return 1
}

power() {
  case ${1:-} in
  on) power_on ;;
  off) block ;;
  toggle) if powered; then block; else power_on; fi ;;
  is-on) powered ;;
  *)
    echo "usage: bluetooth power on|off|toggle|is-on" >&2
    return 2
    ;;
  esac
}

device() {
  local action=$1 address=${2:-}
  [[ $address =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]] || {
    echo "usage: bluetooth $action <address>" >&2
    return 2
  }

  # Nothing here fails loudly: BlueZ reports through the device state the
  # panel is watching.
  if [[ $action != disconnect ]] && ! powered; then power_on || true; fi
  case $action in
  pair)
    timeout 20s bluetoothctl pair "$address" >/dev/null 2>&1 || true
    bluetoothctl trust "$address" >/dev/null 2>&1 || true
    timeout 20s bluetoothctl connect "$address" >/dev/null 2>&1 || true
    ;;
  connect)
    bluetoothctl trust "$address" >/dev/null 2>&1 || true
    timeout 20s bluetoothctl connect "$address" >/dev/null 2>&1 || true
    ;;
  disconnect) timeout 10s bluetoothctl disconnect "$address" >/dev/null 2>&1 || true ;;
  forget)
    timeout 10s bluetoothctl disconnect "$address" >/dev/null 2>&1 || true
    timeout 10s bluetoothctl remove "$address" >/dev/null 2>&1 || true
    ;;
  esac
}

case ${1:-} in
power) power "${2:-}" ;;
pair | connect | disconnect | forget) device "$1" "${2:-}" ;;
*)
  echo "usage: bluetooth power on|off|toggle|is-on | pair|connect|disconnect|forget <address>" >&2
  exit 2
  ;;
esac
