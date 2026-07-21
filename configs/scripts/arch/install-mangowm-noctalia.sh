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

sudo pacman -Syu

install_if_missing \
    mangowm\
    noctalia\
    wl-clipboard\
    alacritty\
    xdg-desktop-portal-gnome\
    nautilus\
    ttf-jetbrains-mono-nerd\
    xorg-xwayland\
    sddm

sudo systemctl enable sddm
