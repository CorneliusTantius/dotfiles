#!/bin/sh
# Undo a mistaken "sudo sh install.sh", which put the dotfiles into /root.
#
# For every file the repo installs: if /root/.dotfiles-backup has the
# original, put it back; otherwise remove the installed copy. Then it
# removes the backup folder and the video group membership that run added
# to root. Packages and services stay (they are wanted).
#
# Run from the checkout, as root:   sudo sh cleanup-root.sh
# Then run "sh install.sh" as your normal user (no sudo).

set -eu

if [ "$(id -u)" -ne 0 ]; then
    echo "Run with sudo: sudo sh cleanup-root.sh" >&2
    exit 1
fi

SRC=$(cd "$(dirname "$0")" && pwd)
ROOT_HOME=/root
BACKUP="$ROOT_HOME/.dotfiles-backup"

cd "$SRC"
find .bashrc .bash_profile .config -type f | while IFS= read -r rel; do
    rel=${rel#./}
    if [ -e "$BACKUP/$rel" ] || [ -L "$BACKUP/$rel" ]; then
        cp -a "$BACKUP/$rel" "$ROOT_HOME/$rel"
    else
        rm -f "$ROOT_HOME/$rel"
    fi
done

# Drop config folders that are now empty (deepest first).
find .config -type d | sort -r | while IFS= read -r dir; do
    rmdir "$ROOT_HOME/${dir#./}" 2>/dev/null || true
done
rmdir "$ROOT_HOME/.config" 2>/dev/null || true

rm -rf "$BACKUP"

if id -nG root | tr ' ' '\n' | grep -qx video; then
    gpasswd -d root video >/dev/null && echo "Removed root from group video."
fi

echo "Cleaned up the dotfiles from $ROOT_HOME."
