return {
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
			-- terminal = { enabled = true },
			rename = { enabled = true },
			dim = {
				animate = { enabled = false }
			},
			indent = {
				animate = { enabled = false },
				chunk = { enabled = true },
			},
		},
		keys = {
			-- { "<c-/>", function() Snacks.terminal() end, desc = "Toggle Terminal"},
			{ "<leader>rr", function() Snacks.rename.rename_file() end, desc = "Rename File" },
		},
		init = function()
			vim.api.nvim_create_autocmd("User", {
				pattern = "VeryLazy",
				callback = function()

					-- Create some toggle mappings
					Snacks.toggle.dim():map("<leader>uD")
				end,
			})
		end
	}
}
