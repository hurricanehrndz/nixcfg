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
export MOCK_DCONF="$test_dir/dconf"
export MOCK_DDC="$test_dir/ddc"
export HOME="$test_dir/home"
export PATH="$test_dir/bin:$PATH"

# Mocks use this bash: the build sandbox has no /usr/bin/env.
shebang="#!$BASH"
{
  echo "$shebang"
  cat <<'EOF'
if [[ $1 == monitors ]]; then
  cat "$MOCK_MONITORS"
elif [[ $1 == eval ]]; then
  printf '%s\n' "$2" >>"$MOCK_EVALS"
else
  exit 1
fi
EOF
} >"$test_dir/bin/hyprctl"
for name in flock systemctl; do
  printf '%s\nexit 0\n' "$shebang" >"$test_dir/bin/$name"
done
{
  echo "$shebang"
  cat <<'EOF'
printf '%s\n' "$*" >>"$MOCK_TIMERS"
EOF
} >"$test_dir/bin/systemd-run"
{
  echo "$shebang"
  cat <<'EOF'
printf '%s\n' "$*" >>"$MOCK_DCONF"
EOF
} >"$test_dir/bin/dconf"
{
  echo "$shebang"
  cat <<'EOF'
printf '%s\n' "$*" >>"$MOCK_DDC"
case "$*" in
"detect --terse")
  printf 'Display 1\n   I2C bus:  /dev/i2c-3\n   DRM connector:  card1-HDMI-A-1\n'
  printf 'Invalid display\n   I2C bus:  /dev/i2c-7\n   DRM connector:  card1-DP-1\n'
  ;;
"--bus 7 getvcp 10 --brief") echo "VCP 10 C 100 200" ;;
"--bus 7 setvcp"*) ;;
*) exit 1 ;;
esac
EOF
} >"$test_dir/bin/ddcutil"
chmod +x "$test_dir/bin/"*

cat >"$MOCK_MONITORS" <<'EOF'
[
  {"name":"eDP-1","focused":true,"disabled":false,"width":1920,"height":1200,"refreshRate":60,"x":0,"y":0,"scale":1},
  {"name":"DP-1","focused":false,"disabled":false,"width":2560,"height":1440,"refreshRate":60,"x":1920,"y":0,"scale":1.25}
]
EOF

monitor="$source_dir/scripts/monitor.sh"
run_monitor() { bash -euo pipefail "$monitor" "$@"; }

# Asking for the current scale previews nothing, so the panel shows no prompt.
status=0
run_monitor scale 1 || status=$?
[[ $status == 3 && ! -e $XDG_RUNTIME_DIR/hrndz-monitor/scale-preview ]]

run_monitor scale 1.5
[[ -f $XDG_RUNTIME_DIR/hrndz-monitor/scale-preview ]]
[[ ! -e $XDG_CONFIG_HOME/hypr/monitors.lua ]]
grep -q 'output = "eDP-1".*scale = 1.5' "$MOCK_EVALS"
# The backstop fires after the panel's 15-second countdown.
grep -q -- '--on-active=20s' "$MOCK_TIMERS"
grep -q -- '--timer-property=AccuracySec=1s' "$MOCK_TIMERS"

run_monitor revert
[[ ! -e $XDG_RUNTIME_DIR/hrndz-monitor/scale-preview ]]
grep -q 'output = "eDP-1".*scale = 1 })' "$MOCK_EVALS"

run_monitor scale 1.5
run_monitor confirm
config_file="$XDG_CONFIG_HOME/hypr/monitors.lua"
grep -q 'output = "eDP-1".*scale = 1.5' "$config_file"
grep -q 'output = "DP-1".*scale = 1.25' "$config_file"
grep -qx 'hl.env("GDK_SCALE", "1")' "$config_file"

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
# XWayland apps follow the largest enabled scale, rounded to a whole factor.
grep -qx 'hl.env("GDK_SCALE", "2")' "$config_file"

# Text size lands in the override the shell watches, and GTK scales with it.
run_monitor text-size 16
grep -qx 'base-size = 16' "$HOME/.local/state/hrndz-shell/shell.toml"
grep -qx 'write /org/gnome/desktop/interface/text-scaling-factor 1.3333' "$MOCK_DCONF"
status=0
run_monitor text-size 99 || status=$?
[[ $status == 2 ]]
grep -qx 'base-size = 16' "$HOME/.local/state/hrndz-shell/shell.toml"

# An external display's brightness is DDC/CI, as a percent of the monitor's
# own maximum; the slow bus lookup runs once.
mapfile -t state < <(run_monitor state)
[[ ${#state[@]} == 4 && ${state[0]} == 50 ]]
run_monitor state >/dev/null
[[ $(grep -c '^detect' "$MOCK_DDC") == 1 ]]
run_monitor brightness 30
grep -qx -- '--bus 7 setvcp 10 60 --noverify' "$MOCK_DDC"
