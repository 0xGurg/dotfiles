return {
	'milanglacier/minuet-ai.nvim',
	event = 'VeryLazy',
	dependencies = {
		'nvim-lua/plenary.nvim',
	},
	config = function()
		require('minuet').setup({
			provider = 'openai_fim_compatible',
			n_completions = 1,

			-- Minimal context for maximum speed
			context_window = 1024, -- Small context for instant responses

			provider_options = {
				openai_fim_compatible = {
					api_key = 'TERM',
					name = 'Ollama',
					end_point = 'http://localhost:11434/v1/completions',
					model = 'qwen2.5-coder:7b',
					optional = {
						max_tokens = 192, -- Longer completions
						top_p = 0.9,
						temperature = 0.3,
						-- Keep model loaded for faster subsequent requests
						num_predict = 192,
					},
				},
			},

			-- Longer timeout for longer completions
			request_timeout = 5,

			-- Only show important notifications
			notify = 'warn',
		})
	end,
}
