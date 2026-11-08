#!/usr/bin/env bash
set -euo pipefail

# 1. Detect internal and external displays from DRM sysfs
internal="eDP-1"
external=""

for f in /sys/class/drm/*/status; do
    if [ "$(cat "$f" 2>/dev/null)" = "connected" ]; then
        dev=$(basename "$(dirname "$f")")
        mon="${dev#card*-}"
        if [[ "$mon" =~ ^(eDP|LVDS|DSI) ]]; then
            internal="$mon"
        else
            external="$mon"
        fi
    fi
done

if [ -z "$external" ]; then
    notify-send -t 2500 -a "Display Switcher" "No External Display" "No connected external monitor or projector found."
    exit 0
fi

# 2. Options menu
options=(
    "📥  Pull All to Laptop"
    "󰍺  Mirror (Duplicate)"
    "󰍹  Extend (Right)"
    "󰍺  Extend (Left)"
    "󰌢  Laptop Only"
    "󰍹  External Only"
)

entries=$(printf "%s\n" "${options[@]}")
chosen=$(echo -e "$entries" | fuzzel --dmenu -p "Display ($external) > ")

[ -z "$chosen" ] && exit 0

case "$chosen" in
    *"Pull All"*)
        ~/.config/hypr/scripts/pull-all.sh
        ;;
    *"Mirror"*)
        hyprctl eval "hl.monitor({ output = '$internal', mode = 'preferred', position = '0x0', scale = 1, disabled = false, mirror = '' })"
        hyprctl eval "hl.monitor({ output = '$external', mode = 'preferred', position = 'auto', scale = 1, disabled = false, mirror = '$internal' })"
        hyprctl dispatch "hl.dsp.focus({ monitor = '$internal' })"
        notify-send -t 2000 -a "Display Switcher" "Mirror Mode" "$external is mirroring $internal"
        ;;
    *"Extend (Right)"*)
        hyprctl eval "hl.monitor({ output = '$internal', mode = 'preferred', position = '0x0', scale = 1, disabled = false, mirror = '' })"
        hyprctl eval "hl.monitor({ output = '$external', mode = 'preferred', position = 'auto-right', scale = 1, disabled = false, mirror = '' })"
        # Park external on workspace 99 so workspaces 1-10 are not held hostage
        hyprctl dispatch "hl.dsp.focus({ monitor = '$external' })"
        hyprctl dispatch "hl.dsp.focus({ workspace = 99 })"
        hyprctl dispatch "hl.dsp.focus({ monitor = '$internal' })"
        notify-send -t 2000 -a "Display Switcher" "Extend (Right)" "$external placed to the right"
        ;;
    *"Extend (Left)"*)
        hyprctl eval "hl.monitor({ output = '$external', mode = 'preferred', position = '0x0', scale = 1, disabled = false, mirror = '' })"
        hyprctl eval "hl.monitor({ output = '$internal', mode = 'preferred', position = 'auto-right', scale = 1, disabled = false, mirror = '' })"
        # Park external on workspace 99 so workspaces 1-10 are not held hostage
        hyprctl dispatch "hl.dsp.focus({ monitor = '$external' })"
        hyprctl dispatch "hl.dsp.focus({ workspace = 99 })"
        hyprctl dispatch "hl.dsp.focus({ monitor = '$internal' })"
        notify-send -t 2000 -a "Display Switcher" "Extend (Left)" "$external placed to the left"
        ;;
    *"Laptop Only"*)
        hyprctl eval "hl.monitor({ output = '$internal', mode = 'preferred', position = '0x0', scale = 1, disabled = false, mirror = '' })"
        hyprctl eval "hl.monitor({ output = '$external', disabled = true })"
        hyprctl dispatch "hl.dsp.focus({ monitor = '$internal' })"
        notify-send -t 2000 -a "Display Switcher" "Laptop Only" "$external disabled"
        ;;
    *"External Only"*)
        hyprctl eval "hl.monitor({ output = '$external', mode = 'preferred', position = '0x0', scale = 1, disabled = false, mirror = '' })"
        hyprctl eval "hl.monitor({ output = '$internal', disabled = true })"
        hyprctl dispatch "hl.dsp.focus({ monitor = '$external' })"
        notify-send -t 2000 -a "Display Switcher" "External Only" "$internal disabled"
        ;;
esac
