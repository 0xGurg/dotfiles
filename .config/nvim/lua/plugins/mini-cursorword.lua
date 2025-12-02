return {
	'echasnovski/mini.cursorword',
	version = '*',
	event = 'VeryLazy',
	config = function()
		require('mini.cursorword').setup({
			delay = 100,
		})
	end
}

