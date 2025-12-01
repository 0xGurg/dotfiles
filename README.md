# Dotfiles

Personal configuration files for macOS development environment, managed with Homebrew and symlinks.

## 📁 Structure

```
~/.config/
├── brew/               # Homebrew Brewfile
│   └── Brewfile        # All packages and casks
├── zsh/                # Zsh configuration
│   └── .zshrc          # Shell config (symlinked to ~/.zshrc)
├── scripts/            # Setup and utility scripts
│   └── setup.sh        # Bootstrap script
├── starship/           # Starship prompt
│   └── starship.toml   # Prompt config (STARSHIP_CONFIG points here)
├── git/                # Git configuration
│   └── config          # Git settings
├── aerospace/          # Window manager
├── btop/               # System monitor
├── fastfetch/          # System info
├── ghostty/            # Terminal emulator + themes
├── nvim/               # Neovim editor (see nvim/README.md)
├── opencode/           # OpenCode config
├── raycast/            # Raycast launcher
└── sketchybar/         # macOS status bar
```

## 🚀 Quick Start

### 1. Clone Repository
```bash
git clone <repository-url> ~/.config
cd ~/.config
```

### 2. Run Setup Script
```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

This will:
- Install Homebrew (if not installed)
- Create symlink: `~/.config/zsh/.zshrc` → `~/.zshrc`
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
Edit `brew/Brewfile` and run `bbiu`.

## 🎨 Customization

### Shell Configuration
Edit `zsh/.zshrc` for:
- Aliases
- Functions  
- Environment variables
- Key bindings

Then reload:
```bash
sz  # alias for: source ~/.zshrc
```

### Starship Prompt
Edit `starship/starship.toml` to customize the prompt theme.

### Git Configuration
Edit `git/config` for user settings.

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
- **Git-tracked**: All configs versioned for easy restoration

## 📖 Detailed Documentation

- **[Neovim](nvim/README.md)** - Complete LSP setup, keymaps, plugins

---

**For tool-specific documentation, see the README in each folder (e.g., `nvim/README.md`)**
