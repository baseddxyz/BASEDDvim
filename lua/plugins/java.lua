local java_filetypes = { "java" }

-- Utility function to extend or override a config table, similar to the way
-- that Plugin.opts works.
---@param config table
---@param custom function | table | nil
local function extend_or_override(config, custom, ...)
  if type(custom) == "function" then
    config = custom(config, ...) or config
  elseif custom then
    config = vim.tbl_deep_extend("force", config, custom) --[[@as table]]
  end
  return config
end

return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = { ensure_installed = { "java" } },
	},
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				jdtls = {},
			},
			setup = {
				jdtls = function()
					return true -- avoid duplicate servers
				end,
			}
		}
	},
	{
		"mfussenegger/nvim-jdtls",
		opts = function()
			local cmd = { vim.fn.exepath("jdtls") }
			local lombok_jar = vim.fn.expand("$MASON/share/jdtls/lombok.jar")
			local capabilities = require('blink.cmp').get_lsp_capabilities()
			table.insert(cmd, string.format("--jvm-arg=-javaagent:%s", lombok_jar))
			return {
				root_dir = function(path)
					return vim.fs.root(path, vim.lsp.config.jdtls.root_markers)
				end,

				project_name = function(root_dir)
					return root_dir and vim.fs.basename(root_dir)
				end,

				jdtls_config_dir = function(project_name)
					return vim.fn.stdpath("cache") .. "/jdtls/" .. project_name .. "/config"
				end,
				jdtls_workspace_dir = function(project_name)
					return vim.fn.stdpath("cache") .. "/jdtls/" .. project_name .. "/workspace"
				end,

				cmd = cmd,
				full_cmd = function(opts)
					local fname = vim.api.nvim_buf_get_name(0)
					local root_dir = opts.root_dir(fname)
					local project_name = opts.project_name(root_dir)
					local cmd = vim.deepcopy(opts.cmd)
					if project_name then
						vim.list_extend(cmd, {
							"-configuration",
							opts.jdtls_config_dir(project_name),
							"-data",
							opts.jdtls_workspace_dir(project_name),
						})
					end
					return cmd
				end,

				test = true,
				settings = {
					java = {
						inlayHints = {
							parameterNames = {
								enabled = "all",
							},
						},
					},
				},
			}
		end,
		config = function(_, opts)
			local bundles = {} ---@type string[]
			local function attach_jdtls()
				local fname = vim.api.nvim_buf_get_name(0)

				-- Configuration can be augmented and overridden by opts.jdtls
				local config = extend_or_override({
					cmd = opts.full_cmd(opts),
					root_dir = opts.root_dir(fname),
					init_options = {
						bundles = bundles,
					},
					settings = opts.settings,
					-- enable CMP capabilities
					capabilities = require('blink.cmp').get_lsp_capabilities(),
				}, opts.jdtls)

				-- Existing server will be reused if the root_dir matches.
				require("jdtls").start_or_attach(config)
				-- not need to require("jdtls.setup").add_commands(), start automatically adds commands
			end

			-- Attach the jdtls for each java buffer. HOWEVER, this plugin loads
			-- depending on filetype, so this autocmd doesn't run for the first file.
			-- For that, we call directly below.
			vim.api.nvim_create_autocmd("FileType", {
				pattern = java_filetypes,
				callback = attach_jdtls,
			})

			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					if client and client.name == "jdtls" then
						local options = {}
						vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, options)
						vim.keymap.set('n', 'gd', vim.lsp.buf.definition, options)
						vim.keymap.set('n', 'K', vim.lsp.buf.hover, options)
						vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, options)
						vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, options)
						vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, options)
						vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, options)
						vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, options)
						vim.keymap.set('n', 'gr', vim.lsp.buf.references, options)
						vim.keymap.set('n', '<leader>fm', function()
							vim.lsp.buf.format { async = true }
						end, options)
					end

					if opts.on_attach then
						opts.on_attach(args)
					end
				end
			})

			-- Avoid race condition by calling attach the first time, since the autocmd won't fire.
			attach_jdtls()
		end,
	},
}
