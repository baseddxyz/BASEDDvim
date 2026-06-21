-- ruff (Astral's Python linter) LSP config.
-- Base config (cmd, filetypes, root_markers) comes from nvim-lspconfig's
-- shipped lsp/ruff.lua — this file only overrides what differs.
-- Shared on_attach + capabilities come from the wildcard default in
-- lua/plugins/lspconfig.lua.
--
-- Disable ruff LSP's organizeImports so it doesn't conflict with conform's
-- ruff_organize_imports formatter (the single source of truth for import
-- sorting on save). ruff still provides lint diagnostics + code actions.
return {
	init_options = {
		settings = {
			organizeImports = false,
		},
	},
}
