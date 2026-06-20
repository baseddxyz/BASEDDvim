local treesitter_options = {
	ensure_installed = {
		"bash",
		"javascript",
		"lua",
		"markdown",
		-- "python",
		"rust",
		-- "svelte",
		"typescript",
		"go",
		"ruby",
		"java",
	},
	sync_install = false,
	highlight = { enable = true },
	indent = { enable = true },
}

local mason_options = {
	ensure_installed = {
		"lua_ls",
		"ts_ls",
		-- "pyright",
		-- "ruff",
		"rust_analyzer",
		-- "svelte",
		"gopls",
		"ruby_lsp",
	},
}

local mason_lsp_mapping = {
	gopls = "gopls",
	lua_ls = "lua-language-server",
	-- pyright = "pyright",
	-- ruff = "ruff",
	rust_analyzer = "rust-analyzer",
	stylua = "stylua",
	-- svelte = "svelte-language-server",
	ts_ls = "typescript-language-server",
	ruby_lsp = "ruby-lsp",
}

local mason_formatters = {
	ensure_installed = { "biome", "stylua" },
}

local rust_diagnostics = "rust-analyzer"

local keymaps = require("keymaps")

return {
	-- treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		event = { "BufReadPre", "BufNewFile" },
		opts = treesitter_options,
	},

	-- lspconfig
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			-- Shared defaults applied to every server via wildcard merge.
			-- Each server's specifics live in lsp/<name>.lua (auto-discovered).
			-- Verified in nvim 0.12: wildcard on_attach + capabilities propagate
			-- to named configs loaded from lsp/, while server-specific fields win.
			vim.lsp.config("*", {
				on_attach = function(_, bufnr)
					keymaps.lsp({ buffer = bufnr })
					keymaps.lsp_format({ buffer = bufnr })
				end,
				capabilities = capabilities,
			})

			-- Enable the loop-managed servers. rust_analyzer is intentionally
			-- omitted: rustaceanvim manages it via vim.g.rustaceanvim.
			-- (Verified: vim.lsp.enable accepts a list.)
			vim.lsp.enable({ "lua_ls", "ts_ls", "gopls", "ruby_lsp" })
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
		ft = { "rust" },
		opts = {
			server = {
				on_attach = function(_, bufnr)
					-- lsp keymap (generic first, so the Rust-specific <leader>ca below wins)
					keymaps.lsp({ buffer = bufnr })

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
