# BASEDDvim Agent Guidelines

A personal Neovim distribution by `baseddxyz`, managed by **lazy.nvim**, written in **LuaJIT 5.1**. It targets modern Neovim (uses the `vim.lsp.config()` / `vim.lsp.enable()` API) and is installed by cloning into `~/.config/nvim`.

## Repository Layout

```
init.lua                 # bootstraps lazy.nvim, requires "vim-options", then { import = "plugins" }
lua/
├── vim-options.lua      # global options + buffer/diagnostic keymaps (leader = <space>)
├── keymaps.lua          # shared helpers: M.lsp() and M.lsp_format() for buffer-local LSP keymaps
├── configs/
│   └── init.lua         # feature flags (ai.enabled) + icon kind table
└── plugins/             # lazy.nvim specs, auto-discovered via { import = "plugins" }
    ├── init.lua         # empty module placeholder
    ├── ai.lua           # supermaven, sidekick.nvim, amp.nvim, 99 (feature-flagged)
    ├── blink.lua        # blink.cmp + blink.compat (merges supermaven when ai.enabled)
    ├── bufferline.lua   # buffer tabline
    ├── coding.lua       # trouble.nvim
    ├── colorscheme.lua  # gruvbox.nvim is active; many alternatives commented out
    ├── flash.lua        # flash.nvim navigation
    ├── img-clip.lua     # clipboard image paste
    ├── java.lua         # nvim-jdtls wrapper (overrides lspconfig for java)
    ├── lazydev.lua      # nvim lua dev environment (+ luvit-meta for vim.uv types)
    ├── lspconfig.lua    # treesitter, nvim-lspconfig, mason.nvim, rustaceanvim, conform.nvim
    ├── mini.lua         # the nvim-mini/* suite (icons, starter, statusline, files, pairs, ...)
    ├── note-taking.lua  # currently empty (obsidian/checkmate commented out)
    ├── qol.lua          # smear-cursor
    ├── snacks.lua       # snacks.nvim (picker, rename, dim, indent, image)
    ├── terminal.lua     # toggleterm.nvim
    ├── tmux.lua         # vim-tmux-navigator
    └── web-linter.lua   # nvim-lint (biome for JS/TS)
lazy-lock.json           # pinned plugin versions — do not hand-edit
.luarc.json              # declares `vim` as a global for lua_ls
```

Each file under `lua/plugins/` returns a **table of lazy.nvim specs**. To add a plugin, put it in the matching category file (or create a new one — lazy auto-discovers all modules under `plugins/`).

## Build / Lint / Test Commands

```bash
# Sync/update all plugins (lazy.nvim)
nvim --headless "+Lazy! sync" +qa

# Install every LSP server + formatter declared in lspconfig.lua
nvim --headless "+MasonInstallAll" +qa   # or run :MasonInstallAll inside nvim

# Format Lua to match the repo (TABS — see Indentation below)
stylua --indent-type Tabs --indent-width 2 lua/

# Format a single file
stylua --indent-type Tabs %

# Neovim health check
nvim --headless "+checkhealth" +qa
```

## Code Style Guidelines

### Indentation & Formatting
- **Tabs for indentation** (the actual source files use tabs; `vim-options.lua` sets `noexpandtab tabstop=2 softtabstop=2 shiftwidth=2`).
- There is **no `.stylua.toml`** in the repo. Run stylua with `--indent-type Tabs --indent-width 2`, otherwise it rewrites files to spaces by default.
- JS/TS is formatted with **biome** (configured in `lspconfig.lua` via `conform.nvim`).

### Module Pattern
```lua
local M = {}

function M.something() ... end

return M
```

### Imports & Requires
- Put top-level `require()` calls near the top of the file.
- Use a local alias: `local keymaps = require("keymaps")`.
- For optional dependencies, `pcall(require, ...)` close to the usage site.

### Naming Conventions
- **Variables**: snake_case (`local treesitter_options`, `local mason_formatters`).
- **Functions**: snake_case (`function M.lsp_format()`, `local diagnostic_goto`).
- **Table keys**: snake_case or camelCase to match the upstream API (`ensure_installed`, `filetypes`).

### Plugin Specification Pattern
```lua
return {
  {
    "author/plugin-name",
    version = false,                                 -- pin to a tag only when needed
    lazy = true,                                     -- prefer lazy loading
    event = { "BufReadPre", "BufNewFile" },          -- load triggers
    keys = { { "<leader>f", cmd, desc = "Description" } },
    opts = { ... },                                  -- preferred over inline config()
    config = function(_, opts) ... end,
  },
}
```

### Feature Flags & Conditional Loading
Feature flags live in `lua/configs/init.lua` (currently `ai = { enabled = true }`). Gated plugin files return either the spec table or an empty table:

```lua
local configs = require("configs")
return configs.ai and configs.ai.enabled
    and { { "...", ... } }
    or {}
```

`lua/plugins/blink.lua` shows the same idea for merging a flagged dependency via `vim.tbl_deep_extend("force", base, override)`.

### Keybindings
```lua
vim.keymap.set("n", "<leader>f", function() ... end, { desc = "Description", buffer = bufnr })
```
- Single-letter mode identifiers: `"n"`, `"v"`, `"i"`, `"c"`, `"t"` (or a table for several).
- Always include `desc` for which-key compatibility.
- Pass `{ buffer = bufnr }` for buffer-local keymaps.

### Error Handling
```lua
local ok, result = pcall(require, "optional_plugin")
if ok then
  -- use result
else
  -- fallback behavior
end
```

### Configuration Merging
```lua
vim.tbl_deep_extend("force", base_config, override_config)  -- deep merge
vim.tbl_extend("force", table1, table2)                      -- shallow merge
```

### Comments
- `--` prefix; one `--` per line for block comments (no `--[[ ]]`).
- Commented-out plugin specs are kept in files as a palette of alternatives — leave existing commented blocks in place unless told otherwise.

### Neovim API
- Prefer `vim.api.nvim_*` for API calls.
- Use `vim.opt.*` / `vim.opt_local.*` for options, `vim.cmd()` for Vimscript.
- Note: setting `vim.opt_local.*` at startup only affects the transient startup buffer; prefer `vim.opt.*` for global defaults (see `vim-options.lua`).

## LSP Integration

- Configure servers with `vim.lsp.config(name, config)` then **enable** with `vim.lsp.enable(name)`. See `lspconfig.lua` for the loop over `mason_options.ensure_installed`.
- Every `on_attach` should call `keymaps.lsp({ buffer = bufnr })` and `keymaps.lsp_format({ buffer = bufnr })`.
- Capabilities come from `require("blink.cmp").get_lsp_capabilities()`.
- **Special-cased servers** (do not add them to the generic lspconfig loop unchanged):
  - `rust_analyzer` is owned by **rustaceanvim** — skipped in the loop, configured via `vim.g.rustaceanvim`.
  - `ts_ls` gets the `@vue/typescript-plugin` injected for `.vue` files.
  - `jdtls` (Java) is owned by **nvim-jdtls** (`java.lua`), which intercepts via `setup.jdtls` returning `true` to avoid a duplicate server.

## Mason

`MasonInstallAll` is a custom user command defined in `lspconfig.lua`. It installs every formatter (`mason_formatters.ensure_installed`) plus every server mapped through `mason_lsp_mapping` (LSP name → Mason package name). When adding a new server, update **both** `mason_options.ensure_installed` and `mason_lsp_mapping`, or it will not be installed.

## Keymap Conventions

- Leader is `<space>` (`vim.g.mapleader = " "`).
- LSP: `gd`/`gD`/`gi`/`gr`/`K`/`<C-k>`/`<leader>D`/`<leader>rn`/`<leader>ca` (see `keymaps.lua`).
- Format: `<leader>fm` (LSP fallback) and `<leader>fM` (conform, file/range).
- Diagnostics: `]d`/`[d`, `]e`/`[e`, `]w`/`[w`, `<leader>cd` (float), `<leader>t*` (trouble).
- Be aware of intentional context-dependent overlaps, e.g. `<C-k>` is tmux-up globally but LSP signature-help buffer-locally.

## When Editing

- Keep `lazy-lock.json` untouched unless intentionally bumping a version (let `:Lazy sync` manage it).
- If you add a treesitter parser, an LSP server, a formatter, or a linter, update the corresponding `ensure_installed` / `formatters_by_ft` / `linters_by_ft` table rather than ad-hoc.
- Prefer extending existing category files over creating new ones; create a new `lua/plugins/<name>.lua` only for a genuinely new concern.
