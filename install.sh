#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="${HOME}"

link_item() {
  local src_rel="$1"
  local src="$REPO_DIR/$src_rel"
  local dst="$HOME_DIR/$src_rel"

  mkdir -p "$(dirname "$dst")"

  if [[ -L "$dst" && "$(readlink -f "$dst")" == "$src" ]]; then
    echo "ok  $src_rel"
    return 0
  fi

  if [[ -e "$dst" || -L "$dst" ]]; then
    mv "$dst" "$dst.backup.$(date +%Y%m%d-%H%M%S)"
    echo "bak $src_rel"
  fi

  ln -s "$src" "$dst"
  echo "ln  $src_rel"
}

items=(
  .zshrc
  .p10k.zsh
  .gitconfig
  .config/niri
  .config/foot
  .config/noctalia
  .config/fish
)

for item in "${items[@]}"; do
  [[ -e "$REPO_DIR/$item" ]] && link_item "$item"
done

echo
echo "Done. Review backups with: find \"$HOME\" -maxdepth 3 -name '*.backup.*'"
