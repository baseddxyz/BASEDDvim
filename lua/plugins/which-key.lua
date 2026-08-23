return {
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			preset = "modern",
			sort = { "alphanum", "local" },
			spec = {
				{ "<leader>f", group = "Find" },
				{ "<leader>c", group = "Code" },
				{ "<leader>t", group = "Toggle/Trouble" },
				{ "<leader>a", group = "AI/Sidekick" },
				{ "<leader>9", group = "99" },
				{ "<leader>u", group = "UI" },
				{ "]", group = "Next" },
				{ "[", group = "Prev" },
			},
		},
		keys = {
			{
				"<leader>?",
				function()
					require("which-key").show({ global = false })
				end,
				desc = "Buffer Keymaps (which-key)",
			},
		},
	},
}
