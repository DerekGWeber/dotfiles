#!/usr/bin/env bash
# install.sh - bootstrap the dotfiles on any fleet host
# Usage: ~/dotfiles/install.sh [--no-brew]
# Idempotent: re-running only repoints what drifted. An existing real file is
# backed up to <file>.bak-<timestamp> before it is replaced by a symlink.
# Last updated 2026-06-20 by Derek G. Weber
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
HOST_SHORT="$(hostname -s 2>/dev/null || hostname)"
OS="$(uname -s)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DO_BREW=1
[ "${1:-}" = "--no-brew" ] && DO_BREW=0

info() { printf '  %s\n' "$*"; }

# link SRC DEST - back up an existing real file, then symlink
link() {
    src="$1"; dest="$2"
    if [ ! -e "$src" ]; then
        info "skip (missing in repo): $src"
        return 0
    fi
    if [ -L "$dest" ]; then
        [ "$(readlink "$dest")" = "$src" ] && { info "ok: $dest"; return 0; }
        rm "$dest"
    elif [ -e "$dest" ]; then
        info "backup: $dest -> $dest.bak-$STAMP"
        mv "$dest" "$dest.bak-$STAMP"
    fi
    ln -s "$src" "$dest"
    info "link: $dest -> $src"
}

# accent color for this host's starship prompt
accent_for_host() {
    case "$1" in
        dgdw-mba-m4)      echo blue   ;;  # MacBook Air M4
        *mbp*)            echo green  ;;  # MacBook Pro
        dwgc-clt-svr-001) echo purple ;;  # Mac Mini
        dwgc-clt-svr-002|dwgc-clt-exit-001) echo red ;;  # Raspberry Pi 5
        dwgc-clt-rtr-001) echo yellow ;;  # Spitz AX
        iad1-shared-*)    echo orange ;;  # DreamHost shared
        *)                echo cyan   ;;  # neutral fallback
    esac
}

echo "Installing dotfiles from $DOTFILES (host: $HOST_SHORT, os: $OS)"

# ---- shell ----
link "$DOTFILES/zsh/zshrc" "$HOME/.zshrc"
[ -f "$HOME/.zshrc.local" ] || { printf '# Machine-local zsh overrides (uncommitted), sourced last\n' > "$HOME/.zshrc.local"; info "seed: ~/.zshrc.local"; }

# ---- starship ----
mkdir -p "$HOME/.config"
link "$DOTFILES/starship/starship.toml" "$HOME/.config/starship.toml"
host_repo_cfg="$DOTFILES/starship/starship-$HOST_SHORT.toml"
host_cfg="$HOME/.config/starship-$HOST_SHORT.toml"
if [ -f "$host_repo_cfg" ]; then
    link "$host_repo_cfg" "$host_cfg"
else
    accent="$(accent_for_host "$HOST_SHORT")"
    info "generate: $host_cfg (accent=$accent)"
    q='"'
    sed "s|^accent = .*|accent = ${q}${accent}${q}|" "$DOTFILES/starship/starship.toml" > "$host_cfg"
fi

# ---- git ----
link "$DOTFILES/git/gitconfig" "$HOME/.gitconfig"
[ -f "$HOME/.gitconfig.local" ] || { printf '# Machine-local git overrides (uncommitted)\n' > "$HOME/.gitconfig.local"; info "seed: ~/.gitconfig.local"; }

# ---- ssh ----
mkdir -p "$HOME/.ssh"; chmod 700 "$HOME/.ssh"
link "$DOTFILES/ssh/config" "$HOME/.ssh/config"
[ -f "$HOME/.ssh/config.local" ] || { printf '# Per-host ssh overrides (uncommitted)\n' > "$HOME/.ssh/config.local"; chmod 600 "$HOME/.ssh/config.local"; info "seed: ~/.ssh/config.local"; }

# ---- Homebrew bundle (macOS only) ----
if [ "$OS" = "Darwin" ] && [ "$DO_BREW" = "1" ]; then
    if command -v brew >/dev/null 2>&1; then
        # Homebrew 6 tap-trust gate: pre-trust the official HashiCorp tap (Terraform)
        # so brew bundle does not stop to ask. Guarded for older brew without 'trust'.
        if brew help trust >/dev/null 2>&1; then
            brew trust hashicorp/tap >/dev/null 2>&1 || true
        fi
        info "brew bundle ..."
        # NO_INSTALL_CLEANUP avoids a per-formula cleanup race during the parallel
        # bundle (harmless 'dir_s_rmdir ... .incomplete' errors). Run 'brew cleanup' later.
        HOMEBREW_NO_INSTALL_CLEANUP=1 brew bundle --file="$DOTFILES/Brewfile"
    else
        info "brew not found; install from https://brew.sh then re-run, or pass --no-brew"
    fi
fi

echo "Done. Open a new shell or run: exec zsh"