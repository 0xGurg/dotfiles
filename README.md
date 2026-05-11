# Dotfiles

Personal configuration files for macOS, managed with GNU Stow.

## 📁 Structure

```
~/dotfiles/
├── .zshrc              # Zsh shell config (stowed to ~/.zshrc)
├── .zprofile           # Login shell startup (fastfetch runs here)
├── Brewfile            # Homebrew packages and casks
├── .config/            # XDG config directory (stowed to ~/.config/)
│   ├── starship/       # Starship prompt
│   │   └── starship.toml
│   ├── git/            # Git configuration
│   │   └── config
│   ├── aerospace/      # Window manager
│   ├── atuin/          # Shell history database
│   ├── btop/           # System monitor
│   ├── fastfetch/      # System info
│   ├── ghostty/        # Terminal emulator + themes
│   ├── nvim/           # Neovim editor (see .config/nvim/README.md)
│   ├── opencode/       # OpenCode config
│   ├── raycast/        # Raycast launcher
│   └── sketchybar/     # macOS status bar
├── scripts/            # Setup and utility scripts
│   ├── setup.sh        # Bootstrap script
│   ├── nvhc.sh         # Cursor + Neovim split workflow
│   └── enable-touchid-sudo.sh
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
- Install GNU Stow
- Create symlinks using stow: `cd ~/dotfiles && stow .`
- Install all packages from Brewfile
- Optionally enable Touch ID for sudo commands

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
| **Zoxide** | Smart directory jumper (`z`, `zi`) |
| **Atuin** | Shell history database with sync |
| **Ollama** | Local LLM runner |
| **OpenCode** | AI coding assistant (shared OpenCode Go account) |

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
brew update && brew bundle install --cleanup --file=~/dotfiles/Brewfile && brew upgrade
```

### Add New Package
Edit `Brewfile` and run `bbiu`.

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

## 🔐 Touch ID for sudo

Enable fingerprint authentication instead of password prompts in terminals:

```bash
./scripts/enable-touchid-sudo.sh
```

Or run during initial setup (prompted automatically).

## 🔑 Secrets & Environment Variables

Secrets are stored in `.env` (gitignored). Copy the template on first setup:

```bash
cp .env.example .env
$EDITOR .env
```

| Variable | Purpose |
|----------|---------|
| `OPENCODE_GO_WORKSPACE_ID` | Shared OpenCode Go workspace ID for quota tracking |
| `BRAVE_API_KEY` | Brave Search API key (used by OpenCode Librarian agent) |
| `SANITY_AUTH_TOKEN` | Sanity CMS authentication |

> **Note:** The OpenCode Go auth cookie is **not** in `.env`. It's stored in
> `~/.config/opencode/opencode-quota/opencode-go.json` (gitignored) and managed
> by the refresh script — see below.

## 🤖 OpenCode Go Setup

This repo includes a shared [OpenCode](https://opencode.ai) configuration with the
[oh-my-opencode-slim](https://github.com/oh-my-opencode/oh-my-opencode-slim) agent
orchestration plugin and [opencode-quota](https://github.com/slkiser/opencode-quota)
for usage tracking.

### Auth Cookie

OpenCode Go requires an auth cookie for quota tracking. To set it up or refresh it:

```bash
~/.config/opencode/scripts/refresh-opencode-quota.sh
```

This extracts the `auth` cookie from your browser and saves it to
`opencode-quota/opencode-go.json`. Run it again when the cookie expires.

| Flag | Purpose |
|------|---------|
| `--check` | Check if current cookie is valid without refreshing |
| `--force` | Force refresh even if the cookie is still valid |

## 📝 Notes

- **Tested on**: Apple Silicon Macs (M1/M2/M4)
- **XDG Base Directory**: Follows `~/.config` standard
- **Stow-based**: Uses GNU Stow for symlink management
- **Git-tracked**: All configs versioned for easy restoration
- **Shared account**: OpenCode Go is shared — use `/quota` in OpenCode to check usage

## 📖 Detailed Documentation

- **[Neovim](.config/nvim/README.md)** - Complete LSP setup, keymaps, plugins

---

**For tool-specific documentation, see the README in each folder (e.g., `nvim/README.md`)**
