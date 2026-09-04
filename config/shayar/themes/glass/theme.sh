#!/usr/bin/env bash
set -euo pipefail
# Shayar Theme Glass

source "$HOME/.config/shayar/library.sh"

# Apply file overlays
$HOME/.config/shayar/scripts/shayar-apply-theme glass

# Record theme state WITHOUT mutating the tracked shayar.conf
mkdir -p "$HOME/.cache/shayar"
if [ ! -f "$HOME/.config/shayar/settings/waybar-disabled" ] && [ -x "$HOME/.config/waybar/launch.sh" ]; then
    "$HOME/.config/waybar/launch.sh" &
fi

# Set swaync (if active)
if command -v swaync-client >/dev/null 2>&1 && pgrep -x swaync >/dev/null 2>&1; then
    swaync-client -rs 2>/dev/null || true
fi

run_extensions "theme-switch"
echo ":: Theme set to Glass"
