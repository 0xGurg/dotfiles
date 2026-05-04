
# =============================================================================
# AUDIO
# PipeWire stack.
# =============================================================================
decman.pacman.packages |= {
    "pipewire",
    "pipewire-alsa",
    "pipewire-jack",
    "pipewire-pulse",
    "wireplumber",
    "gst-plugin-pipewire",
    "libpulse",
}

# =============================================================================
# GPU & DISPLAY
# Intel iGPU + NVIDIA dGPU (hybrid). Wayland compatibility layers.
# =============================================================================
decman.pacman.packages |= {
    "vulkan-intel",
    "intel-media-driver",
    "nvidia-open",
    "nvidia-utils",
    "qt5-wayland",
    "qt6-wayland",
}

# =============================================================================
# WAYLAND / DESKTOP
# Hyprland compositor + supporting utilities.
# =============================================================================
decman.pacman.packages |= {
    "hyprland",
    "xdg-desktop-portal-hyprland",
}

# =============================================================================
# SHELL & CLI TOOLS
# =============================================================================
decman.pacman.packages |= {
    "git",
    "stow",
    "fastfetch",
    "starship",
    "zoxide",
    "atuin",
    "bat",
    "ripgrep",
    "lazygit",
    "shfmt",
    "zsh-autosuggestions",
    "zsh-syntax-highlighting",
}

# =============================================================================
# FONTS
# =============================================================================
decman.pacman.packages |= {
    "ttf-hack-nerd",
    "ttf-jetbrains-mono-nerd",
    "noto-fonts",
    "noto-fonts-cjk",
}

# =============================================================================
# TERMINAL
# =============================================================================
decman.pacman.packages |= {
    "ghostty",
}

# =============================================================================
# DEVELOPMENT
# =============================================================================
decman.pacman.packages |= {
    "neovim",
    "fnm",
    "pnpm",
    "cmake",
}

# =============================================================================
# APPLICATIONS
# =============================================================================
decman.pacman.packages |= {
    "btop",
    "ollama",
    "wireguard-tools",
    "bitwarden",
}

# =============================================================================
# AUR PACKAGES
# Built via devtools/makepkg — no yay required.
#
# NOTE: On first run, AUR builds (especially howdy-git) may need GPG keys or
# extra setup. Use `sudo decman --skip aur` to apply pacman packages first,
# then run `sudo decman` to build AUR packages separately.
# =============================================================================
decman.aur.packages |= {
    "decman",
    "brave-bin",
    "howdy-git",
    "spotify",
    "zapzap",
}
