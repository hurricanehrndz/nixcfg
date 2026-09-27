# agent-usage-update [--force] [--limits-only] [--except <agent>] [agent...]
# Regenerate the agents panel's usage records, ported from Omarchy's
# omarchy-agent-usage-update. Each agent-usage-<agent> collector prints one
# JSON record; this writes it to ~/.local/state/hrndz-shell/agents/usage/,
# which the panel watches. The Home Manager timer runs it plainly; the panel
# runs it with --limits-only on open and --force on refresh.

agents=(claude codex)
usage_dir="${XDG_STATE_HOME:-$HOME/.local/state}/hrndz-shell/agents/usage"
mkdir -p "$usage_dir"

flags=()
only=()
declare -A excluded=()
while (($#)); do
  case $1 in
  --force | --limits-only) flags+=("$1") ;;
  --except)
    excluded[${2:?--except needs an agent}]=1
    shift
    ;;
  *) only+=("$1") ;;
  esac
  shift
done

wanted() {
  [[ -z ${excluded[$1]:-} ]] || return 1
  ((${#only[@]} == 0)) && return 0
  [[ " ${only[*]} " == *" $1 "* ]]
}

collect() {
  local agent=$1 record tmp
  if ! record=$("agent-usage-$agent" "${flags[@]}") || ! jq -e . >/dev/null 2>&1 <<<"$record"; then
    echo "agent-usage-update: the $agent collector failed" >&2
    return 1
  fi
  tmp=$(mktemp "$usage_dir/.$agent.XXXXXX")
  printf '%s\n' "$record" >"$tmp"
  mv "$tmp" "$usage_dir/$agent.json"
}

pids=()
for agent in "${agents[@]}"; do
  wanted "$agent" || continue
  collect "$agent" &
  pids+=($!)
done

status=0
for pid in "${pids[@]}"; do
  wait "$pid" || status=1
done
exit "$status"
