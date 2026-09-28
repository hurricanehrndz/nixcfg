# Copies an emoji to the clipboard and pastes it into the focused window
# with Shift+Insert. The primary selection gets it too, since terminals such
# as Ghostty paste the primary selection on Shift+Insert.
emoji=${1:-}
[[ -n $emoji ]] || exit 0

printf '%s' "$emoji" | wl-copy --type text/plain
printf '%s' "$emoji" | wl-copy --primary --type text/plain

sleep 0.15
wtype -M shift -k Insert -m shift 2>/dev/null || true
