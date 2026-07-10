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

echo "Done! Your dev environment is linked up."
if [ "$BACKUP_NEEDED" = true ]; then
    echo ":: Previous configs saved to: $BACKUP_DIR"
fi
