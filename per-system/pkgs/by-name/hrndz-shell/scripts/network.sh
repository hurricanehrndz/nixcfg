# network: what the network panel reads and changes, ported from Omarchy's
# omarchy-network-status --verbose and omarchy-network-band.
#   network status             key<TAB>value lines about the default route
#   network band [auto|2.4|5|6] show, or pin, the Wi-Fi band of the connection

internet_probe=1.1.1.1

##: status

ping_latency_ms() {
  LC_ALL=C ping -n -c 1 -W 1 "$1" 2>/dev/null | awk -F'time[=<]' '/time[=<]/ { split($2, parts, " "); print parts[1]; exit }'
}

# Both probes in parallel, so a dead gateway costs one second, not two.
print_ping_samples() {
  local gateway=$1 tmpdir router_pid=""
  tmpdir=$(mktemp -d) || return

  if [[ -n $gateway ]]; then
    ping_latency_ms "$gateway" >"$tmpdir/router" &
    router_pid=$!
  fi
  ping_latency_ms "$internet_probe" >"$tmpdir/internet" &
  local internet_pid=$!

  if [[ -n $router_pid ]]; then
    wait "$router_pid" || true
    printf 'router_ping_ms\t%s\n' "$(cat "$tmpdir/router")"
  fi
  wait "$internet_pid" || true
  printf 'internet_ping_ms\t%s\n' "$(cat "$tmpdir/internet")"
  rm -rf "$tmpdir"
}

status() {
  local route_json iface gw src prefix link

  route_json=$(ip -j route get "$internet_probe" 2>/dev/null) || return 0
  iface=$(jq -r '.[0].dev // ""' <<<"$route_json")
  gw=$(jq -r '.[0].gateway // ""' <<<"$route_json")
  src=$(jq -r '.[0].prefsrc // ""' <<<"$route_json")
  [[ -n $iface ]] || return 0

  prefix=$(ip -j addr show "$iface" 2>/dev/null | jq -r '[.[0].addr_info[]? | select(.family == "inet") | .prefixlen][0] // ""') || true

  printf 'iface\t%s\n' "$iface"
  printf 'ip\t%s\n' "$src"
  printf 'prefix\t%s\n' "$prefix"
  printf 'gateway\t%s\n' "$gw"

  local stats=/sys/class/net/$iface/statistics
  [[ -r $stats/rx_bytes ]] && printf 'rx_bytes\t%s\n' "$(<"$stats/rx_bytes")"
  [[ -r $stats/tx_bytes ]] && printf 'tx_bytes\t%s\n' "$(<"$stats/tx_bytes")"

  if [[ -d /sys/class/net/$iface/wireless ]]; then
    printf 'type\twifi\n'
    link=$(iw dev "$iface" link 2>/dev/null) || true
    if [[ -n $link ]]; then
      printf 'ssid\t%s\n' "$(awk '/SSID:/ { sub(/.*SSID: /, ""); print; exit }' <<<"$link")"
      printf 'signal_dbm\t%s\n' "$(awk '/signal:/ { print $2; exit }' <<<"$link")"
      printf 'freq\t%s\n' "$(awk '/freq:/ { print $2; exit }' <<<"$link")"
      printf 'bitrate\t%s\n' "$(awk '/tx bitrate:/ { print $3 " " $4; exit }' <<<"$link")"
    fi
  else
    printf 'type\tethernet\n'
    # Reading speed on a link without carrier fails with EINVAL.
    [[ -r /sys/class/net/$iface/speed ]] && printf 'speed\t%s\n' "$(cat "/sys/class/net/$iface/speed" 2>/dev/null)"
    [[ -r /sys/class/net/$iface/duplex ]] && printf 'duplex\t%s\n' "$(cat "/sys/class/net/$iface/duplex" 2>/dev/null)"
  fi

  print_ping_samples "$gw"
}

##: band
# NetworkManager 1.44+ pins 5 and 6 GHz apart. Pinning the band rather than a
# BSSID survives an AP rotating BSSIDs and leaves roaming intact.

nm_band_for() {
  case $1 in
  2.4) echo bg ;;
  5) echo a ;;
  6) echo 6GHz ;;
  *) return 1 ;;
  esac
}

band_from_nm() {
  case $1 in
  bg) echo 2.4 ;;
  a) echo 5 ;;
  6GHz) echo 6 ;;
  *) echo auto ;;
  esac
}

# Accepts nmcli's "2412 MHz" or iw's "5745.0". The boundaries match
# Model.js formatHeaderFreq.
band_for_freq() {
  local mhz=${1%%[!0-9]*}
  [[ -n $mhz ]] || return 1
  if ((mhz >= 2400 && mhz < 2500)); then
    echo 2.4
  elif ((mhz >= 4900 && mhz < 5925)); then
    echo 5
  elif ((mhz >= 5925 && mhz < 7125)); then
    echo 6
  else
    return 1
  fi
}

# LC_ALL=C: nmcli translates state words. -e no: -g otherwise escapes ':' and
# '\', and an escaped SSID would never match iw's raw one.
nm_get() {
  LC_ALL=C nmcli -e no -g "$@" 2>/dev/null
}

wifi_device() {
  nm_get DEVICE,TYPE,STATE device status | awk -F: '$2 == "wifi" && $3 == "connected" { print $1; exit }'
}

wifi_profile() {
  nm_get GENERAL.CONNECTION device show "$1"
}

# Sets $ssid and $freq from one `iw dev <device> link`.
read_link() {
  local link
  link=$(iw dev "$1" link 2>/dev/null) || true
  ssid=$(awk '/SSID:/ { sub(/.*SSID: /, ""); print; exit }' <<<"$link")
  freq=$(awk '/freq:/ { print $2; exit }' <<<"$link")
}

# Every band the SSID answers on, always including the one in use. Reads
# NetworkManager's scan cache (--rescan no), which the panel's scanner keeps
# warm; the SSID reaches awk through the environment so backslashes survive.
available_bands() {
  local device=$1 ssid=$2 current=$3
  {
    [[ -z $current ]] || echo "$current"
    nm_get FREQ,SSID dev wifi list ifname "$device" --rescan no |
      want="$ssid" awk -F: '
        BEGIN { want = ENVIRON["want"] }
        {
          name = $2
          for (i = 3; i <= NF; i++) name = name ":" $i
          if (name == want) print $1
        }' |
      while read -r f; do band_for_freq "$f" || true; done
  } | sort -u -g | tr '\n' ' ' | sed 's/ $//'
}

band_status() {
  local device profile band ssid freq
  device=$(wifi_device) || true
  [[ -n $device ]] || return 0
  read_link "$device"
  [[ -n $ssid ]] || return 0

  band=$(band_for_freq "$freq" || true)
  profile=$(wifi_profile "$device")
  printf 'band\t%s\n' "$band"
  printf 'available\t%s\n' "$(available_bands "$device" "$ssid" "$band")"
  [[ -z $profile ]] || printf 'selected\t%s\n' "$(band_from_nm "$(nm_get 802-11-wireless.band connection show "$profile")")"
}

set_band() {
  local target=$1 device profile previous desired="" ssid freq
  device=$(wifi_device) || true
  [[ -n $device ]] || {
    echo "network: no connected Wi-Fi device" >&2
    return 1
  }
  profile=$(wifi_profile "$device")
  [[ -n $profile ]] || {
    echo "network: no active Wi-Fi connection profile" >&2
    return 1
  }

  if [[ $target != auto ]]; then
    read_link "$device"
    if [[ " $(available_bands "$device" "$ssid" "$(band_for_freq "$freq" || true)") " != *" $target "* ]]; then
      echo "network: ${target}GHz is not available on this network" >&2
      return 1
    fi
    desired=$(nm_band_for "$target")
  fi

  previous=$(nm_get 802-11-wireless.band connection show "$profile")
  [[ $previous != "$desired" ]] || return 0
  nmcli connection modify "$profile" 802-11-wireless.band "$desired" >/dev/null

  # The change only lands on reassociation. If the radio cannot come back on
  # the requested band, restore the old setting rather than strand the machine.
  if ! nmcli connection up "$profile" >/dev/null 2>&1; then
    nmcli connection modify "$profile" 802-11-wireless.band "$previous" >/dev/null
    nmcli connection up "$profile" >/dev/null 2>&1 || true
    echo "network: could not connect on ${target}GHz; reverted" >&2
    return 1
  fi
}

case ${1:-} in
status) status ;;
band)
  case ${2:-} in
  "") band_status ;;
  auto | 2.4 | 5 | 6) set_band "$2" ;;
  *)
    echo "usage: network band [auto|2.4|5|6]" >&2
    exit 2
    ;;
  esac
  ;;
*)
  echo "usage: network status | band [auto|2.4|5|6]" >&2
  exit 2
  ;;
esac
