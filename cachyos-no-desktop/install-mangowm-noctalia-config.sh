#!/usr/bin/env sh

mkdir -p ~/.config
mkdir -p ~/.config/mango
cp /etc/mango/config.conf ~/.config/mango/

echo "exec-once = noctalia" >> ~/.config/mango/config.conf
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
