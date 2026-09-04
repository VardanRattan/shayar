#!/usr/bin/env bash
set -euo pipefail
_writeLog() {
    m=$1
    echo ":: $m"
}

config_path() {
    local rel="$1"
    local user="${XDG_CONFIG_HOME:-$HOME/.config}/overrides/$rel"
    local def="${XDG_CONFIG_HOME:-$HOME/.config}/$rel"
    if [ -f "$user" ]; then
        echo "$user"
    else
        echo "$def"
    fi
}

ensure_qs() {
    if pgrep -f 'caelestia shell' >/dev/null 2>&1; then
        return 0
    fi
    if command -v caelestia >/dev/null 2>&1; then
        caelestia shell -d &
    fi
}

run_extensions() {
    local hook="$1"
    local dirs=(
        "$HOME/.config/shayar/extensions/enabled/$hook"
        "$HOME/.config/shayar/extensions/user/$hook"
    )
    for dir in "${dirs[@]}"; do
        [ -d "$dir" ] || continue
        for script in "$dir"/*.sh; do
            [ -f "$script" ] && source "$script"
        done
    done
}