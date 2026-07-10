#!/usr/bin/env bash
set -euo pipefail
# Shayar Theme Glass

source "$HOME/.config/shayar/library.sh"

# Apply file overlays
$HOME/.config/shayar/scripts/shayar-apply-theme glass

# Record theme state WITHOUT mutating the tracked shayar.conf
mkdir -p "$HOME/.cache/shayar"
echo 'WAYBAR_THEME="/shayar;/shayar/default"' > "$HOME/.cache/shayar/theme-state"
$HOME/.config/waybar/launch.sh &

# Set swaync
swaync-client -rs

run_extensions "theme-switch"
echo ":: Theme set to Glass"
