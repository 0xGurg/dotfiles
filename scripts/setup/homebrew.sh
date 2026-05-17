#!/bin/bash
# Homebrew (macOS only)

setup_homebrew() {
  if [[ "$OS" != "macos" ]]; then
    print_status "Skipping Homebrew setup (not on macOS)"
    return 0
  fi

  print_status "Setting up Homebrew..."

  if ! command -v brew &> /dev/null; then
    print_status "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  print_success "Homebrew ready"
}
