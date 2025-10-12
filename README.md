# My Terminal Setup

Personal dotfiles for macOS terminal environment.

## Quick Setup on New Machine
1. Install Homebrew
2. Clone this repo: `git clone https://github.com/YOURUSERNAME/dotfiles.git ~/dotfiles`
3. Symlink configs:
```bash
   ln -s ~/dotfiles/zshrc ~/.zshrc
   mkdir -p ~/.config
   ln -s ~/dotfiles/starship.toml ~/.config/starship.toml
   ln -s ~/dotfiles/Brewfile ~/Brewfile
