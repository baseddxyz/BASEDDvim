local configs = require("configs")

return configs.ai and configs.ai.enabled and {
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
			gemini = function()
				return require("codecompanion.adapters").extend("gemini", {
					schema = {
						model = {
							default = "gemini-2.0-flash-exp",
						},
					},
					env = {
						api_key = "GEMINI_API_KEY",
					},
				})
			end,
			display = {
				diff = {
					provider = "mini_diff",
				},
			},
		},
	},
} or {}
