#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${1:-${HOME}/.config/niri/config.kdl}"

say() {
  printf '%s\n' "$*"
}

confirm() {
  local prompt="${1:-Continue?}"
  local reply
  read -r -p "$prompt [y/N]: " reply || true
  [[ "$reply" =~ ^[Yy]([Ee][Ss])?$ ]]
}

say "Plan: reload niri config"
say "Config: $CONFIG_PATH"

if ! command -v niri >/dev/null 2>&1; then
  say "Error: niri command not found"
  exit 1
fi

if [[ ! -f "$CONFIG_PATH" ]]; then
  say "Error: config missing -> $CONFIG_PATH"
  exit 1
fi

say "Validate command: niri validate -c $CONFIG_PATH"
if confirm "Run validation?"; then
  niri validate -c "$CONFIG_PATH"
  say "Validation OK"
else
  say "Skipped validation"
fi

say "Reload command: niri msg action load-config-file --path $CONFIG_PATH"
if confirm "Reload niri config now?"; then
  niri msg action load-config-file --path "$CONFIG_PATH"
  say "Reload sent"
else
  say "Skipped reload"
fi
