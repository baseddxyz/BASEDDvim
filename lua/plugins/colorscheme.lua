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
	{
		"comfysage/evergarden",
		priority = 1000, -- Colorscheme plugin is loaded first before any other plugins
		opts = {
			transparent_background = true,
			contrast_dark = 'hard', -- 'hard'|'medium'|'soft'
			overrides = {},      -- add custom overrides
		},
		config = function(_, opts)
			require("evergarden").setup(opts)
			vim.cmd("colorscheme evergarden")
		end,
	}
}
