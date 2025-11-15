return {
	-- mini.nvim
	{
		"nvim-mini/mini.nvim",
		version = false,
	},
	-- {
	-- 	'nvim-mini/mini.pick',
	-- 	version = false,
	-- 	config = true,
	-- 	lazy = true,
	-- 	keys = {
	-- 		{ '<leader>ff', '<cmd>Pick files<cr>' },
	-- 		{ '<leader>fw', '<cmd>Pick grep_live<cr>' },
	-- 		{ '<leader>fb', '<cmd>Pick buffers<cr>' },
	-- 	},
	-- },
	{
		"nvim-mini/mini.icons",
		version = false,
		config = true,
	},
	{
		"nvim-mini/mini.starter",
		version = false,
		config = function()
			local logo = table.concat({
				"██████╗  █████╗ ███████╗███████╗██████╗ ██████╗ ",
				"██╔══██╗██╔══██╗██╔════╝██╔════╝██╔══██╗██╔══██╗",
				"██████╔╝███████║███████╗█████╗  ██║  ██║██║  ██║",
				"██╔══██╗██╔══██║╚════██║██╔══╝  ██║  ██║██║  ██║",
				"██████╔╝██║  ██║███████║███████╗██████╔╝██████╔╝",
				"╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝ ╚═════╝ ",
				"                                                ",
			}, "\n")

			require("mini.starter").setup({
				header = logo,
			})
		end,
	},
	{
		"nvim-mini/mini.basics",
		version = false,
		opts = {
			mappings = {
				windows = true,
				move_with_alt = true,
			},
		},
	},
	{
		"nvim-mini/mini.files",
		version = false,
		keys = function()
			local MiniFiles = require("mini.files")

			return {
				{
					"<leader>e",
					function()
						MiniFiles.open()
					end,
				},
			}
		end,
	},
	{
		"nvim-mini/mini.statusline",
		version = false,
		config = true,
	},
	-- {
	-- 	'nvim-mini/mini.tabline',
	-- 	version = false,
	-- 	config = true,
	-- },
	{
		"nvim-mini/mini.pairs",
		event = "InsertEnter",
		version = false,
		opts = {
			modes = { insert = true, command = true, terminal = false },
			-- skip autopair when next character is one of these
			skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
			-- skip autopair when the cursor is inside these treesitter nodes
			skip_ts = { "string" },
			-- skip autopair when next character is closing pair
			-- and there are more closing pairs than opening pairs
			skip_unbalanced = true,
			-- better deal with markdown code blocks
			markdown = true,
		},
		config = function(_, opts)
			-- copy from https://github.com/LazyVim/LazyVim/blob/12818a6cb499456f4903c5d8e68af43753ebc869/lua/lazyvim/util/mini.lua#L123-L168
			local pairs = require("mini.pairs")
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
					local ok, captures =
							pcall(vim.treesitter.get_captures_at_pos, 0, cursor[1] - 1, math.max(cursor[2] - 1, 0))
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
		"nvim-mini/mini.comment",
		version = false,
		event = "BufReadPre",
		opts = {
			mappings = {
				comment = "<leader>/",
				comment_line = "<leader>/",
				comment_visual = "<leader>/",
				textobject = "<leader>/",
			},
		},
	},
	{
		"nvim-mini/mini.notify",
		version = false,
		config = function()
			local MiniNotify = require("mini.notify")
			local validate_pattern = "Validate documents"
			local diagnostics_pat = "Publish Diagnostics"
			MiniNotify.setup({
				-- Content management
				content = {
					-- Function which formats the notification message
					-- By default prepends message with notification time
					format = nil,

					-- Function which orders notification array from most to least important
					-- By default orders first by level and then by update timestamp
					sort = function(notif_arr)
						return vim.tbl_filter(function(notif)
							if notif.data.source ~= 'lsp_progress' then
								return true
							end

							return not (notif.msg:find(validate_pattern) or notif.msg:find(diagnostics_pat))
						end, notif_arr)
					end,
				},

				-- Notifications about LSP progress
				lsp_progress = {
					-- Whether to enable showing
					enable = true,

					-- Notification level
					level = "INFO",

					-- Duration (in ms) of how long last message should be shown
					duration_last = 1000,
				},

				-- Window options
				window = {
					-- Floating window config
					config = {},

					-- Maximum window width as share (between 0 and 1) of available columns
					max_width_share = 0.382,

					-- Value of 'winblend' option
					winblend = 25,
				},
			})
		end,
	},
	{
		"nvim-mini/mini.trailspace",
		version = false,
		event = "BufReadPre",
		config = true,
	},
	{
		"nvim-mini/mini.diff",
		version = false,
		config = true,
	},
	{
		"nvim-mini/mini.ai",
		version = false,
		config = true,
	},
}
