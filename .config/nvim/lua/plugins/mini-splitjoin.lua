return {
	'echasnovski/mini.splitjoin',
	version = '*',
	event = 'VeryLazy',
	config = function()
		require('mini.splitjoin').setup({
			-- sj to toggle split/join
			mappings = {
				toggle = 'sj',
				split = '',
				join = '',
			},
		})
	end
}

