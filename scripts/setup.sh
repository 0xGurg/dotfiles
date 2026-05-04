#!/bin/bash
# ============================================================================
# Dotfiles Setup Script
# Run this after cloning dotfiles repo to set up symlinks and install packages
# Supports: macOS (Homebrew) and Arch Linux (pacman + yay)
# ============================================================================

set -e

DOTFILES_DIR="$HOME/dotfiles"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

  print_success "Homebrew ready"
}

# ============================================================================
# YAY (Arch only)
# ============================================================================
setup_yay() {
  if [[ "$OS" != "arch" ]]; then
    return 0
  fi

  print_status "Setting up yay (AUR helper)..."

  if command -v yay &> /dev/null; then
    print_success "yay already installed"
    return 0
  fi

  print_status "Installing base-devel and git (required for yay)..."
  sudo pacman -S --needed base-devel git

  print_status "Building yay from AUR..."
  git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
  (cd /tmp/yay-bin && makepkg -si --noconfirm)
  rm -rf /tmp/yay-bin

  print_success "yay installed"
}

# ============================================================================
# STOW
# ============================================================================
setup_stow() {
  print_status "Setting up GNU Stow..."

  if command -v stow &> /dev/null; then
    print_success "GNU Stow already installed"
    return 0
  fi

  case "$OS" in
    macos)
      brew install stow
      ;;
    arch|linux)
      sudo pacman -S --needed stow
      ;;
  esac

  print_success "GNU Stow installed"
}

# ============================================================================
# SYMLINKS
# ============================================================================
setup_symlinks() {
  print_status "Creating symlinks with stow..."

  # Backup existing files that aren't symlinks (prevents stow conflicts)
  backup_existing() {
    local target="$1"
    if [[ -f "$target" && ! -L "$target" ]]; then
      print_warning "Backing up existing $target to $target.bak"
      mv "$target" "$target.bak"
    elif [[ -d "$target" && ! -L "$target" ]]; then
      # Only backup directories that aren't symlinks and aren't standard XDG dirs
      local basename=$(basename "$target")
      if [[ "$basename" != ".config" && "$basename" != ".local" ]]; then
        print_warning "Backing up existing directory $target to $target.bak"
        mv "$target" "$target.bak"
      fi
    fi
  }

  # Check for conflicts in files we want to stow
  while IFS= read -r -d '' file; do
    local rel="${file#$DOTFILES_DIR/}"
    # Skip ignored paths
    [[ "$rel" == scripts/* ]] && continue
    [[ "$rel" == packages/* ]] && continue
    [[ "$rel" == .git/* ]] && continue
    [[ "$rel" == README* ]] && continue
    [[ "$rel" == Brewfile ]] && continue
    [[ "$rel" == *.bak* ]] && continue

    local target="$HOME/$rel"
    backup_existing "$target"
  done < <(find "$DOTFILES_DIR" \( -type f -o -type l \) ! -path '*/.git/*' ! -name '*.bak' ! -name '*.bak.*' -print0)

  cd "$DOTFILES_DIR"

  case "$OS" in
    macos)
      stow --ignore='hypr' --ignore='quickshell' -v .
      ;;
    arch|linux)
      stow --ignore='Brewfile' --ignore='aerospace' --ignore='sketchybar' --ignore='raycast' -v .
      ;;
  esac

  print_success "Symlinks created"
}

# ============================================================================
# PACKAGES
# ============================================================================
install_packages() {
  case "$OS" in
    macos)
      print_status "Installing packages via Homebrew..."
      brew update
      brew bundle install --verbose --cleanup --file="$DOTFILES_DIR/Brewfile"
      brew upgrade
      print_success "All packages installed"
      ;;
    arch)
      print_status "Installing packages..."

      local PACMAN_LIST="$DOTFILES_DIR/packages/pacman.list"
      local YAY_LIST="$DOTFILES_DIR/packages/yay.list"
      local PNPM_LIST="$DOTFILES_DIR/packages/pnpm.list"

      if [[ -f "$PACMAN_LIST" ]]; then
        print_status "Installing pacman packages..."
        sudo pacman -S --needed $(sed -n '/^[^#[:space:]]/p' "$PACMAN_LIST")
        print_success "Pacman packages installed"
      fi

      if [[ -f "$YAY_LIST" ]]; then
        print_status "Installing AUR packages..."
        yay -S --needed $(sed -n '/^[^#[:space:]]/p' "$YAY_LIST")
        print_success "AUR packages installed"
      fi

      if [[ -f "$PNPM_LIST" ]]; then
        print_status "Installing global pnpm packages..."
        pnpm add -g $(sed -n '/^[^#[:space:]]/p' "$PNPM_LIST")
        print_success "Global pnpm packages installed"
      fi

      print_success "All packages installed"
      ;;
    *)
      print_warning "Unknown package manager for this OS"
      print_warning "Please install packages manually"
      ;;
  esac
}

# ============================================================================
# AUTHENTICATION SETUP (Touch ID / Howdy)
# ============================================================================
setup_auth() {
  if [[ "$OS" == "macos" ]]; then
    setup_touchid
  elif [[ "$OS" == "arch" ]]; then
    setup_howdy
  fi
}

setup_touchid() {
  print_status "Setting up Touch ID for sudo..."

  if [[ -f /etc/pam.d/sudo ]] && grep -q "pam_tid.so" /etc/pam.d/sudo; then
    print_success "Touch ID already enabled for sudo"
    return 0
  fi

  echo ""
  print_warning "Touch ID allows using fingerprint instead of password for sudo"
  read -p "Enable Touch ID for sudo? (y/N): " -n 1 -r
  echo ""

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo sh -c 'echo "auth       sufficient     pam_tid.so" > /etc/pam.d/sudo'
    print_success "Touch ID enabled for sudo"
  else
    print_status "Skipping Touch ID setup (run scripts/enable-touchid-sudo.sh later)"
  fi
}

setup_howdy() {
  if ! command -v howdy &> /dev/null; then
    echo ""
    print_warning "Howdy provides facial recognition for sudo/lock screen (similar to Touch ID on macOS)"
    read -p "Install and configure Howdy? (y/N): " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
      print_status "Installing Howdy..."
      yay -S --needed howdy
      print_success "Howdy installed"
      print_warning "Howdy requires manual configuration:"
      echo "  1. Add your face: sudo howdy add"
      echo "  2. Test: sudo howdy test"
      echo "  3. Edit config: sudo howdy config"
      echo "  PAM is configured in /etc/pam.d/ (refer to Howdy docs)"
    else
      print_status "Skipping Howdy setup"
    fi
  else
    print_success "Howdy already installed"
  fi
}

# ============================================================================
# POST-INSTALL NOTES
# ============================================================================
post_install() {
  if [[ "$OS" == "arch" ]]; then
    # Start/Enable services
    print_status "Enabling services..."

    if command -v docker &> /dev/null; then
      sudo systemctl enable --now docker 2>/dev/null && print_success "Docker enabled" || print_warning "Could not enable docker"
      sudo usermod -aG docker "$USER" 2>/dev/null || true
    fi

    if command -v ufw &> /dev/null; then
      sudo systemctl enable --now ufw 2>/dev/null && print_success "UFW enabled" || true
    fi
  fi
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
  setup_yay
  setup_stow
  setup_symlinks
  install_packages
  setup_auth
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
    echo "  3. Log out and log back in with Hyprland"
    echo "  4. Run Hyprland: Hyprland (from TTY) or select from display manager"
  fi
  echo ""
  echo "To uninstall symlinks, run: cd ~/dotfiles && stow -D ."
  echo ""
}

main "$@"
