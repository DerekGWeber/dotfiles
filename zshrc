# ~/.zshrc - Unified for macOS, Raspberry Pi, and DreamHost
# Last Updated 2025-10-11 by Derek G. Weber

echo "Loading .zshrc"

# ============================================================================
# ENVIRONMENT DETECTION
# ============================================================================

# Detect environment
if [[ -n "$SSH_CONNECTION" ]] && [[ "$(hostname)" =~ (dreamhost|iad1-shared) ]]; then
    export OS_TYPE="dreamhost"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    export OS_TYPE="macos"
elif [[ -f /proc/device-tree/model ]] && grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
    export OS_TYPE="raspberrypi"
else
    export OS_TYPE="linux"
fi

# ============================================================================
# PATH SETUP (MUST BE EARLY - BEFORE TOOL INITIALIZATION!)
# ============================================================================

# Homebrew setup (macOS/Raspberry Pi only)
if [[ "$OS_TYPE" == "macos" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    export PATH="/opt/homebrew/bin:$PATH"
elif [[ "$OS_TYPE" == "raspberrypi" ]] && command -v brew 1>/dev/null 2>&1; then
    eval "$($(which brew) shellenv)"
fi

# DreamHost: Add local bin to PATH FIRST
if [[ "$OS_TYPE" == "dreamhost" ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Base PATH (OS-aware)
if [[ "$OS_TYPE" == "macos" ]]; then
    export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$HOME/Library/Python/3.9/bin:/usr/bin:/bin:/usr/sbin:/sbin"
elif [[ "$OS_TYPE" == "dreamhost" ]]; then
    export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
else
    export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
fi

export PYTHONPATH=".:$PYTHONPATH"

# ============================================================================
# STARSHIP PROMPT (AFTER PATH IS SET!)
# ============================================================================

if command -v starship 1>/dev/null 2>&1; then
    eval "$(starship init zsh)"
    export STARSHIP_DATE=$(date +%Y-%m-%d)
    precmd() { export STARSHIP_DATE=$(date +%Y-%m-%d); }
fi

# ============================================================================
# HISTORY
# ============================================================================

HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_ALL_DUPS  # Don't record duplicates
setopt HIST_FIND_NO_DUPS     # Don't show duplicates in search
setopt SHARE_HISTORY         # Share history across terminals
setopt APPEND_HISTORY        # Append rather than overwrite

# ============================================================================
# COMPLETION SYSTEM
# ============================================================================

autoload -Uz compinit
compinit

# Case insensitive matching
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Menu selection
zstyle ':completion:*' menu select

# DreamHost additions (useful everywhere)
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true

# Colorized completion (needs dircolors on Linux)
if command -v dircolors 1>/dev/null 2>&1; then
    eval "$(dircolors -b)"
    zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
fi

# Process list colors for kill command
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# ============================================================================
# KEY BINDINGS
# ============================================================================

# Use emacs keybindings
bindkey -e

# ============================================================================
# DIRECTORY NAVIGATION
# ============================================================================

setopt AUTO_CD             # Type directory name to cd
setopt AUTO_PUSHD          # Make cd push old directory onto stack
setopt PUSHD_IGNORE_DUPS   # Don't push duplicates

# ============================================================================
# ALIASES - LS/EZA
# ============================================================================

if command -v eza 1>/dev/null 2>&1; then
    alias ls='eza --icons'
    alias ll='eza -lah --icons --git'
    alias la='eza -a --icons'
    alias lt='eza --tree --level=2 --icons'
else
    if [[ "$OS_TYPE" == "macos" ]]; then
        alias ls='ls -G'
    else
        alias ls='ls --color=auto'
    fi
    alias ll='ls -lah'
    alias la='ls -A'
fi

# ============================================================================
# ALIASES - BAT/CAT
# ============================================================================

if command -v bat 1>/dev/null 2>&1; then
    alias cat='bat --paging=never'
    alias batl='bat'  # Use when you want paging
fi

# ============================================================================
# ALIASES - GIT
# ============================================================================

alias gs='git status'
alias gd='git diff'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gco='git checkout'
alias gb='git branch'

# Git integration for diff-so-fancy (if available)
if command -v diff-so-fancy 1>/dev/null 2>&1; then
    git config --global core.pager "diff-so-fancy | less --tabs=4 -RFX"
    git config --global interactive.diffFilter "diff-so-fancy --patch"
fi

# ============================================================================
# ALIASES - PYTHON
# ============================================================================

alias venv='python3 -m venv venv'
alias activate='source venv/bin/activate'

# ============================================================================
# ALIASES - SYSTEM
# ============================================================================

alias myip='curl -s ifconfig.me'

# DreamHost: netstat instead of lsof
if [[ "$OS_TYPE" == "dreamhost" ]]; then
    alias ports='netstat -tuln | grep LISTEN'
else
    alias ports='lsof -i -P -n | grep LISTEN'
fi

# macOS-specific
if [[ "$OS_TYPE" == "macos" ]]; then
    alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
    alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'
    alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'
    alias brewup='brew update && brew upgrade && brew cleanup'
fi

# ============================================================================
# FUNCTIONS
# ============================================================================

# Make directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract any archive
extract() {
    if [ -f $1 ]; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *)           echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Quick search in history
h() {
    history | grep "$1"
}

# Find and kill process by name
killit() {
    ps aux | grep -v grep | grep -i "$1" | awk '{print $2}' | xargs kill -9
}

# ============================================================================
# ENVIRONMENT VARIABLES
# ============================================================================

export EDITOR='vim'
export VISUAL=$EDITOR
export PYTHONDONTWRITEBYTECODE=1  # Don't create .pyc files

# ============================================================================
# PYENV (if installed)
# ============================================================================

if [[ -d "$HOME/.pyenv" ]]; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

# Quick python version switcher
pv() {
    if [ -z "$1" ]; then
        pyenv versions
    else
        pyenv global $1
    fi
}

# ============================================================================
# DIRENV (if installed)
# ============================================================================

if command -v direnv 1>/dev/null 2>&1; then
    eval "$(direnv hook zsh)"
fi

# ============================================================================
# FZF (if installed)
# ============================================================================

if command -v fzf 1>/dev/null 2>&1; then
    if [[ -f ~/.fzf.zsh ]]; then
        source ~/.fzf.zsh
    else
        source <(fzf --zsh) 2>/dev/null
    fi
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
fi

# ============================================================================
# ZSH PLUGINS
# ============================================================================

# Homebrew-installed plugins (macOS/Raspberry Pi)
if [[ "$OS_TYPE" != "dreamhost" ]] && command -v brew 1>/dev/null 2>&1; then
    BREW_PREFIX=$(brew --prefix)
    [ -f "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && \
        source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    [ -f "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && \
        source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
else
    # Manual install locations (for DreamHost if you install them)
    [ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
        source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
    [ -f ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
        source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

