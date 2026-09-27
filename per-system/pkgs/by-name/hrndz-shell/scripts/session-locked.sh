# Exits 0 when the compositor holds a session lock, 1 when it does not, 2
# when it cannot tell yet.
#
# Hyprland reports no lock state directly, but an active ext-session-lock is
# one reason a monitor cannot go solitary: LOCK in solitaryBlockedBy. It stays
# set once the lock's client dies, which is the case worth detecting. A
# monitor with no workspace yet stops at WORKSPACE before reaching the lock,
# so a missing LOCK there means nothing.
monitors=$(hyprctl -j monitors 2>/dev/null) || exit 2

state=$(jq '
  def blockers: .solitaryBlockedBy // [];
  def readable: blockers | index("WORKSPACE") | not;
  if any(.[]; blockers | index("LOCK")) then 0
  elif any(.[]; readable) then 1
  else 2
  end
' <<<"$monitors" 2>/dev/null) || exit 2

case $state in
0 | 1) exit "$state" ;;
*) exit 2 ;;
esac
