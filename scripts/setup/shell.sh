#!/bin/bash
set -euo pipefail
# Shell setup (Arch only — macOS defaults to zsh since Catalina)

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

  if ! grep -qx "$ZSH_PATH" /etc/shells; then
    print_status "Adding $ZSH_PATH to /etc/shells..."
    echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
  fi

  print_status "Changing default shell to zsh ($ZSH_PATH)..."
  chsh -s "$ZSH_PATH"
  print_success "Default shell set to zsh — takes effect on next login"
}
