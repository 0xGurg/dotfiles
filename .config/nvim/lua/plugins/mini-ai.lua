return {
	'echasnovski/mini.ai',
	version = '*',
	event = 'VeryLazy',
	config = function()
		local ai = require('mini.ai')
		ai.setup({
			n_lines = 500,
			custom_textobjects = {
				-- Function (treesitter-based)
				f = ai.gen_spec.treesitter({ a = '@function.outer', i = '@function.inner' }),
				-- Class
				c = ai.gen_spec.treesitter({ a = '@class.outer', i = '@class.inner' }),
				-- Block (if, for, while, etc.)
				o = ai.gen_spec.treesitter({
					a = { '@block.outer', '@conditional.outer', '@loop.outer' },
					i = { '@block.inner', '@conditional.inner', '@loop.inner' },
				}),
			},
		})
	end
}

