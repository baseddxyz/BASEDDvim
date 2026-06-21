vim.cmd("set noexpandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")

vim.cmd("set relativenumber")

vim.g.mapleader = " "

-- mappings
local map = vim.keymap.set

-- buffer
map("n", "<TAB>", "<cmd>bnext<cr>", { desc = "Go to next buffer" })
map("n", "<S-TAB>", "<cmd>bprevious<cr>", { desc = "Go to previes buffer" })
map("n", "<leader>x", "<cmd>bdelete<cr>", { desc = "Delete Buffer" })
map("n", "<leader>X", "<cmd>bd!<cr>", { desc = "Force Delete Buffer" })

-- diagnostic
local diagnostic_goto = function(next, severity)
	severity = severity and vim.diagnostic.severity[severity] or nil
	return function()
		if next then
			vim.diagnostic.jump({ count = 1, float = true, severity = severity })
		else
			vim.diagnostic.jump({ count = -1, float = true, severity = severity })
		end
	end
end

map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
map("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
map("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
map("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
map("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
map("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })

-- Tiered diagnostic display (model borrowed from baseddxyz/paketo):
-- - underline everything (HINT..ERROR) so anything off is always visible
-- - signs in the gutter for WARN+ERROR
-- - inline virtual text ONLY for ERROR, ONLY on the current line
-- - no updates while typing (stable view)
vim.diagnostic.config({
	signs = { priority = 9999, severity = { min = "WARN", max = "ERROR" } },
	underline = { severity = { min = "HINT", max = "ERROR" } },
	virtual_lines = false,
	virtual_text = { current_line = true, severity = { min = "ERROR", max = "ERROR" } },
	update_in_insert = false,
})

vim.opt.conceallevel = 1
