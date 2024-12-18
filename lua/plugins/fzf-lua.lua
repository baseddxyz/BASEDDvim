return {
	{
		"ibhagwan/fzf-lua",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		keys = {
			{ "<leader>ff", "<cmd>lua require('fzf-lua').files({ fzf_opts = { ['--layout'] = 'reverse-list' } })<cr>" },
			{ "<leader>fw", "<cmd>lua require('fzf-lua').live_grep_native({ fzf_opts = { ['--layout'] = 'reverse-list' } })<cr>" },
			{ "<leader>fb", "<cmd>lua require('fzf-lua').buffers({ fzf_opts = { ['--layout'] = 'reverse-list' } })<cr>" },
		},
		config = true,
	}
}
