# Neovim Configuration File Index

**Generated**: December 9, 2025  
**Configuration Path**: `~/.config/nvim/`

This index provides a comprehensive catalog of all files in this Neovim configuration.

---

## 📂 Root Directory

### Core Files
| File | Type | Purpose |
|------|------|---------|
| `init.lua` | Entry Point | Bootstrap file that loads `lua/gurg/lazy.lua` |
| `lazy-lock.json` | Lock File | Plugin version lock file (managed by lazy.nvim) |
| `README.md` | Documentation | Comprehensive configuration guide and features |
| `INDEX.md` | Documentation | This file - complete file inventory |

---

## 📂 lua/gurg/ (Core Configuration)

Core configuration modules loaded before plugins.

| File | Purpose | Key Features |
|------|---------|--------------|
| `lazy.lua` | Plugin Manager Bootstrap | • Installs lazy.nvim if missing<br>• Loads options & keymaps<br>• Imports all plugin configs from `plugins/` |
| `options.lua` | Vim Options | • Line numbers (relative)<br>• Tab/indent settings (4 spaces)<br>• Undo persistence<br>• Search options (smartcase)<br>• `cmdheight=0` (notifications only) |
| `keymaps.lua` | Global Keymaps | • Leader key (`<Space>`)<br>• `_G.setup_lsp_keymaps()` function<br>• LSP keymaps (all servers)<br>• vtsls-specific keymaps<br>• Buffer management<br>• Clipboard operations |

---

## 📂 lua/plugins/ (Plugin Configurations)

All plugins are auto-loaded by lazy.nvim from this directory.

### 🎨 UI & Appearance

| File | Plugin | Purpose |
|------|--------|---------|
| `colors.lua` | kanagawa.nvim, noctis.nvim | Color schemes (Kanagawa active, transparent bg) |
| `colorizer.lua` | nvim-colorizer.lua | Color code highlighting (#RGB, etc.) |
| `mini-statusline.lua` | mini.statusline | Minimal status line |
| `mini-tabline.lua` | mini.tabline | Buffer/tab line |
| `mini-icons.lua` | mini.icons | Icon provider (no patched font needed) |
| `mini-indentscope.lua` | mini.indentscope | Visual indent scope indicator |
| `noice.lua` | noice.nvim | Enhanced UI (command palette, search) |
| `render-markdown.lua` | render-markdown.nvim | Beautiful markdown rendering |

### 🔧 LSP & Development Tools

| File | Plugin | Purpose |
|------|--------|---------|
| `mason.lua` | mason.nvim, mason-lspconfig.nvim | • LSP server management<br>• Auto-install: lua_ls, vtsls, eslint, html, cssls, jsonls, tailwindcss<br>• Uses new `vim.lsp.config` API<br>• Diagnostic configuration<br>• LspAttach autocmd |
| `conform.lua` | conform.nvim | • Format on save<br>• prettierd/prettier for JS/TS/HTML/CSS<br>• stylua for Lua |
| `neotest.lua` | neotest | Testing framework (Jest, Vitest support) |
| `treesitter.lua` | nvim-treesitter | Syntax highlighting & code understanding |
| `ts-comments.lua` | ts-comments.nvim | Smart context-aware commenting |
| `nvim-ts-autotag.lua` | nvim-ts-autotag | Auto-close HTML/JSX tags |

### ✨ Code Editing & Completion

| File | Plugin | Purpose |
|------|--------|---------|
| `blink-cmp.lua` | blink.cmp | • Rust-based completion engine<br>• Sources: LSP, path, snippets, buffer, minuet<br>• Tab/S-Tab navigation<br>• Ghost text enabled |
| `minuet-ai.lua` | minuet-ai.nvim | • AI-powered completions<br>• Ollama local model (qwen2.5-coder:7b)<br>• Fast with small context window |
| `mini-snippets.lua` | mini.snippets | Snippet expansion (used by blink.cmp) |
| `mini-pairs.lua` | mini.pairs | Auto-pair brackets, quotes, etc. |
| `mini-surround.lua` | mini.surround | Surround text objects (ys, ds, cs) |
| `mini-ai.lua` | mini.ai | Enhanced text objects |
| `mini-splitjoin.lua` | mini.splitjoin | Split/join code blocks |
| `mini-move.lua` | mini.move | Move lines/selections |

### 🔍 Navigation & Search

| File | Plugin | Purpose |
|------|--------|---------|
| `mini-pick.lua` | mini.pick | • Fuzzy finder<br>• `<leader><leader>` - Find files (rg)<br>• `<leader>sg` - Live grep<br>• `<leader>es` - Switch buffers<br>• Custom .ripgreprc config |
| `mini-files.lua` | mini.files | • File explorer (default)<br>• `<leader>eb` - Open at current file<br>• `<leader>eB` - Open at cwd<br>• Opens automatically with `nvim .`<br>• Preview enabled |
| `sidekick.lua` | sidekick.nvim | Code outline/symbols viewer |
| `mini-bracketed.lua` | mini.bracketed | Navigate various items with `[` & `]` |

### 📝 Notifications & UI Feedback

| File | Plugin | Purpose |
|------|--------|---------|
| `mini-notify.lua` | mini.notify | • Main notification handler<br>• Custom yank/delete/undo notifications<br>• Priority-based durations<br>• VimEnter autocmd to override vim.notify |
| `mini-clue.lua` | mini.clue | Keymap hints (which-key alternative) |
| `mini-cursorword.lua` | mini.cursorword | Highlight word under cursor |
| `mini-hipatterns.lua` | mini.hipatterns | Pattern highlighting |
| `todo-comments.lua` | todo-comments.nvim | Highlight TODO, FIXME, etc. |

### 🗂️ Git Integration

| File | Plugin | Purpose |
|------|--------|---------|
| `lazygit.lua` | lazygit.nvim | LazyGit TUI integration (`<leader>lg`) |
| `mini-git.lua` | mini.git | Git integration |
| `mini-diff.lua` | mini.diff | Git diff signs in gutter |

### 🔧 Utilities

| File | Plugin | Purpose |
|------|--------|---------|
| `undotree.lua` | undotree.vim | Visualize undo history tree |
| `mini-trailspace.lua` | mini.trailspace | Highlight & remove trailing whitespace |
| `mini-extra.lua` | mini.extra | Extra mini.nvim utilities |
| `editorconfig.lua` | editorconfig-vim | .editorconfig support |
| `package-info.lua` | package-info.nvim | Show package.json versions |
| `vimbegood.lua` | vim-be-good | Vim practice game |

---

## 📊 Statistics

### File Counts
- **Total Files**: 43 files
- **Core Config**: 3 files (`lua/gurg/`)
- **Plugin Configs**: 38 files (`lua/plugins/`)
- **Documentation**: 2 files (README.md, INDEX.md)

### Plugin Categories
- **UI & Appearance**: 9 plugins
- **LSP & Development**: 6 plugins
- **Code Editing**: 8 plugins
- **Navigation**: 4 plugins
- **Notifications**: 5 plugins
- **Git Integration**: 3 plugins
- **Utilities**: 7 plugins

### Mini.nvim Modules (20 total)
1. mini.ai
2. mini.bracketed
3. mini.clue
4. mini.cursorword
5. mini.diff
6. mini.extra
7. mini.files
8. mini.git
9. mini.hipatterns
10. mini.icons
11. mini.indentscope
12. mini.move
13. mini.notify
14. mini.pairs
15. mini.pick
16. mini.snippets
17. mini.splitjoin
18. mini.statusline
19. mini.surround
20. mini.tabline
21. mini.trailspace

---

## 🗺️ Key Mappings Quick Reference

### Leader Key: `<Space>`

#### LSP Operations (`<leader>l`)
| Key | Action | Availability |
|-----|--------|-------------|
| `<leader>la` | Code Action | All LSP buffers |
| `<leader>lr` | Rename | All LSP buffers |
| `<leader>lf` | Format | All LSP buffers |
| `<leader>ls` | Signature Help | All LSP buffers |
| `<leader>ld` | Show Diagnostics | All LSP buffers |
| `<leader>lq` | Diagnostics List | All LSP buffers |
| `<leader>lo` | Organize Imports | vtsls only |
| `<leader>li` | Add Missing Imports | vtsls only |
| `<leader>lu` | Remove Unused | vtsls only |
| `<leader>lx` | Fix All | vtsls only |
| `<leader>lg` | LazyGit | Global |
| `<leader>lm` | Mason | Global |
| `<leader>ln` | Lazy | Global |

#### File Explorer (`<leader>e`)
| Key | Action |
|-----|--------|
| `<leader>eb` | File Browser (current file) |
| `<leader>eB` | File Browser (cwd) |
| `<leader>es` | Switch Buffer |

#### Search (`<leader>s`)
| Key | Action |
|-----|--------|
| `<leader>sg` | Live Grep |
| `<leader>sr` | Replace Word |
| `<leader><leader>` | Find Files |

#### Buffer/Quit (`<leader>q`)
| Key | Action |
|-----|--------|
| `<leader>qq` | Close Buffer (smart) |
| `<leader>qo` | Close Other Buffers |
| `<leader>qa` | Close All Buffers |
| `<leader>Q` | Quit Neovim (no save) |

#### File Operations (`<leader>w`)
| Key | Action |
|-----|--------|
| `<leader>w` | Save File |
| `<leader>wq` | Save & Close Buffer |

#### Clipboard (`<leader>y/p/d`)
| Key | Action |
|-----|--------|
| `<leader>y` | Copy to Clipboard |
| `<leader>Y` | Copy Line to Clipboard |
| `<leader>p` | Paste (keep register) |
| `<leader>d` | Delete to Void (visual) |

#### Diagnostics (Global)
| Key | Action |
|-----|--------|
| `[d` | Previous Diagnostic |
| `]d` | Next Diagnostic |
| `K` | Hover Documentation |

---

## 🔍 File Dependencies

### Load Order
1. **init.lua** → loads `gurg/lazy.lua`
2. **gurg/lazy.lua** → loads:
   - `gurg/options.lua` (Vim settings)
   - `gurg/keymaps.lua` (Global keymaps & LSP function)
   - `plugins/*.lua` (Auto-imported by lazy.nvim)
3. **Plugin configs** → Load based on lazy.nvim events/keys

### Critical Dependencies
- **mini.notify** must load first (priority = 1000) to capture all notifications
- **mason.lua** configures LSP → uses `_G.setup_lsp_keymaps` from keymaps.lua
- **blink-cmp.lua** depends on mini.snippets
- **minuet-ai.lua** integrates with blink-cmp as a completion source

---

## 📦 Generated Files (Not in Version Control)

These files are auto-generated and should be in `.gitignore`:

- `.luarc.json` - Lua LSP workspace config
- `.ripgreprc` - Ripgrep config (auto-created by mini-pick.lua)
- `lazy-lock.json` - Plugin versions (should be committed)

---

## 🔧 Configuration Conventions

### File Structure
- All plugin configs return a table (or array of tables)
- Each plugin config is self-contained
- Lazy-loading via `keys`, `event`, `ft`, or `lazy = false`

### Naming
- Core configs: `lua/gurg/*.lua`
- Plugin configs: `lua/plugins/<plugin-name>.lua`
- Mini.nvim plugins: `lua/plugins/mini-<module>.lua`

### LSP Integration
- All LSP servers get automatic keymaps via `_G.setup_lsp_keymaps()`
- Server-specific features added in keymaps.lua with `if client.name == 'server'`
- Diagnostic config centralized in mason.lua

---

## 📚 Related Documentation

- **Full Guide**: See [README.md](./README.md)
- **Plugin Docs**: Each plugin file contains inline documentation
- **Neovim Help**: `:help <topic>` in Neovim
- **Mini.nvim**: https://github.com/echasnovski/mini.nvim

---

**Last Updated**: December 9, 2025  
**Neovim Version**: 0.11+  
**Total Lines of Config**: ~2,500+ lines across 43 files

