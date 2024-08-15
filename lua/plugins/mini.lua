return {
	{
		"echasnovski/mini.nvim",
		version = false,
	},
	{
		"echasnovski/mini.comment",
		version = false,
		opts = {
			mappings = {
				comment = "<leader>/",
				comment_line = "<leader>/",
				comment_visual = "<leader>/",
				textobjectr= "<leader>/",
			},
		}
	},
	{
		"echasnovski/mini.tabline",
		version = false,
		config = true,
		dependencies = {
			{ "nvim-tree/nvim-web-devicons" },
		},
	},
}
