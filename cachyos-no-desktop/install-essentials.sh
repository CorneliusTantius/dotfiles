#!/bin/bash

sudo pacman -S zen-browser-bin --noconfirm
sudo pacman -S --needed git base-devel --noconfirm
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
cd ..
rm -rf paru
