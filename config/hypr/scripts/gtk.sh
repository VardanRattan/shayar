#!/usr/bin/env bash
set -euo pipefail
#   _____________ __
#  / ___/_  __/ //_/
# / (_ / / / / ,<   
# \___/ /_/ /_/|_|  
#                   
# Source: https://github.com/swaywm/sway/wiki/GTK-3-settings-on-Wayland

# Check that settings file exists
config="$HOME/.config/gtk-3.0/settings.ini"
if [ ! -f "$config" ]; then exit 1; fi

# Read settings file (zero subshell forks)
gnome_schema="org.gnome.desktop.interface"
gtk_theme=""
icon_theme=""
cursor_theme=""
cursor_size=""
font_name=""
prefer_dark_theme=""

while IFS='=' read -r key val || [ -n "$key" ]; do
    key="${key#"${key%%[![:space:]]*}"}"
    key="${key%"${key##*[![:space:]]}"}"
    val="${val#"${val%%[![:space:]]*}"}"
    val="${val%"${val##*[![:space:]]}"}"
    case "$key" in
        gtk-theme-name) gtk_theme="$val" ;;
        gtk-icon-theme-name) icon_theme="$val" ;;
        gtk-cursor-theme-name) cursor_theme="$val" ;;
        gtk-cursor-theme-size) cursor_size="$val" ;;
        gtk-font-name) font_name="$val" ;;
        gtk-application-prefer-dark-theme) prefer_dark_theme="$val" ;;
    esac
done < "$config"

source "$HOME/.config/shayar/settings/shayar.conf" 2>/dev/null || true
terminal="${TERMINAL:-kitty}"

if [[ "$prefer_dark_theme" == "0" || "$prefer_dark_theme" == "false" ]]; then
    prefer_dark_theme_value="prefer-light"
else
    prefer_dark_theme_value="prefer-dark"
fi

# Update gsettings only when changed
set_gsetting() {
    local key="$1" val="$2"
    local cur
    cur=$(gsettings get "$gnome_schema" "$key" 2>/dev/null || true)
    cur="${cur#\'}"
    cur="${cur%\'}"
    if [ "$cur" != "$val" ]; then
        gsettings set "$gnome_schema" "$key" "$val"
    fi
}

set_gsetting gtk-theme "$gtk_theme"
set_gsetting icon-theme "$icon_theme"
set_gsetting cursor-theme "$cursor_theme"
set_gsetting font-name "$font_name"
set_gsetting color-scheme "$prefer_dark_theme_value"
