return {
	{
		'nvim-telescope/telescope-fzf-native.nvim',
		build = 'make',
	},
	{
		'nvim-telescope/telescope.nvim',
		dependencies = {
			'nvim-lua/plenary.nvim',
			'nvim-treesitter/nvim-treesitter',
			'nvim-tree/nvim-web-devicons',
		},
		cmd = 'Telescope',
		keys = {
			{ '<leader>ff', '<cmd>Telescope find_files<cr>' },
			{ '<leader>fw', '<cmd>Telescope live_grep<cr>' },
			{ '<leader>fb', '<cmd>Telescope buffers<cr>' },
		},
		opts = {
			defaults = {
				prompt_prefix = "   ",
				selection_caret = " ",
				entry_prefix = " ",
				sorting_strategy = "ascending",
				layout_config = {
					horizontal = {
						prompt_position = "top",
						preview_width = 0.55,
					},
					width = 0.87,
					height = 0.80,
				},
				mappings = {
					n = { ["q"] = require("telescope.actions").close },
				},
			},
		},
		config = function(_, opts)
			local telescope = require('telescope')
			telescope.setup(opts)

			-- load_extension
			telescope.load_extension('fzf')
		end
	},
}
