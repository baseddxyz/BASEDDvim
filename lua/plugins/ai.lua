return {
	{
		'supermaven-inc/supermaven-nvim',
		event = 'BufReadPre',
		config = function()
			require('supermaven-nvim').setup({
				disable_inline_completion = true,
			})
		end,
	}
}
