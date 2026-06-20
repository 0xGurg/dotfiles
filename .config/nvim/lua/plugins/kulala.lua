return {
	"mistweaverco/kulala.nvim",
	version = "*",
	-- Only activate on .http files for gRPC; rest.nvim handles HTTP
	ft = { "http", "rest" },
	keys = {
		{ "<leader>gr", desc = "Send Request (gRPC/HTTP)" },
		{ "<leader>gl", desc = "Replay Last Request" },
		{ "<leader>gb", desc = "Open Scratchpad" },
		{ "<leader>gn", desc = "Jump Next Request" },
		{ "<leader>gp", desc = "Jump Prev Request" },
	},
	opts = {
		-- Don't register global keymaps (we define our own above)
		global_keymaps = false,
		-- Default view when opening result
		default_view = "body",
		-- Enable Lua/JS scripting in request files
		scripts_enabled = true,
		-- Environment resolution
		environment_scope = "b",
	},
	config = function(_, opts)
		require("kulala").setup(opts)

		-- Bind keymaps
		local map = vim.keymap.set
		local key_opts = { noremap = true, silent = true }

		map("n", "<leader>gr", function() require("kulala").run() end,
			vim.tbl_extend("force", key_opts, { desc = "Send Request (gRPC/HTTP)" }))
		map("n", "<leader>gl", function() require("kulala").replay() end,
			vim.tbl_extend("force", key_opts, { desc = "Replay Last Request" }))
		map("n", "<leader>gb", function() require("kulala").scratchpad() end,
			vim.tbl_extend("force", key_opts, { desc = "Open Scratchpad" }))
		map("n", "<leader>gn", function() require("kulala").jump_next() end,
			vim.tbl_extend("force", key_opts, { desc = "Jump Next Request" }))
		map("n", "<leader>gp", function() require("kulala").jump_prev() end,
			vim.tbl_extend("force", key_opts, { desc = "Jump Prev Request" }))
	end,
}
