#!/usr/bin/env bash
set -euo pipefail

NIRI_KEYBINDS="${HOME}/.config/niri/cfg/keybinds.kdl"
NIRI_REMOVE_LINE_C='    Mod+C                               { center-column; }'
NIRI_REMOVE_LINE_F='    Mod+F                               { fullscreen-window; }'
NIRI_REMOVE_LINE_T='    Mod+T                               { toggle-window-floating; }'
NIRI_REMOVE_LINE_W='    Mod+W                               { toggle-column-tabbed-display; }'
KEYD_CONF="/etc/keyd/default.conf"
STAMP="$(date +%Y%m%d-%H%M%S)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

PROPOSED_KEYD_CONF='[ids]
*

[meta]
c = C-c
v = C-v
x = C-x
z = C-z
a = C-a
f = C-f
s = C-s
n = C-n
r = C-r
t = C-t
w = C-w
'

say() {
  printf '%s\n' "$*"
}

section() {
  printf '\n== %s ==\n' "$*"
}

confirm() {
  local prompt="${1:-Continue?}"
  local reply
  read -r -p "$prompt [y/N]: " reply || true
  [[ "$reply" =~ ^[Yy]([Ee][Ss])?$ ]]
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    say "Missing command: $1"
    exit 1
  }
}

write_file() {
  local path="$1"
  local content="$2"
  python3 - "$path" "$content" <<'PY'
import sys, pathlib
path = pathlib.Path(sys.argv[1])
content = sys.argv[2]
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(content, encoding='utf-8')
PY
}

remove_niri_bind_to_tmp() {
  local src="$1"
  local dst="$2"
  local needle="$3"
  python3 - "$src" "$dst" "$needle" <<'PY'
import sys, pathlib
src = pathlib.Path(sys.argv[1])
dst = pathlib.Path(sys.argv[2])
needle = sys.argv[3]
text = src.read_text(encoding='utf-8')
if needle not in text:
    dst.write_text(text, encoding='utf-8')
    sys.exit(10)
dst.write_text(text.replace(needle + "\n", "", 1), encoding='utf-8')
PY
}

show_diff() {
  local before="$1"
  local after="$2"
  local label_before="$3"
  local label_after="$4"
  diff -u --label "$label_before" --label "$label_after" "$before" "$after" || true
}

backup_file() {
  local path="$1"
  local backup="$2"
  sudo cp -a "$path" "$backup"
  say "Backup -> $backup"
}

show_keyd_file() {
  local path="$1"
  say "Current $path:"
  sudo nl -ba "$path" | sed -n '1,40p'
}

keyd_file_has_legacy_meta_combo() {
  local path="$1"
  sudo grep -nE '^[[:space:]]*meta\+[a-zA-Z0-9_-]+[[:space:]]*=' "$path" >/dev/null 2>&1
}

KEYD_CONFIG_READY=0
KEYD_CONFIG_CHANGED=0

section "Plan"
say "Target:"
say "- free Super+C in niri"
say "- optionally free Super+F/T/W in niri"
say "- install keyd"
say "- map Super+C/V/X/Z/A/F/S/N/R/T/W -> Ctrl+C/V/X/Z/A/F/S/N/R/T/W globally"
say ""
say "Impact:"
say "- Super+C center-column removed from niri"
say "- optional: Super+F fullscreen-window removed from niri"
say "- optional: Super+T toggle-window-floating removed from niri"
say "- optional: Super+W toggle-column-tabbed-display removed from niri"
say "- terminal Super+C = Ctrl+C interrupt, not copy"
say "- terminal Super+V may not paste in terminals using Ctrl+Shift+V"

need_cmd python3
need_cmd diff
need_cmd grep

section "Step 1/4: niri patch preview"
if [[ -f "$NIRI_KEYBINDS" ]]; then
  NIRI_WORKING="$TMPDIR/keybinds.working"
  cp "$NIRI_KEYBINDS" "$NIRI_WORKING"
  NIRI_CHANGED=0

  NIRI_AFTER_C="$TMPDIR/keybinds.after.c"
  if remove_niri_bind_to_tmp "$NIRI_WORKING" "$NIRI_AFTER_C" "$NIRI_REMOVE_LINE_C"; then
    show_diff "$NIRI_WORKING" "$NIRI_AFTER_C" "$NIRI_KEYBINDS" "$NIRI_KEYBINDS (remove Mod+C)"
    if confirm "Remove niri Mod+C bind to free Cmd+C?"; then
      cp "$NIRI_AFTER_C" "$NIRI_WORKING"
      NIRI_CHANGED=1
      say "Selected: remove Mod+C"
    else
      say "Kept Mod+C bind."
    fi
  else
    rc=$?
    if [[ $rc -eq 10 ]]; then
      say "No change needed. Exact Mod+C bind not present."
    else
      exit "$rc"
    fi
  fi

  NIRI_AFTER_F="$TMPDIR/keybinds.after.f"
  if remove_niri_bind_to_tmp "$NIRI_WORKING" "$NIRI_AFTER_F" "$NIRI_REMOVE_LINE_F"; then
    show_diff "$NIRI_WORKING" "$NIRI_AFTER_F" "$NIRI_KEYBINDS" "$NIRI_KEYBINDS (remove Mod+F)"
    if confirm "Remove niri Mod+F bind to free Cmd+F?"; then
      cp "$NIRI_AFTER_F" "$NIRI_WORKING"
      NIRI_CHANGED=1
      say "Selected: remove Mod+F"
    else
      say "Kept Mod+F bind."
    fi
  else
    rc=$?
    if [[ $rc -eq 10 ]]; then
      say "No change needed. Exact Mod+F bind not present."
    else
      exit "$rc"
    fi
  fi

  NIRI_AFTER_T="$TMPDIR/keybinds.after.t"
  if remove_niri_bind_to_tmp "$NIRI_WORKING" "$NIRI_AFTER_T" "$NIRI_REMOVE_LINE_T"; then
    show_diff "$NIRI_WORKING" "$NIRI_AFTER_T" "$NIRI_KEYBINDS" "$NIRI_KEYBINDS (remove Mod+T)"
    if confirm "Remove niri Mod+T bind to free Cmd+T?"; then
      cp "$NIRI_AFTER_T" "$NIRI_WORKING"
      NIRI_CHANGED=1
      say "Selected: remove Mod+T"
    else
      say "Kept Mod+T bind."
    fi
  else
    rc=$?
    if [[ $rc -eq 10 ]]; then
      say "No change needed. Exact Mod+T bind not present."
    else
      exit "$rc"
    fi
  fi

  NIRI_AFTER_W="$TMPDIR/keybinds.after.w"
  if remove_niri_bind_to_tmp "$NIRI_WORKING" "$NIRI_AFTER_W" "$NIRI_REMOVE_LINE_W"; then
    show_diff "$NIRI_WORKING" "$NIRI_AFTER_W" "$NIRI_KEYBINDS" "$NIRI_KEYBINDS (remove Mod+W)"
    if confirm "Remove niri Mod+W bind to free Cmd+W?"; then
      cp "$NIRI_AFTER_W" "$NIRI_WORKING"
      NIRI_CHANGED=1
      say "Selected: remove Mod+W"
    else
      say "Kept Mod+W bind."
    fi
  else
    rc=$?
    if [[ $rc -eq 10 ]]; then
      say "No change needed. Exact Mod+W bind not present."
    else
      exit "$rc"
    fi
  fi

  if [[ $NIRI_CHANGED -eq 1 ]]; then
    show_diff "$NIRI_KEYBINDS" "$NIRI_WORKING" "$NIRI_KEYBINDS" "$NIRI_KEYBINDS (final proposed)"
    if confirm "Apply selected niri patch(es)?"; then
      BACKUP_PATH="${NIRI_KEYBINDS}.bak.${STAMP}"
      cp -a "$NIRI_KEYBINDS" "$BACKUP_PATH"
      cp "$NIRI_WORKING" "$NIRI_KEYBINDS"
      say "Patched: $NIRI_KEYBINDS"
      say "Backup -> $BACKUP_PATH"
    else
      say "Skipped niri patch."
    fi
  else
    say "No niri changes selected."
  fi
else
  say "Skipped. Missing file: $NIRI_KEYBINDS"
fi

section "Step 2/4: keyd install preview"
if command -v keyd >/dev/null 2>&1; then
  say "keyd already installed: $(command -v keyd)"
else
  say "Command to run: sudo pacman -S --needed keyd"
  if confirm "Install keyd?"; then
    sudo pacman -S --needed keyd
  else
    say "Skipped keyd install."
  fi
fi

section "Step 3/4: keyd config preview"
mkdir -p "$TMPDIR/etc-keyd"
PROPOSED_CONF_PATH="$TMPDIR/etc-keyd/default.conf"
write_file "$PROPOSED_CONF_PATH" "$PROPOSED_KEYD_CONF"

say "Proposed $KEYD_CONF:"
nl -ba "$PROPOSED_CONF_PATH"

if sudo test -f "$KEYD_CONF"; then
  sudo cat "$KEYD_CONF" > "$TMPDIR/current.default.conf"
  say "Existing config found: $KEYD_CONF"
  show_keyd_file "$KEYD_CONF"
  if cmp -s "$TMPDIR/current.default.conf" "$PROPOSED_CONF_PATH"; then
    say "No change needed. $KEYD_CONF already matches proposed config."
    KEYD_CONFIG_READY=1
  else
    show_diff "$TMPDIR/current.default.conf" "$PROPOSED_CONF_PATH" "$KEYD_CONF" "$KEYD_CONF (proposed)"
    say "Other keyd config files:"
    sudo find /etc/keyd -maxdepth 1 -type f -name '*.conf' -print 2>/dev/null || true
    if keyd_file_has_legacy_meta_combo "$KEYD_CONF"; then
      say "Warning: detected legacy invalid 'meta+key =' syntax in $KEYD_CONF"
    fi
    if confirm "Backup + overwrite $KEYD_CONF with proposed config?"; then
      BACKUP_PATH="${KEYD_CONF}.bak.${STAMP}"
      backup_file "$KEYD_CONF" "$BACKUP_PATH"
      sudo mkdir -p /etc/keyd
      sudo install -m 0644 "$PROPOSED_CONF_PATH" "$KEYD_CONF"
      say "Wrote: $KEYD_CONF"
      show_keyd_file "$KEYD_CONF"
      KEYD_CONFIG_READY=1
      KEYD_CONFIG_CHANGED=1
    else
      say "Skipped keyd config write."
      if keyd_file_has_legacy_meta_combo "$KEYD_CONF"; then
        say "Current config still contains invalid legacy syntax. Validation will fail until overwritten."
      else
        KEYD_CONFIG_READY=1
      fi
    fi
  fi
else
  say "New file: $KEYD_CONF"
  show_diff /dev/null "$PROPOSED_CONF_PATH" "/dev/null" "$KEYD_CONF"
  if confirm "Create $KEYD_CONF with proposed config?"; then
    sudo mkdir -p /etc/keyd
    sudo install -m 0644 "$PROPOSED_CONF_PATH" "$KEYD_CONF"
    say "Wrote: $KEYD_CONF"
    show_keyd_file "$KEYD_CONF"
    KEYD_CONFIG_READY=1
    KEYD_CONFIG_CHANGED=1
  else
    say "Skipped keyd config creation."
  fi
fi

section "Step 4/4: validate + enable keyd"
if ! command -v keyd >/dev/null 2>&1; then
  say "Skipped. keyd not installed."
else
  KEYD_VALID=0
  if sudo test -f "$KEYD_CONF"; then
    if [[ $KEYD_CONFIG_READY -ne 1 ]]; then
      say "Skipped validation. $KEYD_CONF not ready or still using old syntax."
    else
      say "Validation command: sudo keyd check $KEYD_CONF"
      if confirm "Run config validation?"; then
        VALIDATION_LOG="$TMPDIR/keyd-check.log"
        if sudo keyd check "$KEYD_CONF" 2>&1 | tee "$VALIDATION_LOG"; then
          if grep -q 'not a valid key' "$VALIDATION_LOG"; then
            say "Validation printed warnings. Not enabling service automatically."
            KEYD_VALID=0
          else
            say "Config valid."
            KEYD_VALID=1
          fi
        else
          say "Validation failed. Not enabling service automatically."
          KEYD_VALID=0
        fi
      else
        say "Skipped config validation."
      fi
    fi
  fi

  say "Service commands:"
  say "- sudo systemctl enable --now keyd"
  say "- wait until service active"
  say "- sudo keyd reload"
  if [[ $KEYD_VALID -eq 1 ]]; then
    if confirm "Enable/start keyd service + reload config?"; then
      sudo systemctl enable --now keyd
      START_OK=0
      for _ in 1 2 3 4 5; do
        if sudo systemctl is-active --quiet keyd; then
          START_OK=1
          break
        fi
        sleep 1
      done
      if [[ $START_OK -eq 1 ]]; then
        if ! sudo keyd reload; then
          say "Reload failed. Trying one restart + status check."
          sudo systemctl restart keyd
          sleep 1
        fi
        sudo systemctl --no-pager --full status keyd | sed -n '1,12p'
      else
        say "keyd did not become active in time."
        sudo systemctl --no-pager --full status keyd | sed -n '1,20p'
      fi
    else
      say "Skipped service enable/start."
    fi
  else
    say "Skipped service enable/start. Fix validation first."
  fi
fi

section "Done"
say "Rollback:"
say "- restore ${NIRI_KEYBINDS}.bak.${STAMP} if created"
say "- restore ${KEYD_CONF}.bak.${STAMP} if created"
say "- sudo systemctl disable --now keyd"
say "- sudo pacman -Rns keyd   # optional"
say ""
say "If keyd already had old meta+key syntax, rerun installer and choose overwrite for $KEYD_CONF."
