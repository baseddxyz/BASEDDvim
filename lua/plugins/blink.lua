local configs = require('configs')

local blink_default_config = {
	'saghen/blink.cmp',
	lazy = false,
	dependencies = {
		{ 'rafamadriz/friendly-snippets' },
	},
	version = '*',

	---@module 'blink.cmp'
	---@type blink.cmp.Config
	opts = {
		keymap = {
			['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
			['<C-e>'] = { 'hide' },
			['<CR>'] = { 'select_and_accept', 'fallback' },

			['<C-p>'] = { 'select_prev', 'fallback' },
			['<C-n>'] = { 'select_next', 'fallback' },

			['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
			['<C-f>'] = { 'scroll_documentation_down', 'fallback' },

			['<Tab>'] = { 'snippet_forward', 'fallback' },
			['<S-Tab>'] = { 'snippet_backward', 'fallback' },
		},
		completion = {
			menu = {
				draw = {
					columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind", gap = 1 } },
				}
			}
		},
		sources = {
			default = { 'lsp', 'path', 'snippets', 'buffer' },
			cmdline = {}
		},
		signature = { enabled = true }
	},
}

local ai_config = configs.ai and configs.ai.enabled
		and {
			dependencies = {
				{ 'rafamadriz/friendly-snippets' },
				{ 'supermaven-inc/supermaven-nvim' },
			},
			opts = {
				sources = {
					default = { 'lsp', 'path', 'snippets', 'buffer', 'supermaven' },
					providers = {
						supermaven = {
							name = 'supermaven',
							module = 'blink.compat.source',

							opts = {}
						}
					},
				},
			}
		}
		or {}

local blink_final_config = vim.tbl_deep_extend('force', blink_default_config, ai_config)

return {
	{ 'saghen/blink.compat' },
	blink_final_config,
}
