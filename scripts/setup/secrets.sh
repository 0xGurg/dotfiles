#!/bin/bash
set -euo pipefail
# Secrets injection (Bitwarden → .env, config templates, SSH keys)

setup_secrets() {
  print_status "Setting up secrets from Bitwarden..."

  if ! command -v bw &>/dev/null; then
    print_warning "bitwarden-cli (bw) not found — skipping secrets injection"
    print_warning "Install it and run scripts/inject-secrets.py manually later"
    return 0
  fi

  echo ""
  print_warning "Secrets injection requires your Bitwarden master password"
  read -p "Inject secrets from Bitwarden now? (y/N): " -n 1 -r
  echo ""

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    python3 "$DOTFILES_DIR/scripts/inject-secrets.py"
  else
    print_status "Skipping secrets injection (run scripts/inject-secrets.py later)"
  fi
}
