#!/bin/bash
# ============================================================================
# Dotfiles Setup Script
# Run this after cloning dotfiles repo to set up symlinks and install packages
# Supports: macOS (Homebrew) and Arch Linux (pacman + AUR + flatpak via bigkis)
#
# Each step lives in scripts/setup/*.sh for readability.
# ============================================================================

set -e

DOTFILES_DIR="$HOME/dotfiles"
SETUP_DIR="$DOTFILES_DIR/scripts/setup"
export PATH="$HOME/.local/bin:$PATH"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status()  { echo -e "${BLUE}==>${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error()   { echo -e "${RED}✗${NC} $1"; }

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
        print_warning "Only Arch Linux is officially supported"
      fi
      ;;
    *)
      OS="unknown"
      print_warning "Unknown OS: $(uname -s)"
      ;;
  esac
}

# ============================================================================
# LOAD MODULES
# ============================================================================
source "$SETUP_DIR/homebrew.sh"
source "$SETUP_DIR/multilib.sh"
source "$SETUP_DIR/bigkis.sh"
source "$SETUP_DIR/stow.sh"
source "$SETUP_DIR/packages.sh"
source "$SETUP_DIR/secrets.sh"
source "$SETUP_DIR/pnpm.sh"
source "$SETUP_DIR/shell.sh"
source "$SETUP_DIR/nvidia.sh"
source "$SETUP_DIR/auth.sh"
source "$SETUP_DIR/env.sh"
source "$SETUP_DIR/opencode.sh"
source "$SETUP_DIR/post-install.sh"

# ============================================================================
# MAIN
# ============================================================================
main() {
  echo ""
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "                  Dotfiles Setup Script                         "
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo ""

  detect_os
  setup_homebrew
  setup_multilib
  setup_bigkis
  setup_stow
  setup_pnpm
  install_packages
  setup_secrets
  setup_symlinks
  setup_shell
  setup_early_kms
  setup_auth
  setup_env
  setup_opencode
  post_install

  echo ""
  print_success "Setup complete!"
  echo ""
  echo "Next steps:"
  echo "  1. Restart your terminal or run: source ~/.zshrc"
  echo "  2. Run 'pkgup' anytime to update all packages"
  echo ""
  if [[ "$OS" == "macos" ]]; then
    echo "  3. Try 'sudo ls' to test Touch ID authentication"
  elif [[ "$OS" == "arch" ]]; then
    echo "  3. Log out and log back in — your default shell is now zsh"
    echo "  4. Launch Hyprland: run 'Hyprland' from TTY or select from display manager"
    echo "  5. Set up Secure Boot:"
    echo "       scripts/sbctl-setup.sh          # generate keys"
    echo "       → reboot into BIOS, clear Secure Boot keys (Setup Mode)"
    echo "       scripts/sbctl-sign.sh           # enroll keys + sign EFI binaries"
  fi
  echo ""
  echo "To uninstall symlinks, run: cd ~/dotfiles && stow -D ."
  echo ""
}

main "$@"
