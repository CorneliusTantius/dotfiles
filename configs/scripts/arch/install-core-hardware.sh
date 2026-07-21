#!/bin/bash

sudo pacman -Syu
sudo pacman -Rdd jack2 --noconfirm


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
    pipewire \
    pipewire-alsa \
    pipewire-pulse \
    pipewire-jack \
    wireplumber

install_if_missing \
    bluez \
    bluez-utils

install_if_missing \
    sddm

install_if_missing \
    intel-media-driver \
    libva-utils \
    brightnessctl

install_if_missing \
    network-manager-applet

sudo systemctl enable --now bluetooth
