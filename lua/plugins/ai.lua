return {
	{
		'supermaven-inc/supermaven-nvim',
		event = 'BufReadPre',
		config = function()
			require('supermaven-nvim').setup({})
		end,
	}
}
