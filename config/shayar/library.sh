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
    local qs_pid
    qs_pid=$(pgrep -x qs 2>/dev/null || true)
    if [ -n "$qs_pid" ]; then
        return 0
    fi
    (
        flock -x 200
        if ! pgrep -x qs > /dev/null 2>&1; then
            qs -p "${HOME}/.config/quickshell/shell.qml" &
        fi
        local retries=20
        while ! pgrep -x qs > /dev/null 2>&1; do
            sleep 0.1
            retries=$((retries - 1))
            [ "$retries" -le 0 ] && { echo "Warning: quickshell failed to start" >&2; return 1; }
        done
    ) 200>"/tmp/shayar-qs.lock"
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