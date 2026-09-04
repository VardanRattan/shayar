#!/usr/bin/env bash
set -euo pipefail
# link.sh - Creates symlinks from the repo to ~/.config

# Get the absolute path to the directory where the script is located,
# then get its parent directory (the repo root).
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Creating symlinks from $REPO_ROOT/config to ~/.config..."

# Create ~/.config if it doesn't exist
mkdir -p ~/.config

# Backup directory for displaced configs
BACKUP_DIR="$HOME/.config/shayar-backup/$(date +%Y%m%d_%H%M%S)"
BACKUP_NEEDED=false

# Loop through all files and directories in the config/ folder
for item in "$REPO_ROOT/config"/*; do
    # Skip if it's not actually a file or directory (e.g., empty directory glob)
    [ -e "$item" ] || continue

    basename=$(basename "$item")
    target="$HOME/.config/$basename"

    # If target exists and is NOT already a symlink to our repo, back it up
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        if [ "$BACKUP_NEEDED" = false ]; then
            mkdir -p "$BACKUP_DIR"
            BACKUP_NEEDED=true
            echo ":: Backing up existing configs to $BACKUP_DIR"
        fi
        cp -a "$target" "$BACKUP_DIR/$basename"
        echo "  backed up: $target -> $BACKUP_DIR/$basename"
    fi

    echo "Linking $basename -> $target"
    rm -rf "$target"
    ln -s "$item" "$target"
done

# Link CLI tools from config/shayar/bin to ~/.local/bin
if [ -d "$REPO_ROOT/config/shayar/bin" ]; then
    mkdir -p "$HOME/.local/bin"
    echo "Linking CLI tools from $REPO_ROOT/config/shayar/bin to ~/.local/bin..."
    for bin_item in "$REPO_ROOT/config/shayar/bin"/*; do
        [ -e "$bin_item" ] || continue
        bin_name=$(basename "$bin_item")
        ln -sf "$bin_item" "$HOME/.local/bin/$bin_name"
    done
fi

# Link systemd user units
if [ -d "$REPO_ROOT/config/shayar/systemd" ]; then
    mkdir -p "$HOME/.config/systemd/user"
    echo "Linking systemd user services from $REPO_ROOT/config/shayar/systemd to ~/.config/systemd/user..."
    for unit_item in "$REPO_ROOT/config/shayar/systemd"/*; do
        [ -e "$unit_item" ] || continue
        unit_name=$(basename "$unit_item")
        ln -sf "$unit_item" "$HOME/.config/systemd/user/$unit_name"
    done
fi

# Setup Caelestia Shell QML overlay (keeps upstream updates smooth while branding About page, lockscreen, and fallback assets)
if [ -d "/etc/xdg/quickshell/caelestia" ]; then
    CAEL_DIR="$HOME/.config/quickshell/caelestia"
    echo "Setting up Caelestia QML overlay in $CAEL_DIR..."
    rm -rf "$CAEL_DIR"
    mkdir -p "$CAEL_DIR"

    # Components, services, shell.qml, utils, LICENSE
    for d in components services shell.qml utils LICENSE; do
        [ -e "/etc/xdg/quickshell/caelestia/$d" ] && ln -sf "/etc/xdg/quickshell/caelestia/$d" "$CAEL_DIR/$d"
    done

    # Assets: mirror all upstream assets but replace logo.svg with Shayar logo
    mkdir -p "$CAEL_DIR/assets"
    for a in /etc/xdg/quickshell/caelestia/assets/*; do
        a_name=$(basename "$a")
        if [ "$a_name" != "logo.svg" ]; then
            ln -sf "$a" "$CAEL_DIR/assets/$a_name"
        fi
    done
    if [ -f "$REPO_ROOT/config/shayar/assets/shayar.svg" ]; then
        ln -sf "$REPO_ROOT/config/shayar/assets/shayar.svg" "$CAEL_DIR/assets/logo.svg"
    fi

    # Modules
    mkdir -p "$CAEL_DIR/modules"
    for m in /etc/xdg/quickshell/caelestia/modules/*; do
        m_name=$(basename "$m")
        if [ "$m_name" = "BatteryMonitor.qml" ]; then
            if [ -f "$REPO_ROOT/config/caelestia/overrides/BatteryMonitor.qml" ]; then
                ln -sf "$REPO_ROOT/config/caelestia/overrides/BatteryMonitor.qml" "$CAEL_DIR/modules/BatteryMonitor.qml"
            fi
        elif [ "$m_name" = "lock" ]; then
            mkdir -p "$CAEL_DIR/modules/lock"
            for lk in /etc/xdg/quickshell/caelestia/modules/lock/*; do
                lk_name=$(basename "$lk")
                if [ -f "$REPO_ROOT/config/caelestia/overrides/$lk_name" ]; then
                    ln -sf "$REPO_ROOT/config/caelestia/overrides/$lk_name" "$CAEL_DIR/modules/lock/$lk_name"
                else
                    ln -sf "$lk" "$CAEL_DIR/modules/lock/$lk_name"
                fi
            done
        elif [ "$m_name" = "nexus" ]; then
            mkdir -p "$CAEL_DIR/modules/nexus"
            for n in /etc/xdg/quickshell/caelestia/modules/nexus/*; do
                n_name=$(basename "$n")
                if [ "$n_name" = "pages" ]; then
                    mkdir -p "$CAEL_DIR/modules/nexus/pages"
                    for p in /etc/xdg/quickshell/caelestia/modules/nexus/pages/*; do
                        p_name=$(basename "$p")
                        if [ "$p_name" = "AboutPage.qml" ] && [ -f "$REPO_ROOT/config/caelestia/overrides/AboutPage.qml" ]; then
                            ln -sf "$REPO_ROOT/config/caelestia/overrides/AboutPage.qml" "$CAEL_DIR/modules/nexus/pages/AboutPage.qml"
                        else
                            ln -sf "$p" "$CAEL_DIR/modules/nexus/pages/$p_name"
                        fi
                    done
                else
                    ln -sf "$n" "$CAEL_DIR/modules/nexus/$n_name"
                fi
            done
        else
            ln -sf "$m" "$CAEL_DIR/modules/$m_name"
        fi
    done
fi

echo "Done! Your dev environment is linked up."
if [ "$BACKUP_NEEDED" = true ]; then
    echo ":: Previous configs saved to: $BACKUP_DIR"
fi
