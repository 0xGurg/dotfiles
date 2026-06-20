#!/bin/bash
set -euo pipefail
# PNPM (Arch only — pre-create PNPM_HOME so global installs work without
# the interactive `pnpm setup` step)

setup_pnpm() {
  if [[ "$OS" != "arch" ]]; then
    return 0
  fi

  local PNPM_HOME_DIR="$HOME/.local/share/pnpm"

  if [[ -d "$PNPM_HOME_DIR" ]]; then
    print_success "PNPM_HOME already exists ($PNPM_HOME_DIR)"
    return 0
  fi

  print_status "Creating PNPM_HOME at $PNPM_HOME_DIR..."
  mkdir -p "$PNPM_HOME_DIR"
  print_success "PNPM_HOME ready"
}
