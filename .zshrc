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
# NVM - LAZY LOADING (saves ~12 seconds on shell startup!)
# ============================================================================
export NVM_DIR="$HOME/.nvm"

# Add node to PATH immediately (uses default version without loading nvm)
if [[ -d "$NVM_DIR/versions/node" ]]; then
  NODE_DEFAULT_PATH=$(ls -d "$NVM_DIR/versions/node"/* 2>/dev/null | tail -1)
  if [[ -n "$NODE_DEFAULT_PATH" ]]; then
    export PATH="$NODE_DEFAULT_PATH/bin:$PATH"
  fi
fi

# Lazy load nvm - only loads when you actually use nvm/node/npm/npx/yarn
__load_nvm() {
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
}

# Create lazy-loading wrappers for nvm commands
for cmd in nvm; do
  eval "function $cmd() { unfunction $cmd; __load_nvm; $cmd \"\$@\"; }"
done

# ============================================================================
# ALIASES
# ============================================================================

# System
alias bbiu="brew update && brew bundle install --cleanup --file=~/dotfiles/Brewfile && brew upgrade"
alias cl="clear"
alias ff="fastfetch"
alias q="exit"
alias sz="source ~/.zshrc"

# Directory Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias -- -="cd -"
alias rmd="rm -rf"
alias cdcfg="z ~/.config"

# Editor
alias nv="nvim"
alias nvh="nvim ."
alias nvhc='osascript -e "tell application \"Cursor\" to quit" 2>/dev/null; sleep 1; cursor . && sleep 2 && osascript -e "tell application \"Cursor\" to activate" && osascript -e "tell application \"System Events\" to keystroke \"e\" using {command down, option down}" && sleep 1 && (aerospace list-windows --all --format "%{app-name} %{window-id}" | grep -i ghostty | head -1 | awk "{print \$2}" | xargs -I {} aerospace focus --window-id {}) && aerospace resize smart +300 && nvh'

# Project Scripts
alias pxd="px dev"
alias pxs="px storybook"
alias pxb="px build"
alias pxt="px test"
alias pxtw="px test:watch"
alias pxl="px lint"
alias pxlf="px lint:fix"
alias pxf="px format"
alias pxc="px typecheck"

# Package Management
alias pclean="rm -rf node_modules pnpm-lock.yaml && pi"
alias pfresh="rm -rf node_modules pnpm-lock.yaml yarn.lock package-lock.json && pi"
alias pout="px outdated"
alias pulp="cdp lp && px add @rtl_nl/ui-components-videoland"
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
# PROJECT CONFIGURATION
# ============================================================================
typeset -A projects
projects[ui]="~/projects/ui-components-videoland"
projects[lp]="~/projects/landing-frontend"
projects[be]="~/projects/cc-backend-headless-cms"

# ============================================================================
# FUNCTIONS
# ============================================================================

# Auto-switch Node version if .nvmrc exists (install if missing)
function check_nvmrc() {
  if [[ -f ".nvmrc" ]]; then
    # Load NVM if not already loaded (handles lazy loading)
    if ! command -v nvm &>/dev/null && [[ -s "/opt/homebrew/opt/nvm/nvm.sh" ]]; then
      \. "/opt/homebrew/opt/nvm/nvm.sh"
    fi
    local node_version=$(cat .nvmrc)
    if ! nvm ls "$node_version" &>/dev/null; then
      echo "📦 Node $node_version not installed. Installing..."
      nvm install "$node_version"
    else
      echo "🔄 Switching to Node $node_version"
      nvm use
    fi
  fi
}

# Navigate to project and switch Node version
function cdp {
  local key=$1
  if [[ -z "${projects[$key]}" ]]; then
    echo "❌ Project '$key' not found"
    return 1
  fi

  local expanded_path="${projects[$key]/#\~/$HOME}"
  z "$expanded_path"
  echo "📁 $(basename $expanded_path)"
  check_nvmrc
}

# Kill process on specific port
function killport() {
  lsof -ti:$1 | xargs kill -9
}

# ============================================================================
# PACKAGE MANAGEMENT (PNPM with team lockfile sync)
# ============================================================================

# Install dependencies
function pi() {
  check_nvmrc

  if [[ -f "yarn.lock" ]]; then
    echo "📦 Using pnpm (syncing with yarn.lock)..."
    pnpm import 2>/dev/null || true
    echo "pnpm-lock.yaml" >> .git/info/exclude 2>/dev/null
    pnpm install --shamefully-hoist "$@"
  elif [[ -f "package-lock.json" ]]; then
    echo "📦 Using pnpm (syncing with package-lock.json)..."
    pnpm import 2>/dev/null || true
    echo "pnpm-lock.yaml" >> .git/info/exclude 2>/dev/null
    pnpm install --shamefully-hoist "$@"
  elif [[ -f "pnpm-lock.yaml" ]]; then
    echo "📦 PNPM project detected"
    pnpm install "$@"
  else
    echo "⚠️  No lockfile found. Using pnpm..."
    pnpm install "$@"
  fi
}

# Add package
function pa() {
  check_nvmrc

  if [[ -f "yarn.lock" ]]; then
    echo "📦 Adding with yarn (for lockfile) + pnpm install..."
    yarn add "$@" && pnpm import 2>/dev/null && pnpm install --shamefully-hoist
  elif [[ -f "package-lock.json" ]]; then
    echo "📦 Adding with npm (for lockfile) + pnpm install..."
    npm install "$@" && pnpm import 2>/dev/null && pnpm install --shamefully-hoist
  else
    pnpm add "$@"
  fi
}

# Remove package
function pr() {
  check_nvmrc

  if [[ -f "yarn.lock" ]]; then
    echo "📦 Removing with yarn (for lockfile) + pnpm install..."
    yarn remove "$@" && pnpm import 2>/dev/null && pnpm install --shamefully-hoist
  elif [[ -f "package-lock.json" ]]; then
    echo "📦 Removing with npm (for lockfile) + pnpm install..."
    npm uninstall "$@" && pnpm import 2>/dev/null && pnpm install --shamefully-hoist
  else
    pnpm remove "$@"
  fi
}

# Run pnpm command
function px() {
  check_nvmrc
  pnpm "$@"
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
# fastfetch removed from auto-startup (saves ~2.6 seconds)
# Run 'ff' manually when you want to see system info

# pnpm
export PNPM_HOME="/Users/gpagarigan/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
