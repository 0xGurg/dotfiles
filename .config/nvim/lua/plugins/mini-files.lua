return {
	'echasnovski/mini.files',
	version = '*',
	config = function()
		local width_focus = 30
		-- Calculate preview width: remaining space minus focus window and padding
		local width_preview = math.max(vim.o.columns - width_focus - 12, 40)

		require('mini.files').setup({
			options = {
				use_as_default_explorer = true,
			},
			windows = {
				preview = true,
				width_focus = width_focus,
				width_preview = width_preview,
			},
		})

		-- Open file browser at current file location
		vim.keymap.set("n", "<leader>eb", function()
			MiniFiles.open(vim.api.nvim_buf_get_name(0), true)
		end, { desc = "File Browser (current file)" })

		-- Open at cwd
		vim.keymap.set("n", "<leader>eB", function()
			MiniFiles.open()
		end, { desc = "File Browser (cwd)" })
	end
}
