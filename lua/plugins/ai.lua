local configs = require("configs")

if not configs.ai.enabled then
	return {}
end

return {
	{
		'supermaven-inc/supermaven-nvim',
		event = 'BufReadPre',
		config = function()
			require('supermaven-nvim').setup({
				disable_inline_completion = true,
			})
		end,
	},
	{
		"olimorris/codecompanion.nvim",
		cmd = {
			'CodeCompanion',
			'CodeCompanionActions',
			'CodeCompanionChat',
			'CodeCompanionCmd',
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			{
				"MeanderingProgrammer/render-markdown.nvim",
				ft = { "markdown", "codecompanion" }
			},
		},
		opts = {
			strategies = {
				chat = {
					adapter = "gemini",
				},
				inline = {
					adapter = "gemini",
				},
			},
			display = {
				diff = {
					provider = "mini_diff",
				},
			},
			gemini = function()
				return require("codecompanion.adapters").extend("gemini", {
					env = {
						api_key = "GEMINI_API_KEY",
					}
				})
			end
		},
	},
}
