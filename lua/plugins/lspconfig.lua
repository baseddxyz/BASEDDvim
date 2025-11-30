local treesitter_options = {
	ensure_installed = {
		"bash",
		"javascript",
		"lua",
		"markdown",
		"python",
		"rust",
		"svelte",
		"typescript",
		"go",
		"ruby",
	},
	sync_install = false,
	highlight = { enable = true },
	indent = { enable = true },
}

local mason_options = {
	ensure_installed = {
		"lua_ls",
		"ts_ls",
		"pyright",
		"ruff",
		"rust_analyzer",
		"svelte",
		"gopls",
		"ruby_lsp",
	},
}

local mason_lsp_mapping = {
	gopls = "gopls",
	lua_ls = "lua-language-server",
	pyright = "pyright",
	ruff = "ruff",
	rust_analyzer = "rust-analyzer",
	stylua = "stylua",
	svelte = "svelte-language-server",
	ts_ls = "typescript-language-server",
	ruby_lsp = "ruby-lsp",
}

local mason_formatters = {
	ensure_installed = { "biome", "stylua" },
}

local rust_diagnostics = "rust-analyzer"

local keymaps = require("keymaps")

local default_lspconfig = function(capabilities)
	return {
		on_attach = function()
			keymaps.lsp({ buffer = bufnr })
			keymaps.lsp_format({ buffer = bufnr })
		end,
		capabilities = capabilities,
	}
end

return {
	-- treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local configs = require("nvim-treesitter.configs")

			configs.setup(treesitter_options)
		end,
	},

	-- lspconfig
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			for _, lsp in ipairs(mason_options.ensure_installed) do
				if lsp == "ts_ls" then
					vim.lsp.config(
						lsp,
						vim.tbl_deep_extend("force", default_lspconfig(capabilities), {
							init_options = {
								plugins = {
									{
										name = "@vue/typescript-plugin",
										location = vim.fn.getcwd() .. "/node_modules/@vue/typescript-plugin",
										languages = {
											"javascript",
											"javascriptreact",
											"typescript",
											"typescriptreact",
											"vue",
										},
									},
								},
							},
							filetypes = {
								"javascript",
								"javascriptreact",
								"typescript",
								"typescriptreact",
								"vue",
							},
						})
					)
				elseif lsp == "pyright" then
					vim.lsp.config(
						lsp,
						vim.tbl_deep_extend("force", default_lspconfig(capabilities), {
							settings = {
								pyright = {
									-- Using Ruff's import organizer
									disableOrganizeImports = true,
								},
								python = {
									analysis = {
										-- Ignore all files for analysis to exclusively use Ruff for linting
										ignore = { "*" },
									},
								},
							},
						})
					)
				elseif lsp ~= "rust_analyzer" then
					vim.lsp.config(lsp, default_lspconfig(capabilities))
				end

				-- enable LSP
				vim.lsp.enable(lsp)
			end
		end,
		dependencies = {
			{ "saghen/blink.cmp" },
			{
				"williamboman/mason.nvim",
				event = { "BufReadPre", "BufNewFile" },
				cmd = {
					"Mason",
					"MasonInstall",
					"MasonInstallAll",
					"MasonUninstall",
					"MasonUninstallAll",
					"MasonUpdate",
				},
				config = function()
					require("mason").setup()

					vim.api.nvim_create_user_command("MasonInstallAll", function()
						local mason_servers = {}
						for _, mason_server in ipairs(mason_options.ensure_installed) do
							table.insert(mason_servers, mason_lsp_mapping[mason_server])
						end

						vim.cmd(
							"MasonInstall "
								.. table.concat(mason_formatters.ensure_installed, " ")
								.. " "
								.. table.concat(mason_servers, " ")
						)
					end, {})
				end,
			},
		},
	},

	-- rustacean
	{
		"mrcjkb/rustaceanvim",
		version = false,
		lazy = false,
		ft = { "rust" },
		opts = {
			server = {
				on_attach = function(_, bufnr)
					vim.keymap.set("n", "<leader>ca", function()
						vim.cmd.RustLsp("codeAction")
					end, { desc = "Code Action", buffer = bufnr })
					-- vim.keymap.set(
					-- 	'n',
					-- 	'<leader>dr',
					-- 	function()
					-- 		vim.cmd.RustLsp('debuggables')
					-- 	end,
					-- 	{ desc = "Rust debuggables", buffer = bufnr }
					-- )

					-- lsp keymap
					keymaps.lsp({ buffer = bufnr })
				end,
				default_settings = {
					-- rust-analyzer language server configuration
					["rust-analyzer"] = {
						cargo = {
							allFeatures = true,
							loadOutDirsFromCheck = true,
							buildScripts = {
								enable = true,
							},
						},
						-- Add clippy lints for Rust if using rust-analyzer
						checkOnSave = rust_diagnostics == "rust-analyzer",
						-- Enable diagnostics if using rust-analyzer
						diagnostics = {
							enable = rust_diagnostics == "rust-analyzer",
						},
						procMacro = {
							enable = true,
							ignored = {
								["async-trait"] = { "async_trait" },
								["napi-derive"] = { "napi" },
								["async-recursion"] = { "async_recursion" },
							},
						},
						files = {
							excludeDirs = {
								".direnv",
								".git",
								".github",
								".gitlab",
								"bin",
								"node_modules",
								"target",
								"venv",
								".venv",
							},
						},
					},
				},
			},
		},
		config = function(_, opts)
			vim.g.rustaceanvim = vim.tbl_deep_extend("keep", vim.g.rustaceanvim or {}, opts or {})
		end,
	},

	-- formatter
	{
		"stevearc/conform.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local conform = require("conform")

			conform.setup({
				formatters_by_ft = {
					lua = { "stylua" },
					javascript = { "biome-check" },
					javascriptreact = { "biome-check" },
					typescript = { "biome" },
					typescriptreact = { "biome-check" },
					java = { "google-java-format" },
				},
				format_on_save = {
					timeout_ms = 500,
					lsp_format = "fallback",
				},
			})

			vim.keymap.set({ "n", "v" }, "<leader>fM", function()
				conform.format({
					lsp_fallback = true,
					async = false,
					timeout_ms = 500,
				})
			end, { desc = "Format file or range (in visual mode)" })
		end,
	},
}
