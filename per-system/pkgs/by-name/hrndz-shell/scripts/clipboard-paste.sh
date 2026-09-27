# Copies a clipboard history entry (or a file) back to the clipboard and
# pastes it into the focused window with Shift+Insert, which terminals and
# GUI apps both accept.
#   clipboard-paste [--copy-only] --history-index <n>
#   clipboard-paste [--copy-only] --file <mime> <path>

history="$HOME/.local/state/hrndz-shell/clipboard-history.json"
copy_only=false
index=""
mime=""
path=""

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
  *)
    echo "usage: clipboard-paste [--copy-only] (--history-index <n> | --file <mime> <path>)" >&2
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
else
  exit 1
fi

$copy_only && exit 0

sleep 0.15
wtype -M shift -k Insert -m shift 2>/dev/null || true
