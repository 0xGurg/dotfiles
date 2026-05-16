#!/bin/bash
# Package installation (Homebrew on macOS, bigkis on Arch)

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
        local BIGKIS_CFG="$HOME/.config/bigkis/system.toml"

        print_status "Running bigkis doctor preflight checks..."
        if ! sudo env "PATH=$PATH" bigkis --config "$BIGKIS_CFG" doctor; then
          print_error "bigkis doctor failed — fix the issues above before re-running"
          return 1
        fi

        print_status "Installing packages with bigkis..."
        sudo env "PATH=$PATH" bigkis --config "$BIGKIS_CFG" apply --yes
        print_success "All packages installed"

        print_status "Verifying system matches declaration..."
        if ! sudo env "PATH=$PATH" bigkis --config "$BIGKIS_CFG" status; then
          print_warning "System still drifted after apply — see above"
          print_warning "Re-run 'pkgup' once the underlying issue is fixed"
        fi
      fi
      ;;
    *)
      print_warning "Unknown package manager for this OS"
      print_warning "Please install packages manually"
      ;;
  esac
}
