#!/bin/sh
# Install dotfiles: copies .bashrc and everything in .config/ into $HOME.
#
# Any file or folder it is about to overwrite is backed up to
# $HOME/.dotfiles-backup. Only the latest backup is kept: each run
# replaces the previous backup.
#
# It also installs the apps the configs use that are missing, on Arch
# (incl. CachyOS), Debian/Ubuntu and Fedora. Set NO_DEPS=1 to skip that.
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

# --- Dependencies -----------------------------------------------------------
# Entries are "command=package". The pseudo-command "font" checks for
# JetBrains Mono via fc-list.
DEPS_ARCH="waybar=waybar mako=mako udiskie=udiskie fuzzel=fuzzel foot=foot grim=grim slurp=slurp wl-copy=wl-clipboard brightnessctl=brightnessctl wpctl=wireplumber bluetui=bluetui impala=impala wiremix=wiremix font=ttf-jetbrains-mono"
DEPS_DEBIAN="waybar=waybar mako=mako-notifier udiskie=udiskie fuzzel=fuzzel foot=foot grim=grim slurp=slurp wl-copy=wl-clipboard brightnessctl=brightnessctl wpctl=wireplumber font=fonts-jetbrains-mono"
DEPS_FEDORA="waybar=waybar mako=mako udiskie=udiskie fuzzel=fuzzel foot=foot grim=grim slurp=slurp wl-copy=wl-clipboard brightnessctl=brightnessctl wpctl=wireplumber font=jetbrains-mono-fonts"

have() {
    if [ "$1" = font ]; then
        command -v fc-list >/dev/null 2>&1 && fc-list | grep -qi "JetBrains Mono"
    else
        command -v "$1" >/dev/null 2>&1
    fi
}

install_deps() {
    [ "${NO_DEPS:-0}" = 1 ] && return 0

    # Detect by package manager: works for any derivative (CachyOS, Monarch,
    # Mint...) and does not depend on /etc/os-release or the kernel name.
    family=""
    if command -v pacman >/dev/null 2>&1; then family=arch
    elif command -v apt-get >/dev/null 2>&1; then family=debian
    elif command -v dnf >/dev/null 2>&1; then family=fedora
    fi

    case $family in
        arch)   deps=$DEPS_ARCH ;;
        debian) deps=$DEPS_DEBIAN ;;
        fedora) deps=$DEPS_FEDORA ;;
        *) echo "No pacman/apt-get/dnf found: skipping dependency install."; return 0 ;;
    esac

    missing=""
    for entry in $deps; do
        have "${entry%%=*}" || missing="$missing ${entry#*=}"
    done
    # mango is not in the main repos of any of these distros.
    have mango || have mmsg || echo "Note: install the mango compositor yourself (AUR: mangowc on Arch)."
    have monarch-popup || echo "Note: monarch-popup (used by waybar) is not packaged; install it yourself."

    if [ -z "$missing" ]; then
        echo "All dependencies already installed."
        return 0
    fi
    echo "Installing missing packages:$missing"

    if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi
    # One package at a time so an unavailable name does not abort the rest.
    case $family in
        arch)   [ -n "$SUDO" ] && $SUDO -v || true; cmd="$SUDO pacman -S --needed --noconfirm" ;;
        debian) $SUDO apt-get update || true; cmd="$SUDO apt-get install -y" ;;
        fedora) cmd="$SUDO dnf install -y" ;;
    esac
    for pkg in $missing; do
        $cmd "$pkg" || echo "Warning: could not install $pkg."
    done
}

install_deps

# Replace the previous backup with a fresh one.
rm -rf "$BACKUP_DIR"
backed_up=0
for_each_item backup_item

for_each_item install_item

echo "Dotfiles installed from $SRC."
if [ "$backed_up" -eq 1 ]; then
    echo "Previous files backed up to $BACKUP_DIR."
fi
