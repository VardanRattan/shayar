#!/usr/bin/env bash
set -euo pipefail

# Find internal display
internal="eDP-1"
for f in /sys/class/drm/*/status; do
    if [ "$(cat "$f" 2>/dev/null)" = "connected" ]; then
        dev=$(basename "$(dirname "$f")")
        mon="${dev#card*-}"
        if [[ "$mon" =~ ^(eDP|LVDS|DSI) ]]; then
            internal="$mon"
            break
        fi
    fi
done

# Ensure internal monitor is enabled (in case it was disabled in external-only mode)
hyprctl eval "hl.monitor({ output = '$internal', disabled = false })" >/dev/null 2>&1 || true

# Focus internal monitor
hyprctl dispatch "hl.dsp.focus({ monitor = '$internal' })" >/dev/null 2>&1 || true

notify-send -t 1500 -a "Hyprland" "Display Focus" "Focused laptop screen ($internal)"
