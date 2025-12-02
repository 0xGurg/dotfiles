return {
	'saghen/blink.cmp',
	dependencies = {
		'echasnovski/mini.snippets',
	},
	version = 'v0.*',
	opts = {
		keymap = {
			preset = 'default',
			['<Tab>'] = { 'select_and_accept', 'snippet_forward', 'fallback' },
			['<S-Tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },
			['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
			['<C-e>'] = { 'hide', 'fallback' },
			['<CR>'] = { 'accept', 'fallback' },
			['<C-p>'] = { 'select_prev', 'fallback' },
			['<C-n>'] = { 'select_next', 'fallback' },
			['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
			['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
		},
		appearance = {
			use_nvim_cmp_as_default = true,
			nerd_font_variant = 'mono'
		},
		-- Use mini.snippets for snippet expansion
		snippets = {
			preset = 'mini_snippets',
		},
		sources = {
			default = { 'lsp', 'path', 'snippets', 'buffer', 'minuet' },
			providers = {
				snippets = {
					min_keyword_length = 1,
					score_offset = 5, -- Higher priority to show snippets
				},
				minuet = {
					name = 'minuet',
					module = 'minuet.blink',
					score_offset = 8, -- Higher priority for AI completions
					async = true,
				},
			},
		},
		completion = {
			menu = {
				border = 'rounded',
				draw = {
					columns = { { 'label', 'label_description', gap = 1 }, { 'kind_icon', 'kind' } },
				},
			},
			documentation = {
				auto_show = true,
				auto_show_delay_ms = 200,
				window = {
					border = 'rounded',
				},
			},
			ghost_text = {
				enabled = true,
			},
		},
		signature = {
			enabled = true,
			window = {
				border = 'rounded',
			},
		},
	},
}
