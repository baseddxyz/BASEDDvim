vim.opt.expandtab = false
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2

vim.opt.relativenumber = true

-- search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- persistence / responsiveness
vim.opt.undofile = true
vim.opt.updatetime = 250

-- window behavior
vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.termguicolors = true

vim.g.mapleader = " "

-- mappings
local map = vim.keymap.set

-- buffer
map("n", "<TAB>", "<cmd>bnext<cr>", { desc = "Go to next buffer" })
map("n", "<S-TAB>", "<cmd>bprevious<cr>", { desc = "Go to previous buffer" })
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

vim.diagnostic.config({
	virtual_text = true,
	-- virtual_lines = true,
})

-- conceal markers only in filetypes that benefit from it
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "markdown", "json", "jsonc" },
	callback = function()
		-- conceallevel is window-local; FileType fires in the buffer's window
		vim.wo.conceallevel = 1
	end,
})
