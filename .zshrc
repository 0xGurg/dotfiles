# ============================================================================
# SHELL OPTIONS
# ============================================================================
setopt AUTO_CD

# ============================================================================
# ENVIRONMENT VARIABLES
# ============================================================================
export TMPDIR=$(getconf DARWIN_USER_TEMP_DIR)
export PATH="$HOME/.local/bin:$PATH"
export OLLAMA_NUM_GPU=99
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"

# nvm (Node Version Manager) setup
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

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
alias nvhc='osascript -e "tell application \"Cursor\" to quit" 2>/dev/null; sleep 1; cursor . && sleep 2 && osascript -e "tell application \"Cursor\" to activate" && osascript -e "tell application \"System Events\" to keystroke \"e\" using {command down, option down}" && sleep 1 && (aerospace list-windows --all --format "%{app-name} %{window-id}" | grep -i ghostty | head -1 | awk "{print \$2}" | xargs -I {} aerospace focus --window-id {}) && aerospace resize smart +400 && nvh'
alias nvc="nvim ~/.config"

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

# Git
alias gpo="git pull origin --no-rebase"
alias glog="git log --graph --topo-order --pretty='%w(100,0,6)%C(yellow)%h%C(bold)%C(black)%d %C(cyan)%ar %C(green)%an%n%C(bold)%C(white)%s %N' --abbrev-commit"
alias lg="lazygit"

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

# zsh-autosuggestions (installed via brew)
if [[ -f "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# zsh-syntax-highlighting (installed via brew - must be last)
if [[ -f "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Kubernetes completion
if command -v kubectl &> /dev/null; then
  source <(kubectl completion zsh)
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
# SDKMAN (Must be at the end)
# ============================================================================
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# ============================================================================
# STARTUP
# ============================================================================
ff
