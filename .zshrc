# ============================================================================
# SHELL OPTIONS
# ============================================================================
setopt AUTO_CD

# ============================================================================
# ENVIRONMENT VARIABLES
# ============================================================================
export TMPDIR=$(getconf DARWIN_USER_TEMP_DIR)
export PATH="$HOME/.local/bin:$PATH"
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"

# ============================================================================
# ALIASES
# ============================================================================

# System
alias bbiu="brew update && brew bundle install --cleanup --file=~/dotfiles/Brewfile && brew upgrade"
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
alias nvhc="$HOME/dotfiles/scripts/nvhc.sh"

# Git
alias gpo="git pull origin --no-rebase"
alias glog="git log --graph --topo-order --pretty='%w(100,0,6)%C(yellow)%h%C(bold)%C(black)%d %C(cyan)%ar %C(green)%an%n%C(bold)%C(white)%s %N' --abbrev-commit"
alias lg="lazygit"

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
function killport() {
  lsof -ti:$1 | xargs kill -9
}

# ============================================================================
# COMPLETIONS & PLUGINS
# ============================================================================

# Initialize zsh completion system (required for kubectl, etc.)
autoload -Uz compinit
# Only regenerate completion dump once per day for speed
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# zsh-autosuggestions (installed via brew)
if [[ -f "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# zsh-syntax-highlighting (installed via brew - must be last)
if [[ -f "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

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
# SDKMAN - LAZY LOADING (saves ~1.3 seconds)
# ============================================================================
export SDKMAN_DIR="$HOME/.sdkman"

# Add SDKMAN candidates to PATH immediately (without loading full sdkman)
if [[ -d "$SDKMAN_DIR/candidates/java/current/bin" ]]; then
  export PATH="$SDKMAN_DIR/candidates/java/current/bin:$PATH"
fi

# Lazy load sdk command
function sdk() {
  unfunction sdk
  [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
  sdk "$@"
}

# ============================================================================
# STARTUP
# ============================================================================
ff

# bun completions
[ -s "/Users/georgepagarigan/.bun/_bun" ] && source "/Users/georgepagarigan/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
