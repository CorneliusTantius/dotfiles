#!/usr/bin/env sh
# Install and enable keyd — system-level key remapping daemon
# Config sourced from: ~/Workspace/dotfiles/configs/keyd/default.conf
#
# Notes:
#   - Super is remapped to Ctrl for copy/paste shortcuts (Super+C → Ctrl+C)
#   - Window manager binds using Super are NOT affected — keyd only remaps
#     when no other modifier or keycombo is active
#   - Requires root; keyd reads from /etc/keyd/default.conf

set -e

SRC="$HOME/Workspace/dotfiles/configs/keyd/default.conf"
DEST="/etc/keyd/default.conf"

if ! command -v keyd >/dev/null 2>&1; then
    echo "→ Installing keyd..."
    sudo pacman -S --needed keyd
fi

echo "→ Symlinking config: $DEST → $SRC"
sudo mkdir -p /etc/keyd
sudo ln -sf "$SRC" "$DEST"

echo "→ Enabling and starting keyd..."
sudo systemctl enable --now keyd

echo "✓ keyd installed and running"
keyd --version 2>/dev/null || true
