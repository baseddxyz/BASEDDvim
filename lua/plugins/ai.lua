return {
	{
		'monkoose/neocodeium',
		event = 'VeryLazy',
		config = function()
			local neocodeium = require('neocodeium')
			local support_filetypes = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' }
			neocodeium.setup({
				filetypes = {
					TelescopePrompt = false
				},
				filter = function(bufnr)
					if vim.tbl_contains(support_filetypes, vim.api.nvim_get_option_value('filetype', { buf = bufnr })) then
						return true
					end
					return false
				end
			})
			vim.keymap.set("i", "<M-l>", neocodeium.accept)
		end
	}
}
