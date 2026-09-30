# Copies a clipboard history entry, a file, or some text to the clipboard
# and pastes it into the focused window, the way SUPER + V does: Shift+Insert
# in terminals, Ctrl+V elsewhere (browsers ignore Shift+Insert).
#   clipboard-paste [--copy-only] --history-index <n>
#   clipboard-paste [--copy-only] --file <mime> <path>
#   clipboard-paste [--copy-only] --text <text>

history="$HOME/.local/state/hrndz-shell/clipboard-history.json"
copy_only=false
index=""
mime=""
path=""
text=""

while (($# > 0)); do
  case $1 in
  --copy-only)
    copy_only=true
    shift
    ;;
  --history-index)
    index=${2:-}
    shift 2
    ;;
  --file)
    mime=${2:-}
    path=${3:-}
    shift 3
    ;;
  --text)
    text=${2:-}
    shift 2
    ;;
  *)
    echo "usage: clipboard-paste [--copy-only] (--history-index <n> | --file <mime> <path> | --text <text>)" >&2
    exit 2
    ;;
  esac
done

if [[ -n $index ]]; then
  [[ $index =~ ^[0-9]+$ ]] || exit 1
  jq -e --argjson i "$index" '.[$i].type == "text" and (.[$i].text | type == "string")' "$history" >/dev/null || exit 1
  jq -j --argjson i "$index" '.[$i].text' "$history" | wl-copy
elif [[ -n $mime && -r $path ]]; then
  wl-copy --type "$mime" <"$path"
elif [[ -n $text ]]; then
  printf '%s' "$text" | wl-copy --type text/plain
else
  exit 1
fi

$copy_only && exit 0

mods=CTRL key=V
if hyprctl activewindow -j 2>/dev/null | jq -e 'any(.tags[]?; sub("\\*$"; "") == "terminal")' >/dev/null; then
  mods=SHIFT key=Insert
fi

send() {
  hyprctl dispatch "hl.dsp.send_key_state({ mods = \"$mods\", key = \"$key\", state = \"$1\" })" >/dev/null
}

sleep 0.15
send down
sleep 0.05
send up
