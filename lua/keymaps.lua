local M = {}

-- Standard LSP keymaps used across all LSP clients
function M.lsp(opts)
	opts = opts or {}

	local keymaps = {
		{ "n", "gD", vim.lsp.buf.declaration, opts },
		{ "n", "gd", vim.lsp.buf.definition, opts },
		{ "n", "K", vim.lsp.buf.hover, opts },
		{ "n", "gi", vim.lsp.buf.implementation, opts },
		-- NOTE: <C-k> stays with tmux-navigator; blink.cmp signature help covers this
		{ "n", "<leader>D", vim.lsp.buf.type_definition, opts },
		{ "n", "<leader>rn", vim.lsp.buf.rename, opts },
		{ { "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts },
		{ "n", "gr", vim.lsp.buf.references, opts },
	}

	for _, keymap in ipairs(keymaps) do
		vim.keymap.set(keymap[1], keymap[2], keymap[3], keymap[4])
	end
end

return M
