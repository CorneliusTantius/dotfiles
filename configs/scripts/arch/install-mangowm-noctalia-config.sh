#!/usr/bin/env sh

mkdir -p ~/.config
rm -rf ~/.config/mango
rm -rf ~/.config/noctalia

cp -r ../../mango ~/.config/
cp -r ../../noctalia ~/.config/

gsettings set org.gnome.desktop.interface color-scheme prefer-dark
