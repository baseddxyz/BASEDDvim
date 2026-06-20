-- ts_ls (typescript-language-server) config, with @vue/typescript-plugin for .vue support.
-- Shared on_attach + capabilities come from the wildcard default set in
-- lua/plugins/lspconfig.lua.
--
-- NOTE (deferred N2): the `location` below is resolved once at config load
-- via vim.fn.getcwd(), so it is frozen to the launch dir. Moving it here
-- isolates the bug; a per-attach fix via `before_init` is a follow-up.
return {
	filetypes = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
		"vue",
	},
	init_options = {
		plugins = {
			{
				name = "@vue/typescript-plugin",
				location = vim.fn.getcwd() .. "/node_modules/@vue/typescript-plugin",
				languages = {
					"javascript",
					"javascriptreact",
					"typescript",
					"typescriptreact",
					"vue",
				},
			},
		},
	},
}
