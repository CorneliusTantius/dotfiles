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
    zed \
    nvm \
    github-cli \
    python \
    python-pip

git config --global user.name "Cornelius Tantius"
git config --global user.email "corneliustantius.ct@gmail.com"
