# Types an emoji into the focused window. The copy is sensitive so the
# clipboard history skips it, and only lives until the paste has landed.
emoji=${1:-}
[[ -n $emoji ]] || exit 0

printf '%s' "$emoji" | wl-copy --type text/plain --sensitive --foreground &
copy_pid=$!

sleep 0.15
wtype -M shift -k Insert -m shift 2>/dev/null || true
sleep 0.2

kill "$copy_pid" 2>/dev/null || true
