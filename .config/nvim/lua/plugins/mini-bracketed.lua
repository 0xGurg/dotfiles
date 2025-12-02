return {
	'echasnovski/mini.bracketed',
	version = '*',
	event = 'VeryLazy',
	config = function()
		require('mini.bracketed').setup({
			-- Navigate with [x and ]x where x is:
			buffer     = { suffix = 'b', options = {} }, -- [b ]b - buffers
			comment    = { suffix = 'c', options = {} }, -- [c ]c - comments
			conflict   = { suffix = 'x', options = {} }, -- [x ]x - git conflicts
			diagnostic = { suffix = '', options = {} },  -- disabled (you have [d ]d custom)
			file       = { suffix = 'f', options = {} }, -- [f ]f - files in directory
			indent     = { suffix = 'i', options = {} }, -- [i ]i - indent changes
			jump       = { suffix = 'j', options = {} }, -- [j ]j - jumplist
			location   = { suffix = 'l', options = {} }, -- [l ]l - location list
			oldfile    = { suffix = 'o', options = {} }, -- [o ]o - old files
			quickfix   = { suffix = 'q', options = {} }, -- [q ]q - quickfix
			treesitter = { suffix = 't', options = {} }, -- [t ]t - treesitter nodes
			undo       = { suffix = 'u', options = {} }, -- [u ]u - undo states
			window     = { suffix = 'w', options = {} }, -- [w ]w - windows
			yank       = { suffix = 'y', options = {} }, -- [y ]y - yank history
		})
	end
}

