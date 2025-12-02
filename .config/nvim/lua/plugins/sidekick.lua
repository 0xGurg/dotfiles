return {
	'folke/sidekick.nvim',
	event = 'VeryLazy',
	opts = {
		-- NES (Next Edit Suggestions) - Disable since we're using minuet-ai
		nes = {
			enabled = false,
		},

		-- AI CLI Integration
		cli = {
			enabled = true,

			-- Terminal multiplexer for persistent sessions
			mux = {
				enabled = false, -- Set to true if you have tmux/zellij
				backend = 'tmux', -- or 'zellij'
			},

			-- AI CLI tools configuration
			tools = {
				-- Cursor CLI agent with Claude Sonnet 4.5
				cursor = {
					enabled = true,
					cmd = { 'cursor', 'agent', '--model', 'sonnet-4.5-thinking' },
				},
			},

			-- Default tool to use
			default = 'cursor',

			-- Custom prompts for your workflow
			prompts = {
				explain = 'Explain this code in detail',
				refactor = 'Refactor this code to be more maintainable and efficient',
				fix = 'Fix any bugs or issues in this code',
				tests = 'Write comprehensive tests for this code',
				docs = 'Add detailed documentation comments to this code',
				optimize = 'Optimize this code for better performance',
				review = 'Review this code and suggest improvements',
			},

			-- Window configuration
			win = {
				position = 'right',
				size = 0.4,
				border = 'rounded',
			},
		},
	},
	keys = {
		-- CLI commands
		{ '<leader>ai', '<cmd>Sidekick cli toggle<cr>', desc = 'Toggle AI CLI', mode = { 'n', 'v' } },
		{ '<leader>ac', '<cmd>Sidekick cli close<cr>',  desc = 'Close AI CLI' },
		{ '<leader>ap', '<cmd>Sidekick cli prompt<cr>', desc = 'Select Prompt', mode = { 'n', 'v' } },

		-- Send selection to AI
		{
			'<leader>aa',
			function()
				require('sidekick.cli').send({ msg = vim.fn.getreg('"') })
			end,
			desc = 'Ask AI',
			mode = { 'v' }
		},
	},
}
