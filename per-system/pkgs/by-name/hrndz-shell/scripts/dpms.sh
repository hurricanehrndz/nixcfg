# Turns every display off or on, and tells the shell, which pauses the
# ambient video while they are off.
notify() {
  hrndz-shell ipc ambient displays "$1" >/dev/null 2>&1 || true
}

case ${1:-} in
off)
  hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })' >/dev/null
  notify false
  ;;
on)
  notify true
  # A redundant enable right after resume forces another modeset, which
  # blanks the panel for a beat, so skip it when every display is lit.
  hyprctl monitors -j 2>/dev/null |
    jq -e '[.[] | select(.disabled == false)] | length > 0 and all(.dpmsStatus)' >/dev/null 2>&1 && exit 0
  hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })' >/dev/null
  ;;
*)
  echo "usage: dpms on|off" >&2
  exit 2
  ;;
esac
