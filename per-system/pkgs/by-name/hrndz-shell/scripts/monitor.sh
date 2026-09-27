# monitor: the display panel's reads and writes, ported from Omarchy's
# omarchy-monitor-state, omarchy-hyprland-monitor-scaling and the backlight
# half of omarchy-brightness-display.
#   monitor state          four lines: brightness percent (empty without a
#                          backlight on the focused display), focused output,
#                          its scale, and a JSON array of the displays
#   monitor scale <scale>  apply to the focused display now and persist it
#   monitor brightness <N> set the internal panel's backlight to N percent
#
# CEILING: brightness covers internal panels (eDP/LVDS/DSI) through
# brightnessctl only. External monitors report no brightness; DDC/CI
# (ddcutil, hardware.i2c) would be the upgrade.
#
# Scale persists in $XDG_CONFIG_HOME/hypr/monitors.lua, which the Hyprland
# config loads after its fallback rule. This rewrites the whole file.
# CEILING: one catch-all rule, so every output gets the last scale set. Per
# output rules keyed by name would be the upgrade once there are several.

monitors_lua="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/monitors.lua"

internal() {
  [[ $1 =~ ^(eDP|LVDS|DSI)- ]]
}

focused() {
  hyprctl monitors -j | jq -ec '.[] | select(.focused)'
}

# The backlight device most likely to drive the panel (omarchy-hw-display).
backlight() {
  local dir=/sys/class/backlight candidate
  for candidate in "$dir"/amdgpu_bl* "$dir"/intel_backlight "$dir"/acpi_video*; do
    if [[ -e $candidate ]]; then
      echo "${candidate##*/}"
      return
    fi
  done
  find "$dir" -mindepth 1 -maxdepth 1 -printf '%f\n' 2>/dev/null | sort | head -n1
}

brightness_percent() {
  local device
  device=$(backlight)
  [[ -n $device ]] || return 0
  brightnessctl -d "$device" -m 2>/dev/null | awk -F, '{ gsub("%", "", $4); print $4 }'
}

state() {
  local all name
  all=$(hyprctl monitors all -j)
  name=$(jq -r '[.[] | select(.focused)][0].name // ""' <<<"$all")
  if internal "$name"; then brightness_percent; else echo; fi
  echo "$name"
  jq -r '[.[] | select(.focused)][0].scale // "" | tostring' <<<"$all"
  jq -c '[.[] | {name, enabled: (.disabled != true), focused: (.focused == true), width, height}]' <<<"$all"
}

# Hyprland only takes scales that divide the mode into whole logical pixels,
# in 1/120 steps; round up to the nearest one. Model.js cleanScale matches.
clean_scale() {
  awk -v scale="$1" -v width="$2" -v height="$3" '
    function gcd(a, b, t) { while (b) { t = a % b; a = b; b = t } return a }
    BEGIN {
      g = gcd(width * 120, height * 120)
      k = int(scale * 120 + 0.5)
      if (k > g) k = g
      while (g % k != 0) k++
      printf "%g\n", k / 120
    }'
}

scale() {
  local requested=$1 info name mode scale gdk tmp
  if [[ ! $requested =~ ^[0-9]+([.][0-9]+)?$ ]] || ! awk -v s="$requested" 'BEGIN { exit !(s >= 1 && s <= 4) }'; then
    echo "monitor: scale must be a number from 1 to 4" >&2
    return 2
  fi

  info=$(focused)
  name=$(jq -r .name <<<"$info")
  # The name lands inside the Lua below; only a plain connector name may.
  [[ $name =~ ^[A-Za-z0-9._-]+$ ]] || {
    echo "monitor: refusing output name '$name'" >&2
    return 1
  }
  mode=$(jq -r '"\(.width)x\(.height)@\(.refreshRate)"' <<<"$info")
  scale=$(clean_scale "$requested" "$(jq -r .width <<<"$info")" "$(jq -r .height <<<"$info")")
  # GTK takes only whole GDK_SCALE factors, so it gets the nearest one.
  gdk=$(awk -v s="$scale" 'BEGIN { printf "%d", int(s + 0.5) }')

  hyprctl eval "hl.monitor({ output = \"$name\", mode = \"$mode\", position = \"auto\", scale = $scale })" >/dev/null

  mkdir -p "${monitors_lua%/*}"
  tmp=$(mktemp "$monitors_lua.XXXXXX")
  cat >"$tmp" <<EOF
-- Written by the shell's display panel (hrndz-shell), which rewrites this
-- file on every scale change. Hand edits last until the next one.
-- GDK_SCALE applies to apps started after the next login.
local scale = $scale
local gdk_scale = $gdk
hl.env("GDK_SCALE", tostring(gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = scale })
EOF
  # mktemp makes it 0600; keep the usual mode of a config file.
  chmod 644 "$tmp"
  mv "$tmp" "$monitors_lua"
}

brightness() {
  local percent=${1:-} device
  if [[ ! $percent =~ ^[0-9]+$ ]] || ((percent < 1 || percent > 100)); then
    echo "monitor: brightness must be 1-100" >&2
    return 2
  fi
  device=$(backlight)
  [[ -n $device ]] || return 0
  brightnessctl -d "$device" set "$percent%" >/dev/null
}

case ${1:-} in
state) state ;;
scale) scale "${2:-}" ;;
brightness) brightness "${2:-}" ;;
*)
  echo "usage: monitor state | scale <scale> | brightness <percent>" >&2
  exit 2
  ;;
esac
