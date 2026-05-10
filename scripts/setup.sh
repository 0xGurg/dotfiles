#!/bin/bash
# ============================================================================
# Dotfiles Setup Script
# Run this after cloning dotfiles repo to set up symlinks and install packages
# Supports: macOS (Homebrew) and Arch Linux (pacman)
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
# OS DETECTION
# ============================================================================
detect_os() {
  case "$(uname -s)" in
    Darwin*)
      OS="macos"
      print_status "Detected OS: macOS"
      ;;
    Linux*)
      if [[ -f /etc/arch-release ]]; then
        OS="arch"
        print_status "Detected OS: Arch Linux"
      else
        OS="linux"
        print_status "Detected OS: Linux (generic)"
      fi
      ;;
    *)
      OS="unknown"
      print_warning "Unknown OS: $(uname -s)"
      ;;
  esac
}

# ============================================================================
# HOMEBREW (macOS only)
# ============================================================================
setup_homebrew() {
  if [[ "$OS" != "macos" ]]; then
    print_status "Skipping Homebrew setup (not on macOS)"
    return 0
  fi

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
  if [[ "$OS" == "macos" ]]; then
    print_status "Installing packages via Homebrew..."
    brew update
    brew bundle install --verbose --cleanup --file="$DOTFILES_DIR/Brewfile"
    brew upgrade
    print_success "All packages installed"
  elif [[ "$OS" == "arch" ]]; then
    print_status "Skipping package installation on Arch Linux"
    print_warning "Note: Install packages manually using pacman/yay on Arch"
    print_warning "Brewfile is macOS-specific"
  else
    print_warning "Unknown package manager for this OS"
    print_warning "Please install packages manually"
  fi
}

# ============================================================================
# TOUCH ID (macOS only)
# ============================================================================
setup_touchid() {
  if [[ "$OS" != "macos" ]]; then
    print_status "Skipping Touch ID setup (macOS only feature)"
    return 0
  fi

  print_status "Setting up Touch ID for sudo..."

  # Check if already enabled
  if [[ -f /etc/pam.d/sudo ]] && grep -q "pam_tid.so" /etc/pam.d/sudo; then
    print_success "Touch ID already enabled for sudo"
    return 0
  fi

  echo ""
  print_warning "Touch ID allows using fingerprint instead of password for sudo commands"
  read -p "Enable Touch ID for sudo? (y/N): " -n 1 -r
  echo ""

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo sh -c 'echo "# Touch ID support for sudo
auth       sufficient     pam_tid.so" > /etc/pam.d/sudo'
    print_success "Touch ID enabled for sudo"
  else
    print_status "Skipping Touch ID setup (you can run scripts/enable-touchid-sudo.sh later)"
  fi
}

# ============================================================================
# ENVIRONMENT VARIABLES
# ============================================================================
setup_env() {
  print_status "Setting up environment variables..."

  if [[ -f "$DOTFILES_DIR/.env" ]]; then
    print_success ".env already exists"
    return 0
  fi

  if [[ ! -f "$DOTFILES_DIR/.env.example" ]]; then
    print_warning "No .env.example found, skipping"
    return 0
  fi

  cp "$DOTFILES_DIR/.env.example" "$DOTFILES_DIR/.env"
  print_success "Created .env from .env.example"
  print_warning "Edit ~/dotfiles/.env and fill in your secrets before using OpenCode"
}

# ============================================================================
# OPENCODE PLUGINS
# ============================================================================
setup_opencode() {
  print_status "Installing OpenCode plugins..."

  local opencode_dir="$DOTFILES_DIR/.config/opencode"
  if [[ ! -f "$opencode_dir/package.json" ]]; then
    print_warning "No OpenCode package.json found, skipping"
    return 0
  fi

  if ! command -v pnpm &>/dev/null; then
    print_warning "pnpm not found, skipping OpenCode plugin install"
    print_warning "Install pnpm and run: cd ~/.config/opencode && pnpm install"
    return 0
  fi

  (cd "$opencode_dir" && pnpm install --frozen-lockfile 2>/dev/null) \
    && print_success "OpenCode plugins installed" \
    || print_warning "OpenCode plugin install failed — run manually: cd ~/.config/opencode && pnpm install"
}

# ============================================================================
# MAIN
# ============================================================================
main() {
  echo ""
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "                🛠️  Dotfiles Setup Script                        "
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo ""

  detect_os
  setup_homebrew
  setup_stow
  setup_symlinks
  install_packages
  setup_touchid
  setup_env
  setup_opencode

  echo ""
  print_success "Setup complete! 🎉"
  echo ""
  echo "Next steps:"
  echo "  1. Restart your terminal or run: source ~/.zshrc"
  echo "  2. Edit ~/dotfiles/.env and fill in your secrets"
  if [[ "$OS" == "macos" ]]; then
    echo "  3. Run 'bbiu' anytime to update packages"
    echo "  4. Try 'sudo ls' to test Touch ID authentication"
    echo "  5. Run ~/.config/opencode/scripts/refresh-opencode-quota.sh to set up OpenCode Go auth"
  elif [[ "$OS" == "arch" ]]; then
    echo "  3. Install Arch packages manually with pacman/yay"
    echo "  4. Adjust configs as needed for your Arch setup"
  fi
  echo ""
  echo "To uninstall symlinks, run: cd ~/dotfiles && stow -D ."
  echo ""
}

main "$@"
