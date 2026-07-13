#!/usr/bin/env bash
set -euo pipefail
# unlink.sh - Removes symlinks and restores the latest backup

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Removing Shayar symlinks from ~/.config..."

# Remove symlinks
for item in "$REPO_ROOT/config"/*; do
    [ -e "$item" ] || continue
    basename=$(basename "$item")
    target="$HOME/.config/$basename"

    if [ -L "$target" ]; then
        echo "Removing symlink: $target"
        rm "$target"
    elif [ -e "$target" ]; then
        echo "Warning: $target exists but is not a symlink. Skipping."
    fi
done

# Find and restore the latest backup
BACKUP_PARENT="$HOME/.config/shayar-backup"
if [ -d "$BACKUP_PARENT" ]; then
    latest_backup=$(ls -td "$BACKUP_PARENT"/* 2>/dev/null | head -n 1 || true)
    if [ -n "$latest_backup" ] && [ -d "$latest_backup" ]; then
        echo ":: Restoring latest backup from $latest_backup..."
        for item in "$latest_backup"/*; do
            [ -e "$item" ] || continue
            basename=$(basename "$item")
            dest="$HOME/.config/$basename"
            echo "  restoring: $dest"
            cp -a "$item" "$dest"
        done
        # Clean up this specific backup directory
        rm -rf "$latest_backup"
        # If the parent backup dir is now empty, remove it too
        rmdir "$BACKUP_PARENT" 2>/dev/null || true
        echo "Rollback complete."
    else
        echo "No backups found to restore."
    fi
else
    echo "No backups directory found."
fi

echo "Shayar unlinked successfully."
