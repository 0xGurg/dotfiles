# Neovim Configuration

A modern, minimal Neovim configuration focused on TypeScript/JavaScript development with LSP, notifications, and a clean UI.

## 📁 Structure

```
nvim/
├── init.lua                 # Entry point (requires lua/gurg/lazy.lua)
├── lazy-lock.json          # Plugin version lock file
├── .luarc.json             # Lua LSP configuration (gitignored)
├── .gitignore              # Ignores .luarc.json
└── lua/
    ├── gurg/               # Core configuration
    │   ├── lazy.lua        # Lazy.nvim plugin manager setup
    │   ├── keymaps.lua     # Global keymaps & LSP keymap function
    │   └── options.lua     # Neovim options (cmdheight=0, etc.)
    └── plugins/            # Plugin configurations
        ├── blink-cmp.lua           # Completion engine
        ├── colors.lua              # Color scheme (Kanagawa/Noctis)
        ├── conform.nvim            # Formatting (Prettier, stylua)
        ├── lazygit.lua             # LazyGit integration
        ├── mason.lua               # LSP server management
        ├── mini-*.lua              # Mini.nvim plugins (20+ modules)
        ├── minuet-ai.lua           # AI completion
        ├── neotest.lua             # Testing framework
        ├── noice.lua               # UI enhancement (command palette)
        ├── nvim-ts-autotag.lua     # Auto-close HTML tags
        ├── render-markdown.lua     # Markdown rendering
        ├── sidekick.nvim           # Code outline
        ├── treesitter.lua          # Syntax highlighting
        ├── ts-comments.lua         # Smart comments
        ├── undotree.lua            # Undo history visualizer
        └── vimbegood.lua           # Vim practice game
```

## 🎯 Key Features

### 1. **Notification System**
- **mini.notify**: Handles ALL notifications (yanks, deletes, undo/redo, LSP events)
- **noice.nvim**: Only handles UI elements (command palette, search popup)
- **cmdheight = 0**: Command line hidden, all messages become notifications
- Custom notifications for:
  - Yank/delete operations with content preview
  - Undo/redo with change number
  - Void register deletes (`<leader>d`)
  - Clipboard yanks (`<leader>y`)
  - LSP attachment (DEBUG level)

### 2. **LSP Configuration**
- **Automatic keymap setup**: All LSP servers get standard keymaps automatically
- **Server-specific actions**: Special keymaps for servers like vtsls
- **Powered by Mason**: Easy LSP installation and management

#### Standard LSP Keymaps (Applied to ALL servers)
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>la` | Code Action | Show available code actions |
| `<leader>lr` | Rename | Rename symbol under cursor |
| `<leader>lf` | Format | Format buffer (tries conform first) |
| `<leader>ls` | Signature | Show signature help |
| `<leader>ld` | Diagnostics | Show line diagnostics |
| `<leader>lq` | Diag List | Add diagnostics to location list |
| `K` | Hover | Show hover documentation |
| `[d` | Prev Diagnostic | Jump to previous diagnostic |
| `]d` | Next Diagnostic | Jump to next diagnostic |

#### vtsls-Specific Keymaps (TypeScript/JavaScript)
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>lo` | Organize Imports | Sort and organize imports |
| `<leader>li` | Add Imports | Add missing imports |
| `<leader>lu` | Remove Unused | Remove unused imports |
| `<leader>lx` | Fix All | Apply all available fixes |

#### Global Tool Keymaps
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>lg` | LazyGit | Open LazyGit |
| `<leader>lm` | Mason | Open Mason (LSP manager) |
| `<leader>ln` | Lazy | Open Lazy (plugin manager) |

### 3. **LSP Servers Installed**
- `lua_ls` - Lua language server (Neovim config)
- `vtsls` - TypeScript/JavaScript (faster, more features than ts_ls)
- `eslint` - ESLint linting (respects local .eslintrc)
- `html` - HTML
- `cssls` - CSS
- `jsonls` - JSON
- `tailwindcss` - Tailwind CSS IntelliSense

### 4. **Formatting**
- **conform.nvim**: Primary formatter
- **Formatters**:
  - JavaScript/TypeScript: `prettierd` → `prettier` (fallback)
  - Lua: `stylua`
  - HTML/CSS/JSON/YAML/Markdown: `prettierd` → `prettier`
- **Respects local configs**: Reads `.prettierrc`, `.eslintrc`, etc.
- **Format on save**: Enabled with LSP fallback

## 🚀 Adding a New LSP Server

Just add it to the `ensure_installed` list in `lua/plugins/mason.lua`:

```lua
ensure_installed = {
    'lua_ls',
    'vtsls',
    'pyright',  -- ← Add new server here
}
```

**That's it!** All standard keymaps work automatically via `_G.setup_lsp_keymaps()`.

### Adding Server-Specific Keymaps

If the server has special features, add them in `lua/gurg/keymaps.lua`:

```lua
-- In _G.setup_lsp_keymaps function, after the vtsls block:
if client.name == 'pyright' then
    vim.keymap.set('n', '<leader>lp', function()
        -- Python-specific action
    end, vim.tbl_extend('force', opts, { desc = 'Python Action' }))
end
```

### Server-Specific Configuration

For custom settings, add to `lua/plugins/mason.lua`:

```lua
local server_configs = {
    lua_ls = { ... },
    pyright = {
        settings = {
            python = {
                analysis = {
                    typeCheckingMode = "basic",
                }
            }
        }
    }
}
```

## 🎨 UI & Appearance

- **Color Scheme**: Kanagawa (with Noctis variants available)
- **Statusline**: mini.statusline (minimal, fast)
- **Tabline**: mini.tabline (buffer tabs)
- **Git Signs**: mini.diff (inline diff signs)
- **File Explorer**: mini.files (`<leader>e`)
- **Fuzzy Finder**: mini.pick
- **Icons**: mini.icons (no patched font required)
- **Indent Guides**: mini.indentscope

## ⌨️ Other Notable Keymaps

### Buffer Management
- `<leader>qq` - Close buffer (with unsaved warning)
- `<leader>qo` - Close other buffers
- `<leader>qa` - Close all buffers
- `<leader>Q` - Quit Neovim (no save)

### File Operations
- `<leader>w` - Save file
- `<leader>wq` - Save & close buffer

### Clipboard
- `<leader>y` - Copy to system clipboard (visual/normal)
- `<leader>Y` - Copy line to clipboard
- `<leader>p` - Paste without replacing register (visual)
- `<leader>d` - Delete to void register (shows notification)

### Navigation
- `<C-d>` / `<C-u>` - Scroll down/up (centered)
- `n` / `N` - Next/prev search (centered)

### Utilities
- `<leader>x` - Make file executable
- `<leader>sr` - Search & replace word under cursor
- `u` - Undo (with notification)
- `<C-r>` / `<D-r>` - Redo (with notification)

## 📦 Plugin Highlights

### Mini.nvim Suite (20+ modules)
A collection of small, independent, fast Lua modules:
- **mini.notify** - Notification manager
- **mini.clue** - Keymap hints (shows available keys)
- **mini.pick** - Fuzzy finder
- **mini.files** - File explorer
- **mini.diff** - Git diff signs
- **mini.git** - Git integration
- **mini.statusline** - Statusline
- **mini.tabline** - Tab/buffer line
- **mini.pairs** - Auto-pairs
- **mini.surround** - Surround text objects
- **mini.move** - Move lines/selections
- **mini.snippets** - Snippet support
- **mini.indentscope** - Indent scope indicator
- **mini.hipatterns** - Highlight patterns
- **mini.icons** - Icon provider

### Other Key Plugins
- **blink.cmp** - Completion engine (fast, Rust-based)
- **treesitter** - Syntax highlighting & code understanding
- **conform.nvim** - Formatter runner
- **lazygit.nvim** - Git UI
- **mason.nvim** - LSP/DAP/linter installer
- **noice.nvim** - Enhanced UI (command palette)
- **neotest** - Testing framework (Jest, Vitest)
- **render-markdown.nvim** - Beautiful markdown rendering
- **minuet-ai** - AI-powered completion

## 🔧 Technical Details

### LSP Attachment Flow
1. File opened → LSP server starts
2. `LspAttach` autocmd triggered
3. Calls `on_attach(client, bufnr)`
4. Calls `_G.setup_lsp_keymaps(client, bufnr)`
5. Sets up buffer-local keymaps
6. Shows "LSP attached: {name}" notification (DEBUG level)
7. Refreshes mini.clue to show new keymaps

### Notification Priority & Duration
- **ERROR**: 10 seconds (red)
- **WARN**: 5 seconds (yellow)
- **INFO**: 5 seconds (blue)
- **DEBUG**: 2 seconds (yellow, linked to WARN)
- **TRACE**: 2 seconds (gray)

### Diagnostic Configuration
- **Virtual text**: Enabled with `●` prefix
- **Signs**: Custom icons (`, `, `, `)
- **Underline**: Enabled
- **Update in insert**: Disabled
- **Severity sort**: Enabled
- **Float border**: Rounded

## 📝 Notes

- **Neovim Version**: 0.11+ (uses new diagnostic and LSP APIs)
- **cmdheight = 0**: Forces all messages through `vim.notify()`
- **mini.notify priority = 1000**: Loads first to capture all notifications
- **VimEnter autocmd**: Re-overrides `vim.notify` after other plugins load
- **lua_ls warnings suppressed**: vtsls uses custom `.ts` suffix actions not in LSP spec

## 🔍 Troubleshooting

### LSP Not Attaching
1. Check `:LspInfo` to see if server started
2. Check `:Mason` to ensure server is installed
3. Restart LSP: `:LspRestart`

### Keymaps Not Showing in mini.clue
1. Check `_G.setup_lsp_keymaps` is defined (`:lua print(_G.setup_lsp_keymaps)`)
2. Ensure LSP is attached (`:LspInfo`)
3. Trigger mini.clue refresh: `<leader>l` then `<Esc>`

### Notifications Not Appearing
1. Check mini.notify is loaded: `:lua print(require('mini.notify'))`
2. Test notification: `:lua vim.notify('test', vim.log.levels.INFO)`
3. Check cmdheight: `:set cmdheight?` (should be 0)

## 🎓 Learning Resources

- **Neovim LSP**: `:help lsp`
- **Diagnostic API**: `:help diagnostic`
- **Keymap API**: `:help vim.keymap.set`
- **Mini.nvim docs**: https://github.com/echasnovski/mini.nvim
- **Mason**: `:help mason.nvim`
- **Lazy.nvim**: `:help lazy.nvim`

---

**Last Updated**: November 2024  
**Neovim Version**: 0.11+  
**Maintainer**: Setup optimized for TypeScript/JavaScript development

