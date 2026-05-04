#!/bin/bash
# ============================================================================
# Dotfiles Setup Script
# Run this after cloning dotfiles repo to set up symlinks and install packages
# Supports: macOS (Homebrew) and Arch Linux (pacman + decman)
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
# MULTILIB (Arch only — required for steam and 32-bit libs)
# ============================================================================
setup_multilib() {
  if [[ "$OS" != "arch" ]]; then
    return 0
  fi

  if grep -q '^\[multilib\]' /etc/pacman.conf; then
    print_success "multilib repo already enabled"
    return 0
  fi

  print_status "Enabling multilib repo in /etc/pacman.conf..."
  sudo sed -i 's/^#\[multilib\]/[multilib]/' /etc/pacman.conf
  sudo sed -i '/^\[multilib\]/{n;s/^#Include/Include/}' /etc/pacman.conf
  sudo pacman -Sy
  print_success "multilib enabled"
}

# ============================================================================
# DECMAN (Arch only)
# ============================================================================
setup_decman() {
  if [[ "$OS" != "arch" ]]; then
    return 0
  fi

  print_status "Setting up decman..."

  if command -v decman &> /dev/null; then
    print_success "decman already installed"
    return 0
  fi

  print_status "Installing base-devel and git (required for building AUR packages)..."
  sudo pacman -S --needed base-devel git

  print_status "Building decman from AUR..."
  git clone https://aur.archlinux.org/decman.git /tmp/decman
  (cd /tmp/decman && makepkg -si --noconfirm)
  rm -rf /tmp/decman

  print_success "decman installed"
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

  local BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

  # Check if a target path has a symlink ancestor (meaning it's already
  # reachable through a stow-managed symlink and shouldn't be moved)
  has_symlink_ancestor() {
    local check="$1"
    while [[ "$check" != "/" && "$check" != "$HOME" ]]; do
      if [[ -L "$check" ]]; then
        return 0  # found symlink ancestor
      fi
      check=$(dirname "$check")
    done
    return 1  # no symlink ancestor
  }

  # Back up files that would conflict with stow.
  # Moves them to ~/.dotfiles-backup/TIMESTAMP/ preserving relative path.
  backup_existing() {
    local target="$1" rel="$2"

    # Already a symlink — stow will handle it
    if [[ -L "$target" ]]; then
      return
    fi

    # Regular file or directory that isn't a symlink
    if [[ -f "$target" ]] || [[ -d "$target" ]]; then
      # Skip if target is reachable through an existing symlink (e.g., from
      # a previous stow run). Moving it would delete the file from the repo.
      if has_symlink_ancestor "$target"; then
        return
      fi

      print_warning "Backing up $target → $BACKUP_DIR/$rel"
      mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
      mv "$target" "$BACKUP_DIR/$rel"
    fi
  }

  # Scan for files in the dotfiles repo that would become symlink targets,
  # and back up any existing non-symlink files at those paths
  while IFS= read -r -d '' file; do
    local rel="${file#$DOTFILES_DIR/}"

    # Skip paths that shouldn't be stowed
    [[ "$rel" == scripts/* ]] && continue
    [[ "$rel" == packages/* ]] && continue
    [[ "$rel" == .git/* ]] && continue
    [[ "$rel" == README* ]] && continue
    [[ "$rel" == Brewfile ]] && continue

    local target="$HOME/$rel"
    backup_existing "$target" "$rel"
  done < <(find "$DOTFILES_DIR" \( -type f -o -type l \) ! -path '*/.git/*' -print0)

  cd "$DOTFILES_DIR"

  case "$OS" in
    macos)
      stow -v .
      ;;
    arch|linux)
      stow --ignore='Brewfile' --ignore='aerospace' --ignore='sketchybar' --ignore='raycast' -v .
      ;;
  esac

  print_success "Symlinks created"
  if [[ -d "$BACKUP_DIR" ]] && [[ "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
    print_status "Backups stored in $BACKUP_DIR"
  else
    rmdir "$BACKUP_DIR" 2>/dev/null || true
  fi
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
      print_status "Installing native packages with decman..."
      sudo decman --source "$DOTFILES_DIR/decman/source.py" --skip aur --skip flatpak
      print_success "Native packages installed"

      print_status "Installing flatpak apps with decman..."
      sudo decman --skip aur
      print_success "Flatpak apps installed"

      print_status "Building AUR packages with decman..."
      sudo decman
      print_success "AUR packages installed"

      if [[ -f "$DOTFILES_DIR/packages/pnpm.list" ]]; then
        print_status "Installing global pnpm packages..."
        pnpm add -g $(sed -n '/^[^#[:space:]]/p' "$DOTFILES_DIR/packages/pnpm.list")
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
    print_warning "Howdy (facial recognition for sudo) is declared in decman/source.py"
    print_warning "Run 'sudo decman' to install it, then configure:"
    echo "  1. Add your face: sudo howdy add"
    echo "  2. Test: sudo howdy test"
    echo "  3. Edit config: sudo howdy config"
    echo "  PAM is configured in /etc/pam.d/ (refer to Howdy docs)"
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
  setup_multilib
  setup_decman
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
