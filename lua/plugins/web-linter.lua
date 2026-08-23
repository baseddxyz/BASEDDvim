return {
	{
		"mfussenegger/nvim-lint",
		ft = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
		opts = {
			-- Events to trigger linter
			events = { "BufWritePost", "BufEnter", "InsertLeave" },
			linters_by_ft = {
				javascript = { "oxlint" },
				javascriptreact = { "oxlint" },
				typescript = { "oxlint" },
				typescriptreact = { "oxlint" },
			},
		},
		config = function(_, opts)
			local lint = require("lint")
			lint.linters_by_ft = opts.linters_by_ft

			vim.api.nvim_create_autocmd(opts.events, {
				callback = function()
					lint.try_lint()
				end,
			})
		end,
	},
}
