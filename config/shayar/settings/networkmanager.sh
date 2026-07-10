#!/usr/bin/env bash
set -euo pipefail
source "${HOME}/.config/shayar/settings/shayar.conf" 2>/dev/null
exec networkmanager_dmenu
