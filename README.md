# dotfiles

Personal dotfiles: `.bashrc`, `.bash_profile` and configs under `.config/`.

## Install

Quick install:

```sh
curl -fsSL https://raw.githubusercontent.com/CorneliusTantius/dotfiles/main/install.sh | sh
```

Or from a clone:

```sh
git clone https://github.com/CorneliusTantius/dotfiles.git
cd dotfiles
sh install.sh
```

The same script is the installer on a blank Arch/CachyOS tty and the updater on machines that already have it. It is safe to re-run. It:

1. installs git if missing (when run through `curl`);
2. installs missing packages: mango (`mangowm`), waybar, mako, fuzzel, foot, udiskie, grim, slurp, wl-clipboard, brightnessctl, pipewire, bluez, iwd, polkit, JetBrains Mono, plus bluetui/impala/wiremix on Arch. It uses pacman, apt or dnf, whichever exists (mango is only packaged for Arch);
3. enables `bluetooth` and `iwd` (unless NetworkManager is enabled) and adds you to the `video` group;
4. copies `.bashrc`, `.bash_profile` and everything in `.config/` into your home directory (copied, not symlinked);
5. reloads mango, mako and waybar if a session is running.

Logging in on tty1 starts mango (see `.bash_profile`); tty2-6 stay text. Set `NO_DEPS=1` to skip steps 1-3.

## Backup

Before overwriting anything, the script backs up existing files to `~/.dotfiles-backup`. Only the latest backup is kept: each run replaces the previous one. Running the script again therefore backs up the dotfiles that were installed last time, so keep your own copies of anything you want to preserve.

## Restore

To put back the files from the last backup:

```sh
sh restore.sh
```

This copies `~/.dotfiles-backup` over your home directory. Files that had no backup are left as they are.
