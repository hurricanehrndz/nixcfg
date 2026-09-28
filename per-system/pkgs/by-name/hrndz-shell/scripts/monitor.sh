# monitor: the display panel's reads and writes, ported from Omarchy's
# omarchy-monitor-state, omarchy-hyprland-monitor-scaling and the backlight
# half of omarchy-brightness-display.
#   monitor state          four lines: brightness percent (empty without a
#                          backlight on the focused display), focused output,
#                          its scale, and a JSON array of the displays
#   monitor scale <scale>  preview on the focused display for 15 seconds;
#                          exits 3 when the display is already at that scale
#   monitor confirm        persist the preview per display
#   monitor revert         restore the previous scale
#   monitor brightness <N> set the internal panel's backlight to N percent
#
# CEILING: brightness covers internal panels (eDP/LVDS/DSI) through
# brightnessctl only. External monitors report no brightness; DDC/CI
# (ddcutil, hardware.i2c) would be the upgrade.
#
# Scale persists in $XDG_CONFIG_HOME/hypr/monitors.lua, which the Hyprland
# config loads after its fallback rule. This rewrites the generated file.
# CEILING: hand-written Lua in that file is replaced on confirmation; put
# custom monitor rules in Hyprland's main config if they must coexist.

monitors_lua="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/monitors.lua"
preview_dir="${XDG_RUNTIME_DIR:-/run/user/$UID}/hrndz-monitor"
preview_file="$preview_dir/scale-preview"
preview_unit=hrndz-monitor-revert

lock_preview() {
  mkdir -p "$preview_dir"
  exec 9>"$preview_dir/lock"
  flock 9
}

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

valid_scale() {
  [[ $1 =~ ^[0-9]+([.][0-9]+)?$ ]] && awk -v s="$1" 'BEGIN { exit !(s >= 0.5 && s <= 4) }'
}

apply_live() {
  local name=$1 mode=$2 position=$3 scale=$4
  hyprctl eval "hl.monitor({ output = \"$name\", mode = \"$mode\", position = \"$position\", scale = $scale })" >/dev/null
}

stop_preview_timer() {
  systemctl --user stop "$preview_unit.timer" 2>/dev/null || true
}

read_preview() {
  [[ -f $preview_file ]] || {
    echo "monitor: no scale preview is pending" >&2
    return 1
  }
  IFS=$'\t' read -r preview_name preview_mode preview_position preview_old_scale preview_new_scale <"$preview_file"
}

scale() {
  local requested=${1:-} info name mode position old_scale new_scale tmp variable
  local -a timer_env=()
  valid_scale "$requested" || {
    echo "monitor: scale must be a number from 0.5 to 4" >&2
    return 2
  }
  lock_preview
  [[ ! -f $preview_file ]] || {
    echo "monitor: finish the current scale preview first" >&2
    return 1
  }

  info=$(focused)
  name=$(jq -r .name <<<"$info")
  # Values land inside Lua; validate every interpolated field.
  [[ $name =~ ^[A-Za-z0-9._-]+$ ]] || {
    echo "monitor: refusing output name '$name'" >&2
    return 1
  }
  mode=$(jq -r '"\(.width)x\(.height)@\(.refreshRate)"' <<<"$info")
  position=$(jq -r '"\(.x)x\(.y)"' <<<"$info")
  old_scale=$(jq -r '.scale | tostring' <<<"$info")
  [[ $mode =~ ^[0-9]+x[0-9]+@[0-9]+([.][0-9]+)?$ && $position =~ ^-?[0-9]+x-?[0-9]+$ ]] || {
    echo "monitor: invalid focused monitor geometry" >&2
    return 1
  }
  new_scale=$(clean_scale "$requested" "$(jq -r .width <<<"$info")" "$(jq -r .height <<<"$info")")
  [[ $new_scale != "$old_scale" ]] || return 3

  tmp=$(mktemp "$preview_file.XXXXXX")
  printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$mode" "$position" "$old_scale" "$new_scale" >"$tmp"
  mv "$tmp" "$preview_file"
  systemctl --user reset-failed "$preview_unit.service" "$preview_unit.timer" 2>/dev/null || true
  for variable in HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_RUNTIME_DIR; do
    if [[ -n ${!variable:-} ]]; then timer_env+=("--setenv=$variable=${!variable}"); fi
  done
  # The panel reverts at 15 seconds. This timer is the backstop if the shell
  # dies, late enough that a last-second Keep still finds the preview.
  if ! systemd-run --user --quiet --collect --unit="$preview_unit" --on-active=20s \
    "${timer_env[@]}" "$0" revert; then
    rm -f "$preview_file"
    return 1
  fi
  if ! apply_live "$name" "$mode" "$position" "$new_scale"; then
    stop_preview_timer
    rm -f "$preview_file"
    return 1
  fi
}

write_scales() {
  local target=$1 target_scale=$2 all name scale tmp gdk_scale
  local -A scales=()
  local -a names=()

  # Carry forward disconnected outputs from the last generated file. Only
  # strict generated rules are parsed; hand-written Lua is not executed here.
  if [[ -f $monitors_lua ]]; then
    while read -r name scale; do
      if [[ $name =~ ^[A-Za-z0-9._-]+$ ]] && valid_scale "$scale"; then
        scales[$name]=$scale
      fi
    done < <(sed -nE 's/^hl\.monitor\(\{ output = "([A-Za-z0-9._-]+)", mode = "preferred", position = "auto", scale = ([0-9]+(\.[0-9]+)?) \}\)$/\1 \2/p' "$monitors_lua")
  fi

  all=$(hyprctl monitors all -j) || return 1
  while IFS=$'\t' read -r name scale; do
    if [[ $name =~ ^[A-Za-z0-9._-]+$ ]] && valid_scale "$scale"; then
      scales[$name]=$scale
    fi
  done < <(jq -r '.[] | select(.disabled != true) | [.name, (.scale | tostring)] | @tsv' <<<"$all")
  scales[$target]=$target_scale

  mkdir -p "${monitors_lua%/*}"
  tmp=$(mktemp "$monitors_lua.XXXXXX")
  mapfile -t names < <(printf '%s\n' "${!scales[@]}" | LC_ALL=C sort)
  # XWayland apps are unscaled (force_zero_scaling) and GTK takes only whole
  # factors, so GDK_SCALE is the largest enabled output's scale, rounded.
  # The preview is live while confirming, so this includes the new scale.
  gdk_scale=$(jq -r '[.[] | select(.disabled != true) | .scale] | max // 1' <<<"$all")
  gdk_scale=$(awk -v s="$gdk_scale" 'BEGIN { g = int(s + 0.5); print (g < 1 ? 1 : g) }')
  {
    printf '%s\n' '-- Managed by hrndz-shell. Scale is stored per connector.'
    printf '%s\n' '-- GDK_SCALE applies to apps started after the next login.'
    printf 'hl.env("GDK_SCALE", "%s")\n' "$gdk_scale"
    for name in "${names[@]}"; do
      printf 'hl.monitor({ output = "%s", mode = "preferred", position = "auto", scale = %s })\n' "$name" "${scales[$name]}"
    done
  } >"$tmp"
  chmod 644 "$tmp"
  mv "$tmp" "$monitors_lua"
}

confirm_scale() {
  lock_preview
  read_preview || return 1
  write_scales "$preview_name" "$preview_new_scale" || return 1
  rm -f "$preview_file"
  stop_preview_timer
}

revert_scale() {
  lock_preview
  [[ -f $preview_file ]] || return 0
  read_preview || return 1
  apply_live "$preview_name" "$preview_mode" "$preview_position" "$preview_old_scale" || return 1
  rm -f "$preview_file"
  stop_preview_timer
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
confirm) confirm_scale ;;
revert) revert_scale ;;
brightness) brightness "${2:-}" ;;
*)
  echo "usage: monitor state | scale <scale> | confirm | revert | brightness <percent>" >&2
  exit 2
  ;;
esac
