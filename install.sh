#!/bin/sh
# Install dotfiles: copies .bashrc and everything in .config/ into $HOME.
#
# Any file or folder it is about to overwrite is backed up to
# $HOME/.dotfiles-backup. Only the latest backup is kept: each run
# replaces the previous backup.
#
# Run from a checkout:   sh install.sh
# Run from the web:      curl -fsSL https://raw.githubusercontent.com/CorneliusTantius/dotfiles/main/install.sh | sh

set -eu

REPO_URL="https://github.com/CorneliusTantius/dotfiles.git"
BACKUP_DIR="$HOME/.dotfiles-backup"
TMP=""

cleanup() {
    if [ -n "$TMP" ]; then
        rm -rf "$TMP"
    fi
}
trap cleanup EXIT

# Use the checkout this script lives in. When piped into sh there is no
# script file, so clone the repo instead.
SRC=""
if [ -f "$0" ]; then
    script_dir=$(cd "$(dirname "$0")" && pwd)
    if [ -f "$script_dir/install.sh" ] && [ -f "$script_dir/.bashrc" ] && [ -d "$script_dir/.config" ]; then
        SRC="$script_dir"
    fi
fi
if [ -z "$SRC" ]; then
    echo "Downloading dotfiles..."
    TMP=$(mktemp -d)
    git clone --depth 1 -q "$REPO_URL" "$TMP/dotfiles"
    SRC="$TMP/dotfiles"
fi

# Call $1 with the path (relative to $HOME) of every item to install.
for_each_item() {
    "$1" ".bashrc"
    for entry in "$SRC"/.config/*; do
        "$1" ".config/$(basename "$entry")"
    done
}

backup_item() {
    rel=$1
    dst="$HOME/$rel"
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
        cp -a "$dst" "$BACKUP_DIR/$rel"
        backed_up=1
    fi
}

install_item() {
    rel=$1
    src="$SRC/$rel"
    dst="$HOME/$rel"
    if [ -d "$src" ]; then
        mkdir -p "$dst"
        cp -a "$src/." "$dst/"
    else
        mkdir -p "$(dirname "$dst")"
        cp -a "$src" "$dst"
    fi
}

# Replace the previous backup with a fresh one.
rm -rf "$BACKUP_DIR"
backed_up=0
for_each_item backup_item

for_each_item install_item

echo "Dotfiles installed from $SRC."
if [ "$backed_up" -eq 1 ]; then
    echo "Previous files backed up to $BACKUP_DIR."
fi
