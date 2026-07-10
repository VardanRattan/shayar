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