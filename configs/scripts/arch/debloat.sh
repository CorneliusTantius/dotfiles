#!/bin/bash

sudo pacman -Rns cachyos-micro-settings micro shelly meld vim  --noconfirm
sudo pacman -Rns vlc-plugins-all cachyos-packageinstaller
rm -rf ~/.config/micro
