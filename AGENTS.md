# BASEDDvim Agent Guidelines

This repository is a Neovim configuration managed by lazy.nvim using LuaJIT 5.1.

## Build/Lint/Test Commands

```bash
# Sync/Update all plugins (lazy.nvim)
nvim --headless "+Lazy! sync" +qa

# Install LSP servers and formatters via Mason
:MasonInstallAll

# Format code (stylua for Lua, biome for JS/TS)
stylua %

# Neovim checkhealth
nvim --headless "+checkhealth" +qa
```

## Code Style Guidelines

### Indentation & Formatting
- **Tabs for indentation** (tabstop=2, noexpandtab, softtabstop=2)
- Use `stylua` for Lua formatting
- Use `biome` for JavaScript/TypeScript formatting

### Module Pattern
```lua
local M = {}

return M
```

### Imports & Requires
- Place `require()` calls at the top of files
- Use local references: `local keymaps = require("keymaps")`
- Keep requires close to usage for optional dependencies

### Naming Conventions
- **Variables**: snake_case (`local_treesitter_options`, `mason_formatters`)
- **Functions**: snake_case (`function M.lsp_format()`, `local diagnostic_goto`)
- **Keys in tables**: snake_case or camelCase based on API (`ensure_installed`, `filetypes`)
- **Constants**: UPPER_SNAKE_CASE (rarely used, prefer regular snake_case)

### Plugin Specification Pattern
```lua
return {
  {
    "author/plugin-name",
    version = false,
    lazy = true,
    event = { "BufReadPre", "BufNewFile" },
    keys = { { "<leader>f", cmd, desc = "Description" } },
    opts = { ... },
    config = function(_, opts) ... end,
  },
}
```

### Keybindings
```lua
vim.keymap.set("n", "<leader>f", function() ... end, { desc = "Description", buffer = bufnr })
```
- Use single-letter mode identifiers: `"n"`, `"v"`, `"i"`, `"c"`, `"t"`
- Include `desc` field for which-key compatibility
- Pass `{ buffer = bufnr }` for buffer-local keymaps

### Error Handling
```lua
local ok, result = pcall(require, "optional_plugin")
if ok then
  -- use result
else
  -- fallback behavior
end
```

### Comments
- Use `--` prefix for comments
- Comments above relevant code blocks
- Block comments with `--` on each line

### Configuration Merging
```lua
vim.tbl_deep_extend("force", base_config, override_config)
vim.tbl_extend("force", table1, table2)
```

### Neovim API
- Use `vim.api.nvim_*` functions for API calls
- Use `vim.opt.*` or `vim.opt_local.*` for options
- Use `vim.cmd()` for Vimscript commands

### Optional Features
- Check `configs.ai.enabled` before enabling AI features
- Commented-out code should use `--` prefix on each line
- Feature flags: Use conditional checks in opts

### File Organization
- `init.lua`: Entry point, lazy.nvim setup
- `lua/vim-options.lua`: Global options and basic keymaps
- `lua/keymaps.lua`: Shared LSP keymaps
- `lua/configs/`: Configuration constants
- `lua/plugins/`: Plugin specifications (one file per plugin category)

### LSP Integration
- Use `vim.lsp.config()` to configure LSP servers
- On attach should call `keymaps.lsp()` and `keymaps.lsp_format()`
- Use `require("blink.cmp").get_lsp_capabilities()` for capabilities
