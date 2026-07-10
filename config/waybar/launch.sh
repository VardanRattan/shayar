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

# -----------------------------------------------------
# Quit all running waybar instances and runners
# -----------------------------------------------------

if [ -f "$runtime_dir/waybar-runner.pid" ]; then
    kill -9 "$(cat "$runtime_dir/waybar-runner.pid")" 2>/dev/null || true
    rm -f "$runtime_dir/waybar-runner.pid"
fi

killall -q waybar 2>/dev/null || true
pkill -x waybar 2>/dev/null || true
sleep 0.2

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

# Resolve @color-name refs in config using design-tokens.env
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
if [ -f "$TOKENS_ENV" ]; then
    CONFIG_TMP="$runtime_dir/waybar-config-$$.json"
    cp "$CONFIG_SRC" "$CONFIG_TMP"
    # Process longer keys first to prevent substring collisions (e.g. @on-surface before @on-surface-variant)
    while IFS='=' read -r key value; do
        case "$key" in
            DT_COLORS_*)
                color_name="$(echo "$key" | sed 's/^DT_COLORS_//' | tr '[:upper:]' '[:lower:]' | tr '_' '-')"
                hex_value="$(echo "$value" | tr -d '"')"
                sed -i "s|@${color_name}|${hex_value}|g" "$CONFIG_TMP"
                ;;
            DT_*)
                val="$(echo "$value" | tr -d '"')"
                sed -i "s|@${key}@|${val}|g" "$CONFIG_TMP"
                ;;
        esac
    done < <(awk '{ print length, $0 }' "$TOKENS_ENV" | sort -rn | cut -d' ' -f2-)
    echo ":: Resolved @color refs -> $CONFIG_TMP"
    CONFIG_PATH="$CONFIG_TMP"
fi

if [ ! -f "$HOME/.config/shayar/settings/waybar-disabled" ]; then
    HYPRLAND_SIGNATURE=$(hyprctl instances -j | jq -r '.[0].instance')
setsid -f bash -c "
    echo \$\$ > \"$runtime_dir/waybar-runner.pid\"
    fail=0
    while true; do
        HYPRLAND_INSTANCE_SIGNATURE="$HYPRLAND_SIGNATURE" waybar -c "$CONFIG_PATH" -s ~/.config/waybar/themes${arrThemes[1]}/$style_file
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
