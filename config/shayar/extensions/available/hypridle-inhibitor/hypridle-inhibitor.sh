#!/usr/bin/env bash
set -euo pipefail
# hypridle-inhibitor: toggle hypridle via flag file
# Place in enabled/post-reload/ to run on reload, or run manually.
# Hook: post-reload, or standalone via keybind.

HYPRIDLE_FLAG="${XDG_RUNTIME_DIR:-/tmp}/hypridle-inhibited"

if [ -f "$HYPRIDLE_FLAG" ]; then
    rm -f "$HYPRIDLE_FLAG"
    hyprctl notify -1 2000 "rgb(66cc66)" "hypridle: enabled"
else
    touch "$HYPRIDLE_FLAG"
    hyprctl notify -1 2000 "rgb(ff6666)" "hypridle: disabled"
fi

# If this is a post-reload hook, just report status
if [ "${1:-}" = "status" ]; then
    if [ -f "$HYPRIDLE_FLAG" ]; then
        echo '{"text": "", "tooltip": "hypridle inhibited", "class": "inhibited"}'
    else
        echo '{"text": "", "tooltip": "hypridle active", "class": "active"}'
    fi
fi
