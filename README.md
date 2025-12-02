# Dotfiles

Personal configuration files for macOS development environment, managed with GNU Stow and Homebrew.

## 📁 Structure

```
~/dotfiles/
├── .zshrc              # Zsh shell config (stowed to ~/.zshrc)
├── .config/            # XDG config directory (stowed to ~/.config/)
│   ├── brew/           # Homebrew Brewfile
│   │   └── Brewfile    # All packages and casks
│   ├── starship/       # Starship prompt
│   │   └── starship.toml   # Prompt config (STARSHIP_CONFIG points here)
│   ├── git/            # Git configuration
│   │   └── config      # Git settings
│   ├── aerospace/      # Window manager
│   ├── btop/           # System monitor
│   ├── fastfetch/      # System info
│   ├── ghostty/        # Terminal emulator + themes
│   ├── nvim/           # Neovim editor (see .config/nvim/README.md)
│   ├── opencode/       # OpenCode config
│   ├── raycast/        # Raycast launcher
│   └── sketchybar/     # macOS status bar
├── scripts/            # Setup and utility scripts
│   └── setup.sh        # Bootstrap script
└── README.md           # This file
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

This will:
- Install Homebrew (if not installed)
- Install GNU Stow (if not installed)
- Create symlinks using stow: `cd ~/dotfiles && stow .`
- Install all packages from Brewfile

### 3. Restart Terminal
```bash
source ~/.zshrc
# or just open a new terminal
```

## 🔧 Tools

| Tool | Purpose |
|------|---------|
| **Neovim** | Code editor (TypeScript/JS focus) |
| **Zsh** | Shell with autosuggestions & syntax highlighting |
| **Starship** | Fast, customizable prompt |
| **Ghostty** | GPU-accelerated terminal emulator |
| **AeroSpace** | Window tiling manager |
| **SketchyBar** | Custom macOS status bar |
| **Lazygit** | Terminal UI for git |
| **Ollama** | Local LLM runner |

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
bbiu
```

This alias runs:
```bash
brew update && brew bundle install --cleanup --file=~/.config/brew/Brewfile && brew upgrade
```

### Add New Package
Edit `.config/brew/Brewfile` and run `bbiu`.

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
| `bbiu` | Update all brew packages |
| `sz` | Reload shell config |
| `nv` | Open neovim |
| `nvh` | Open neovim in current dir |
| `lg` | Open lazygit |
| `ff` | Show system info (fastfetch) |
| `cdcfg` | cd to ~/.config |

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

## 📝 Notes

- **macOS support**: Tested on Apple Silicon (M1/M2/M4) Macs
- **XDG Base Directory**: Follows `~/.config` standard
- **Stow-based**: Uses GNU Stow for symlink management
- **Git-tracked**: All configs versioned for easy restoration

## 📖 Detailed Documentation

- **[Neovim](.config/nvim/README.md)** - Complete LSP setup, keymaps, plugins

---

**For tool-specific documentation, see the README in each folder (e.g., `nvim/README.md`)**
