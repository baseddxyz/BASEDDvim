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
	-- {
	-- 	"bjarneo/aether.nvim",
	-- 	name = "aether",
	-- 	priority = 1000,
	-- 	opts = {
	-- 		disable_italics = false,
	-- 		colors = {
	-- 			-- Monotone shades (base00-base07)
	-- 			base00 = "#0F1B1D", -- Default background
	-- 			base01 = "#6b8d94", -- Lighter background (status bars)
	-- 			base02 = "#0F1B1D", -- Selection background
	-- 			base03 = "#6b8d94", -- Comments, invisibles
	-- 			base04 = "#F3BF5D", -- Dark foreground
	-- 			base05 = "#fde2af", -- Default foreground
	-- 			base06 = "#fde2af", -- Light foreground
	-- 			base07 = "#F3BF5D", -- Light background
	--
	-- 			-- Accent colors (base08-base0F)
	-- 			base08 = "#c27166", -- Variables, errors, red
	-- 			base09 = "#dfaca5", -- Integers, constants, orange
	-- 			base0A = "#F4AE59", -- Classes, types, yellow
	-- 			base0B = "#8dac8b", -- Strings, green
	-- 			base0C = "#a5cfcd", -- Support, regex, cyan
	-- 			base0D = "#93bfc2", -- Functions, keywords, blue
	-- 			base0E = "#e09785", -- Keywords, storage, magenta
	-- 			base0F = "#fdd8ab", -- Deprecated, brown/yellow
	-- 		},
	-- 	},
	-- 	config = function(_, opts)
	-- 		require("aether").setup(opts)
	-- 		vim.cmd.colorscheme("aether")
	--
	-- 		-- Enable hot reload
	-- 		require("aether.hotreload").setup()
	-- 	end,
	-- },
	{
		"gthelding/monokai-pro.nvim",
		priority = 1000,
		opts = {
			filter = "machine", -- classic | octagon | pro | machine | ristretto | spectrum
			override = function()
				return {
					NonText = { fg = "#948a8b" },
					MiniIconsGrey = { fg = "#948a8b" },
					MiniIconsRed = { fg = "#fd6883" },
					MiniIconsBlue = { fg = "#85dacc" },
					MiniIconsGreen = { fg = "#adda78" },
					MiniIconsYellow = { fg = "#f9cc6c" },
					MiniIconsOrange = { fg = "#f38d70" },
					MiniIconsPurple = { fg = "#a8a9eb" },
					MiniIconsAzure = { fg = "#a8a9eb" },
					MiniIconsCyan = { fg = "#85dacc" }, -- same value as MiniIconsBlue for consistency
				}
			end,
			background_clear = { "float_win" },
		},
		config = function(_, opts)
			require("monokai-pro").setup(opts)
			vim.cmd.colorscheme("monokai-pro")
		end,
	},

	-- {
	-- 	"everviolet/nvim",
	-- 	name = "evergarden",
	-- 	priority = 1000, -- Colorscheme plugin is loaded first before any other plugins
	-- 	opts = {
	-- 		theme = {
	-- 			variant = "fall", -- 'winter'|'fall'|'spring'|'summer'
	-- 			accent = "green",
	-- 		},
	-- 		editor = {
	-- 			transparent_background = false,
	-- 			sign = { color = "none" },
	-- 			float = {
	-- 				color = "mantle",
	-- 				solid_border = false,
	-- 			},
	-- 			completion = {
	-- 				color = "surface0",
	-- 			},
	-- 		},
	-- 	},
	-- 	config = function(_, opts)
	-- 		require("evergarden").setup(opts)
	-- 		vim.cmd("colorscheme evergarden")
	-- 	end,
	-- },
}
