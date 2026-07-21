#!/bin/bash

sudo pacman -Syu
sudo pacman -S mangowm noctalia --noconfirm
sudo pacman -S wl-clipboard alacritty xdg-desktop-portal-gnome nautilus --noconfirm
sudo pacman -S ttf-jetbrains-mono-nerd --noconfirm
sudo pacman -S xorg-xwayland --noconfirm

sudo systemctl enable sddm
