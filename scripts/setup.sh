#!/bin/bash
# ============================================================================
# Dotfiles Setup Script
# Run this after cloning .config to set up symlinks and install packages
# ============================================================================

set -e

DOTFILES_DIR="$HOME/.config"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() { echo -e "${BLUE}==>${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

# ============================================================================
# HOMEBREW
# ============================================================================
setup_homebrew() {
  print_status "Setting up Homebrew..."
  
  if ! command -v brew &> /dev/null; then
    print_status "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add to path for this session
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  
  print_success "Homebrew installed"
}

# ============================================================================
# SYMLINKS
# ============================================================================
create_symlink() {
  local source=$1
  local target=$2
  
  if [[ -L "$target" ]]; then
    rm "$target"
  elif [[ -f "$target" ]]; then
    print_warning "Backing up existing $target to ${target}.bak"
    mv "$target" "${target}.bak"
  fi
  
  ln -s "$source" "$target"
  print_success "Linked $target -> $source"
}

setup_symlinks() {
  print_status "Creating symlinks..."
  
  # ZSH
  create_symlink "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
  
  print_success "Symlinks created"
}

# ============================================================================
# PACKAGES
# ============================================================================
install_packages() {
  print_status "Installing packages via Homebrew..."
  
  brew update
  brew bundle install --cleanup --file="$DOTFILES_DIR/brew/Brewfile"
  brew upgrade
  
  print_success "All packages installed"
}

# ============================================================================
# MAIN
# ============================================================================
main() {
  echo ""
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║               🛠️  Dotfiles Setup Script                       ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo ""
  
  setup_homebrew
  setup_symlinks
  install_packages
  
  echo ""
  print_success "Setup complete! 🎉"
  echo ""
  echo "Next steps:"
  echo "  1. Restart your terminal or run: source ~/.zshrc"
  echo "  2. Run 'bbiu' anytime to update packages"
  echo ""
}

main "$@"

