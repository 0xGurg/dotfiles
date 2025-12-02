return {
	'echasnovski/mini.nvim',
	name = 'mini.git',
	version = '*',
	config = function()
		require('mini.git').setup({
			-- Job management
			job = {
				git_executable = 'git',
				timeout = 30000,
			},
			-- Command options
			command = {
				split = 'auto',
			},
		})
	end
}
