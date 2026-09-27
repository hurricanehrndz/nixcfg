# power: the power panel's reads and writes, ported from Omarchy's
# omarchy-battery-status --shell and omarchy-powerprofiles-{list,set}.
#   power battery              key<TAB>value lines; nothing without a battery
#   power profiles             <profile><TAB><1 if active> per profile
#   power set-profile <name>   switch power-profiles-daemon to it
#
# Omarchy also remembered a profile per AC/battery and restored it on plug
# events; nothing here restores it, so a pick simply stands until changed.

supplies=/sys/class/power_supply

battery() {
  local battery info percentage capacity time rate native path state start end
  battery=$(upower -e 2>/dev/null | grep BAT | head -n1) || true
  [[ -n $battery ]] || return 0
  info=$(upower -i "$battery")

  percentage=$(awk '/percentage/ { print int($2); exit }' <<<"$info")
  capacity=$(awk '/energy-full:/ { printf "%d", $2; exit }' <<<"$info")
  time=$(awk '/time to (empty|full)/ {
    value = $4; unit = $5
    if (unit ~ /^minute/) printf "%dm", int(value)
    else {
      hours = int(value); minutes = int((value - hours) * 60)
      if (minutes > 0) printf "%dh %dm", hours, minutes
      else printf "%dh", hours
    }
    exit
  }' <<<"$info")
  rate=$(awk '/energy-rate/ { print $2; exit }' <<<"$info")
  native=$(awk '/native-path/ { print $2; exit }' <<<"$info")
  path=$supplies/$native

  # UPower's energy-rate lags the kernel by tens of seconds; sysfs is live.
  if [[ -r $path/power_now ]]; then
    rate=$(awk -v uw="$(<"$path/power_now")" 'BEGIN { print uw / 1000000 }')
  elif [[ -r $path/current_now && -r $path/voltage_now ]]; then
    rate=$(awk -v ua="$(<"$path/current_now")" -v uv="$(<"$path/voltage_now")" 'BEGIN { print ua * uv / 1000000000000 }')
  fi

  state=$(awk '/state/ { print $2; exit }' <<<"$info")
  start=$(awk '/charge-start-threshold:/ { gsub(/%/, "", $2); print int($2); exit }' <<<"$info")
  end=$(awk '/charge-end-threshold:/ { gsub(/%/, "", $2); print int($2); exit }' <<<"$info")
  [[ -n $end ]] || end=$(cat "$supplies"/BAT*/charge_control_end_threshold 2>/dev/null | head -n1) || true
  [[ -n $start ]] || start=$(cat "$supplies"/BAT*/charge_control_start_threshold 2>/dev/null | head -n1) || true

  local ac=false supply
  for supply in "$supplies"/*; do
    if [[ -r $supply/type && $(<"$supply/type") == Mains && -r $supply/online && $(<"$supply/online") == 1 ]]; then
      ac=true
      break
    fi
  done

  # On AC below a charge threshold the battery holds rather than charges.
  local holding=false
  if [[ $ac == true && -n $end ]]; then
    if [[ $state == pending-charge ]] || { [[ $state == fully-charged ]] && ((percentage < 99)); }; then
      holding=true
    elif [[ $state == charging ]] && awk -v r="${rate:-0}" 'BEGIN { exit !(r <= 0.2) }' && ((end < 99 && percentage >= end)); then
      holding=true
    fi
  fi

  printf 'percentage\t%s%%\n' "$percentage"
  printf 'state\t%s\n' "$([[ $holding == true ]] && echo holding || echo "$state")"
  printf 'rate\t%sW\n' "$(awk -v r="${rate:-0}" 'BEGIN { s = sprintf("%.1f", r); sub(/\.0$/, "", s); print s }')"
  printf 'size\t%sWh\n' "$capacity"
  printf 'time\t%s\n' "$time"

  local cycles
  cycles=$(cat "$supplies"/BAT*/cycle_count 2>/dev/null | head -n1) || true
  [[ -z $cycles ]] || printf 'cycles\t%s\n' "$cycles"
  if [[ -n $end ]]; then
    if [[ -n $start && $start != "$end" ]]; then
      printf 'threshold\t%s-%s%%\n' "$start" "$end"
    else
      printf 'threshold\t%s%%\n' "$end"
    fi
  fi
}

# powerprofilesctl lists the active profile with a leading '*', highest first.
profiles() {
  powerprofilesctl list 2>/dev/null |
    awk '/^\s*[* ]\s*[a-zA-Z0-9-]+:$/ {
      active = ($1 == "*") ? 1 : 0
      gsub(/^[*[:space:]]+|:$/, "")
      print $0 "\t" active
    }' | tac
}

case ${1:-} in
battery) battery ;;
profiles) profiles ;;
set-profile)
  [[ -n ${2:-} ]] || {
    echo "usage: power set-profile <profile>" >&2
    exit 2
  }
  powerprofilesctl set "$2"
  ;;
*)
  echo "usage: power battery | profiles | set-profile <profile>" >&2
  exit 2
  ;;
esac
