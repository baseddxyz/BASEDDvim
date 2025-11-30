return {
	-- {
	-- 	"neanias/everforest-nvim",
	-- 	lazy = false,
	-- 	priority = 1000,
	-- 	opts = {
	-- 		background = "hard"
	-- 	},
	-- 	config = function(_, opts)
	-- 		require('everforest').setup(opts)
	-- 		vim.cmd('colorscheme everforest')
	-- 	end,
	-- },
	-- {
	-- 	"ellisonleao/gruvbox.nvim",
	-- 	priority = 1000,
	-- 	config = function(_, opts)
	-- 		require("gruvbox").setup(opts)
	-- 		vim.o.background = "dark"
	-- 		vim.cmd("colorscheme gruvbox")
	-- 	end,
	-- },
	-- {
	-- 	"folke/tokyonight.nvim",
	-- 	lazy = false,
	-- 	priority = 1000,
	-- 	opts = {},
	-- 	config = function(_, opts)
	-- 		require("tokyonight").setup(opts)
	-- 		vim.cmd("colorscheme tokyonight-night")
	-- 	end,
	-- },
	-- {
	-- 	"comfysage/evergarden",
	-- 	lazy = false,
	-- 	priority = 1000,
	-- 	opts = {
	-- 		theme = {
	-- 			variant = "winter", -- "winter"|"fall"|"spring"
	-- 			accent = "green",
	-- 		},
	-- 	},
	-- 	config = function(_, opts)
	-- 		require("evergarden").setup(opts)
	-- 		vim.cmd("colorscheme evergarden")
	-- 	end,
	-- }
	-- {
	-- 	"ribru17/bamboo.nvim",
	-- 	lazy = false,
	-- 	priority = 1000,
	-- 	config = function()
	-- 		require("bamboo").setup({
	-- 			style = "multiplex",
	-- 		})
	-- 		require("bamboo").load()
	-- 	end,
	-- },
	{
		"everviolet/nvim",
		name = "evergarden",
		priority = 1000, -- Colorscheme plugin is loaded first before any other plugins
		opts = {
			theme = {
				variant = "fall", -- 'winter'|'fall'|'spring'|'summer'
				accent = "green",
			},
			editor = {
				transparent_background = false,
				sign = { color = "none" },
				float = {
					color = "mantle",
					solid_border = false,
				},
				completion = {
					color = "surface0",
				},
			},
		},
		config = function(_, opts)
			require("evergarden").setup(opts)
			vim.cmd("colorscheme evergarden")
		end,
	},
}
