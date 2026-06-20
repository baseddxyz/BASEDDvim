-- ts_ls (typescript-language-server) config, with @vue/typescript-plugin for .vue support.
-- Shared on_attach + capabilities come from the wildcard default set in
-- lua/plugins/lspconfig.lua.
--
-- The Vue plugin `location` is resolved PER-ATTACH in before_init from the
-- workspace root the LSP client already computed (params.rootUri), NOT frozen
-- at config load. This fixes N2: the old code used vim.fn.getcwd() at load
-- time, which froze the path to the launch dir and broke .vue support when
-- opening a different project or after :cd.
return {
	filetypes = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
		"vue",
	},
	-- Static plugin scaffolding; the `location` is injected per-attach below.
	init_options = {
		plugins = {},
	},
	-- Mutate params.initializationOptions (NOT config.init_options): params is
	-- the actual initialize payload sent to the server, and mutating it is
	-- per-attach (config is shared across attaches; mutating it would leak).
	before_init = function(params, config)
		-- Reuse the workspace root the client already resolved. Prefer rootUri
		-- (file:// URI), fall back to rootPath (deprecated but present).
		local root
		if params.rootUri then
			root = vim.uri_to_fname(params.rootUri)
		elseif params.rootPath then
			root = params.rootPath
		end
		if not root or root == "" then
			return
		end

		-- Only inject the Vue plugin if it's actually installed in this project
		-- (check package.json, not just the dir — a failed npm install can leave
		-- an empty dir). Plain JS/TS projects without Vue skip this cleanly.
		local plugin_path = root .. "/node_modules/@vue/typescript-plugin"
		local marker = plugin_path .. "/package.json"
		if vim.fn.filereadable(marker) ~= 1 then
			return
		end

		-- Defensive: ensure the plugins table exists on the params being sent.
		params.initializationOptions = params.initializationOptions or {}
		params.initializationOptions.plugins = params.initializationOptions.plugins or {}

		table.insert(params.initializationOptions.plugins, {
			name = "@vue/typescript-plugin",
			location = plugin_path,
			languages = {
				"javascript",
				"javascriptreact",
				"typescript",
				"typescriptreact",
				"vue",
			},
		})
	end,
}
