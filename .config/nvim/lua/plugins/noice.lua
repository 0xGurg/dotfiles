return {
	'folke/noice.nvim',
	event = 'VeryLazy',
	dependencies = {
		'MunifTanjim/nui.nvim',
		'echasnovski/mini.notify',
	},
	config = function()
		require('noice').setup({
			lsp = {
				override = {
					['vim.lsp.util.convert_input_to_markdown_lines'] = true,
					['vim.lsp.util.stylize_markdown'] = true,
					['cmp.entry.get_documentation'] = true,
				},
			},
			presets = {
				bottom_search = true,
				command_palette = true,
				long_message_to_split = true,
				inc_rename = false,
				lsp_doc_border = false,
			},
			-- Disable noice's cmdline and message views (keep only search/command palette)
			cmdline = {
				enabled = true, -- Keep command palette
				view = "cmdline_popup",
			},
			popupmenu = {
				enabled = true, -- Keep popup menu
			},
			notify = {
				enabled = false, -- Disable noice notifications - use mini.notify
			},
		})
	end
}
