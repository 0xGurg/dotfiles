#!/bin/bash
set -euo pipefail
# GNU Stow — install and create symlinks

setup_stow() {
  print_status "Setting up GNU Stow..."

  if command -v stow &> /dev/null; then
    print_success "GNU Stow already installed"
    return 0
  fi

  case "$OS" in
    macos)
      brew install stow
      ;;
    arch|linux)
      sudo pacman -S --needed stow
      ;;
    *)
      echo "Unknown OS — stow must be installed manually"
      return 1
      ;;
  esac

  print_success "GNU Stow installed"
}

setup_symlinks() {
  print_status "Creating symlinks with stow..."

  local BACKUP_DIR
  BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

  has_symlink_ancestor() {
    local check="$1"
    while [[ "$check" != "/" && "$check" != "$HOME" ]]; do
      if [[ -L "$check" ]]; then
        return 0
      fi
      check=$(dirname "$check")
    done
    return 1
  }

  backup_existing() {
    local target="$1" rel="$2"

    if [[ -L "$target" ]]; then
      return
    fi

    if [[ -f "$target" ]] || [[ -d "$target" ]]; then
      if has_symlink_ancestor "$target"; then
        return
      fi

      print_warning "Backing up $target → $BACKUP_DIR/$rel"
      mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
      mv "$target" "$BACKUP_DIR/$rel"
    fi
  }

  while IFS= read -r -d '' file; do
    local rel="${file#"$DOTFILES_DIR"/}"

    [[ "$rel" == scripts/* ]] && continue
    [[ "$rel" == .git/* ]] && continue
    [[ "$rel" == README* ]] && continue
    [[ "$rel" == Brewfile ]] && continue

    local target="$HOME/$rel"
    backup_existing "$target" "$rel"
  done < <(find "$DOTFILES_DIR" -path '*/.git' -prune -o \( -type f -o -type l \) -print0)

  cd "$DOTFILES_DIR"

  case "$OS" in
    macos)
      stow -v .
      ;;
    arch|linux)
      stow -v .
      ;;
  esac

  print_success "Symlinks created"
  if [[ -d "$BACKUP_DIR" ]] && [[ "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
    print_status "Backups stored in $BACKUP_DIR"
  else
    rmdir "$BACKUP_DIR" 2>/dev/null || true
  fi
}
