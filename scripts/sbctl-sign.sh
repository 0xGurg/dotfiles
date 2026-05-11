#!/bin/bash
# ============================================================================
# Secure Boot Setup — Part 2: Enroll Keys & Sign EFI Binaries
# Arch Linux only — run AFTER clearing Secure Boot keys in BIOS (Setup Mode)
#
# Usage: ./scripts/sbctl-sign.sh
#
# Prerequisites:
#   - scripts/sbctl-setup.sh has been run (keys exist)
#   - You have rebooted into BIOS, cleared existing Secure Boot keys,
#     and booted back into Arch Linux (firmware is now in Setup Mode)
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_status()  { echo -e "${BLUE}==>${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error()   { echo -e "${RED}✗${NC} $1"; }
print_info()    { echo -e "${CYAN}  $1${NC}"; }

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
echo "      🔐  Secure Boot Setup — Part 2: Enroll Keys & Sign        "
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# ── Step 1: Current status ────────────────────────────────────────────────────
print_status "Current Secure Boot status:"
sbctl status
echo ""

# ── Step 2: Enroll keys (only if still in Setup Mode) ────────────────────────
# "Setup Mode: ✓ Disabled" = keys already enrolled, skip
# "Setup Mode: ✗ Enabled"  = firmware is ready, enroll now
if sbctl status 2>&1 | grep -q "Setup Mode:.*Enabled"; then
  print_status "Enrolling Secure Boot keys (including Microsoft keys for hardware compatibility)..."
  sudo sbctl enroll-keys -m
  print_success "Keys enrolled (including Microsoft keys)"
  echo ""
else
  print_success "Keys already enrolled — skipping enrollment"
  echo ""
fi

# ── Step 3: Verify which EFI files need signing ──────────────────────────────
print_status "Checking EFI binaries for signing status..."
echo ""
sudo sbctl verify
echo ""

# ── Step 4: Sign all unsigned EFI binaries ───────────────────────────────────
print_status "Signing all unsigned EFI binaries..."

# Parse sbctl verify output: lines with ✗ contain unsigned files
# Extract the absolute path (starts with /) — avoids awk $NF fragility across output format changes
mapfile -t UNSIGNED < <(sudo sbctl verify 2>/dev/null | grep -E '^\s*✗' | grep -oE '/[^[:space:]]+')

if [[ ${#UNSIGNED[@]} -eq 0 ]]; then
  print_success "All EFI binaries are already signed — nothing to do"
else
  for file in "${UNSIGNED[@]}"; do
    if [[ -f "$file" ]]; then
      print_status "Signing: $file"
      sudo sbctl sign -s "$file"
      print_success "Signed:  $file"
    else
      print_warning "File not found, skipping: $file"
    fi
  done
fi

echo ""

# ── Step 5: Final verification ────────────────────────────────────────────────
print_status "Final verification:"
sudo sbctl verify
echo ""

# Check if any unsigned files remain
REMAINING=$(sudo sbctl verify 2>/dev/null | grep -cE '^\s*✗' || true)
if [[ "$REMAINING" -gt 0 ]]; then
  print_warning "$REMAINING file(s) still unsigned — review the output above"
else
  print_success "All EFI binaries are signed"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "                    ✅  Secure Boot Ready                        "
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
print_info "Secure Boot is configured. On next boot, UEFI will enforce signed binaries."
print_info "The -s flag saves each file path so sbctl re-signs them automatically"
print_info "after kernel updates via the pacman hook."
echo ""
print_status "Reboot to activate Secure Boot. Press Enter to reboot (or Ctrl-C to cancel)..."
read -r

print_status "Rebooting in 5 seconds... (Ctrl-C to cancel)"
for i in 5 4 3 2 1; do
  echo -ne "  ${YELLOW}$i${NC}\r"
  sleep 1
done
echo ""

sudo systemctl reboot
