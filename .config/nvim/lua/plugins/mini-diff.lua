return {
	'echasnovski/mini.nvim',
	name = 'mini.diff',
	version = '*',
	config = function()
		require('mini.diff').setup({
			view = {
				style = 'sign',
				signs = {
					add = '▎',
					change = '▎',
					delete = '▎',
				},
			},
			mappings = {
				apply = 'gh',
				reset = 'gH',
				textobject = 'gh',
				goto_first = '[H',
				goto_prev = '[h',
				goto_next = ']h',
				goto_last = ']H',
			},
			options = {
				algorithm = 'histogram',
				indent_heuristic = true,
				linematch = 60,
			},
		})
	end
}
