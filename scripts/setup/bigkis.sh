#!/bin/bash
# Bigkis — declarative package manager (Arch only)

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

    local YAY_DIR
    YAY_DIR="$(mktemp -d -t yay-build.XXXXXX)"
    trap 'rm -rf "$YAY_DIR"' RETURN

    if ! git clone https://aur.archlinux.org/yay.git "$YAY_DIR"; then
      print_warning "git clone of yay failed (see error above)"
      print_warning "Install yay manually later, then run: sudo bigkis apply"
      return 0
    fi

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
