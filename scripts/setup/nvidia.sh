#!/bin/bash
# Early KMS — NVIDIA (Arch only)

setup_early_kms() {
  if [[ "$OS" != "arch" ]]; then
    return 0
  fi

  print_status "Configuring NVIDIA Early KMS..."

  local MKINIT="/etc/mkinitcpio.conf"

  if grep -qP '^MODULES=\(.*nvidia.*\)' "$MKINIT"; then
    print_success "NVIDIA modules already present in $MKINIT"
  else
    print_status "Adding NVIDIA modules to MODULES= in $MKINIT..."
    sudo sed -i \
      's/^MODULES=(\(.*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' \
      "$MKINIT"
    sudo sed -i \
      's/^MODULES=( /MODULES=(/' \
      "$MKINIT"
    print_success "NVIDIA modules added to $MKINIT"

    print_status "Regenerating initramfs (mkinitcpio -P)..."
    sudo mkinitcpio -P
    print_success "Initramfs regenerated"
  fi

  local PARAM="nvidia_drm.modeset=1"
  local patched=0

  # ── systemd-boot ──────────────────────────────────────────────
  local ENTRIES_DIR="/boot/loader/entries"
  if [[ -d "$ENTRIES_DIR" ]]; then
    for entry in "$ENTRIES_DIR"/*.conf; do
      [[ -f "$entry" ]] || continue

      if grep -q "$PARAM" "$entry"; then
        print_success "$(basename "$entry"): $PARAM already set"
      else
        print_status "Adding $PARAM to $(basename "$entry")..."
        sudo sed -i "s|^\(options\s.*\)$|\1 $PARAM|" "$entry"
        print_success "$(basename "$entry"): $PARAM added"
        ((patched++)) || true
      fi
    done
  fi

  # ── GRUB ──────────────────────────────────────────────────────
  local GRUB_DEFAULT="/etc/default/grub"
  if [[ -f "$GRUB_DEFAULT" ]]; then
    if grep -q "$PARAM" "$GRUB_DEFAULT"; then
      print_success "GRUB: $PARAM already set"
    else
      print_status "Adding $PARAM to GRUB_CMDLINE_LINUX..."
      sudo sed -i "s|^GRUB_CMDLINE_LINUX=\"\(.*\)\"|GRUB_CMDLINE_LINUX=\"\1 $PARAM\"|" "$GRUB_DEFAULT"

      # Ensure /boot/grub exists (may not yet on a fresh install
      # where the ESP is at /efi and /boot is inside the root fs)
      sudo mkdir -p /boot/grub

      if sudo grub-mkconfig -o /boot/grub/grub.cfg; then
        print_success "GRUB: $PARAM added + grub.cfg regenerated"
      else
        print_warning "GRUB: $PARAM added to /etc/default/grub but grub-mkconfig failed"
        print_warning "Run 'sudo grub-mkconfig -o /boot/grub/grub.cfg' manually after boot is set up"
      fi
      ((patched++)) || true
    fi
  fi

  if [[ $patched -gt 0 ]]; then
    print_warning "Kernel parameter change requires a reboot to take effect"
  fi
  if [[ ! -d "$ENTRIES_DIR" ]] && [[ ! -f "$GRUB_DEFAULT" ]]; then
    print_warning "No systemd-boot entries dir or GRUB default found — skipping kernel param"
  fi
}
