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

  local ENTRIES_DIR="/boot/loader/entries"

  if [[ ! -d "$ENTRIES_DIR" ]]; then
    print_warning "systemd-boot entries directory not found at $ENTRIES_DIR — skipping kernel param"
    return 0
  fi

  local PARAM="nvidia_drm.modeset=1"
  local patched=0

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

  if [[ $patched -gt 0 ]]; then
    print_warning "Kernel parameter change requires a reboot to take effect"
  fi
}
