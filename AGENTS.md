# AGENTS.md

Personal Neovim configuration, built on **lazy.nvim**, **blink.cmp**, and **snacks.nvim**. Everything lives under `lua/`; there is no `after/`, `ftplugin/`, or Vimscript beyond a few `vim.cmd` calls.

## Layout

- `init.lua` — bootstraps `lazy.nvim` (clones stable branch on first run), then loads `vim-options` and imports the whole `lua/plugins/` directory as the plugin spec.
- `lua/vim-options.lua` — global options, `vim.g.mapleader = " "`, buffer/diagnostic keymaps (`<TAB>`/`<S-TAB>`, `<leader>x/X`, `]d`/`[d`/`]e`/`[e`/`]w`/`[w`, `<leader>cd`), and `vim.diagnostic.config`.
- `lua/keymaps.lua` — shared LSP keymap module. `M.lsp()` / `M.lsp_format()` are called from every LSP `on_attach` (lspconfig, rustaceanvim, jdtls). Do not duplicate these maps in plugin specs.
- `lua/configs/init.lua` — central feature-flag/config table (`configs.ai.enabled`, `configs.icons.kinds`). Toggles and shared lookups belong here.
- `lua/plugins/*.lua` — one file per concern, each returning a lazy.nvim spec table (or `{}`/`false` when disabled). New plugins go in a **new file here** — they are picked up automatically by the `import = "plugins"` in `init.lua`. No registration needed.

## Plugin-map (who owns what)

| Concern | File | Notes |
|---|---|---|
| Completion | `blink.lua` | blink.cmp + blink.compat; Supermaven source merged in only when `configs.ai.enabled` via `vim.tbl_deep_extend` |
| LSP / TS / Mason / conform | `lspconfig.lua` | treesitter is the **main-branch rewrite**: `require('nvim-treesitter').install(parsers)` + `FileType` autocmd calling `vim.treesitter.start()` and setting `indentexpr` (needs the `tree-sitter` CLI — installed via mise). Generic enable loop over `servers`; **rust_analyzer is NOT in it** (rustaceanvim owns rust and disables lspconfig's copy) and jdtls is installed but never enabled (nvim-jdtls starts it). Mason tools (servers + formatters + `jdtls`, `google-java-format`, `stylua`) are installed declaratively by `mason-tool-installer.nvim` |
| Rust | `lspconfig.lua` (rustaceanvim) | `<leader>ca` → RustLsp codeAction |
| Java | `java.lua` | nvim-jdtls setup; defers `jdtls` from nvim-lspconfig to avoid duplicate servers |
| Linting | `web-linter.lua` | nvim-lint + oxlint; JS/TS formatting is `oxfmt` via conform (both installed as bun globals in `~/.bun/bin` — mise's npm backend currently fails on them) |
| AI | `ai.lua` | sidekick.nvim (zellij mux) + ThePrimeagen/99; entire spec is `configs.ai.enabled`-gated |
| Picker/rename/dim/indent | `snacks.lua` | `<leader>ff/fw/fb`, `<leader>rr`, `<leader>y` |
| Diagnostics UI | `coding.lua` | trouble.nvim |
| Motion | `flash.lua` | `s`, `S`, `r`, `R` |
| Terminal | `terminal.lua` | toggleterm, `<leader>tf` |
| Tmux nav | `tmux.lua` | `<C-h/j/k/l>` |
| Colorscheme | `colorscheme.lua` | gruvbox active; previous themes kept commented as alternatives |
| Misc UI | `mini.lua`, `bufferline.lua`, `qol.lua` (smear cursor), `img-clip.lua` (`<leader>p`) | |
| Lua dev | `lazydev.lua` | types for editing this config itself |

`note-taking.lua` is currently fully commented out (obsidian/checkmate parked there).

## Conventions

- **Indentation: tabs, width 2** — enforced by the committed `.stylua.toml`; StyLua formats on save (`conform` → `stylua` for `lua`) and `stylua --check` must pass before committing.
- Keymaps follow the `desc = "Title Case"` style. Global maps go in `vim-options.lua`; plugin maps live in the plugin's `keys =` spec; LSP maps only in `lua/keymaps.lua`. `<C-k>` belongs to tmux-navigator; signature help comes from blink.cmp (`signature = { enabled = true }`).
- Commented-out plugin blocks (colorschemes, avante, codecompanion, obsidian…) are **intentional alternatives** — don't delete them when editing nearby code.
- Feature toggles go through `lua/configs/init.lua`, not by editing specs. Pattern used in `ai.lua`/`blink.lua`: return the spec table only when the flag is on, else `{}`.
- `lazy-lock.json` is committed — keep versions pinned; don't bump unless asked.
- `.luarc.json` declares `vim` as a global for lua_ls; when editing this repo in Neovim, `lazydev.nvim` supplies the nvim API types.

## Adding a plugin

1. Create `lua/plugins/<name>.lua` returning the spec table.
2. Use `event`/`ft`/`cmd`/`keys` to lazy-load where possible (see existing files).
3. If it needs LSP attach behavior, call `require("keymaps").lsp({ buffer = bufnr })` instead of redefining `gd`, `K`, `gr`, etc.
4. Restart Neovim (or `:Lazy sync`) so `lazy-lock.json` updates.

## Verifying changes

There is no test suite. Minimum checks before committing:

```sh
# Headless smoke test — must exit 0 with no errors in output
nvim --headless "+Lazy! sync" +qa

# Load a specific config module
nvim --headless "+lua assert(require('vim-options'))" +qa

# Style check (stylua is Mason-installed)
stylua --check lua/

# Reinstall/update Mason tools after touching the mason_tools list in lspconfig.lua
# (inside nvim) :MasonToolsInstallSync  /  :MasonToolsUpdateSync
```

Watch for keymap clashes: `<TAB>`/`<S-TAB>` (buffers, and blink snippet nav in insert mode), `r`/`R` (flash, operator-pending/visual only).
