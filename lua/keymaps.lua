local M = {}

-- Standard LSP keymaps used across all LSP clients
function M.lsp(opts)
	opts = opts or {}

	local keymaps = {
		{ "n", "gD", vim.lsp.buf.declaration, opts },
		{ "n", "gd", vim.lsp.buf.definition, opts },
		{ "n", "K", vim.lsp.buf.hover, opts },
		{ "n", "gi", vim.lsp.buf.implementation, opts },
		{ "n", "<C-k>", vim.lsp.buf.signature_help, opts },
		{ "n", "<leader>D", vim.lsp.buf.type_definition, opts },
		{ "n", "<leader>rn", vim.lsp.buf.rename, opts },
		{ { "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts },
		{ "n", "gr", vim.lsp.buf.references, opts },
	}

	-- Apply keymaps using vim.keymap.set for now (can switch to Snacks later)
	for _, keymap in ipairs(keymaps) do
		vim.keymap.set(keymap[1], keymap[2], keymap[3], keymap[4])
	end
end

-- Format keymap (optional, used by some LSP clients)
function M.lsp_format(opts)
	opts = opts or {}
	vim.keymap.set("n", "<leader>fm", function()
		local ok, conform = pcall(require, "conform")
		if ok then
			conform.format({
				lsp_fallback = true,
				async = false,
				timeout_ms = 500,
			})
		else
			vim.lsp.buf.format({ async = true })
		end
	end, opts)
end

return M

