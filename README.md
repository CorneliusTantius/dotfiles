# dotfiles

Personal Arch / CachyOS dotfiles for a MacBookPro16,1 running **niri + Noctalia + foot**.

## Included
- **zsh** + powerlevel10k prompt
- **niri** compositor config
- **foot** terminal config
- **Noctalia** shell/config
- helper scripts for:
  - AMD GPU low-power mode
  - CPU low/medium-low power profiles
  - power draw checks
  - mac-style keybind workflow on CachyOS

## Layout
```text
.
├── .zshrc
├── .p10k.zsh
├── .gitconfig
├── .config/
│   ├── foot/
│   ├── niri/
│   └── noctalia/
├── cachyos-mac-a2141-scripts/
└── install.sh
```

## Quick install
Clone repo, then run:

```bash
./install.sh
```

What it does:
- symlinks tracked files into `$HOME`
- backs up existing files before replacing them
- keeps setup easy to update with `git pull`

## Manual apply
If you prefer manual setup, copy or symlink the files you want into `$HOME`.

## Notes
- tuned for **CachyOS** on **MacBookPro16,1**
- some paths are user-specific and may need edits after cloning
- review helper scripts before running on another machine
- Noctalia config is included so setup restores more cleanly out of box

## Related scripts
See `cachyos-mac-a2141-scripts/` for power + keybind helpers.
