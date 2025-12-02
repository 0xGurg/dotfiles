return {
	'norcalli/nvim-colorizer.lua',
	event = 'BufReadPost',
	config = function()
		require('colorizer').setup({
			'css', 'scss', 'html', 'javascript', 'typescript',
			'javascriptreact', 'typescriptreact', 'lua', 'vue', 'svelte',
		}, {
			RGB = true,
			RRGGBB = true,
			names = false,
			RRGGBBAA = true,
			css = true,
			css_fn = true,
			tailwind = true,
		})
	end
}

