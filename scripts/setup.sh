#!/bin/bash
# ============================================================================
# Dotfiles Setup Script
# Run this after cloning dotfiles repo to set up symlinks and install packages
# Supports: macOS (Homebrew) and Arch Linux (pacman + AUR + flatpak via bigkis)
# ============================================================================

set -e

DOTFILES_DIR="$HOME/dotfiles"
export PATH="$HOME/.local/bin:$PATH"
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
# BIGKIS (Arch only)
# ============================================================================
setup_bigkis() {
  if [[ "$OS" != "arch" ]]; then
    return 0
  fi

  # makepkg refuses to run as root. Bail early with a clear message rather
  # than hiding the failure two layers deep in a subshell.
  if [[ $EUID -eq 0 ]]; then
    print_error "setup.sh must not be run as root — makepkg refuses to run as root"
    print_error "Re-run as your normal user; the script will sudo where needed"
    exit 1
  fi

  # Install AUR helper (required by bigkis for AUR plugin)
  if command -v yay &> /dev/null; then
    print_success "yay already installed"
  else
    print_status "Installing yay (AUR helper)..."
    sudo pacman -S --needed --noconfirm base-devel git

    # Use a fresh tempdir so a previous half-finished build can't poison
    # the next run with a stale /tmp/yay directory.
    local YAY_DIR
    YAY_DIR="$(mktemp -d -t yay-build.XXXXXX)"
    trap 'rm -rf "$YAY_DIR"' RETURN

    # Don't swallow stderr — git's error message is the only signal we get
    # when DNS, TLS, or "directory exists" failures happen.
    if ! git clone https://aur.archlinux.org/yay.git "$YAY_DIR"; then
      print_warning "git clone of yay failed (see error above)"
      print_warning "Install yay manually later, then run: sudo bigkis apply"
      return 0
    fi

    # Run makepkg in a subshell so a build failure doesn't abort the whole
    # setup script via set -e. Capture the exit status explicitly.
    local mp_status=0
    ( cd "$YAY_DIR" && makepkg -si --noconfirm ) || mp_status=$?

    if [[ $mp_status -ne 0 ]]; then
      print_warning "makepkg failed for yay (exit $mp_status)"
      print_warning "Install yay manually later, then run: sudo bigkis apply"
      return 0
    fi

    print_success "yay installed"
  fi

  # Install bigkis
  if command -v bigkis &> /dev/null; then
    print_success "bigkis already installed"
    return 0
  fi

  print_status "Installing bigkis..."
  curl -fsSL https://codeberg.org/gurg/bigkis/raw/branch/main/install.sh | sh

  print_success "bigkis installed"
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
      if ! command -v bigkis &> /dev/null; then
        print_warning "bigkis not found — skipping package installation"
        print_warning "Install bigkis and yay, then run: sudo bigkis apply"
      else
        print_status "Installing packages with bigkis..."
        sudo env "PATH=$PATH" bigkis apply --config "$HOME/.config/bigkis/system.toml"
        print_success "All packages installed"
      fi
      ;;
    *)
      print_warning "Unknown package manager for this OS"
      print_warning "Please install packages manually"
      ;;
  esac
}

# ============================================================================
# SHELL (Arch only — macOS defaults to zsh since Catalina)
# ============================================================================
setup_shell() {
  if [[ "$OS" != "arch" ]]; then
    return 0
  fi

  print_status "Setting up default shell..."

  local ZSH_PATH
  ZSH_PATH="$(which zsh 2>/dev/null || echo '')"

  if [[ -z "$ZSH_PATH" ]]; then
    print_warning "zsh not found in PATH — skipping chsh (was it installed?)"
    return 0
  fi

  if [[ "$SHELL" == "$ZSH_PATH" ]]; then
    print_success "Default shell is already zsh ($ZSH_PATH)"
    return 0
  fi

  # Ensure zsh is listed in /etc/shells (required for chsh to accept it)
  if ! grep -qx "$ZSH_PATH" /etc/shells; then
    print_status "Adding $ZSH_PATH to /etc/shells..."
    echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
  fi

  print_status "Changing default shell to zsh ($ZSH_PATH)..."
  chsh -s "$ZSH_PATH"
  print_success "Default shell set to zsh — takes effect on next login"
}

# ============================================================================
# EARLY KMS — NVIDIA (Arch only)
# ============================================================================
setup_early_kms() {
  if [[ "$OS" != "arch" ]]; then
    return 0
  fi

  print_status "Configuring NVIDIA Early KMS..."

  # ── mkinitcpio.conf ──────────────────────────────────────────────────────
  local MKINIT="/etc/mkinitcpio.conf"

  if grep -qP '^MODULES=\(.*nvidia.*\)' "$MKINIT"; then
    print_success "NVIDIA modules already present in $MKINIT"
  else
    print_status "Adding NVIDIA modules to MODULES= in $MKINIT..."
    # Handle both empty MODULES=() and MODULES=(existing items)
    sudo sed -i \
      's/^MODULES=(\(.*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' \
      "$MKINIT"
    # Collapse any leading space if MODULES was previously empty: "(  nvidia" → "(nvidia"
    sudo sed -i \
      's/^MODULES=( /MODULES=(/' \
      "$MKINIT"
    print_success "NVIDIA modules added to $MKINIT"

    print_status "Regenerating initramfs (mkinitcpio -P)..."
    sudo mkinitcpio -P
    print_success "Initramfs regenerated"
  fi

  # ── systemd-boot kernel parameter ────────────────────────────────────────
  local ENTRIES_DIR="/boot/loader/entries"

  if [[ ! -d "$ENTRIES_DIR" ]]; then
    print_warning "systemd-boot entries directory not found at $ENTRIES_DIR — skipping kernel param"
    return 0
  fi

  local PARAM="nvidia_drm.modeset=1"
  local patched=0

  for entry in "$ENTRIES_DIR"/*.conf; do
    [[ -f "$entry" ]] || continue

    if grep -q "$PARAM" "$entry"; then
      print_success "$(basename "$entry"): $PARAM already set"
    else
      print_status "Adding $PARAM to $(basename "$entry")..."
      sudo sed -i "s|^\(options\s.*\)$|\1 $PARAM|" "$entry"
      print_success "$(basename "$entry"): $PARAM added"
      ((patched++)) || true
    fi
  done

  if [[ $patched -gt 0 ]]; then
    print_warning "Kernel parameter change requires a reboot to take effect"
  fi
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
    print_warning "Howdy (facial recognition for sudo) is currently disabled."
    print_warning "howdy-git is commented out in bigkis/system.toml — blocked by a"
    print_warning "python-dlib → CUDA build failure with GCC 16 / CUDA 13."
    echo ""
    echo "  To enable once the upstream build issue is resolved:"
    echo "    1. Uncomment 'howdy-git' in bigkis/system.toml"
    echo "    2. Run: sudo bigkis apply --config ~/.config/bigkis/system.toml"
    echo "    3. Add your face:   sudo howdy add"
    echo "    4. Test:            sudo howdy test"
    echo "    5. Edit config:     sudo howdy config"
    echo "    6. Configure PAM:   refer to https://github.com/boltgolt/howdy"
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

    echo ""
    print_status "Secure Boot setup (run manually after setup completes):"
    echo "  Step 1 — Generate keys : scripts/sbctl-setup.sh"
    echo "  Step 2 — Reboot into BIOS, delete existing Secure Boot keys (enter Setup Mode)"
    echo "  Step 3 — Enroll & sign  : scripts/sbctl-sign.sh"
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
  setup_bigkis
  setup_stow
  setup_symlinks
  install_packages
  setup_shell
  setup_early_kms
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
