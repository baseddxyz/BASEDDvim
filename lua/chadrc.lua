local M = {}

M.base46 = {
	theme = 'catppuccin',
}

M.lsp = {
	signature = true,
}

M.ui = {
	cmp = {
		format_colors = {
			tailwind = true,
		}
	},
	tabufline = {
		enabled = false,
	},
	statusline = {
		theme = "minimal"
	}
}

return M
