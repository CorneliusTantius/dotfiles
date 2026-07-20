#!/bin/bash

sudo pacman -Syu
sudo pacman -Rdd jack2 --noconfirm
sudo pacman -S pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber --noconfirm
sudo pacman -S bluez bluez-utils --noconfirm
sudo pacman -S sddm --noconfirm
sudo pacman -S intel-media-driver libva-utils brightnessctl --noconfirm
sudo pacman -S network-manager-applet --noconfirm

sudo systemctl enable --now bluetooth
