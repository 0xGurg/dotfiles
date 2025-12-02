-- ============================================================================
-- Leader Key
-- ============================================================================
vim.g.mapleader = " "

-- ============================================================================
-- Global LSP Keymap Setup Function
-- ============================================================================
-- This function is called by all LSP servers when they attach to a buffer
_G.setup_lsp_keymaps = function(client, bufnr)
	local opts = { buffer = bufnr, silent = true }

	-- <leader>l prefix - LSP Actions (buffer-local)
	vim.keymap.set('n', '<leader>la', vim.lsp.buf.code_action, vim.tbl_extend('force', opts, { desc = 'Code Action' }))
	vim.keymap.set('n', '<leader>lr', vim.lsp.buf.rename, vim.tbl_extend('force', opts, { desc = 'Rename' }))
	vim.keymap.set('n', '<leader>lf', function()
		-- Try conform first, fallback to LSP
		local ok, conform = pcall(require, 'conform')
		if ok and conform then
			conform.format({ async = true, lsp_fallback = true })
		else
			vim.lsp.buf.format({ async = true })
		end
	end, vim.tbl_extend('force', opts, { desc = 'Format' }))
	vim.keymap.set('n', '<leader>ls', vim.lsp.buf.signature_help,
		vim.tbl_extend('force', opts, { desc = 'Signature' }))
	vim.keymap.set('n', '<leader>ld', vim.diagnostic.open_float,
		vim.tbl_extend('force', opts, { desc = 'Diagnostics' }))
	vim.keymap.set('n', '<leader>lq', vim.diagnostic.setloclist,
		vim.tbl_extend('force', opts, { desc = 'Diagnostics List' }))

	-- Hover documentation
	vim.keymap.set('n', 'K', vim.lsp.buf.hover, vim.tbl_extend('force', opts, { desc = 'Hover' }))

	-- vtsls-specific keymaps
	if client.name == 'vtsls' then
		vim.keymap.set('n', '<leader>lo', function()
			vim.lsp.buf.code_action({
				apply = true,
				context = {
					---@diagnostic disable-next-line: assign-type-mismatch
					only = { 'source.organizeImports.ts' },
					diagnostics = {}
				}
			})
		end, vim.tbl_extend('force', opts, { desc = 'Organize Imports' }))

		vim.keymap.set('n', '<leader>li', function()
			vim.lsp.buf.code_action({
				apply = true,
				context = {
					---@diagnostic disable-next-line: assign-type-mismatch
					only = { 'source.addMissingImports.ts' },
					diagnostics = {}
				}
			})
		end, vim.tbl_extend('force', opts, { desc = 'Add Missing Imports' }))

		vim.keymap.set('n', '<leader>lu', function()
			vim.lsp.buf.code_action({
				apply = true,
				context = {
					---@diagnostic disable-next-line: assign-type-mismatch
					only = { 'source.removeUnused.ts' },
					diagnostics = {}
				}
			})
		end, vim.tbl_extend('force', opts, { desc = 'Remove Unused Imports' }))

		vim.keymap.set('n', '<leader>lx', function()
			vim.lsp.buf.code_action({
				apply = true,
				context = {
					---@diagnostic disable-next-line: assign-type-mismatch
					only = { 'source.fixAll.ts' },
					diagnostics = {}
				}
			})
		end, vim.tbl_extend('force', opts, { desc = 'Fix All' }))
	end

	-- Visual indicator that LSP is attached
	vim.notify(string.format('LSP attached: %s', client.name), vim.log.levels.DEBUG)

	-- Refresh mini.clue to show new buffer-local keymaps
	vim.schedule(function()
		local ok, miniclue = pcall(require, 'mini.clue')
		if ok and miniclue.refresh then
			miniclue.refresh()
		end
	end)
end

-- ============================================================================
-- Diagnostic Navigation (global keymaps, work for all buffers)
-- ============================================================================
vim.keymap.set('n', '[d', function() vim.diagnostic.jump({ count = -1 }) end, { desc = 'Previous Diagnostic' })
vim.keymap.set('n', ']d', function() vim.diagnostic.jump({ count = 1 }) end, { desc = 'Next Diagnostic' })

-- ============================================================================
-- Better Defaults (movement & navigation improvements)
-- ============================================================================
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join Lines" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll Down (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll Up (centered)" })
vim.keymap.set("n", "n", "nzzzv", { desc = "Next Search (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Prev Search (centered)" })
vim.keymap.set("n", "=ai", "ma=ap'a", { desc = "Format Paragraph" })
vim.keymap.set("n", "Q", "<nop>", { desc = "Disable Ex mode" })

-- ============================================================================
-- Clipboard Operations (yank, paste, delete)
-- ============================================================================
-- Yank to system clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Copy to Clipboard" })
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = "Copy Line to Clipboard" })

-- Paste without replacing register
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste (keep register)" })

-- Delete to void register is defined in mini-notify.lua with notification

-- ============================================================================
-- Buffer & Quit Management (<leader>q)
-- ============================================================================
-- Smart buffer close with unsaved warning
local function close_buffer()
	local force = false

	-- Check if buffer has unsaved changes
	if vim.bo.modified then
		local choice = vim.fn.confirm("Buffer has unsaved changes. Close anyway?", "&Yes\n&No\n&Save", 2)
		if choice == 1 then -- Yes
			force = true
		elseif choice == 3 then -- Save
			vim.cmd("w")
		else
			return -- No, cancel
		end
	end

	-- Check if this is the last buffer
	local buffers = vim.fn.getbufinfo({ buflisted = 1 })
	if #buffers > 1 then
		-- Switch to previous buffer, then delete the one we were on
		vim.cmd(force and "bp|bd! #" or "bp|bd #")
	else
		-- Last buffer - just delete it (creates empty buffer)
		vim.cmd(force and "bd!" or "bd")
	end
end

vim.keymap.set("n", "<leader>qq", close_buffer, { desc = "Close Buffer" })
vim.keymap.set("n", "<leader>qo", "<cmd>%bd|e#|bd#<cr>", { desc = "Close Other Buffers" })
vim.keymap.set("n", "<leader>qa", "<cmd>%bd!<cr>", { desc = "Close All Buffers" })
vim.keymap.set("n", "<leader>Q", "<cmd>qa!<cr>", { desc = "Quit Neovim (no save)" })

-- ============================================================================
-- File Operations (<leader>w)
-- ============================================================================
vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", { desc = "Save File" })
vim.keymap.set("n", "<leader>wq", "<cmd>w|bp|bd! #<cr>", { desc = "Save & Close Buffer" })


-- ============================================================================
-- Search & Replace (<leader>s)
-- ============================================================================
vim.keymap.set("n", "<leader>sr", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Replace Word" })

-- ============================================================================
-- Utilities
-- ============================================================================
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true, desc = "Make Executable" })

-- ============================================================================
-- LSP & Plugin Management
-- ============================================================================
vim.keymap.set("n", "<leader>lg", "<cmd>LazyGit<CR>", { desc = "[Global] LazyGit" })
vim.keymap.set("n", "<leader>lm", "<cmd>Mason<CR>", { desc = "[Global] Mason" })
vim.keymap.set("n", "<leader>ln", "<cmd>Lazy<CR>", { desc = "[Global] Lazy" })
