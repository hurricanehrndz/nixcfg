#!/usr/bin/env bash
set -euo pipefail

source_dir=$(cd "$(dirname "$0")/.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
mkdir -p "$test_dir/bin" "$test_dir/config"

export XDG_RUNTIME_DIR="$test_dir/run"
export XDG_CONFIG_HOME="$test_dir/config"
export MOCK_MONITORS="$test_dir/monitors.json"
export MOCK_EVALS="$test_dir/evals"
export MOCK_TIMERS="$test_dir/timers"
export HOME="$test_dir/home"
export PATH="$test_dir/bin:$PATH"

cat >"$test_dir/bin/hyprctl" <<'EOF'
#!/usr/bin/env bash
if [[ $1 == monitors ]]; then
  cat "$MOCK_MONITORS"
elif [[ $1 == eval ]]; then
  printf '%s\n' "$2" >>"$MOCK_EVALS"
else
  exit 1
fi
EOF
for name in flock systemctl; do
  printf '#!/usr/bin/env bash\nexit 0\n' >"$test_dir/bin/$name"
done
cat >"$test_dir/bin/systemd-run" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$MOCK_TIMERS"
EOF
chmod +x "$test_dir/bin/"*

cat >"$MOCK_MONITORS" <<'EOF'
[
  {"name":"eDP-1","focused":true,"disabled":false,"width":1920,"height":1200,"refreshRate":60,"x":0,"y":0,"scale":1},
  {"name":"DP-1","focused":false,"disabled":false,"width":2560,"height":1440,"refreshRate":60,"x":1920,"y":0,"scale":1.25}
]
EOF

monitor="$source_dir/scripts/monitor.sh"
run_monitor() { bash -euo pipefail "$monitor" "$@"; }

run_monitor scale 1.5
[[ -f $XDG_RUNTIME_DIR/hrndz-monitor/scale-preview ]]
[[ ! -e $XDG_CONFIG_HOME/hypr/monitors.lua ]]
grep -q 'output = "eDP-1".*scale = 1.5' "$MOCK_EVALS"
grep -q -- '--on-active=15s' "$MOCK_TIMERS"

run_monitor revert
[[ ! -e $XDG_RUNTIME_DIR/hrndz-monitor/scale-preview ]]
grep -q 'output = "eDP-1".*scale = 1 })' "$MOCK_EVALS"

run_monitor scale 1.5
run_monitor confirm
config_file="$XDG_CONFIG_HOME/hypr/monitors.lua"
grep -q 'output = "eDP-1".*scale = 1.5' "$config_file"
grep -q 'output = "DP-1".*scale = 1.25' "$config_file"

cat >"$MOCK_MONITORS" <<'EOF'
[
  {"name":"eDP-1","focused":false,"disabled":false,"width":1920,"height":1200,"refreshRate":60,"x":0,"y":0,"scale":1.5},
  {"name":"DP-1","focused":true,"disabled":false,"width":2560,"height":1440,"refreshRate":60,"x":1920,"y":0,"scale":1.25}
]
EOF
run_monitor scale 2
run_monitor confirm
grep -q 'output = "eDP-1".*scale = 1.5' "$config_file"
grep -q 'output = "DP-1".*scale = 2' "$config_file"
[[ $(grep -c '^hl.monitor' "$config_file") == 2 ]]
