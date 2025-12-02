return {
	'echasnovski/mini.trailspace',
	version = '*',
	event = 'VeryLazy',
	config = function()
		require('mini.trailspace').setup()

		-- Trim trailing whitespace on save
		vim.api.nvim_create_autocmd('BufWritePre', {
			callback = function()
				-- Skip certain filetypes
				local ft = vim.bo.filetype
				if ft == 'markdown' or ft == 'diff' then
					return
				end
				MiniTrailspace.trim()
				MiniTrailspace.trim_last_lines()
			end,
		})
	end
}

