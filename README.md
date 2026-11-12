# dotfiles

Personal dotfiles: `.bashrc` and configs under `.config/`.

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

The script copies `.bashrc` and everything in `.config/` into your home directory. Files are copied, not symlinked.

## Backup

Before overwriting anything, the script backs up existing files to `~/.dotfiles-backup`. Only the latest backup is kept: each run replaces the previous one. Running the script again therefore backs up the dotfiles that were installed last time, so keep your own copies of anything you want to preserve.
