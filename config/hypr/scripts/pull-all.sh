#!/usr/bin/env bash
set -euo pipefail

# 1. Find internal display
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

# Ensure internal monitor is active
hyprctl eval "hl.monitor({ output = '$internal', disabled = false })" >/dev/null 2>&1 || true

# 2. Find any active external monitors
ext_monitors=$(hyprctl monitors -j | jq -r '.[] | select(.name != "'"$internal"'") | .name' 2>/dev/null || true)

dummy_ws=99
for ext in $ext_monitors; do
    # Park the external monitor on workspace 99 so workspaces 1-10 are never hijacked
    hyprctl dispatch "hl.dsp.focus({ monitor = '$ext' })" >/dev/null 2>&1 || true
    hyprctl dispatch "hl.dsp.focus({ workspace = $dummy_ws })" >/dev/null 2>&1 || true
    dummy_ws=$((dummy_ws - 1))
done

# 3. Pull all non-dummy workspaces from other monitors to internal
for ws in $(hyprctl workspaces -j | jq -r '.[] | select(.monitor != "'"$internal"'" and .id < 90) | .id' 2>/dev/null || true); do
    hyprctl dispatch "hl.dsp.workspace.move({ workspace = $ws, monitor = '$internal' })" >/dev/null 2>&1 || true
done

# 4. Pull any stranded windows on other monitors to internal
for addr in $(hyprctl clients -j | jq -r '.[] | select(.monitor != 0) | .address' 2>/dev/null || true); do
    hyprctl dispatch "hl.dsp.window.move({ address = '$addr', monitor = '$internal' })" >/dev/null 2>&1 || true
done

# 5. Focus internal monitor
hyprctl dispatch "hl.dsp.focus({ monitor = '$internal' })" >/dev/null 2>&1 || true

notify-send -t 2000 -a "Hyprland" "📥 Pulled Back All" "All workspaces and windows returned to $internal."
