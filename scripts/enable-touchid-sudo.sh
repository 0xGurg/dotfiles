#!/bin/bash
# ============================================================================
# Enable Touch ID for sudo Commands (macOS only)
# Allows fingerprint authentication instead of password for sudo in terminals
# Note: This script only works on macOS and will exit on other systems
# ============================================================================

set -e
source "$(dirname "${BASH_SOURCE[0]}")/lib/ui.sh"

# ============================================================================
# TOUCH ID SETUP
# ============================================================================
enable_touchid() {
  print_status "Enabling Touch ID for sudo commands..."

  local PAM_LINE="auth       sufficient     pam_tid.so"

  if { [[ -f /etc/pam.d/sudo_local ]] && grep -q "pam_tid.so" /etc/pam.d/sudo_local; } ||
     { [[ -f /etc/pam.d/sudo ]] && grep -q "pam_tid.so" /etc/pam.d/sudo; }; then
    print_success "Touch ID is already enabled for sudo"
    return 0
  fi

  if [[ -f /etc/pam.d/sudo_local.template ]]; then
    print_status "Enabling Touch ID via /etc/pam.d/sudo_local..."
    [[ -f /etc/pam.d/sudo_local ]] || sudo cp /etc/pam.d/sudo_local.template /etc/pam.d/sudo_local
    printf '%s\n' "$PAM_LINE" | sudo tee -a /etc/pam.d/sudo_local > /dev/null
  else
    local backup="/etc/pam.d/sudo.dotfiles-backup.$(date +%Y%m%d-%H%M%S)"
    print_status "Enabling Touch ID in /etc/pam.d/sudo..."
    sudo cp /etc/pam.d/sudo "$backup"
    awk -v line="$PAM_LINE" 'BEGIN { print line } { print }' /etc/pam.d/sudo | sudo tee /etc/pam.d/sudo > /dev/null
    print_status "Original sudo PAM config backed up to $backup"
  fi

  print_success "Touch ID enabled for sudo commands!"
  echo ""
  echo "You can now use your fingerprint for sudo authentication in:"
  echo "  • Ghostty"
  echo "  • iTerm2"
  echo "  • Terminal.app"
  echo "  • Any other terminal emulator"
  echo ""
  print_warning "Note: You may need to restart your terminal for changes to take effect"
}

# ============================================================================
# MAIN
# ============================================================================
main() {
  echo ""
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║           🔐 Touch ID for sudo Setup                          ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo ""

  # Check if running on macOS
  if [[ "$(uname)" != "Darwin" ]]; then
    print_error "This script is only for macOS (Touch ID is not available on Linux)"
    print_status "If you're on Arch Linux, this feature will be skipped automatically"
    exit 1
  fi

  # Check if Touch ID is available
  if ! bioutil -r -s &>/dev/null; then
    print_warning "Touch ID may not be available on this Mac"
    print_warning "Continuing anyway..."
  fi

  enable_touchid

  echo ""
  print_success "Setup complete! 🎉"
  echo ""
  echo "Try it out:"
  echo "  1. Close and reopen your terminal"
  echo "  2. Run any sudo command (e.g., 'sudo ls')"
  echo "  3. Touch your fingerprint sensor when prompted"
  echo ""
}

main "$@"
