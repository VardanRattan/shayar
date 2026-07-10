#!/usr/bin/env bash
set -euo pipefail
source "${HOME}/.config/shayar/settings/shayar.conf" 2>/dev/null
alias rofi='rofi -theme ~/.config/rofi/config-popup.rasi'
shopt -s expand_aliases
exec rofi-bluetooth "$@"
