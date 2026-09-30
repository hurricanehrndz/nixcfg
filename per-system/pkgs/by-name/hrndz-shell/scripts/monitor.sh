# monitor: the display panel's reads and writes, ported from Omarchy's
# omarchy-monitor-state, omarchy-hyprland-monitor-scaling and the backlight
# half of omarchy-brightness-display.
#   monitor state          four lines: brightness percent (empty when the
#                          focused display can't report it), focused output,
#                          its scale, and a JSON array of the displays
#   monitor scale <scale>  preview on the focused display for 15 seconds;
#                          exits 3 when the display is already at that scale
#   monitor confirm        persist the preview per display
#   monitor revert         restore the previous scale
#   monitor brightness <N> set the focused display's brightness to N percent
#   monitor text-size <px> set the shell's base font size and scale GTK text
#                          to match (omarchy-display-text-size)
#
# Internal panels (eDP/LVDS/DSI) use the backlight through brightnessctl,
# external monitors DDC/CI through ddcutil. A sleeping monitor doesn't answer
# DDC, so the panel hides its slider until it wakes.
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

# ddcutil's I2C bus for a connector, looked up once per boot; the lookup
# takes seconds. Monitors don't move buses without a replug.
# CEILING: a monitor plugged into a new connector after the first lookup
# needs the runtime cache cleared (or a new login) to get brightness.
ddc_bus() {
  local name=$1 cache="$preview_dir/ddc-bus-$1" bus=
  if [[ ! -f $cache ]]; then
    mkdir -p "$preview_dir"
    bus=$(ddcutil detect --terse 2>/dev/null | awk -v name="$name" '
      /I2C bus:/ { bus = $NF; sub(".*i2c-", "", bus) }
      /DRM connector:/ { c = $NF; sub("^card[0-9]+-", "", c); if (c == name) { print bus; exit } }')
    echo "${bus:-none}" >"$cache"
  fi
  bus=$(<"$cache")
  [[ $bus =~ ^[0-9]+$ ]] && echo "$bus"
}

# One ddcutil call at a time per bus: overlapping transactions fail.
ddc() {
  local bus=$1
  shift
  {
    flock 8
    ddcutil --bus "$bus" "$@"
  } 8>"$preview_dir/ddc-$bus.lock"
}

# The monitor's brightness (VCP 0x10) as a percent of its maximum, which is
# remembered for writes.
ddc_percent() {
  local bus out
  bus=$(ddc_bus "$1") || return 0
  out=$(ddc "$bus" getvcp 10 --brief 2>/dev/null) || return 0
  read -r _ _ _ current max <<<"$out"
  [[ $current =~ ^[0-9]+$ && $max =~ ^[1-9][0-9]*$ ]] || return 0
  echo "$max" >"$preview_dir/ddc-max-$bus"
  echo $(((current * 100 + max / 2) / max))
}

state() {
  local all name
  all=$(hyprctl monitors all -j)
  name=$(jq -r '[.[] | select(.focused)][0].name // ""' <<<"$all")
  if internal "$name"; then
    printf '%s\n' "$(brightness_percent)"
  else
    printf '%s\n' "$(ddc_percent "$name")"
  fi
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
  # dies, late enough that a last-second Keep still finds the preview. User
  # timers default to a minute's accuracy, which let it fire at 40s or later.
  if ! systemd-run --user --quiet --collect --unit="$preview_unit" --on-active=20s \
    --timer-property=AccuracySec=1s "${timer_env[@]}" "$0" revert; then
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
  local percent=${1:-} name device bus max=100
  if [[ ! $percent =~ ^[0-9]+$ ]] || ((percent < 1 || percent > 100)); then
    echo "monitor: brightness must be 1-100" >&2
    return 2
  fi
  name=$(focused | jq -r .name)
  if internal "$name"; then
    device=$(backlight)
    [[ -n $device ]] || return 0
    brightnessctl -d "$device" set "$percent%" >/dev/null
    return
  fi
  bus=$(ddc_bus "$name") || return 0
  [[ -f $preview_dir/ddc-max-$bus ]] && max=$(<"$preview_dir/ddc-max-$bus")
  ddc "$bus" setvcp 10 $(((percent * max + 50) / 100)) --noverify
}

# The shell layers the state file over its Nix theme and watches it. GTK's
# text-scaling-factor is relative to the shell's default 12px.
# CEILING: Ghostty keeps its own font-size; ctrl+= / ctrl+- zoom per window.
text_size() {
  local px=${1:-} state_file tmp
  if [[ ! $px =~ ^[0-9]+$ ]] || ((px < 6 || px > 32)); then
    echo "monitor: text size must be 6-32" >&2
    return 2
  fi
  state_file="$HOME/.local/state/hrndz-shell/shell.toml"
  mkdir -p "${state_file%/*}"
  tmp=$(mktemp "$state_file.XXXXXX")
  printf '[font]\nbase-size = %s\n' "$px" >"$tmp"
  mv "$tmp" "$state_file"
  dconf write /org/gnome/desktop/interface/text-scaling-factor "$(awk -v px="$px" 'BEGIN { printf "%.4f", px / 12 }')"
}

case ${1:-} in
state) state ;;
scale) scale "${2:-}" ;;
confirm) confirm_scale ;;
revert) revert_scale ;;
brightness) brightness "${2:-}" ;;
text-size) text_size "${2:-}" ;;
*)
  echo "usage: monitor state | scale <scale> | confirm | revert | brightness <percent> | text-size <px>" >&2
  exit 2
  ;;
esac
