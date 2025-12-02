return {
	'folke/todo-comments.nvim',
	event = 'VeryLazy',
	dependencies = { 'nvim-lua/plenary.nvim' },
	keys = {
		{ ']T', function() require('todo-comments').jump_next() end, desc = 'Next TODO' },
		{ '[T', function() require('todo-comments').jump_prev() end, desc = 'Prev TODO' },
	},
	opts = {
		signs = true,
		keywords = {
			FIX = { icon = ' ', color = 'error', alt = { 'FIXME', 'BUG', 'FIXIT', 'ISSUE' } },
			TODO = { icon = ' ', color = 'info' },
			HACK = { icon = ' ', color = 'warning' },
			WARN = { icon = ' ', color = 'warning', alt = { 'WARNING', 'XXX' } },
			PERF = { icon = ' ', color = 'default', alt = { 'OPTIM', 'PERFORMANCE', 'OPTIMIZE' } },
			NOTE = { icon = ' ', color = 'hint', alt = { 'INFO' } },
			TEST = { icon = '⏲ ', color = 'test', alt = { 'TESTING', 'PASSED', 'FAILED' } },
		},
		-- Highlight the keyword and text after it
		highlight = {
			before = '',
			keyword = 'wide',
			after = 'fg',
			pattern = [[.*<(KEYWORDS)\s*:]],
			comments_only = true,
		},
	},
}


