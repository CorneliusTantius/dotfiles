#!/bin/sh
# Install dotfiles: copies .bashrc and everything in .config/ into $HOME.
#
# Any file or folder it is about to overwrite is backed up to
# $HOME/.dotfiles-backup. Only the latest backup is kept: each run
# replaces the previous backup.
#
# It also sets up the desktop: installs the apps the configs use that are
# missing (Arch/CachyOS, Debian/Ubuntu, Fedora), enables the bluetooth and
# iwd services, adds you to the video group, and starts mango on tty1 at
# login (via ~/.bash_profile). Every step is idempotent, so running it again
# on an existing install just updates the dotfiles and fills in what is
# missing. Set NO_DEPS=1 to skip the system setup (packages, services,
# groups).
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
    if ! command -v git >/dev/null 2>&1; then
        # Blank installs have no git. Needs root or sudo.
        [ "$(id -u)" -eq 0 ] && S="" || S="sudo"
        if command -v pacman >/dev/null 2>&1; then $S pacman -S --needed --noconfirm git
        elif command -v apt-get >/dev/null 2>&1; then $S apt-get update && $S apt-get install -y git
        elif command -v dnf >/dev/null 2>&1; then $S dnf install -y git
        fi
    fi
    TMP=$(mktemp -d)
    git clone --depth 1 -q "$REPO_URL" "$TMP/dotfiles"
    SRC="$TMP/dotfiles"
fi

# Call $1 with the path (relative to $HOME) of every item to install.
for_each_item() {
    "$1" ".bashrc"
    "$1" ".bash_profile"
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
DEPS_ARCH="mango=mangowm pipewire=pipewire pipewire-pulse=pipewire-pulse bluetoothctl=bluez iwctl=iwd pkexec=polkit waybar=waybar mako=mako udiskie=udiskie fuzzel=fuzzel foot=foot grim=grim slurp=slurp wl-copy=wl-clipboard brightnessctl=brightnessctl wpctl=wireplumber bluetui=bluetui impala=impala wiremix=wiremix font=ttf-jetbrains-mono"
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

    # Detect by package manager: works for any derivative (CachyOS,
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
    [ "$family" = arch ] || have mango || echo "Note: mango is only packaged for Arch; install it yourself."

    if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi
    if [ -n "$SUDO" ] && ! command -v sudo >/dev/null 2>&1; then
        echo "sudo not found: skipping system setup. Re-run as root."
        return 0
    fi

    if [ -z "$missing" ]; then
        echo "All dependencies already installed."
    else
        echo "Installing missing packages:$missing"
        # No -Sy on Arch: a partial upgrade breaks systems. If a package is
        # not found, run "sudo pacman -Syu" and re-run this script.
        # One package at a time so an unavailable name does not abort the rest.
        case $family in
            arch)   cmd="$SUDO pacman -S --needed --noconfirm" ;;
            debian) $SUDO apt-get update || true; cmd="$SUDO apt-get install -y" ;;
            fedora) cmd="$SUDO dnf install -y" ;;
        esac
        for pkg in $missing; do
            $cmd "$pkg" || echo "Warning: could not install $pkg."
        done
    fi

    setup_system
}

# Enable services and group membership. Safe to re-run.
setup_system() {
    command -v systemctl >/dev/null 2>&1 || return 0

    # iwd (used by impala) conflicts with NetworkManager: leave those alone.
    if systemctl is-enabled NetworkManager >/dev/null 2>&1; then
        echo "NetworkManager is enabled: not enabling iwd."
    elif command -v iwctl >/dev/null 2>&1; then
        if [ ! -e /etc/iwd/main.conf ]; then
            $SUDO mkdir -p /etc/iwd
            printf '[General]\nEnableNetworkConfiguration=true\n' | $SUDO tee /etc/iwd/main.conf >/dev/null
        fi
        $SUDO systemctl enable --now iwd.service || echo "Warning: could not enable iwd."
    fi
    if command -v bluetoothctl >/dev/null 2>&1; then
        $SUDO systemctl enable --now bluetooth.service || echo "Warning: could not enable bluetooth."
    fi

    # brightnessctl needs the video group (takes effect on next login).
    if getent group video >/dev/null 2>&1 && ! id -nG | tr ' ' '\n' | grep -qx video; then
        $SUDO usermod -aG video "$(id -un)" && echo "Added $(id -un) to group video: log out and in again."
    fi
}

install_deps

# Replace the previous backup with a fresh one.
rm -rf "$BACKUP_DIR"
backed_up=0
for_each_item backup_item

for_each_item install_item

# If a mango session is running, apply the new configs now.
if [ -n "${WAYLAND_DISPLAY:-}" ]; then
    mmsg dispatch reload_config >/dev/null 2>&1 || true
    makoctl reload >/dev/null 2>&1 || true
    pkill -SIGUSR2 waybar >/dev/null 2>&1 || true
fi

echo "Dotfiles installed from $SRC."
if ! command -v mango >/dev/null 2>&1; then
    echo "mango is not installed: the desktop will not start on login."
else
    echo "Log in on tty1 to start the desktop."
fi
if [ "$backed_up" -eq 1 ]; then
    echo "Previous files backed up to $BACKUP_DIR."
fi
