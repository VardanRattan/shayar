#!/usr/bin/env bash
set -euo pipefail
#                    __
#  _    _____ ___ __/ /  ___ _____
# | |/|/ / _ `/ // / _ \/ _ `/ __/
# |__,__/\_,_/\_, /_.__/\_,_/_/
#            /___/
#

# -----------------------------------------------------
# Prevent duplicate launches: only the first parallel
# invocation proceeds; all others exit immediately.
# -----------------------------------------------------

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
lock_file="$runtime_dir/waybar-launch.lock"
exec 200>"$lock_file"
flock -n 200 || exit 0

RESTART=false
if [ "${1:-}" = "--restart" ]; then
    RESTART=true
fi

# Set up static paths for persistent waybar configs
UID_VAL=$(id -u)
CONFIG_TMP="$runtime_dir/waybar-config-shayar-$UID_VAL.json"
STYLE_TMP="$runtime_dir/waybar-style-shayar-$UID_VAL.css"
STYLE_FINAL="$runtime_dir/waybar-style-flat-shayar-$UID_VAL.css"

[ -f "$HOME/.config/shayar/settings/shayar.conf" ] && source "$HOME/.config/shayar/settings/shayar.conf"
# Theme switch may override WAYBAR_THEME without touching the tracked shayar.conf
[ -f "$HOME/.cache/shayar/theme-state" ] && source "$HOME/.cache/shayar/theme-state"
themestyle="${WAYBAR_THEME:-/shayar;/shayar/default}"

# Layered config: let ~/.config/overrides/... win over shipped files
[ -f "$HOME/.config/shayar/library.sh" ] && source "$HOME/.config/shayar/library.sh"

IFS=';' read -ra arrThemes <<<"$themestyle"
echo ":: Theme: ${arrThemes[0]}"

config_file="config"
style_file="style.css"

if [ -f ~/.config/waybar/themes${arrThemes[0]}/config-custom ]; then
    config_file="config-custom"
fi
if [ -f ~/.config/waybar/themes${arrThemes[1]}/style-custom.css ]; then
    style_file="style-custom.css"
fi

TOKENS_ENV="$HOME/.config/shayar/themes/design-tokens.env"
# Self-heal: if tokens were never generated, generate them so the bar isn't unstyled
if [ ! -f "$TOKENS_ENV" ]; then
    echo ":: design-tokens.env missing, regenerating..."
    "$HOME/.config/shayar/scripts/shayar-design-tokens" generate >/dev/null 2>&1 || true
fi

CONFIG_REL="waybar/themes${arrThemes[0]}/$config_file"
if command -v config_path >/dev/null 2>&1; then
    CONFIG_SRC="$(config_path "$CONFIG_REL")"
else
    CONFIG_SRC="$HOME/.config/$CONFIG_REL"
fi

CONFIG_PATH="$CONFIG_SRC"
STYLE_PATH=""

generate_files() {
    [ -f "$TOKENS_ENV" ] || return 0

    # Single awk pass: load all tokens, then replace @refs@ in one sweep.
    # This replaces 200+ individual sed -i forks with a single fork per file.
    _resolve() {
        local src="$1" dst="$2"
        awk -F'=' '
            NR==FNR {
                key=$1; val=""
                for (i=2;i<=NF;i++) val = (val=="" ? $i : val "=" $i)
                gsub(/^"/, "", val); gsub(/"$/, "", val)
                if (key ~ /^DT_COLORS_/) {
                    name=substr(key, 11)
                    lower=tolower(name)
                    gsub(/_/, "-", lower)
                    refs["@" lower]=val             # @primary (no trailing @)
                } else {
                    refs["@" key "@"]=val           # @DT_SPACING_...@ (with trailing @)
                }
                next
            }
            {
                for (k in refs) gsub(k, refs[k])
                print
            }
        ' "$TOKENS_ENV" "$src" > "$dst"
    }

    cp "$CONFIG_SRC" "$CONFIG_TMP"
    _resolve "$CONFIG_TMP" "$CONFIG_TMP.resolved"
    mv "$CONFIG_TMP.resolved" "$CONFIG_TMP"
    echo ":: Resolved @color refs -> $CONFIG_TMP"
    CONFIG_PATH="$CONFIG_TMP"

    if [ ! -f "$HOME/.config/shayar/settings/waybar-disabled" ]; then
        STYLE_SRC="$HOME/.config/waybar/themes${arrThemes[1]}/$style_file"
        STYLE_PATH="$STYLE_SRC"
        cp "$STYLE_SRC" "$STYLE_TMP"
        _resolve "$STYLE_TMP" "$STYLE_TMP.resolved"
        mv "$STYLE_TMP.resolved" "$STYLE_TMP"

        # Flatten @import chains into a single file
        CSS_IMPORTS=$(grep -oP '@import\s+['"'"'"]([^'"'"'"]+)['"'"'"]\s*;' "$STYLE_TMP" | head -5)
        if [ -n "$CSS_IMPORTS" ]; then
            > "$STYLE_FINAL"
            while IFS= read -r import_line; do
                import_path=$(echo "$import_line" | grep -oP '(['"'"'"])([^'"'"'"]+)\1' | tr -d '"' | tr -d "'")
                if [ -n "$import_path" ]; then
                    resolved="$HOME/.config/waybar/themes${arrThemes[1]}/$(dirname "$style_file")/$import_path"
                    [ -f "$resolved" ] && cat "$resolved" >> "$STYLE_FINAL"
                fi
            done <<< "$CSS_IMPORTS"
            grep -v '^\s*@import' "$STYLE_TMP" >> "$STYLE_FINAL"
            _resolve "$STYLE_FINAL" "$STYLE_FINAL.resolved"
            mv "$STYLE_FINAL.resolved" "$STYLE_FINAL"
            STYLE_PATH="$STYLE_FINAL"
        else
            STYLE_PATH="$STYLE_TMP"
        fi
        echo ":: Resolved @color refs -> $STYLE_PATH"
    fi
}

# Check if Waybar is already running. If it is and we don't force a restart,
# just regenerate configs and trigger reload.
if pgrep -x waybar >/dev/null && [ "$RESTART" = false ]; then
    echo ":: Waybar is running, hot-reloading (flicker-free)..."
    generate_files
    pkill -SIGUSR2 waybar
    flock -u 200
    exec 200>&-
    exit 0
fi

# -----------------------------------------------------
# Hard restart Waybar (if requested or if not running)
# -----------------------------------------------------
echo ":: Starting/restarting Waybar..."
if [ -f "$runtime_dir/waybar-runner.pid" ]; then
    kill -9 "$(cat "$runtime_dir/waybar-runner.pid")" 2>/dev/null || true
    rm -f "$runtime_dir/waybar-runner.pid"
fi

killall -q waybar 2>/dev/null || true
pkill -x waybar 2>/dev/null || true
sleep 0.05

generate_files

if [ ! -f "$HOME/.config/shayar/settings/waybar-disabled" ]; then
    HYPRLAND_SIGNATURE=$(hyprctl instances -j | jq -r '.[0].instance')
    setsid -f bash -c "
        echo \$\$ > \"$runtime_dir/waybar-runner.pid\"
        fail=0
        while true; do
            HYPRLAND_INSTANCE_SIGNATURE=\"$HYPRLAND_SIGNATURE\" waybar -c \"$CONFIG_PATH\" -s \"$STYLE_PATH\"
            rc=\$?
            [ \"\$rc\" -eq 0 ] && exit 0
            fail=\$((fail+1))
            [ \"\$fail\" -ge 5 ] && { echo \":: waybar crashed \$fail times; stopping auto-restart\"; exit 1; }
            sleep 1
        done
    " >/dev/null 2>&1
else
    echo ":: Waybar disabled"
fi

# Explicitly release the lock (optional) -> flock releases on exit
flock -u 200
exec 200>&-
