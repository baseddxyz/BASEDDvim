# Plan 013: Restructure LSP config into `lsp/<name>.lua` files + establish `after/ftplugin/`

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md`.
>
> **Drift check (run first)**:
> `git diff --stat 2f10ac4..HEAD -- lua/plugins/lspconfig.lua`
> If `lua/plugins/lspconfig.lua` changed since this plan was written, compare
> the "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: MED (rewrites the core LSP enable path; additive but central)
- **Depends on**: none
- **Category**: tech-debt / architecture
- **Planned at**: commit `2f10ac4`, 2026-06-19
- **Finding**: Tier-1 borrow from `baseddxyz/paketo` (same author's leaner config)

## Why this matters

BASEDDvim's `lua/plugins/lspconfig.lua` holds the entire LSP setup in one
~130-line `config = function()`: a `for` loop over `mason_options.ensure_installed`
with an `elseif lsp == "ts_ls" / pyright / ~= rust_analyzer` chain, a
`default_lspconfig(capabilities)` helper, and `vim.lsp.enable(lsp)` at the
bottom. It's the clunkiest file in the repo, and the deferred N2 finding
(ts_ls Vue plugin path frozen to `vim.fn.getcwd()` at setup) exists *because*
that chain crams per-server config into a loop.

The same author's other config, `baseddxyz/paketo`, uses the native Neovim 0.11+
pattern: each server's config lives in its own `lsp/<name>.lua` file, and
`vim.lsp.enable()` auto-discovers it. This plan adopts that pattern —
**verified on this box (nvim 0.12.3)** to also use two features paketo doesn't:

1. **`vim.lsp.config("*", { on_attach=..., capabilities=... })` wildcard
   defaults MERGE into every named server config.** Verified: `on_attach`,
   capabilities, and arbitrary shared fields all propagate to a named config
   loaded from `lsp/<name>.lua`, while server-specific fields (cmd, settings)
   still win. So the shared `keymaps.lsp()`/`keymaps.lsp_format()` on_attach
   is set ONCE, not duplicated per server.
2. **`vim.lsp.enable({ "lua_ls", "ts_ls", ... })` accepts a list** — verified.
   The whole loop collapses to one call.

Net result: the `elseif` chain and `default_lspconfig` helper disappear; each
server's specifics live in a focused file you can read and edit in isolation;
the ts_ls N2 bug becomes a one-file follow-up instead of buried in a loop.

### What this is NOT

- Not a `vim.pack` migration — lazy.nvim stays. This is a config-organization
  change that works with lazy.nvim and is the natural first step IF you ever
  do migrate.
- Not touching rustaceanvim or jdtls — they manage their own clients
  (`vim.g.rustaceanvim`, `start_or_attach`) and stay in `lspconfig.lua`/`java.lua`.
- Not fixing N2 in this plan — the ts_ls config moves VERBATIM (preserving
  current behavior, including the `getcwd()` freeze). N2 is now trivially
  fixable in `lsp/ts_ls.lua` as a follow-up; recorded in Maintenance.

## Current state

`lua/plugins/lspconfig.lua` — the enable loop (lines ~76–132). Current shape:

```lua
		config = function()
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			for _, lsp in ipairs(mason_options.ensure_installed) do
				if lsp == "ts_ls" then
					vim.lsp.config(
						lsp,
						vim.tbl_deep_extend("force", default_lspconfig(capabilities), {
							init_options = { plugins = { { name = "@vue/typescript-plugin",
								location = vim.fn.getcwd() .. "/node_modules/@vue/typescript-plugin",
								languages = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" } } } },
							filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
						})
					)
				elseif lsp == "pyright" then
					-- ... (pyright is commented out of ensure_installed; dead branch)
				elseif lsp ~= "rust_analyzer" then
					vim.lsp.config(lsp, default_lspconfig(capabilities))
				end

				-- enable LSP
				vim.lsp.enable(lsp)
			end
		end,
```

`default_lspconfig` (lines ~53–61):
```lua
local default_lspconfig = function(capabilities)
	return {
		on_attach = function(_, bufnr)
			keymaps.lsp({ buffer = bufnr })
			keymaps.lsp_format({ buffer = bufnr })
		end,
		capabilities = capabilities,
	}
end
```

`mason_options.ensure_installed` (the loop source):
```lua
ensure_installed = { "lua_ls", "ts_ls", "rust_analyzer", "gopls", "ruby_lsp" }
```

### Verified API behavior (nvim 0.12.3, tested during planning)

- A file at `<config-root>/lsp/<name>.lua` returning a table is auto-loaded
  by `vim.lsp.enable(name)` and `vim.lsp.config["<name>"]`. (Tested with a
  fake server; `_marker` field resolved correctly.)
- `vim.lsp.enable({ "a", "b" })` — accepts a list, no error.
- `vim.lsp.config("*", { on_attach=..., capabilities=... })` — wildcard SET
  works, and the fields MERGE into named configs loaded from `lsp/<name>.lua`
  (verified: `on_attach`, shared markers, and capabilities all propagate; the
  named config's own `cmd`/`settings` still win).

The canonical path is **`lsp/<name>.lua` at the repo root** (on the
runtimepath), NOT `lua/lsp/`. paketo uses `after/lsp/`; both work, but
top-level `lsp/` is the documented canonical location.

### Repo conventions to match

- Module pattern `local M = {} … return M` for `lua/`; but `lsp/<name>.lua`
  files just `return { ... }` (they're config tables, not modules — same as
  paketo's `after/lsp/lua_ls.lua`).
- `keymaps.lsp({ buffer = bufnr })` / `keymaps.lsp_format(...)` is the shared
  on_attach pattern (see `lua/keymaps.lua`, used at `lspconfig.lua:56` and
  `:178`, `java.lua:139`).
- Tabs for indentation.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Server config files exist | `ls lsp/lua_ls.lua lsp/ts_ls.lua lsp/gopls.lua lsp/ruby_lsp.lua` | all four listed |
| No `default_lspconfig` helper left | `grep -n 'default_lspconfig' lua/plugins/lspconfig.lua` | no matches |
| No enable loop / `elseif` chain left | `grep -nE 'for _, lsp in ipairs\|elseif lsp ==' lua/plugins/lspconfig.lua` | no matches |
| Wildcard defaults present | `grep -n 'vim.lsp.config("\*"' lua/plugins/lspconfig.lua` | one match |
| List-enable present | `grep -n 'vim.lsp.enable({' lua/plugins/lspconfig.lua` | one match with 4 servers |
| MasonInstallAll command body unchanged | see Done criteria | verbatim |
| Each file parses | see Done criteria loop | exit 0 each |

## Scope

**In scope** (the only files you should create or modify):
- `lsp/lua_ls.lua` (new) — `return {}` (LuaLS-specific settings slot for the future).
- `lsp/ts_ls.lua` (new) — ts_ls specifics: Vue plugin + filetypes (moved verbatim).
- `lsp/gopls.lua` (new) — `return {}`.
- `lsp/ruby_lsp.lua` (new) — `return {}`.
- `after/ftplugin/markdown.lua` (new) — establishes the ftplugin pattern (spell + wrap + treesitter fold), borrowed from paketo.
- `lua/plugins/lspconfig.lua` — replace the enable loop + `default_lspconfig` with wildcard defaults + list-enable.

**Out of scope** (do NOT touch):
- `lua/plugins/java.lua` (jdtls) and the rustaceanvim spec in `lspconfig.lua` —
  they manage their own clients and keep their own on_attach. The wildcard
  does NOT apply to them (rustaceanvim uses `vim.g.rustaceanvim`; jdtls uses
  `start_or_attach`).
- `mason_options.ensure_installed`, `mason_lsp_mapping`, `mason_formatters`, and
  the `MasonInstallAll` command — unchanged (Mason install is orthogonal to
  LSP enable; see plan 010 decision 5).
- `lua/keymaps.lua` — the shared `keymaps.lsp`/`keymaps.lsp_format` helpers are
  used as-is by the new wildcard on_attach.
- nvim-treesitter and conform specs in `lspconfig.lua` — unchanged.
- Do NOT create `lsp/rust_analyzer.lua` — rustaceanvim owns rust-analyzer.

## Git workflow

- Branch: `advisor/013-lsp-restructure`
- One commit. Message style (conventional commits):
  `refactor: move LSP server configs to lsp/ files via native wildcard defaults`.

## Steps

### Step 1: Create `lsp/lua_ls.lua`

Create `lsp/lua_ls.lua` (repo root, NOT in `lua/`):

```lua
-- lua_ls (lua-language-server) config.
-- Shared on_attach + capabilities come from the wildcard default set in
-- lua/plugins/lspconfig.lua. Add LuaLS-specific settings here as needed.
-- See :h vim.lsp.Config for available fields.
return {}
```

**Verify**: `test -f lsp/lua_ls.lua && echo OK`.

### Step 2: Create `lsp/ts_ls.lua` (move Vue config VERBATIM)

Create `lsp/ts_ls.lua` with the ts_ls specifics, moved verbatim from the
current loop (do NOT "fix" the `getcwd()` — that's N2, a separate follow-up):

```lua
-- ts_ls (typescript-language-server) config, with @vue/typescript-plugin for .vue support.
-- Shared on_attach + capabilities come from the wildcard default set in
-- lua/plugins/lspconfig.lua.
--
-- NOTE (deferred N2): the `location` below is resolved once at config load
-- via vim.fn.getcwd(), so it is frozen to the launch dir. Moving it here
-- isolates the bug; a per-attach fix via `before_init` is a follow-up.
return {
	filetypes = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
		"vue",
	},
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
}
```

**Verify**: `test -f lsp/ts_ls.lua && echo OK`. The `location` line must be
byte-identical to the current `lspconfig.lua` version (preserves behavior).

### Step 3: Create `lsp/gopls.lua` and `lsp/ruby_lsp.lua`

`lsp/gopls.lua`:
```lua
-- gopls config. Shared on_attach + capabilities come from the wildcard default.
return {}
```

`lsp/ruby_lsp.lua`:
```lua
-- ruby_lsp config. Shared on_attach + capabilities come from the wildcard default.
return {}
```

**Verify**: `ls lsp/gopls.lua lsp/ruby_lsp.lua` → both listed.

### Step 4: Rewrite the enable section in `lua/plugins/lspconfig.lua`

In the nvim-lspconfig spec's `config = function()` (currently lines ~76–132),
REPLACE the entire `local capabilities = ... for ... end` block with:

```lua
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
```

Also DELETE the now-unused `default_lspconfig` helper (lines ~53–61, the
`local default_lspconfig = function(capabilities) ... end` block) — nothing
references it after this change.

Leave `local keymaps = require("keymaps")` at the top of the file (still used
by the wildcard on_attach and by the rustaceanvim on_attach).

**Verify**:
- `grep -n 'default_lspconfig' lua/plugins/lspconfig.lua` → no matches.
- `grep -nE 'for _, lsp in ipairs|elseif lsp ==' lua/plugins/lspconfig.lua` →
  no matches.
- `grep -n 'vim.lsp.config("\*")' lua/plugins/lspconfig.lua` → one match.
- `grep -n 'vim.lsp.enable({' lua/plugins/lspconfig.lua` → one match.
- `grep -n 'MasonInstallAll\|mason_options.ensure_installed' lua/plugins/lspconfig.lua`
  → MasonInstallAll command body still present and reads
  `mason_options.ensure_installed` (unchanged).

### Step 5: Establish `after/ftplugin/markdown.lua` (pattern + small improvement)

Create `after/ftplugin/markdown.lua` (borrowed from paketo, establishes the
ftplugin pattern for future per-filetype config):

```lua
-- Markdown filetype config. Borrowed from baseddxyz/paketo.
-- Establishes the after/ftplugin/ pattern for per-filetype settings.
vim.cmd("setlocal spell wrap")
vim.cmd("setlocal foldmethod=expr foldexpr=v:lua.vim.treesitter.foldexpr()")
```

(This is additive behavior — spell + wrap + treesitter fold for markdown. If
the maintainer doesn't want spell-checking, drop the first line; keep the
rest. Treesitter fold needs the markdown parser, which is in
`treesitter_options.ensure_installed`.)

**Verify**: `test -f after/ftplugin/markdown.lua && echo OK`.

### Step 6: Parse-check and commit

**Verify** (each parses — note `lsp/*.lua` use `loadfile` since they're not
on rtp from the worktree root without nvim's config resolution):
```bash
for f in lua/plugins/lspconfig.lua lsp/lua_ls.lua lsp/ts_ls.lua lsp/gopls.lua lsp/ruby_lsp.lua after/ftplugin/markdown.lua; do
  nvim --headless -u NONE +"lua local fn,err=loadfile('$f'); assert(fn,err)" +qa && echo "OK $f" || echo "FAIL $f"
done
```
All six should print `OK`.

- Stage all six files.
- Commit: `refactor: move LSP server configs to lsp/ files via native wildcard defaults`.

**Verify**: `git show --stat HEAD` → six files (4 new lsp/, 1 new ftplugin, 1 modified lspconfig.lua).

## Test plan

- **Static (required)**: all the grep checks + the parse loop above.
- **Structural merge test (recommended, plugin-free)**: in a throwaway config
  dir, confirm the wildcard + `lsp/fakelsp.lua` merge produces a config with
  both the shared `on_attach` AND the file's own field. The planning box
  verified this exact merge behavior; a re-run in the executor's environment
  is cheap confirmation. (Not a hard gate — the behavior was verified during
  planning.)
- **Manual runtime check (requires plugins)**: load the full config, open a
  Lua file → lua_ls attaches and `gd`/`K`/`gr`/`gK` (signature help) work
  (proves wildcard on_attach propagated). Open a `.ts`/`.vue` file → ts_ls
  attaches with Vue plugin. Open a `.go` → gopls. Open a `.rb` → ruby_lsp.
  Open a `.rs` → rust_analyzer still attaches (rustaceanvim, unaffected).
  Open a `.md` → spell + treesitter fold active.
- **MasonInstallAll orthogonality**: `:MasonInstallAll` still installs all 5
  servers + formatters (it reads the unchanged `mason_options.ensure_installed`).

## Done criteria

ALL must hold:

- [ ] `ls lsp/lua_ls.lua lsp/ts_ls.lua lsp/gopls.lua lsp/ruby_lsp.lua` → all four exist.
- [ ] `test -f after/ftplugin/markdown.lua` succeeds.
- [ ] `grep -n 'default_lspconfig' lua/plugins/lspconfig.lua` → no matches.
- [ ] `grep -nE 'for _, lsp in ipairs|elseif lsp ==' lua/plugins/lspconfig.lua` → no matches.
- [ ] `grep -n 'vim.lsp.config("\*")' lua/plugins/lspconfig.lua` → one match.
- [ ] `grep -n 'vim.lsp.enable({' lua/plugins/lspconfig.lua` → one match listing
  exactly `{ "lua_ls", "ts_ls", "gopls", "ruby_lsp" }` (no rust_analyzer).
- [ ] The `MasonInstallAll` command body is byte-identical to before
  (`git show 2f10ac4:lua/plugins/lspconfig.lua | sed -n '/MasonInstallAll/,/},/p'`
  matches the new file's same region).
- [ ] All six in-scope files parse (the Step 6 loop prints `OK` each).
- [ ] `git show --stat HEAD` shows exactly: 4 new `lsp/`, 1 new
  `after/ftplugin/markdown.lua`, 1 modified `lua/plugins/lspconfig.lua`.
- [ ] `lua/plugins/java.lua` and the rustaceanvim spec are NOT modified beyond
  what was already there.
- [ ] `plans/README.md` status row for 013 updated.

## STOP conditions

Stop and report back (do not improvise) if:

- **`vim.lsp.config("*", ...)` does not merge into named configs in your
  environment.** This was verified on the planning box (nvim 0.12.3): wildcard
  `on_attach`/capabilities propagated to a named config loaded from
  `lsp/<name>.lua`. If a re-check shows the merge doesn't happen, the whole
  "shared defaults via wildcard" approach fails and each `lsp/<name>.lua`
  would need its own `on_attach`. STOP and report; do not duplicate on_attach
  silently (that hides the real issue).
- **`lsp/<name>.lua` is not auto-discovered.** Verified on the planning box
  (a fake server's `_marker` resolved). If your nvim requires `after/lsp/`
  (paketo's path) instead of top-level `lsp/`, move the four files to
  `after/lsp/` and report — but verify first; top-level `lsp/` is canonical.
- **rust-analyzer stops attaching to `.rs` files** after removing it from the
  enable list. It shouldn't (rustaceanvim manages it via `vim.g.rustaceanvim`,
  independent of `vim.lsp.enable`). If it does, report — re-adding
  `"rust_analyzer"` to the enable list would just paper over the real issue.
- **MasonInstallAll changes.** The command body must stay byte-identical
  (orthogonality, plan 010 decision 5). If your refactor touched it, STOP.
- Any file at the cited locations doesn't match its excerpt (drift). Report.

## Maintenance notes

- **The two-list invariant:** the set passed to `vim.lsp.enable({...})`
  (loop-managed servers) is a SUBSET of `mason_options.ensure_installed`
  (servers to install), MINUS `rust_analyzer` (rustaceanvim-owned) and
  `jdtls` (nvim-jdtls-owned). If you add a new loop-managed server: (a) add
  it to `mason_options.ensure_installed` + `mason_lsp_mapping` (Mason),
  (b) create `lsp/<name>.lua`, (c) add it to the `vim.lsp.enable({...})` list.
  Three places, documented here so they stay in sync.
- **N2 (ts_ls Vue `getcwd()`) is now a one-file follow-up.** It lives in
  `lsp/ts_ls.lua` and is flagged in a comment there. The fix: replace the
  frozen `location = vim.fn.getcwd() .. ...` with a `before_init` hook that
  resolves the path relative to the project root at attach time. Out of scope
  here; the isolation is the win.
- **Wildcard on_attach vs rust/jdtls:** the wildcard applies ONLY to servers
  enabled via `vim.lsp.enable` (lua_ls, ts_ls, gopls, ruby_lsp). rustaceanvim
  and jdtls set their OWN on_attach (in `lspconfig.lua` rust spec and
  `java.lua`), which correctly call `keymaps.lsp()` themselves. Keep that
  distinction when adding servers.
- **Reviewer focus**: confirm the MasonInstallAll body is untouched, the
  enable list has exactly the 4 servers, the wildcard has the shared
  on_attach + capabilities, and `default_lspconfig` is fully removed.
- **Lesson from planning**: the wildcard-merge API (`vim.lsp.config("*", ...)`)
  was verified empirically before writing this plan, not assumed — same
  discipline that caught the plan-007 digraph and plan-010 `package.path`
  issues. The `lsp/<name>.lua` auto-discovery and list-enable were likewise
  tested with a fake server.
