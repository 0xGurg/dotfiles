#!/bin/bash
# ============================================================================
# Secure Boot Setup — Part 1: Generate Keys
# Arch Linux only — run BEFORE entering BIOS to clear Secure Boot keys
#
# Usage: ./scripts/sbctl-setup.sh
#
# After this script completes:
#   1. Reboot into BIOS/UEFI firmware
#   2. Navigate to Secure Boot settings
#   3. Delete / clear all existing Secure Boot keys  (this puts the firmware
#      into "Setup Mode", allowing custom keys to be enrolled)
#   4. Save and boot back into Arch Linux
#   5. Run scripts/sbctl-sign.sh to enroll keys and sign EFI binaries
# ============================================================================

set -e
source "$(dirname "${BASH_SOURCE[0]}")/lib/ui.sh"

# ── Guard: Arch Linux only ────────────────────────────────────────────────────
if [[ ! -f /etc/arch-release ]]; then
  print_error "This script is for Arch Linux only."
  exit 1
fi

# ── Guard: must not run as root ───────────────────────────────────────────────
if [[ "$EUID" -eq 0 ]]; then
  print_error "Do not run this script as root. It will call sudo where needed."
  exit 1
fi

# ── Guard: sbctl must be installed ───────────────────────────────────────────
if ! command -v sbctl &> /dev/null; then
  print_error "sbctl is not installed. Install it first:"
  echo "  sudo pacman -S sbctl"
  exit 1
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "         🔐  Secure Boot Setup — Part 1: Generate Keys          "
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# ── Step 1: Current status ────────────────────────────────────────────────────
print_status "Current Secure Boot status:"
sudo sbctl status
echo ""

# ── Step 2: Check if keys already exist (sudo test — /usr/share/secureboot/ is root-owned) ──
if sudo test -f /usr/share/secureboot/keys/db/db.key; then
  print_success "sbctl keys already exist — skipping key creation"
else
  print_status "Creating Secure Boot signing keys..."
  sudo sbctl create-keys
  print_success "Keys created at /usr/share/secureboot/"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "              ⚠️   BIOS ACTION REQUIRED                          "
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
print_warning "Keys are generated. You must now perform a manual BIOS step:"
echo ""
print_info "1. Reboot your machine"
print_info "2. Enter your BIOS/UEFI firmware (usually Del, F2, or F12 on boot)"
print_info "3. Navigate to the Secure Boot settings"
print_info "4. Delete / clear ALL existing Secure Boot keys"
print_info "   (This puts the firmware in 'Setup Mode')"
print_info "5. Save changes and boot back into Arch Linux"
print_info "6. Run:  scripts/sbctl-sign.sh"
echo ""
print_status "When you are ready to reboot, press Enter (or Ctrl-C to stay)..."
read -r

print_status "Rebooting in 5 seconds... (Ctrl-C to cancel)"
for i in 5 4 3 2 1; do
  echo -ne "  ${YELLOW}$i${NC}\r"
  sleep 1
done
echo ""

sudo systemctl reboot
