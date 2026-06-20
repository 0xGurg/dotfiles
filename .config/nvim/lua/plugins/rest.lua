return {
	"rest-nvim/rest.nvim",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"j-hui/fidget.nvim", -- GH version has fidget.progress; LuaRocks version doesn't
	},
	config = function()
		-- Force-load fidget so fidget.progress is available when rest.nvim's curl client loads
		require("fidget")

		vim.g.rest_nvim = {
			-- Skip SSL verification (toggle per-request with @skipSsl)
			request = {
				skip_ssl_verification = false,
				hooks = {
					encode_url = true,
					set_content_type = true,
				},
			},
			-- Env file auto-discovery (matches *.env*, e.g. .env, .env.local, .env.production)
			env = {
				enable = true,
				pattern = ".*%.env.*",
			},
			-- Persist cookies between requests
			cookies = {
				enable = true,
			},
			-- Show timing/size stats in result winbar
			clients = {
				curl = {
					statistics = {
						{ id = "time_total", winbar = "take", title = "Time taken" },
						{ id = "size_download", winbar = "size", title = "Download size" },
					},
				},
			},
			-- Highlight the request line briefly on execution
			highlight = {
				enable = true,
				timeout = 750,
			},
			-- Result pane navigation
			ui = {
				winbar = true,
				keybinds = {
					prev = "H",
					next = "L",
				},
			},
		}

		-- Keymaps
		local map = vim.keymap.set
		local opts = { noremap = true, silent = true }

		map("n", "<leader>rr", "<cmd>Rest run<CR>", vim.tbl_extend("force", opts, { desc = "Run Request" }))
		map("n", "<leader>rl", "<cmd>Rest last<CR>", vim.tbl_extend("force", opts, { desc = "Rerun Last Request" }))
		map("n", "<leader>ro", "<cmd>Rest open<CR>", vim.tbl_extend("force", opts, { desc = "Open Result Pane" }))
		map("n", "<leader>re", "<cmd>Rest env select<CR>", vim.tbl_extend("force", opts, { desc = "Select Env File" }))
		map("n", "<leader>rc", "<cmd>Rest cookies<CR>", vim.tbl_extend("force", opts, { desc = "Edit Cookies" }))
	end,
}
