return {
	-- -- autocompletion
	-- {
	-- 	"iguanacucumber/magazine.nvim",
	-- 	name = "nvim-cmp",
	-- 	version = false,
	-- 	event = 'InsertEnter',
	-- 	config = function()
	-- 		vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
	-- 		local cmp = require 'cmp'
	-- 		local defaults = require('cmp.config.default')()
	-- 		require("luasnip.loaders.from_vscode").lazy_load()
	--
	-- 		cmp.setup({
	-- 			completion = {
	-- 				completeopt = "menu,menuone,noinsert",
	-- 			},
	-- 			snippet = {
	-- 				-- REQUIRED - you must specify a snippet engine
	-- 				expand = function(args)
	-- 					require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
	-- 				end,
	-- 			},
	-- 			window = {
	-- 				completion = cmp.config.window.bordered(),
	-- 				documentation = cmp.config.window.bordered(),
	-- 			},
	-- 			mapping = cmp.mapping.preset.insert({
	-- 				["<TAB>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
	-- 				["<S-TAB>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
	-- 				['<C-b>'] = cmp.mapping.scroll_docs(-4),
	-- 				['<C-f>'] = cmp.mapping.scroll_docs(4),
	-- 				['<C-Space>'] = cmp.mapping.complete(),
	-- 				['<C-e>'] = cmp.mapping.abort(),
	-- 				['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
	-- 			}),
	-- 			sources = cmp.config.sources({
	-- 				{ name = 'nvim_lsp' },
	-- 				{ name = 'luasnip' }, -- For luasnip users.
	-- 			}, {
	-- 				{ name = 'buffer' },
	-- 				{ name = 'path' },
	-- 			}),
	-- 			formatting = {
	-- 				format = function(_, item)
	-- 					local icons = require("configs").icons.kinds
	-- 					if icons[item.kind] then
	-- 						item.kind = icons[item.kind] .. item.kind
	-- 					end
	-- 					return item
	-- 				end,
	-- 			},
	-- 			experimental = {
	-- 				ghost_text = {
	-- 					hl_group = "CmpGhostText",
	-- 				},
	-- 			},
	-- 			sorting = defaults.sorting,
	-- 		})
	-- 	end,
	-- 	dependencies = {
	-- 		{ 'hrsh7th/cmp-nvim-lsp' },
	-- 		{ 'hrsh7th/cmp-buffer' },
	-- 		{ 'hrsh7th/cmp-path' },
	-- 		{
	-- 			'L3MON4D3/LuaSnip',
	-- 			dependencies = {
	-- 				{ 'saadparwaiz1/cmp_luasnip' },
	-- 				{ 'rafamadriz/friendly-snippets' },
	-- 			},
	-- 		},
	-- 	},
	-- },

	{ 'saghen/blink.compat' },
	{
		'saghen/blink.cmp',
		lazy = false,
		dependencies = 'rafamadriz/friendly-snippets',
		build = 'cargo build --release',

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
			-- keymap = {
			-- 	accept = '<CR>',
			-- 	select_next = { '<UP>', '<TAB>' },
			-- 	select_prev = { '<DOWN>', '<S-TAB>' },
			--
			-- 	snippet_forward = '<C-n>',
			-- 	snippet_backward = '<C-p>',
			-- },
			nerd_font_variant = 'mono',
			trigger = {
				signature_help = {
					enabled = true,
				}
			},
			providers = {
				supermaven = {
					name = 'supermaven',
					module = 'blink.compat.sources'
				}
			}
		},
	}
}
