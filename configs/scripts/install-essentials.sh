#!/bin/bash

install_if_missing() {
    local missing=()

    for pkg in "$@"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        sudo pacman -S --noconfirm "${missing[@]}"
    fi
}

install_if_missing \
    zen-browser-bin\
    git\
    base-devel

git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
cd ..
rm -rf paru
