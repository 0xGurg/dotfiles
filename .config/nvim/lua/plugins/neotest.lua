return {
	'nvim-neotest/neotest',
	dependencies = {
		'nvim-neotest/nvim-nio',
		'nvim-lua/plenary.nvim',
		'antoinemadec/FixCursorHold.nvim',
		'nvim-treesitter/nvim-treesitter',
		-- Test adapters
		'nvim-neotest/neotest-jest',
		'marilari88/neotest-vitest',
	},
	keys = {
		{ '<leader>tt', function() require('neotest').run.run() end,                                        desc = 'Run Nearest Test' },
		{ '<leader>tf', function() require('neotest').run.run(vim.fn.expand('%')) end,                      desc = 'Run Test File' },
		{ '<leader>ta', function() require('neotest').run.run(vim.fn.getcwd()) end,                         desc = 'Run All Tests' },
		{ '<leader>ts', function() require('neotest').summary.toggle() end,                                 desc = 'Toggle Test Summary' },
		{ '<leader>to', function() require('neotest').output.open({ enter = true, auto_close = true }) end, desc = 'Show Test Output' },
		{ '<leader>tO', function() require('neotest').output_panel.toggle() end,                            desc = 'Toggle Test Output Panel' },
		{ '<leader>tS', function() require('neotest').run.stop() end,                                       desc = 'Stop Test' },
		{ '<leader>tw', function() require('neotest').watch.toggle(vim.fn.expand('%')) end,                 desc = 'Toggle Watch Test File' },
	},
	config = function()
		require('neotest').setup({
			adapters = {
				require('neotest-jest')({
					jestCommand = 'npm test --',
					jestConfigFile = 'jest.config.js',
					env = { CI = true },
					cwd = function()
						return vim.fn.getcwd()
					end,
				}),
				require('neotest-vitest')({
					vitestCommand = 'npm test --',
					vitestConfigFile = 'vitest.config.js',
				}),
			},
			icons = {
				passed = '✓',
				running = '⟳',
				failed = '✗',
				skipped = '⊘',
				unknown = '?',
			},
			floating = {
				border = 'rounded',
				max_height = 0.6,
				max_width = 0.6,
			},
			summary = {
				open = 'botright vsplit | vertical resize 50',
			},
		})
	end
}
