#!/bin/bash
set -euo pipefail
# Post-install — enable services and print next steps

post_install() {
  if [[ "$OS" == "arch" ]]; then
    print_status "Enabling services..."

    if command -v ufw &> /dev/null; then
      sudo systemctl enable --now ufw 2>/dev/null && print_success "UFW enabled" || true
    fi

    if [[ -f "$DOTFILES_DIR/scripts/snapper-rsync-backup.timer" ]]; then
      sudo cp "$DOTFILES_DIR/scripts/snapper-rsync-backup.service" /etc/systemd/system/
      sudo cp "$DOTFILES_DIR/scripts/snapper-rsync-backup.timer" /etc/systemd/system/
      sudo systemctl daemon-reload
      sudo systemctl enable --now snapper-rsync-backup.timer
      print_success "snapper-rsync-backup.timer enabled"
    fi

    echo ""
    print_status "Secure Boot setup (run manually after setup completes):"
    echo "  Step 1 — Generate keys : scripts/sbctl-setup.sh"
    echo "  Step 2 — Reboot into BIOS, delete existing Secure Boot keys (enter Setup Mode)"
    echo "  Step 3 — Enroll & sign  : scripts/sbctl-sign.sh"
  fi
}
