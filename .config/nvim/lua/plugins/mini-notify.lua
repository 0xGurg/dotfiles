return {
	'echasnovski/mini.notify',
	version = '*',
	lazy = false, -- Load immediately at startup
	priority = 1000, -- Load before other plugins
	config = function()
		local notify = require('mini.notify')
		notify.setup()

		-- Set DEBUG to use WARN colors
		vim.api.nvim_set_hl(0, 'MiniNotifyDebug', { link = 'DiagnosticWarn' })

		-- Override vim.notify to use mini.notify (show all levels including DEBUG)
		vim.notify = notify.make_notify({
			ERROR = { duration = 10000 },
			WARN  = { duration = 5000 },
			INFO  = { duration = 5000 },  -- Increased from 3000 to 5000
			DEBUG = { duration = 2000 },
			TRACE = { duration = 2000 },
		})

		-- Re-override after other plugins load (in case noice overrides it)
		vim.api.nvim_create_autocmd("VimEnter", {
			callback = function()
				vim.schedule(function()
					-- Set DEBUG to use WARN colors
					vim.api.nvim_set_hl(0, 'MiniNotifyDebug', { link = 'DiagnosticWarn' })

					vim.notify = notify.make_notify({
						ERROR = { duration = 10000 },
						WARN  = { duration = 5000 },
						INFO  = { duration = 5000 },  -- Increased from 3000 to 5000
						DEBUG = { duration = 2000 },
						TRACE = { duration = 2000 },
					})
					-- Notify current working directory
					local cwd = vim.fn.getcwd()
					vim.notify(string.format("CWD: %s", cwd), vim.log.levels.INFO)
				end)
			end,
		})

		-- Show notification when text is yanked or deleted
		local yank_group = vim.api.nvim_create_augroup('YankNotification', { clear = true })
		vim.api.nvim_create_autocmd('TextYankPost', {
			group = yank_group,
			callback = function()
				-- Visual highlight of yanked text
				vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 200 })

				local event = vim.v.event
				local lines = event.regcontents or {}
				local line_count = #lines
				local regname = event.regname or ''
				local operator = event.operator
				local regtype = event.regtype

				-- Skip void register operations (leader d) - handled separately
				if regname == '_' then
					return
				end

				-- Get content preview (first line or combined if short)
				local preview = ''
				if line_count == 1 then
					preview = lines[1]
				elseif line_count > 1 then
					-- For multi-line, show first line
					preview = lines[1]
				end

				-- Remove leading and trailing spaces
				preview = preview:gsub('^%s+', ''):gsub('%s+$', '')

				-- Truncate preview if too long
				local max_length = 50
				if #preview > max_length then
					preview = preview:sub(1, max_length) .. '...'
				end

				-- Handle clipboard yanks (leader y/Y)
				if regname == '+' or regname == '*' then
					if regtype == 'V' or regtype == '\x16' then -- linewise or block
						local line_word = line_count == 1 and 'line' or 'lines'
						vim.notify(string.format('Yanked %d %s to clipboard: %s', line_count, line_word, preview),
							vim.log.levels.INFO)
					else
						vim.notify(string.format('Yanked to clipboard: %s', preview), vim.log.levels.INFO)
					end
					return
				end

				-- Format message based on operation
				local line_word = line_count == 1 and 'line' or 'lines'

				if operator == 'd' then
					-- For deletes, only show "deleted X lines" for linewise deletes
					if regtype == 'V' or regtype == '\x16' then -- linewise or block
						local message = string.format('Deleted %d %s: %s', line_count, line_word, preview)
						vim.notify(message, vim.log.levels.INFO)
					else
						-- For character-wise deletes, just show "Deleted: content"
						local message = string.format('Deleted: %s', preview)
						vim.notify(message, vim.log.levels.INFO)
					end
				else
					-- Regular yank
					if regtype == 'V' or regtype == '\x16' then -- linewise or block
						local message = string.format('Yanked %d %s: %s', line_count, line_word, preview)
						vim.notify(message, vim.log.levels.INFO)
					else
						-- For character-wise yanks, just show "Yanked: content"
						local message = string.format('Yanked: %s', preview)
						vim.notify(message, vim.log.levels.INFO)
					end
				end
			end,
		})

		-- Override leader d to show void delete notification (visual mode)
		vim.keymap.set("v", "<leader>d", function()
			-- Visual mode - get selection first for preview
			local start_pos = vim.fn.getpos("'<")
			local end_pos = vim.fn.getpos("'>")
			local start_line = start_pos[2]
			local end_line = end_pos[2]
			local line_count = end_line - start_line + 1

			-- Delete to void register
			vim.cmd('normal! "_d')

			-- Show notification
			if line_count > 1 then
				vim.notify(string.format('Deleted %d lines to void register', line_count), vim.log.levels.INFO)
			else
				vim.notify('Deleted to void register', vim.log.levels.INFO)
			end
		end, { desc = "Delete (void register)" })

		-- Override leader d to show void delete notification (normal mode)
		vim.keymap.set("n", "<leader>d", function()
			-- Normal mode - need motion
			vim.o.operatorfunc = 'v:lua._void_delete_opfunc'
			return 'g@'
		end, { expr = true, desc = "Delete (void register)" })

		-- Opfunc for leader d motion
		_G._void_delete_opfunc = function(type)
			local start_pos = vim.fn.getpos("'[")
			local end_pos = vim.fn.getpos("']")

			-- Delete to void register
			vim.cmd('normal! `[v`]"_d')

			-- Show notification
			if type == 'line' then
				local line_count = end_pos[2] - start_pos[2] + 1
				vim.notify(string.format('Deleted %d lines to void register', line_count), vim.log.levels.INFO)
			else
				vim.notify('Deleted to void register', vim.log.levels.INFO)
			end
		end

		-- Map undo/redo to show notifications
		vim.keymap.set('n', 'u', function()
			local undolevels_before = vim.fn.undotree().seq_cur
			vim.cmd('silent! undo')
			local undolevels_after = vim.fn.undotree().seq_cur

			if undolevels_before == undolevels_after then
				vim.notify('Already at oldest change', vim.log.levels.WARN)
			else
				vim.defer_fn(function()
					local changes = vim.fn.undotree().seq_last - undolevels_after
					vim.notify(string.format('Undo: now at change #%d', undolevels_after), vim.log.levels.INFO)
				end, 10)
			end
		end, { desc = 'Undo with notification' })

		-- Redo with Ctrl-r
		vim.keymap.set('n', '<C-r>', function()
			local undolevels_before = vim.fn.undotree().seq_cur
			vim.cmd('silent! redo')
			local undolevels_after = vim.fn.undotree().seq_cur

			if undolevels_before == undolevels_after then
				vim.notify('Already at newest change', vim.log.levels.WARN)
			else
				vim.defer_fn(function()
					vim.notify(string.format('Redo: now at change #%d', undolevels_after), vim.log.levels.INFO)
				end, 10)
			end
		end, { desc = 'Redo with notification' })

		-- Redo with Cmd-r (macOS)
		vim.keymap.set('n', '<D-r>', function()
			local undolevels_before = vim.fn.undotree().seq_cur
			vim.cmd('silent! redo')
			local undolevels_after = vim.fn.undotree().seq_cur

			if undolevels_before == undolevels_after then
				vim.notify('Already at newest change', vim.log.levels.WARN)
			else
				vim.defer_fn(function()
					vim.notify(string.format('Redo: now at change #%d', undolevels_after), vim.log.levels.INFO)
				end, 10)
			end
		end, { desc = 'Redo with notification (Cmd-r)' })
	end
}
