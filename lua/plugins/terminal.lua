return {
	{
		'akinsho/toggleterm.nvim',
		version = '*',
		config = function()
			require('toggleterm').setup{}
			vim.keymap.set('n', '<leader>tf', '<cmd>ToggleTerm direction=float<cr>')
		end,
	}
}
