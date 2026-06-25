#!/usr/bin/env sh
set -eu

DOTFILES_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

echo '==> install packages'
sudo pacman -S --needed zsh yay github-cli nvm alacritty keyd niri noctalia-shell
yay -S --needed helium-browser-bin

echo '==> install keyd config'
sudo install -Dm644 "$DOTFILES_DIR/etc/keyd/default.conf" /etc/keyd/default.conf
sudo systemctl enable --now keyd
sudo keyd reload || sudo systemctl restart keyd

echo '==> install shell config'
cp "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
cp "$DOTFILES_DIR/.p10k.zsh" "$HOME/.p10k.zsh"

echo '==> install app configs'
mkdir -p "$HOME/.config/alacritty" "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0" "$HOME/.config/qt5ct" "$HOME/.config/qt6ct" "$HOME/.config"
cp "$DOTFILES_DIR/.config/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
cp "$DOTFILES_DIR/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-3.0/settings.ini"
cp "$DOTFILES_DIR/.config/gtk-4.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"
cp "$DOTFILES_DIR/.config/qt5ct/qt5ct.conf" "$HOME/.config/qt5ct/qt5ct.conf"
cp "$DOTFILES_DIR/.config/qt6ct/qt6ct.conf" "$HOME/.config/qt6ct/qt6ct.conf"

echo '==> replace niri and noctalia config'
rm -rf "$HOME/.config/niri" "$HOME/.config/noctalia"
[ -d /etc/skel/.config/niri ] && cp -r /etc/skel/.config/niri "$HOME/.config/"
[ -d /etc/skel/.config/noctalia ] && cp -r /etc/skel/.config/noctalia "$HOME/.config/"
cp -r "$DOTFILES_DIR/.config/niri" "$HOME/.config/"
cp -r "$DOTFILES_DIR/.config/noctalia" "$HOME/.config/"

echo '==> install wallpaper'
mkdir -p "$HOME/.config/noctalia/wallpapers"
cp "$DOTFILES_DIR/wallpaper.jpg" "$HOME/.config/noctalia/wallpapers/wallpaper.jpg"
sed -i "s|__HOME__|$HOME|g" "$HOME/.config/noctalia/settings.json"
python - <<'PY'
import json
from pathlib import Path

p = Path.home() / '.config/noctalia/settings.json'
data = json.loads(p.read_text())
bar = data['bar']
bar['backgroundOpacity'] = 0.78
bar['frameThickness'] = 4
bar['marginVertical'] = 8
bar['widgetSpacing'] = 10
data['ui']['panelBackgroundOpacity'] = 0.78

for w in bar['widgets']['left']:
    if w.get('id') == 'Launcher':
        w['useDistroLogo'] = False
        w['icon'] = 'rocket'

for w in bar['widgets']['right']:
    if w.get('id') == 'Battery':
        # ponytail: enforce simple battery text+charging icon even if upstream defaults drift
        w['displayMode'] = 'icon-always'
        w['hideIfIdle'] = False

p.write_text(json.dumps(data, indent=2) + '\n')
PY
rm -f "$HOME/.cache/noctalia-shell/wallpapers.json"

echo '==> app dark mode defaults'
if command -v gsettings >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
  gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' || true
fi
python - <<'PY'
import json
from pathlib import Path

slack = Path.home() / '.config/Slack/storage/root-state.json'
if slack.exists():
    data = json.loads(slack.read_text())
    settings = data.setdefault('settings', {})
    settings['userTheme'] = 'dark'
    settings['systemThemeSyncEnabled'] = True
    user_choices = settings.setdefault('userChoices', {})
    user_choices['userTheme'] = 'dark'
    user_choices['systemThemeSyncEnabled'] = True
    slack.write_text(json.dumps(data, separators=(',', ':')))

helium = Path.home() / '.config/net.imput.helium/Default/Preferences'
if helium.exists():
    data = json.loads(helium.read_text())
    browser = data.setdefault('browser', {})
    theme = browser.setdefault('theme', {})
    theme['color_scheme2'] = 2
    helium.write_text(json.dumps(data, separators=(',', ':')))
PY

echo '==> reload shell'
if command -v qs >/dev/null 2>&1; then
  qs kill -c noctalia-shell --any-display || true
  sleep 1
  nohup qs -c noctalia-shell --daemonize >/tmp/noctalia-shell.log 2>&1 &
  sleep 2
fi

echo '==> set default shell'
if command -v zsh >/dev/null 2>&1; then
  ZSH_PATH=$(command -v zsh)
  CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7 || true)

  if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
    echo "Setting default shell to $ZSH_PATH"
    chsh -s "$ZSH_PATH"
  fi
fi
