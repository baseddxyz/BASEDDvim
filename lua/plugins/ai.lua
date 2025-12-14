local configs = require("configs")
return configs.ai
		and configs.ai.enabled
		and {
			{
				"supermaven-inc/supermaven-nvim",
				event = "BufReadPre",
				config = function()
					require("supermaven-nvim").setup({
						disable_inline_completion = true,
					})
				end,
			},
			-- {
			-- 	"olimorris/codecompanion.nvim",
			-- 	opts = {
			-- 		strategies = {
			-- 			chat = {
			-- 				adapter = "claude_code",
			-- 			},
			-- 			inline = {
			-- 				adapter = "claude_code",
			-- 			},
			-- 			cmd = {
			-- 				adapter = "claude_code",
			-- 			},
			-- 		},
			-- 		adapters = {
			-- 			http = {
			-- 				anthropic = function()
			-- 					return require("codecompanion.adapters").extend("anthropic", {
			-- 						env = {
			-- 							api_key = "ANTHROPIC_API_KEY",
			-- 						},
			-- 					})
			-- 				end,
			-- 				acp = {
			-- 					claude_code = function()
			-- 						return require("codecompanion.adapters").extend("claude_code", {
			-- 							env = {
			-- 								ANTHROPIC_API_KEY = "ANTHROPIC_API_KEY",
			-- 							},
			-- 						})
			-- 					end,
			-- 				},
			-- 			},
			-- 		},
			-- 	},
			-- 	dependencies = {
			-- 		"nvim-lua/plenary.nvim",
			-- 		{
			-- 			"MeanderingProgrammer/render-markdown.nvim",
			-- 			ft = { "markdown", "codecompanion" },
			-- 		},
			-- 	},
			-- },

			-- {
			-- 	"olimorris/codecompanion.nvim",
			-- 	cmd = {
			-- 		'CodeCompanion',
			-- 		'CodeCompanionActions',
			-- 		'CodeCompanionChat',
			-- 		'CodeCompanionCmd',
			-- 	},
			-- 	dependencies = {
			-- 		"nvim-lua/plenary.nvim",
			-- 		"nvim-treesitter/nvim-treesitter",
			-- 		{
			-- 			"MeanderingProgrammer/render-markdown.nvim",
			-- 			ft = { "codecompanion" }
			-- 		},
			-- 	},
			-- 	opts = {
			-- 		strategies = {
			-- 			chat = {
			-- 				adapter = "gemini",
			-- 			},
			-- 			inline = {
			-- 				adapter = "gemini",
			-- 			},
			-- 		},
			-- 		gemini = function()
			-- 			return require("codecompanion.adapters").extend("gemini", {
			-- 				schema = {
			-- 					model = {
			-- 						default = "gemini-2.5-flash-preview-05-20"
			-- 					},
			-- 				},
			-- 				env = {
			-- 					api_key = "GEMINI_API_KEY",
			-- 				},
			-- 			})
			-- 		end,
			-- 		display = {
			-- 			diff = {
			-- 				provider = "mini_diff",
			-- 			},
			-- 		},
			-- 	},
			-- },
			{
				"qapquiz/sidekick.nvim",
				opts = {
					-- add any options here
					cli = {
						mux = {
							backend = "zellij",
							enabled = true,
						},
					},
				},
				keys = {
					-- {
					-- 	"<tab>",
					-- 	function()
					-- 		-- if there is a next edit, jump to it, otherwise apply it if any
					-- 		if not require("sidekick").nes_jump_or_apply() then
					-- 			return "<Tab>" -- fallback to normal tab
					-- 		end
					-- 	end,
					-- 	expr = true,
					-- 	desc = "Goto/Apply Next Edit Suggestion",
					-- },
					{
						"<c-.>",
						function()
							require("sidekick.cli").toggle()
						end,
						desc = "Sidekick Toggle",
						mode = { "n", "t", "i", "x" },
					},
					{
						"<leader>aa",
						function()
							require("sidekick.cli").toggle()
						end,
						desc = "Sidekick Toggle CLI",
					},
					{
						"<leader>as",
						function()
							require("sidekick.cli").select()
						end,
						-- Or to select only installed tools:
						-- require("sidekick.cli").select({ filter = { installed = true } })
						desc = "Select CLI",
					},
					{
						"<leader>ad",
						function()
							require("sidekick.cli").close()
						end,
						desc = "Detach a CLI Session",
					},
					{
						"<leader>at",
						function()
							require("sidekick.cli").send({ msg = "{this}" })
						end,
						mode = { "x", "n" },
						desc = "Send This",
					},
					{
						"<leader>af",
						function()
							require("sidekick.cli").send({ msg = "{file}" })
						end,
						desc = "Send File",
					},
					{
						"<leader>av",
						function()
							require("sidekick.cli").send({ msg = "{selection}" })
						end,
						mode = { "x" },
						desc = "Send Visual Selection",
					},
					{
						"<leader>ap",
						function()
							require("sidekick.cli").prompt()
						end,
						mode = { "n", "x" },
						desc = "Sidekick Select Prompt",
					},
					-- Example of a keybinding to open Claude directly
					{
						"<leader>ac",
						function()
							require("sidekick.cli").toggle({ name = "claude", focus = true })
						end,
						desc = "Sidekick Toggle Claude",
					},
				},
			},
			-- {
			-- 	"yetone/avante.nvim",
			-- 	event = "VeryLazy",
			-- 	version = false,
			-- 	---@module 'avante'
			-- 	---@type avante.Config
			-- 	opts = {
			-- 		instructions_file = "avante.md",
			-- 		provider = "claude-code",
			-- 		acp_providers = {
			-- 			["claude-code"] = {
			-- 				command = "bunx",
			-- 				args = { "@zed-industries/claude-code-acp" },
			-- 				env = {
			-- 					NODE_NO_WARNINGS = "1",
			-- 					ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY"),
			-- 				},
			-- 			},
			-- 		},
			-- 	},
			-- 	dependencies = {
			-- 		"nvim-lua/plenary.nvim",
			-- 		"MunifTanjim/nui.nvim",
			-- 		{
			-- 			-- Make sure to set this up properly if you have lazy=true
			-- 			'MeanderingProgrammer/render-markdown.nvim',
			-- 			opts = {
			-- 				file_types = { "markdown", "Avante" },
			-- 			},
			-- 			ft = { "markdown", "Avante" },
			-- 		},
			-- 	},
			-- },
			{
				"sourcegraph/amp.nvim",
				branch = "main",
				lazy = false,
				opts = { auto_start = true, log_level = "info" },
			},
			-- keys = {
			-- 	{
			-- 		"<leader>ab",
			-- 		function()
			-- 			local buf = vim.api.nvim_get_current_buf()
			-- 			local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
			-- 			local content = table.concat(lines, "\n")

			-- 			local amp_message = require("amp.message")
			-- 			amp_message.send_message(content)
			-- 		end,
			-- 		mode = { "n", "v" },
			-- 		desc = "Add buffer to Amp prompt",
			-- 	},
			-- 	{
			-- 		"<leader>as",
			-- 		function()
			-- 			local lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
			-- 			local text = table.concat(lines, "\n")

			-- 			local amp_message = require("amp.message")
			-- 			amp_message.send_to_prompt(text)
			-- 		end,
			-- 		mode = { "n", "v" },
			-- 		desc = "Add selected text to Amp prompt",
			-- 	},
			-- },
			-- 	config = function()
			-- 		vim.api.nvim_create_user_command("AmpSendBuffer", function(opts)
			-- 			local buf = vim.api.nvim_get_current_buf()
			-- 			local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
			-- 			local content = table.concat(lines, "\n")
			--
			-- 			local amp_message = require("amp.message")
			-- 			amp_message.send_message(content)
			-- 		end, {
			-- 			nargs = "?",
			-- 			desc = "Send current buffer contents to Amp",
			-- 		})
			--
			-- 		-- Add selected text directly to prompt
			-- 		vim.api.nvim_create_user_command("AmpPromptSelection", function(opts)
			-- 			local lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
			-- 			local text = table.concat(lines, "\n")
			--
			-- 			local amp_message = require("amp.message")
			-- 			amp_message.send_to_prompt(text)
			-- 		end, {
			-- 			range = true,
			-- 			desc = "Add selected text to Amp prompt",
			-- 		})
			--
			-- 		-- Add file+selection reference to prompt
			-- 		vim.api.nvim_create_user_command("AmpPromptRef", function(opts)
			-- 			local bufname = vim.api.nvim_buf_get_name(0)
			-- 			if bufname == "" then
			-- 				print("Current buffer has no filename")
			-- 				return
			-- 			end
			--
			-- 			local relative_path = vim.fn.fnamemodify(bufname, ":.")
			-- 			local ref = "@" .. relative_path
			-- 			if opts.line1 ~= opts.line2 then
			-- 				ref = ref .. "#L" .. opts.line1 .. "-" .. opts.line2
			-- 			elseif opts.line1 > 1 then
			-- 				ref = ref .. "#L" .. opts.line1
			-- 			end
			--
			-- 			local amp_message = require("amp.message")
			-- 			amp_message.send_to_prompt(ref)
			-- 		end, {
			-- 			range = true,
			-- 			desc = "Add file reference (with selection) to Amp prompt",
			-- 		})
			--
			-- 		vim.keymap.set("v", "<leader>as", "<cmd>AmpPromptSelection<cr>", { desc = "Add selection to Amp prompt" })
			-- 	end,
			-- },
		}
	or {}
