# Split DNS for Tailscale without letting Tailscale take over as the default
# resolver. Use with `tailscale set --accept-dns=false`.
#
# Registers a supplemental resolver in configd's dynamic store. Its match
# domains are also appended to the global search list, so short names work.
#
# CEILING: State: keys are in-memory; they're gone after reboot or a configd
# restart. Re-run `tsdns up`, or wrap it in a LaunchDaemon if that gets old.

PREFIX="State:/Network/Service/tsdns"

# One key per nameserver: "name nameserver domain..."
RESOLVERS=(
  "magicdns 100.100.100.100 long-bee.ts.net"
  "home 172.24.224.1 hrndz.ca lan.internal"
)

flush() {
  dscacheutil -flushcache
  killall -HUP mDNSResponder
}

case "${1:-status}" in
up)
  [[ $EUID -eq 0 ]] || exec sudo "$0" "$@"
  for r in "${RESOLVERS[@]}"; do
    read -r name ns domains <<<"$r"
    scutil <<EOF
d.init
d.add ServerAddresses * $ns
d.add SupplementalMatchDomains * $domains
set $PREFIX-$name/DNS
EOF
  done
  flush
  ;;
down)
  [[ $EUID -eq 0 ]] || exec sudo "$0" "$@"
  for r in "${RESOLVERS[@]}"; do
    scutil <<<"remove $PREFIX-${r%% *}/DNS"
  done
  flush
  ;;
status)
  for r in "${RESOLVERS[@]}"; do
    echo "== ${r%% *}"
    scutil <<<"show $PREFIX-${r%% *}/DNS"
  done
  ;;
*)
  echo "usage: ${0##*/} up|down|status" >&2
  exit 2
  ;;
esac
