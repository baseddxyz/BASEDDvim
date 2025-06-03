return {
	{
		"obsidian-nvim/obsidian.nvim",
		version = "*",
		lazy = true,
		ft = "markdown",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"saghen/blink.cmp", -- optional
			"folke/snacks.nvim", -- optional
		},
		opts = {
			workspaces = {
				{
					name = "personal",
					path = "~/vaults/personal",
				},
			},
			completion = {
				nvim_cmp = false,
				blink = true,
			},
			picker = {
				name = "snacks.pick",
			}
		},
	},
	{
		"bngarren/checkmate.nvim",
		ft = "markdown",
		opts = {},
	}
}
