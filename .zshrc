# ============================================================================
# OS DETECTION
# ============================================================================
case "$(uname -s)" in
  Darwin*) OS="macos" ;;
  Linux*)  OS="linux"  ;;
esac

# ============================================================================
# SHELL OPTIONS
# ============================================================================
setopt AUTO_CD

# ============================================================================
# ENVIRONMENT VARIABLES
# ============================================================================
[[ "$OS" == "macos" ]] && export TMPDIR=$(getconf DARWIN_USER_TEMP_DIR)
export PATH="$HOME/.local/bin:$PATH"
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
export EDITOR=nvim

# Load secrets from .env (gitignored)
[[ -f "$HOME/dotfiles/.env" ]] && source "$HOME/dotfiles/.env" && export SANITY_AUTH_TOKEN

# ============================================================================
# ALIASES
# ============================================================================

# System
alias cl="clear"
alias ff="fastfetch"
alias q="exit"
alias sz="source ~/.zshrc"

# Directory Navigation (zoxide: use `z` for smart cd, `zi` for interactive)
alias ..="z .."
alias ...="z ../.."
alias ....="z ../../.."
alias -- -="z -"
alias rmd="rm -rf"

# Editor
alias nv="nvim"
alias nvh="nvim ."
[[ "$OS" == "macos" ]] && alias nvhc="$HOME/dotfiles/scripts/nvhc.sh"

# Git
alias gpo="git pull origin --no-rebase"
alias glog="git log --graph --topo-order --pretty='%w(100,0,6)%C(yellow)%h%C(bold)%C(black)%d %C(cyan)%ar %C(green)%an%n%C(bold)%C(white)%s %N' --abbrev-commit"
alias lg="lazygit"

# ============================================================================
# PKGUP - Declarative Package Manager (cross-platform)
# ============================================================================
pkgup() {
  if [[ "$OS" == "macos" ]]; then
    brew update && brew bundle install --verbose --cleanup --file="$HOME/dotfiles/Brewfile" && brew upgrade
  elif [[ "$OS" == "linux" ]]; then
    sudo pacman -Sy \
      && yay -S --needed $(sed -n '/^[^#[:space:]]/p' "$HOME/dotfiles/packages/pacman.list") \
      && yay -S --needed $(sed -n '/^[^#[:space:]]/p' "$HOME/dotfiles/packages/yay.list") \
      && pnpm add -g $(sed -n '/^[^#[:space:]]/p' "$HOME/dotfiles/packages/pnpm.list") \
      && sudo pacman -Su \
      && yay -Yc
  fi
}

# ============================================================================
# BAT (Modern cat replacement)
# ============================================================================
if command -v bat &> /dev/null; then
  alias cat="bat"
  alias rcat="/bin/cat"
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

# ============================================================================
# KEY BINDINGS
# ============================================================================
bindkey jj vi-cmd-mode

# ============================================================================
# FUNCTIONS
# ============================================================================

# Kill process on specific port
killport() {
  if [[ "$OS" == "macos" ]]; then
    lsof -ti:$1 | xargs kill -9
  else
    fuser -k "$1"/tcp 2>/dev/null
  fi
}

# ============================================================================
# COMPLETIONS & PLUGINS
# ============================================================================

# Initialize zsh completion system (required for kubectl, etc.)
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# zsh-autosuggestions
if [[ "$OS" == "macos" ]]; then
  ZSH_AUTOSUGGEST_PATH="/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
else
  ZSH_AUTOSUGGEST_PATH="/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi
[[ -f "$ZSH_AUTOSUGGEST_PATH" ]] && source "$ZSH_AUTOSUGGEST_PATH"

# zsh-syntax-highlighting (must be last)
if [[ "$OS" == "macos" ]]; then
  ZSH_SYNTAX_HIGHLIGHTING_PATH="/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
else
  ZSH_SYNTAX_HIGHLIGHTING_PATH="/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
[[ -f "$ZSH_SYNTAX_HIGHLIGHTING_PATH" ]] && source "$ZSH_SYNTAX_HIGHLIGHTING_PATH"

# Kubernetes completion (cached for speed)
if command -v kubectl &> /dev/null; then
  KUBECTL_COMPLETION_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/kubectl-completion.zsh"
  if [[ ! -f "$KUBECTL_COMPLETION_CACHE" || $(command -v kubectl) -nt "$KUBECTL_COMPLETION_CACHE" ]]; then
    mkdir -p "$(dirname "$KUBECTL_COMPLETION_CACHE")"
    kubectl completion zsh > "$KUBECTL_COMPLETION_CACHE" 2>/dev/null
  fi
  [[ -f "$KUBECTL_COMPLETION_CACHE" ]] && source "$KUBECTL_COMPLETION_CACHE"
fi

# ============================================================================
# FNM (Fast Node Manager)
# ============================================================================
if command -v fnm &> /dev/null; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

# ============================================================================
# ATUIN (Shell History Database)
# ============================================================================
if command -v atuin &> /dev/null; then
  eval "$(atuin init zsh --disable-up-arrow)"
fi

# ============================================================================
# STARSHIP PROMPT
# ============================================================================
eval "$(starship init zsh)"

# ============================================================================
# ZOXIDE
# ============================================================================
eval "$(zoxide init zsh)"

# ============================================================================
# STARTUP
# ============================================================================
ff

# pnpm
export PNPM_HOME="/home/gurg/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
