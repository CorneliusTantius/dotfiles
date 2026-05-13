# cachyos-niri-mac-keybind

Small helper scripts for CachyOS + niri to add Mac-style `Super` shortcuts.

What it does:
- installs and configures `keyd` on CachyOS
- maps `Super+C/V/X/Z/A/F/S/N/R/T/W` -> `Ctrl+C/V/X/Z/A/F/S/N/R/T/W`
- removes conflicting niri binds for `Super+C`
- optionally removes conflicting niri binds for `Super+F`, `Super+T`, `Super+W`
- validates and starts `keyd`
- reloads niri config on demand

Files:
- `install-macos-cmd-shortcuts.sh` — interactive installer with diff preview, confirmations, validation, and safer keyd startup handling
- `reload-niri-config.sh` — validate + reload niri config

Status:
- tested working on CachyOS + niri

Notes:
- global remap affects all apps
- `Super+C` in terminal becomes `Ctrl+C` interrupt
- terminal paste may still differ in some terminals
- `keyd` service is enabled to start automatically on boot
