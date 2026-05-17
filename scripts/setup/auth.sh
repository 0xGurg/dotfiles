#!/bin/bash
# Authentication setup (Touch ID on macOS, Howdy on Arch)

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
