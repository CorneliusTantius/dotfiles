#!/bin/sh
# Delete the backup made by install.sh ($HOME/.dotfiles-backup).
# After this, restore.sh has nothing to restore.
#
# Usage: sh cleanup-backup.sh

set -eu

BACKUP_DIR="$HOME/.dotfiles-backup"

if [ ! -d "$BACKUP_DIR" ]; then
    echo "No backup found at $BACKUP_DIR."
    exit 0
fi

rm -rf "$BACKUP_DIR"
echo "Removed $BACKUP_DIR."
