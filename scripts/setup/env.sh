#!/bin/bash
# Environment variables setup (.env from .env.example)

setup_env() {
  print_status "Setting up environment variables..."

  if [[ -f "$DOTFILES_DIR/.env" ]]; then
    print_success ".env already exists"
    return 0
  fi

  if [[ ! -f "$DOTFILES_DIR/.env.example" ]]; then
    print_warning "No .env.example found, skipping"
    return 0
  fi

  cp "$DOTFILES_DIR/.env.example" "$DOTFILES_DIR/.env"
  print_success "Created .env from .env.example"
  print_warning "Edit ~/dotfiles/.env and fill in your secrets before using OpenCode"
}
