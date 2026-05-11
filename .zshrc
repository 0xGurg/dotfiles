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
[[ -f "$HOME/dotfiles/.env" ]] && source "$HOME/dotfiles/.env"

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

# Wireguard
alias wg="sudo wg"
alias wgu="wg-quick up"
alias wgd="wg-quick down"

# ============================================================================
# PKGUP - Declarative Package Manager (cross-platform)
# ============================================================================
pkgup() {
  if [[ "$OS" == "macos" ]]; then
    local cleanup_list
    cleanup_list=$(brew bundle cleanup --file="$HOME/dotfiles/Brewfile" 2>/dev/null)
    if [[ -n "$cleanup_list" ]]; then
      echo "The following packages are not in Brewfile and would be removed:"
      echo "$cleanup_list"
      if read -q "REPLY?Proceed with cleanup? (y/N) "; then
        echo ""
        brew update && brew bundle install --verbose --cleanup --file="$HOME/dotfiles/Brewfile" && brew upgrade
      else
        echo ""
        brew update && brew bundle install --verbose --file="$HOME/dotfiles/Brewfile" && brew upgrade
      fi
    else
      brew update && brew bundle install --verbose --file="$HOME/dotfiles/Brewfile" && brew upgrade
    fi
  elif [[ "$OS" == "linux" ]]; then
    local PNPM_LIST="$HOME/dotfiles/packages/pnpm.list"

    sudo decman || return 1

    local PKGS=("${(@f)$(sed -n '/^[^#[:space:]]/p' "$PNPM_LIST")}")
    [[ ${#PKGS[@]} -gt 0 ]] && pnpm add -g "${PKGS[@]}"
    pnpm update -g

    # Cleanup: remove globals not declared in pnpm.list
    local pkg
    while IFS= read -r pkg; do
      grep -qxF -- "$pkg" "$PNPM_LIST" 2>/dev/null \
        || pnpm remove -g "$pkg"
    done < <(pnpm list -g --depth=0 --json 2>/dev/null | jq -r '.[].dependencies // {} | keys[]')
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

# wg-quick requires bash 4+, but macOS ships with bash 3.2.
# This wrapper forces it to run under Homebrew bash.
if [[ "$OS" == "macos" ]]; then
  function wg-quick() {
    sudo /opt/homebrew/bin/bash /opt/homebrew/bin/wg-quick "$@"
  }
fi

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
# fastfetch runs in .zprofile (login shells only) to avoid slowing down subshells

# pnpm (cross-platform)
if [[ "$OS" == "macos" ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="$HOME/.local/share/pnpm"
fi
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Added by Antigravity
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"
