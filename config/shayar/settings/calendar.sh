#!/usr/bin/env bash
set -euo pipefail
source "${HOME}/.config/shayar/settings/shayar.conf" 2>/dev/null

# Open a calendar near the top right/center depending on bar position
yad --calendar \
    --title="Calendar" \
    --borders=15 \
    --no-buttons \
    --close-on-unfocus \
    --fixed \
    --undecorated \
    --posx=-50 --posy=50 >/dev/null &
