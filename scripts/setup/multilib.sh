#!/bin/bash
set -euo pipefail
# Multilib (Arch only — required for steam and 32-bit libs)

setup_multilib() {
  if [[ "$OS" != "arch" ]]; then
    return 0
  fi

  if grep -q '^\[multilib\]' /etc/pacman.conf; then
    print_success "multilib repo already enabled"
    return 0
  fi

  print_status "Enabling multilib repo in /etc/pacman.conf..."
  sudo cp /etc/pacman.conf "/etc/pacman.conf.dotfiles-backup.$(date +%Y%m%d-%H%M%S)"
  sudo sed -i 's/^#\[multilib\]/[multilib]/' /etc/pacman.conf
  sudo sed -i '/^\[multilib\]/{n;s/^#Include/Include/}' /etc/pacman.conf
  sudo pacman -Sy
  print_success "multilib enabled"
}
