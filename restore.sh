#!/bin/sh
# Restore the last backup made by install.sh.
#
# Copies everything in $HOME/.dotfiles-backup back into $HOME, overwriting
# the files that install.sh put there. Files that had no backup (for example
# new config files that did not exist before) are left in place.
#
# Usage: sh restore.sh

set -eu

BACKUP_DIR="$HOME/.dotfiles-backup"

if [ ! -d "$BACKUP_DIR" ]; then
    echo "No backup found at $BACKUP_DIR." >&2
    exit 1
fi

cp -a "$BACKUP_DIR/." "$HOME/"

echo "Restored backup from $BACKUP_DIR."
