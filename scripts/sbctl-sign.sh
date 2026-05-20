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
#
# GRUB + Secure Boot note:
#   Arch's grub package embeds the shim_lock module in the GRUB core image.
#   At boot, shim_lock looks for EFI_SHIM_LOCK_PROTOCOL (registered by shim.efi).
#   Without shim in the chain, this hard-fails with "shim_lock protocol not found"
#   and GRUB refuses to load the kernel.
#
#   Fix: grub-install --disable-shim-lock rebuilds the core image without shim_lock,
#   so GRUB doesn't try to find shim at boot. sbctl then signs the result.
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
if sbctl status 2>&1 | grep -q "Setup Mode:.*Enabled"; then
  print_status "Enrolling Secure Boot keys (including Microsoft keys for hardware compatibility)..."
  sudo sbctl enroll-keys -m
  print_success "Keys enrolled (including Microsoft keys)"
  echo ""
else
  print_success "Keys already enrolled — skipping enrollment"
  echo ""
fi

# ── Step 3: Reinstall GRUB without shim_lock module ──────────────────────────
# The shim_lock module is baked into the GRUB core image by default. At boot
# it looks for EFI_SHIM_LOCK_PROTOCOL (registered by shim.efi). Without shim
# in the chain this hard-fails → "shim_lock protocol not found" → kernel blocked.
#
# --disable-shim-lock rebuilds the core image without that module.
#
# CRITICAL: Without shim_lock, GRUB has no verifier registered. When Secure Boot
# is on, GRUB asks "does anyone want to verify this file?" and if nobody cares,
# it refuses to load modules (normal.mod etc.) → rescue mode.
# The --modules="tpm" flag embeds the TPM verifier in the core image. The TPM
# verifier "cares" about verification requests and allows them through (it
# measures files to the TPM but doesn't block them). This prevents the
# "verification requested but nobody cares" error.
if command -v grub-install &> /dev/null; then
  # Detect ESP mount point
  ESP_DIR=""
  for esp in /efi /boot/efi; do
    if [[ -d "$esp/EFI" ]]; then
      ESP_DIR="$esp"
      break
    fi
  done

  if [[ -z "$ESP_DIR" ]]; then
    print_error "Cannot find ESP mount point (checked /efi and /boot/efi)"
    print_error "Make sure the ESP is mounted and re-run this script"
    exit 1
  fi

  print_status "Reinstalling GRUB without shim_lock (--disable-shim-lock --modules=tpm)..."
  sudo grub-install \
    --target=x86_64-efi \
    --efi-directory="$ESP_DIR" \
    --bootloader-id=GRUB \
    --disable-shim-lock \
    --modules="tpm"
  print_success "GRUB reinstalled to $ESP_DIR without shim_lock module (tpm verifier embedded)"
  echo ""

  # Ensure rootflags=subvol=@ is set for Btrfs @ subvolume layouts
  GRUB_DEFAULT="/etc/default/grub"
  if findmnt -n -o OPTIONS / 2>/dev/null | grep -q 'subvol=@'; then
    if [[ -f "$GRUB_DEFAULT" ]] && ! grep -q 'rootflags=subvol=@' "$GRUB_DEFAULT"; then
      print_status "Adding rootflags=subvol=@ to GRUB_CMDLINE_LINUX..."
      sudo sed -i "s|^GRUB_CMDLINE_LINUX=\"\(.*\)\"|GRUB_CMDLINE_LINUX=\"\1 rootflags=subvol=@\"|" "$GRUB_DEFAULT"
      print_success "Added rootflags=subvol=@"
    fi
  fi

  # Regenerate grub.cfg
  sudo mkdir -p /boot/grub
  print_status "Regenerating grub.cfg..."
  sudo grub-mkconfig -o /boot/grub/grub.cfg
  print_success "grub.cfg regenerated"
  echo ""
else
  print_warning "grub-install not found — skipping GRUB reinstall"
fi

# ── Step 4: Sign EFI binaries ─────────────────────────────────────────────────
print_status "Checking EFI binaries for signing status..."
echo ""
sudo sbctl verify
echo ""

print_status "Signing all unsigned EFI binaries..."

mapfile -t UNSIGNED < <(sudo sbctl verify 2>/dev/null | grep -E '^\s*✗' | grep -oE '/[^[:space:]]+')

# Explicitly check GRUB binary in case sbctl verify doesn't find it
for candidate in /efi/EFI/GRUB/grubx64.efi /boot/efi/EFI/GRUB/grubx64.efi; do
  if [[ -f "$candidate" ]] && ! sudo sbctl verify 2>/dev/null | grep -q "$candidate"; then
    UNSIGNED+=("$candidate")
  fi
done

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

# ── Step 5: Sign the kernel ───────────────────────────────────────────────────
# Without shim_lock, GRUB performs no kernel verification. Sign the kernel
# so the sbctl pacman hook re-signs it automatically after updates.
print_status "Signing kernel(s)..."
for kernel in /boot/vmlinuz-linux /boot/vmlinuz-linux-lts /boot/vmlinuz-linux-zen; do
  if [[ -f "$kernel" ]]; then
    sudo sbctl sign -s "$kernel"
    print_success "Signed: $kernel"
  fi
done
echo ""

# ── Step 6: Final verification ────────────────────────────────────────────────
print_status "Final verification:"
sudo sbctl verify
echo ""

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
print_info "The -s flag saves each path so sbctl re-signs automatically after updates."
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
