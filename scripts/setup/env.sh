#!/bin/bash
# Environment variables setup (.env from .env.tmpl)

setup_env() {
  print_status "Setting up environment variables..."

  if [[ -f "$DOTFILES_DIR/.env" ]]; then
    print_success ".env already exists"
    return 0
  fi

  if [[ ! -f "$DOTFILES_DIR/.env.tmpl" ]]; then
    print_warning "No .env.tmpl found, skipping"
    return 0
  fi

  cp "$DOTFILES_DIR/.env.tmpl" "$DOTFILES_DIR/.env"
  chmod 600 "$DOTFILES_DIR/.env"
  print_success "Created .env from .env.tmpl"
  print_warning "Edit ~/dotfiles/.env and fill in your secrets before using OpenCode"
  print_warning "Or run: python3 ~/dotfiles/scripts/inject-secrets.py (if using Bitwarden)"
}
