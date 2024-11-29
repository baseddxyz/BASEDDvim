return {
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
			rename = { enabled = true },
			-- terminal = { enabled = true },
		},
		keys ={
			-- { "<c-/>", function() Snacks.terminal() end, desc = "Toggle Terminal"},
			{ "<leader>rr", function() Snacks.rename.rename_file() end, desc = "Rename File" },
		},
		init = function()
		end
	}
}
