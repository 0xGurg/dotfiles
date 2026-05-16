# Dotfiles

Personal configuration files for macOS and Arch Linux, managed with GNU Stow.

## 📁 Structure

```
~/dotfiles/
├── .zshrc              # Zsh shell config (stowed to ~/.zshrc)
├── Brewfile            # Homebrew packages (macOS)
├── .config/            # XDG config directory (stowed to ~/.config/)
│   ├── bigkis/         # Arch Linux package declarations (pacman/AUR/flatpak/node)
│   │   └── system.toml
│   ├── starship/       # Starship prompt
│   │   └── starship.toml
│   ├── git/            # Git configuration
│   │   └── config
│   ├── hypr/           # Hyprland window manager (Arch)
│   ├── aerospace/      # Window manager (macOS)
│   ├── atuin/          # Shell history database
│   ├── btop/           # System monitor
│   ├── fastfetch/      # System info
│   ├── ghostty/        # Terminal emulator + themes
│   ├── nvim/           # Neovim editor (see .config/nvim/README.md)
│   ├── opencode/       # OpenCode config
│   ├── raycast/        # Raycast launcher (macOS)
│   └── sketchybar/     # macOS status bar
└── scripts/            # Setup and utility scripts
    ├── setup.sh        # Bootstrap script (macOS + Arch)
    ├── sbctl-setup.sh  # Secure Boot — Part 1: generate keys (Arch)
    ├── sbctl-sign.sh   # Secure Boot — Part 2: enroll + sign (Arch)
    ├── nvhc.sh         # Cursor + Neovim split workflow (macOS)
    └── enable-touchid-sudo.sh
```

## 🚀 Quick Start

### 1. Clone Repository
```bash
git clone <repository-url> ~/dotfiles
cd ~/dotfiles
```

### 2. Run Setup Script
```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

The script auto-detects your OS and handles everything:

| Step | macOS | Arch Linux |
|------|-------|------------|
| Package manager | Homebrew | bigkis (pacman + AUR + flatpak + node) |
| Symlinks | `stow .` | `stow .` (macOS-only configs ignored) |
| Default shell | — (zsh is default) | `chsh` to zsh |
| NVIDIA Early KMS | — | `mkinitcpio.conf` + systemd-boot param |
| Auth | Touch ID for sudo | Howdy (facial recognition) |

### 3. Restart Terminal
```bash
source ~/.zshrc
# or just open a new terminal
```

---

## 🔒 Arch Linux — Secure Boot Setup

Secure Boot requires a manual BIOS step so it is handled by two separate scripts, run **after** `setup.sh` completes.

### Part 1 — Generate keys (before BIOS)
```bash
./scripts/sbctl-setup.sh
```
This runs `sbctl status`, creates your signing keys, then prompts you to reboot.

### BIOS step (manual)
1. Enter your BIOS/UEFI firmware (Del, F2, or F12 on boot)
2. Navigate to **Secure Boot** settings
3. **Delete / clear all existing Secure Boot keys** — this puts the firmware into *Setup Mode*
4. Save and boot back into Arch Linux

### Part 2 — Enroll keys & sign EFI binaries (after BIOS)
```bash
./scripts/sbctl-sign.sh
```
This enrolls your keys (including Microsoft keys with `-m` for hardware compatibility), discovers all unsigned EFI binaries via `sbctl verify`, signs each one with `sbctl sign -s` (the `-s` flag saves paths for automatic re-signing on kernel updates), and reboots to activate Secure Boot.

## 🔧 Tools

| Tool | Purpose | Platform |
|------|---------|----------|
| **Neovim** | Code editor (TypeScript/JS focus) | Both |
| **Zsh** | Shell with autosuggestions & syntax highlighting | Both |
| **Starship** | Fast, customizable prompt | Both |
| **Ghostty** | GPU-accelerated terminal emulator | Both |
| **Lazygit** | Terminal UI for git | Both |
| **Zoxide** | Smart directory jumper (`z`, `zi`) | Both |
| **Atuin** | Shell history database with sync | Both |
| **Ollama** | Local LLM runner | Both |
| **AeroSpace** | Window tiling manager | macOS |
| **SketchyBar** | Custom macOS status bar | macOS |
| **Hyprland** | Wayland compositor / tiling WM | Arch |
| **bigkis** | Declarative package manager (pacman/AUR/flatpak/node) | Arch |
| **UFW** | Firewall | Arch |
| **sbctl** | Secure Boot key management | Arch |

## 🔗 Symlink Management with Stow

### Create Symlinks
```bash
cd ~/dotfiles
stow .
```

### Remove Symlinks
```bash
cd ~/dotfiles
stow -D .
```

### Restow (useful after adding new files)
```bash
cd ~/dotfiles
stow -R .
```

## 📦 Package Management

### Update Everything
```bash
pkgup
```

On macOS this runs `brew update && brew bundle install && brew upgrade`.
On Arch it runs `bigkis apply` (pacman + AUR + flatpak + node).

### macOS — Add New Package
Edit `Brewfile` and run `pkgup`.

### Arch — Add New Package
Edit `bigkis/system.toml` and run `pkgup`.

## 🎨 Customization

### Shell Configuration
Edit `.zshrc` for:
- Aliases
- Functions  
- Environment variables
- Key bindings

Then reload:
```bash
sz  # alias for: source ~/.zshrc
```

### Starship Prompt
Edit `.config/starship/starship.toml` to customize the prompt theme.

### Git Configuration
Edit `.config/git/config` for user settings.

## ⌨️ Key Aliases

| Alias | Command |
|-------|---------|
| `pkgup` | Update all packages (brew on macOS, bigkis on Arch) |
| `sz` | Reload shell config |
| `nv` | Open neovim |
| `nvh` | Open neovim in current dir |
| `nvhc` | Cursor + Neovim split layout |
| `lg` | Open lazygit |
| `ff` | Show system info (fastfetch) |
| `z <dir>` | Smart cd (zoxide) |
| `zi` | Interactive directory picker |

## 🔄 Maintenance

### Reload Configs
```bash
# Shell
sz

# SketchyBar
sketchybar --reload

# AeroSpace
aerospace reload-config

# Neovim
# Restart or :Lazy sync
```

## 🔐 Touch ID for sudo (macOS)

Enable fingerprint authentication instead of password prompts in terminals:

```bash
./scripts/enable-touchid-sudo.sh
```

Or run during initial setup (prompted automatically).

## 📝 Notes

- **Tested on**: Apple Silicon Macs (M1/M2/M4) and Arch Linux (Intel + NVIDIA)
- **XDG Base Directory**: Follows `~/.config` standard
- **Stow-based**: Uses GNU Stow for symlink management
- **Git-tracked**: All configs versioned for easy restoration
- **macOS-only configs** (`aerospace`, `sketchybar`, `raycast`, `Brewfile`) are automatically ignored by stow on Arch Linux

## 📖 Detailed Documentation

- **[Neovim](.config/nvim/README.md)** - Complete LSP setup, keymaps, plugins

---

**For tool-specific documentation, see the README in each folder (e.g., `nvim/README.md`)**
