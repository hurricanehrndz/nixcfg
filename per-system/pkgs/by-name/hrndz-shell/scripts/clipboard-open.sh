# Opens a clipboard history entry: a URL in the browser, other text in the
# default text handler, an image in the default image viewer.
#   clipboard-open --history-index <n>

history="$HOME/.local/state/hrndz-shell/clipboard-history.json"
index=""
[[ ${1:-} == --history-index ]] && index=${2:-}
[[ $index =~ ^[0-9]+$ && -r $history ]] || exit 1

case $(jq -er --argjson i "$index" '.[$i].type' "$history") in
image)
  exec xdg-open "$(jq -er --argjson i "$index" '.[$i].path' "$history")"
  ;;
text)
  text=$(jq -er --argjson i "$index" '.[$i].text' "$history")
  url=$(grep -Eom1 'https?://[^[:space:]"'\''<>]+' <<<"$text" || true)
  [[ -n $url ]] && exec xdg-open "$url"
  dir="$HOME/.local/state/hrndz-shell/clipboard-open"
  mkdir -p "$dir"
  file=$(mktemp --tmpdir="$dir" clipboard.XXXXXX.txt)
  printf '%s' "$text" >"$file"
  exec xdg-open "$file"
  ;;
*) exit 1 ;;
esac
