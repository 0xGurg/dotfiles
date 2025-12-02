return {
	'vuki656/package-info.nvim',
	dependencies = { 'MunifTanjim/nui.nvim' },
	ft = 'json',
	keys = {
		{ '<leader>ns', function() require('package-info').show() end, desc = 'Show Package Versions' },
		{ '<leader>nh', function() require('package-info').hide() end, desc = 'Hide Package Versions' },
		{ '<leader>nu', function() require('package-info').update() end, desc = 'Update Package' },
		{ '<leader>nd', function() require('package-info').delete() end, desc = 'Delete Package' },
		{ '<leader>ni', function() require('package-info').install() end, desc = 'Install Package' },
		{ '<leader>nc', function() require('package-info').change_version() end, desc = 'Change Version' },
	},
	config = function()
		require('package-info').setup({
			autostart = true,
			hide_up_to_date = true,
		})
	end
}

