#!/bin/bash
set -euo pipefail
# OpenCode plugin installation

setup_opencode() {
  print_status "Installing OpenCode plugins..."

  local opencode_dir="$DOTFILES_DIR/.config/opencode"
  if [[ ! -f "$opencode_dir/package.json" ]]; then
    print_warning "No OpenCode package.json found, skipping"
    return 0
  fi

  if ! command -v pnpm &>/dev/null; then
    print_warning "pnpm not found, skipping OpenCode plugin install"
    print_warning "Install pnpm and run: cd ~/.config/opencode && pnpm install"
    return 0
  fi

  (cd "$opencode_dir" && pnpm install --frozen-lockfile 2>/dev/null) \
    && print_success "OpenCode plugins installed" \
    || print_warning "OpenCode plugin install failed — run manually: cd ~/.config/opencode && pnpm install"
}
