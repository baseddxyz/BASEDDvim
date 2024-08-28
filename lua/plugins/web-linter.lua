local linters = {
	-- web
	'biome',
}

return {
	{
		'mfussenegger/nvim-lint',
		event = { 'VeryLazy' },
		opts = {
			-- Events to trigger linter
			events = { "BufWritePost", "BufReadPost", "InsertLeave" },
			linters_by_ft = {
				javascript = { 'biomejs' },
				javascriptreact = { 'biomejs' },
				typescript = { 'biomejs' },
				typescriptreact = { 'biomejs' },
			},
		},
		config = function(_, opts)
			local mason_registry = require('mason-registry')
			for _, linter in ipairs(linters) do
				if not mason_registry.is_installed(linter) then
					vim.cmd('MasonInstall ' .. linter)
				end
			end

			local lint = require('lint')
			lint.linters_by_ft = opts.linters_by_ft

			vim.api.nvim_create_autocmd(
				{ 'BufWritePost', 'BufEnter' },
				{
					callback = function()
						lint.try_lint()
					end
				}
			)
		end,
		dependencies = {
			{ 'williamboman/mason.nvim' }
		}
	},
}
