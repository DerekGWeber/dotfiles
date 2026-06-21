# Dotfiles

Personal dotfiles for a unified terminal environment across macOS, Raspberry Pi, OpenWrt, and DreamHost.

## Repo layout

    common/      shared shell config sourced everywhere
    zsh/         zshrc and zsh-specific config
    bash/        bash fallback for hosts without zsh
    starship/    starship.toml (base) + per-host starship-<hostname>.toml
    git/         gitconfig template
    ssh/         ssh config (fleet Host blocks)
    openwrt/     router-specific
    host/        per-host overrides
    gaps/        notes on tool gaps per platform
    macos/       defaults.sh and mac-only setup
    Brewfile     Homebrew bundle (macOS)
    install.sh   symlink and bootstrap script

## Quick setup on a new machine

1. Install Homebrew (https://brew.sh)
2. Clone: git clone https://github.com/DerekGWeber/dotfiles.git ~/dotfiles
3. Install packages (macOS): brew bundle --file=~/dotfiles/Brewfile
4. Run ~/dotfiles/install.sh to symlink everything, or do it manually:

        ln -s ~/dotfiles/zsh/zshrc ~/.zshrc
        mkdir -p ~/.config
        ln -s ~/dotfiles/starship/starship.toml ~/.config/starship.toml
        ln -s ~/dotfiles/starship/starship-$(hostname -s).toml ~/.config/starship-$(hostname -s).toml
        ln -s ~/dotfiles/git/gitconfig ~/.gitconfig
        mkdir -p ~/.ssh && chmod 700 ~/.ssh
        ln -s ~/dotfiles/ssh/config ~/.ssh/config

## Per-host prompt tint

zshrc points STARSHIP_CONFIG at ~/.config/starship-$(hostname -s).toml when that file exists, otherwise it falls back to the base starship.toml. Fleet palette: Air blue, MBP green, Mac Mini purple, Pi red, Spitz yellow, DreamHost orange.

## Machine-local overrides

Put machine-specific, uncommitted settings in ~/.zshrc.local; zshrc sources it last.
