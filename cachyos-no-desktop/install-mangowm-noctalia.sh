#!/bin/bash

sudo pacman -Syu
sudo pacman -S mangowm noctalia --noconfirm
sudo pacman -S wl-clipboard alacritty xdg-desktop-portal-gnome nautilus --noconfirm
sudo pacman -S ttf-jetbrains-mono-nerd --noconfirm
mkdir -p ~/.config
mkdir -p ~/.config/mango
cp /etc/mango/config.conf ~/.config/mango/

echo "exec-once = noctalia" >> ~/.config/mango/config.conf 

sudo systemctl enable sddm
