import decman

decman.execution_order = ["files", "pacman", "aur", "flatpak", "systemd"]

# =============================================================================
# SYSTEM
# Core packages required for a bootable, functional Arch system.
# =============================================================================
decman.pacman.packages |= {
    "base",
    "base-devel",
    "linux",
    "linux-firmware",
    "sudo",
    "zsh",
    "ufw",
    "iwd",
    "lvm2",
    "sbctl",
    "efibootmgr",
    "intel-ucode",
    "zram-generator",
    "openssh",
    "lsof",
}

# =============================================================================
# BLUETOOTH & FIRMWARE
# =============================================================================
decman.pacman.packages |= {
    "bluez",
    "bluez-utils",
    "sof-firmware",
}

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
    "flatpak",
}

# =============================================================================
# FLATPAK
# =============================================================================
decman.flatpak.packages |= {
    "com.spotify.Client",
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
    "zapzap",
}
