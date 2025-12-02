return {
	'echasnovski/mini.pick',
	version = '*',
	keys = {
		{
			"<leader><leader>",
			function() require('mini.pick').builtin.files({ tool = 'rg' }) end,
			desc = "Find Files",
		},
		{ "<leader>es", "<cmd>Pick buffers<cr>", desc = "Switch Buffer" },
		{ "<leader>sg", "<cmd>Pick grep_live<cr>", desc = "Live Grep" },
	},
	config = function()
		-- Set RIPGREP_CONFIG_PATH to use custom rg config with hidden files
		local rg_config = vim.fn.stdpath('config') .. '/.ripgreprc'
		vim.env.RIPGREP_CONFIG_PATH = rg_config

		-- Create .ripgreprc if it doesn't exist
		if vim.fn.filereadable(rg_config) == 0 then
			vim.fn.writefile({
				'--hidden',
				'--no-ignore',
				'--glob=!.git',
				'--glob=!node_modules',
				'--glob=!dist',
				'--glob=!build',
				'--glob=!.next',
				'--glob=!out',
				'--glob=!coverage',
				'--glob=!.turbo',
				'--glob=!target',
				'--glob=!vendor',
			}, rg_config)
		end

		require('mini.pick').setup({
			options = {
				use_cache = true,
			},
		})
	end
}
