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
				animate = { enabled = false },
			},
			indent = {
				animate = { enabled = false },
				chunk = { enabled = true },
			},
			picker = {
				layout = {
					cycle = true,
					--- Use the default layout or vertical if the window is too narrow
					preset = function()
						return vim.o.columns >= 120 and "default" or "vertical"
					end,
				},
			},
			image = {},
		},
		keys = {
			-- { "<c-/>", function() Snacks.terminal() end, desc = "Toggle Terminal"},
			{
				"<leader>rr",
				function()
					Snacks.rename.rename_file()
				end,
				desc = "Rename File",
			},
			{
				"<leader>ff",
				function()
					Snacks.picker.files()
				end,
				desc = "Find Files",
			},
			{
				"<leader>fw",
				function()
					Snacks.picker.grep()
				end,
				desc = "Grep",
			},
			{
				"<leader>fb",
				function()
					Snacks.picker.buffers()
				end,
				desc = "Buffers",
			},
		},
		init = function()
			local Snacks = require("snacks")
			Snacks.keymap.set({ "n", "v" }, "<leader>y", '"+y', { desc = "Copy to clipboard" })

			vim.api.nvim_create_autocmd("User", {
				pattern = "VeryLazy",
				callback = function()
					-- Create some toggle mappings
					Snacks.toggle.dim():map("<leader>uD")
				end,
			})
		end,
	},
}
