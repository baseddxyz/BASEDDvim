return {
	-- mini.nvim
	{
		'echasnovski/mini.nvim',
		version = false
	},
	{
		'echasnovski/mini.pick',
		version = false,
		config = true,
		lazy = true,
		keys = {
			{ '<leader>ff', '<cmd>Pick files<cr>' },
			{ '<leader>fw', '<cmd>Pick grep_live<cr>' },
			{ '<leader>fb', '<cmd>Pick buffers<cr>' },
		},
	},
	{ 'echasnovski/mini.starter', version = false, config = true },
	{
		'echasnovski/mini.basics',
		version = false,
		opts = {
			mappings = {
				windows = true,
				move_with_alt = true,
			},
		},
	},
	{
		'echasnovski/mini.files',
		version = false,
		keys = function()
			local MiniFiles = require('mini.files')

			return {
				{ '<leader>e', function() MiniFiles.open() end },
			}
		end,
	},
	{
		'echasnovski/mini.statusline',
		version = false,
		config = true,
		dependencies = {
			{ "nvim-tree/nvim-web-devicons" },
		},
	},
	{
		'echasnovski/mini.tabline',
		version = false,
		config = true,
		dependencies = {
			{ "nvim-tree/nvim-web-devicons" },
		},
	},
	{
		'echasnovski/mini.pairs',
		event = 'VeryLazy',
		version = false,
		opts = {
			modes = { insert = true, command = true, terminal = false },
			-- skip autopair when next character is one of these
			skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
			-- skip autopair when the cursor is inside these treesitter nodes
			skip_ts = { 'string' },
			-- skip autopair when next character is closing pair
			-- and there are more closing pairs than opening pairs
			skip_unbalanced = true,
			-- better deal with markdown code blocks
			markdown = true,
		},
		config = function(_, opts)
			-- copy from https://github.com/LazyVim/LazyVim/blob/12818a6cb499456f4903c5d8e68af43753ebc869/lua/lazyvim/util/mini.lua#L123-L168
			local pairs = require('mini.pairs')
			pairs.setup(opts)
			local open = pairs.open
			pairs.open = function(pair, neigh_pattern)
				if vim.fn.getcmdline() ~= "" then
					return open(pair, neigh_pattern)
				end
				local o, c = pair:sub(1, 1), pair:sub(2, 2)
				local line = vim.api.nvim_get_current_line()
				local cursor = vim.api.nvim_win_get_cursor(0)
				local next = line:sub(cursor[2] + 1, cursor[2] + 1)
				local before = line:sub(1, cursor[2])
				if opts.markdown and o == "`" and vim.bo.filetype == "markdown" and before:match("^%s*``") then
					return "`\n```" .. vim.api.nvim_replace_termcodes("<up>", true, true, true)
				end
				if opts.skip_next and next ~= "" and next:match(opts.skip_next) then
					return o
				end
				if opts.skip_ts and #opts.skip_ts > 0 then
					local ok, captures = pcall(vim.treesitter.get_captures_at_pos, 0, cursor[1] - 1,
						math.max(cursor[2] - 1, 0))
					for _, capture in ipairs(ok and captures or {}) do
						if vim.tbl_contains(opts.skip_ts, capture.capture) then
							return o
						end
					end
				end
				if opts.skip_unbalanced and next == c and c ~= o then
					local _, count_open = line:gsub(vim.pesc(pair:sub(1, 1)), "")
					local _, count_close = line:gsub(vim.pesc(pair:sub(2, 2)), "")
					if count_close > count_open then
						return o
					end
				end
				return open(pair, neigh_pattern)
			end
		end,
	},
	{
		'echasnovski/mini.comment',
		version = false,
		opts = {
			mappings = {
				comment = '<leader>/',
				comment_line = '<leader>/',
				comment_visual = '<leader>/',
				textobject = '<leader>/',
			}
		},
	},
	{
		'echasnovski/mini.notify',
		version = false,
		config = true,
	},
}
