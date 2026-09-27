# hrndz-shell: the one command bindings, menus and scripts call for what the
# desktop shell provides.
#   hrndz-shell <feature> [args]            see usage below
#   hrndz-shell ipc <target> <method> [args] raw IPC into the running shell

# The Quickshell config name Home Manager installs the shell under, and the
# user unit programs.quickshell runs it as.
config=hrndz-shell
unit=quickshell.service
state="$HOME/.local/state/hrndz-shell"

usage() {
  cat <<'USAGE'
usage: hrndz-shell <feature> [args]

  start                       start the shell (a no-op once it runs)
  launcher | menu | system-menu
  keybindings                 searchable list of the key bindings
  clipboard | emoji
  lock [--wait]               lock; --wait returns once the lock is secure
  bar                         show or hide the bar
  osd volume|microphone|brightness
  notifications dismiss-one|dismiss-all|invoke-last|history
  panel audio|bluetooth|network|power|display|calendar
  screenshot region|window|screen [--edit]
  color-picker
  ipc <target> <method> [args...]
USAGE
}

ipc() {
  # qs matches instances by display. A caller from outside the session (ssh,
  # desktop-vnc) has none, so recover it from the newest compositor socket.
  if [[ -z ${WAYLAND_DISPLAY:-} ]]; then
    local socket
    socket=$(find "${XDG_RUNTIME_DIR:-/run/user/$UID}" -maxdepth 1 -name 'wayland-[0-9]*' ! -name '*.lock' -printf '%T@ %f\n' 2>/dev/null |
      sort -rn | head -n1 | cut -d' ' -f2)
    [[ -n $socket ]] && export WAYLAND_DISPLAY=$socket
  fi

  # qs reports connection failures with a nonzero exit, but IPC-level ones
  # (unknown target, bad arguments) on stdout with exit 0.
  local output
  if ! output=$(timeout --kill-after=1s 2s qs ipc -n -c "$config" call -- "$@" 2>/dev/null); then
    echo "hrndz-shell: the shell is not running" >&2
    return 1
  fi
  case $output in
  "Target not found." | "Function not found." | "Too few arguments provided"* | "Too many arguments provided"* | "Not ready to accept queries yet"*)
    echo "hrndz-shell: $output" >&2
    return 1
    ;;
  esac
  [[ -z $output ]] || printf '%s\n' "$output"
}

toggle() {
  ipc shell toggle "$1" "${2:-"{}"}" >/dev/null
}

menu() {
  toggle omarchy.menu "$(jq -nc --arg menu "$1" '{menu: $menu}')"
}

# Pick one line from stdin in the menu; prints the pick, exits 1 on cancel.
select_line() {
  local prompt=$1 width=$2 height=$3 dir payload status=0
  dir=$(mktemp -d)
  payload=$(jq -Rsc --arg prompt "$prompt" --arg sel "$dir/selection" --arg donefile "$dir/done" \
    --argjson width "$width" --argjson height "$height" \
    '{mode: "select", prompt: $prompt, options: (split("\n") | map(select(length > 0))),
      selectionFile: $sel, doneFile: $donefile, width: $width, maxHeight: $height}')
  if ipc shell summon omarchy.menu "$payload" >/dev/null; then
    while [[ ! -e $dir/done ]]; do sleep 0.05; done
    [[ -s $dir/selection ]] && cat "$dir/selection" || status=1
  else
    status=1
  fi
  rm -rf "$dir"
  return "$status"
}

lock() {
  if [[ ${1:-} != --wait ]]; then
    [[ $(ipc lock lock) == ok ]]
    return
  fi

  # The lock is asynchronous, and a shell that is still starting refuses it
  # or is not answering yet; ask until the session reports secure.
  local deadline=$((SECONDS + 30)) status
  while ((SECONDS < deadline)); do
    status=$(ipc lock status 2>/dev/null |
      jq -r 'if .secure then "secure" elif .requested then "locking" else "idle" end' 2>/dev/null) || status=""
    case $status in
    secure) return 0 ;;
    locking) ;;
    *) ipc lock lock >/dev/null 2>&1 || true ;;
    esac
    sleep 0.1
  done
  echo "hrndz-shell: the session did not lock" >&2
  return 1
}

toggle_bar() {
  local flag="$state/toggles/bar-off"
  if [[ -e $flag ]]; then
    rm -f "$flag"
  else
    mkdir -p "${flag%/*}"
    touch "$flag"
  fi
  # The shell's watch on the toggles directory can miss quick flips.
  ipc omarchy.bar syncHidden >/dev/null 2>&1 || true
}

# osd <icon> <percent>
show_osd() {
  ipc osd show "$(jq -nc --arg icon "$1" --arg value "$2" \
    '{icon: $icon, message: "", value: $value, progressText: ($value + "%"), max: "100", duration: ""}')" >/dev/null
}

osd() {
  local out percent device
  case ${1:-} in
  volume | microphone)
    device=$([[ $1 == volume ]] && echo @DEFAULT_AUDIO_SINK@ || echo @DEFAULT_AUDIO_SOURCE@)
    # "Volume: 0.45" or "Volume: 0.45 [MUTED]"
    out=$(wpctl get-volume "$device") || return 1
    percent=$(awk '{ printf "%d", $2 * 100 + 0.5 }' <<<"$out")
    if [[ $out == *MUTED* ]]; then
      show_osd "$([[ $1 == volume ]] && echo volume-muted || echo microphone-muted)" "$percent"
    else
      # An empty icon lets the OSD pick the volume glyph by level.
      show_osd "$([[ $1 == volume ]] && echo "" || echo microphone)" "$percent"
    fi
    ;;
  brightness)
    # "device,class,current,percent%,max"; no backlight means nothing to show.
    out=$(brightnessctl -m 2>/dev/null) || return 0
    percent=$(cut -d, -f4 <<<"$out")
    show_osd brightness "${percent%\%}"
    ;;
  *)
    usage >&2
    return 2
    ;;
  esac
}

notifications() {
  local method
  case ${1:-} in
  dismiss-one) method=dismissOne ;;
  dismiss-all) method=dismissAll ;;
  invoke-last) method=invokeLast ;;
  history) method=showHistory ;;
  *)
    usage >&2
    return 2
    ;;
  esac
  ipc notifications "$method" >/dev/null
}

panel() {
  local id
  case ${1:-} in
  audio | bluetooth | network | power) id=omarchy.$1 ;;
  display) id=omarchy.monitor ;;
  calendar) id=omarchy.clock ;;
  *)
    usage >&2
    return 2
    ;;
  esac
  toggle "$id"
}

keybindings() {
  local list="${XDG_CONFIG_HOME:-$HOME/.config}/hrndz-shell/keybindings.txt"
  [[ -r $list ]] || {
    echo "hrndz-shell: no $list" >&2
    return 1
  }
  # CEILING: a read-only reference; picking a row only closes the menu.
  # Dispatching the pick would need the bind's action next to each line.
  select_line Keybindings 800 500 <"$list" >/dev/null || true
}

screenshot() {
  local mode=${1:-region} edit=${2:-} dir file region
  local -a target
  dir="${XDG_PICTURES_DIR:-$HOME/Pictures}"
  mkdir -p "$dir"
  file="$dir/screenshot-$(date +%Y-%m-%d_%H-%M-%S).png"
  case $mode in
  region)
    region=$(slurp -d) || return 0
    target=(-g "$region")
    ;;
  window) target=(-g "$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')") ;;
  screen) target=(-o "$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')") ;;
  *)
    usage >&2
    return 2
    ;;
  esac
  if [[ $edit == --edit ]]; then
    grim "${target[@]}" - | satty --filename - --output-filename "$file" --early-exit --copy-command wl-copy
  else
    grim "${target[@]}" "$file" && wl-copy --type image/png <"$file"
  fi
}

feature=${1:-}
shift || true
case $feature in
start) systemctl --user start "$unit" ;;
launcher) menu apps ;;
menu) menu root ;;
system-menu) menu system ;;
keybindings) keybindings ;;
clipboard) toggle omarchy.clipboard ;;
emoji) toggle omarchy.emojis ;;
lock) lock "$@" ;;
bar) toggle_bar ;;
osd) osd "$@" ;;
notifications) notifications "$@" ;;
panel) panel "$@" ;;
screenshot) screenshot "$@" ;;
color-picker) pkill hyprpicker || hyprpicker -a ;;
ipc) ipc "$@" ;;
-h | --help | help) usage ;;
*)
  usage >&2
  exit 2
  ;;
esac
