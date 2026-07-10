#!/usr/bin/env bash
set -euo pipefail
# Toggle waybar on/off

disabled_file="$HOME/.config/shayar/settings/waybar-disabled"
runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"

if [ -f "$disabled_file" ]; then
    rm "$disabled_file"
    "$HOME/.config/waybar/launch.sh"
else
    touch "$disabled_file"
    if [ -f "$runtime_dir/waybar-runner.pid" ]; then
        kill -9 "$(cat "$runtime_dir/waybar-runner.pid")" 2>/dev/null || true
        rm -f "$runtime_dir/waybar-runner.pid"
    fi
    killall -q waybar 2>/dev/null || true
    pkill -x waybar 2>/dev/null || true
fi
