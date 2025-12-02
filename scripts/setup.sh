#!/bin/bash
# ============================================================================
# Dotfiles Setup Script
# Run this after cloning dotfiles repo to set up symlinks and install packages
# ============================================================================

set -e

DOTFILES_DIR="$HOME/dotfiles"
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
# STOW
# ============================================================================
setup_stow() {
  print_status "Setting up GNU Stow..."
  
  if ! command -v stow &> /dev/null; then
    print_status "Installing GNU Stow via Homebrew..."
    brew install stow
  fi
  
  print_success "GNU Stow installed"
}

setup_symlinks() {
  print_status "Creating symlinks with stow..."
  
  # Remove existing manual symlinks if they exist
  if [[ -L "$HOME/.zshrc" ]]; then
    print_status "Removing old manual symlink: ~/.zshrc"
    rm "$HOME/.zshrc"
  fi
  
  # Backup existing files that aren't symlinks
  if [[ -f "$HOME/.zshrc" ]] && [[ ! -L "$HOME/.zshrc" ]]; then
    print_warning "Backing up existing ~/.zshrc to ~/.zshrc.bak"
    mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
  fi
  
  # Use stow to create all symlinks
  cd "$DOTFILES_DIR"
  stow -v .
  
  print_success "Symlinks created with stow"
}

# ============================================================================
# PACKAGES
# ============================================================================
install_packages() {
  print_status "Installing packages via Homebrew..."
  
  brew update
  brew bundle install --cleanup --file="$DOTFILES_DIR/Brewfile"
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
  setup_stow
  setup_symlinks
  install_packages
  
  echo ""
  print_success "Setup complete! 🎉"
  echo ""
  echo "Next steps:"
  echo "  1. Restart your terminal or run: source ~/.zshrc"
  echo "  2. Run 'bbiu' anytime to update packages"
  echo ""
  echo "To uninstall symlinks, run: cd ~/dotfiles && stow -D ."
  echo ""
}

main "$@"

