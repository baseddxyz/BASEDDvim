# Plan 017: Add Python support via the astral.sh stack (ruff + ty)

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md`.
>
> **Drift check (run first)**:
> `git diff --stat 3934b32..HEAD -- lua/plugins/lspconfig.lua lua/plugins/web-linter.lua`
> If either file changed since this plan was written, compare the "Current
> state" excerpts against the live code before proceeding; on a mismatch,
> treat it as a STOP condition.

## Status

- **Priority**: P2 (new language support)
- **Effort**: S
- **Risk**: LOW (additive; uses lspconfig-provided defaults + one override)
- **Depends on**: none (works on top of plan 013's native `lsp/` pattern and
  your post-pull `mason_linters`/`mason_formatters` split)
- **Category**: feature
- **Planned at**: commit `3934b32`, 2026-06-20

## Why this matters

The repo currently has **no Python support** — `python` is commented out of
treesitter, `pyright`/`ruff` are commented out of the Mason lists, and no
Python LSP is enabled. This plan adds the **astral.sh stack** end-to-end:

- **`ty`** (Astral's type checker) as an LSP — fast types + hover + diagnostics
- **`ruff`** (Astral's linter) as an LSP — linting + code actions + diagnostics
- **`ruff_format` + `ruff_organize_imports`** in conform — format-on-save
- **`python`** in treesitter — syntax highlighting

This matches what `baseddxyz/paketo` (the same author's other config) already
does (`mise.toml` ships `ty`; `plugin/40_plugins.lua` enables `ty` + `ruff`),
and the existing commented-out `pyright`/`ruff` lines in this repo signal the
same intent — now resolved with the more cohesive Astral-native choice.

### Verified (all three namespaces checked against real sources — no assumptions)

| Tool | lspconfig server | conform name | Mason package |
|---|---|---|---|
| ty | `ty` (`cmd={'ty','server'}`, `filetypes={'python'}`, root_markers include `ty.toml`/`pyproject.toml`) ✓ | — | `ty` (`pkg:pypi/ty@0.0.51`) ✓ |
| ruff | `ruff` (`cmd={'ruff','server'}`, `filetypes={'python'}`, root_markers `pyproject.toml`/`ruff.toml`/`.ruff.toml`) ✓ | (also `ruff_format`/`ruff_organize_imports`) | `ruff` (`pkg:pypi/ruff`) ✓ |
| ruff format | — | `ruff_format` (runs `ruff format`) ✓ | (same `ruff` binary) |
| ruff imports | — | `ruff_organize_imports` (runs `ruff check --fix --select=I001`) ✓ | (same `ruff` binary) |

**`ty` is alpha** (`0.0.x` versioning — Astral's newest tool). It type-checks
fast and the LSP works, but expect rough edges and behavior changes between
versions. For a personal config that's fine and Astral-consistent; reverting
to pyright later is trivial (swap `"ty"` → `"pyright"` in the enable list).

### Why no redundant `lsp/ruff.lua`/`lsp/ty.lua` files (corrected from plan 013's pattern)

Plan 013 created `lsp/{lua_ls,gopls,ruby_lsp}.lua` with `return {}` — verified
later to be **redundant no-ops** because nvim-lspconfig already ships native
`lsp/<name>.lua` configs (deep-merged by Neovim's loader; lspconfig provides
`cmd`/`filetypes`/`root_markers` for free). This plan follows the corrected
discipline: **only create `lsp/<name>.lua` when there's something real to
override.**

- `lsp/ruff.lua` — created here, with a real override: disable ruff LSP's
  `organizeImports` so it doesn't fight conform's `ruff_organize_imports` on
  save (the same reason the old commented pyright had `disableOrganizeImports`).
- `lsp/ty.lua` — **not created.** Its lspconfig defaults are correct; nothing
  to override.

### How ty + ruff coexist

Both attach to `.py` files. ruff gives lint diagnostics + code actions; ty
gives type diagnostics + types. They complement each other — `:LspInfo` will
show two clients per Python buffer, which is expected and correct (paketo
runs the same combo).

## Current state

### Mason install lists (`lua/plugins/lspconfig.lua`, post pull `3934b32`)

```lua
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

local mason_linters = {
	ensure_installed = { "oxlint" },
}
local mason_formatters = {
	ensure_installed = { "oxfmt", "stylua" },
}
```

### Enable list + wildcard (`lua/plugins/lspconfig.lua`, line ~88)

```lua
			vim.lsp.enable({ "lua_ls", "ts_ls", "gopls", "ruby_lsp" })
```

### Conform formatters (`lua/plugins/lspconfig.lua`, ~line 199, post plan 016)

```lua
				formatters_by_ft = {
					lua = { "stylua" },
					javascript = { "oxfmt" },
					javascriptreact = { "oxfmt" },
					typescript = { "oxfmt" },
					typescriptreact = { "oxfmt" },
					java = { "google-java-format" },
				},
```

### Treesitter (`lua/plugins/lspconfig.lua`, top of file)

```lua
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
```

### `MasonInstallAll` wiring (the three-list pattern you established in `3934b32`)

The command concatenates `mason_formatters.ensure_installed`, then
`mason_servers` (from `mason_lsp_mapping`), then `mason_linters.ensure_installed`.
So adding to `mason_options.ensure_installed` + `mason_lsp_mapping` is what
gets a new LSP installed; adding to `mason_linters` gets a new linter installed.

### Repo conventions to match

- Three-list Mason pattern: `mason_options` (LSP), `mason_linters`, `mason_formatters`.
- `lsp/<name>.lua` only when overriding (corrected discipline from plan 013's review).
- Tabs for indentation.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| ruff in mason_options | `grep -n '"ruff"' lua/plugins/lspconfig.lua` | one match in mason_options |
| ty in mason_options | `grep -n '"ty"' lua/plugins/lspconfig.lua` | one match in mason_options |
| enable list has both | `grep -n 'vim.lsp.enable({' lua/plugins/lspconfig.lua` | includes `"ruff", "ty"` |
| ruff override file exists | `test -f lsp/ruff.lua && echo OK` | OK |
| NO lsp/ty.lua (not redundant) | `test ! -e lsp/ty.lua && echo OK` | OK |
| conform has python entry | `grep -n 'python' lua/plugins/lspconfig.lua` | `python = { "ruff_organize_imports", "ruff_format" }` |
| treesitter has python | `grep -n '"python"' lua/plugins/lspconfig.lua` | one match (uncommented) |
| Files parse | see Done criteria loop | exit 0 each |

## Scope

**In scope** (the only files you should create or modify):
- `lua/plugins/lspconfig.lua` — enable `ruff`+`ty`; add them to `mason_options` + `mason_lsp_mapping`; add `python` to treesitter; add `python` to conform.
- `lsp/ruff.lua` (new) — the one real override (disable organize-imports).

**Out of scope** (do NOT touch):
- `lua/plugins/web-linter.lua` — JS/TS linting; unrelated to Python.
- `lua/plugins/java.lua`, rustaceanvim spec — other languages.
- The wildcard defaults block — the shared `on_attach`/`capabilities` from
  plan 013 apply to ruff/ty automatically (they're enabled servers).
- Do NOT create `lsp/ty.lua` — redundant; lspconfig provides correct defaults.
- Do NOT wire nvim-lint for Python — ruff LSP already provides diagnostics;
  doubling up causes duplicate diagnostics (the lesson from the biome regression).

## Git workflow

- Branch: `advisor/017-python-astral`
- Single commit. Message style (conventional commits):
  `feat: add Python support via astral stack (ruff + ty)`.

## Steps

### Step 1: Enable ruff + ty in the enable list

In `lua/plugins/lspconfig.lua` (~line 88), add `ruff` and `ty` to the
`vim.lsp.enable({...})` list:

Before:
```lua
			vim.lsp.enable({ "lua_ls", "ts_ls", "gopls", "ruby_lsp" })
```

After:
```lua
			vim.lsp.enable({ "lua_ls", "ts_ls", "gopls", "ruby_lsp", "ruff", "ty" })
```

**Verify**: `grep -n 'vim.lsp.enable({' lua/plugins/lspconfig.lua` → the list
ends with `..., "ruff", "ty" }`.

### Step 2: Add ruff + ty to the Mason install lists

In `mason_options.ensure_installed`, replace the commented `-- "pyright",` and
`-- "ruff",` block. Since you're switching to the astral stack (no pyright),
uncomment `"ruff"` and add `"ty"`. Remove the `pyright` line (the astral stack
uses ty for types). Result:

```lua
local mason_options = {
	ensure_installed = {
		"lua_ls",
		"ts_ls",
		"ruff",
		"ty",
		"rust_analyzer",
		"gopls",
		"ruby_lsp",
	},
}
```

(Also remove the now-stale `-- "svelte",` if it bothers you, or leave it.
Drop the commented `pyright`.)

In `mason_lsp_mapping`, replace the commented pyright/ruff lines with the
real mappings:

```lua
local mason_lsp_mapping = {
	gopls = "gopls",
	lua_ls = "lua-language-server",
	ruff = "ruff",
	ty = "ty",
	rust_analyzer = "rust-analyzer",
	stylua = "stylua",
	ts_ls = "typescript-language-server",
	ruby_lsp = "ruby-lsp",
}
```

(The Mason package name == lspconfig server name for both — verified. `ruff`
installs the `ruff` binary that serves the ruff LSP AND the conform
formatters; `ty` installs the `ty` binary.)

**Verify**:
- `grep -n '"ruff"' lua/plugins/lspconfig.lua` → ≥2 matches (mason_options + mason_lsp_mapping).
- `grep -n '"ty"' lua/plugins/lspconfig.lua` → ≥2 matches (same).

### Step 3: Create `lsp/ruff.lua` (the one real override)

Create `lsp/ruff.lua` (repo root). Its single purpose: disable ruff LSP's
import-organizing so conform's `ruff_organize_imports` (Step 5) is the single
source of truth for import sorting on save (otherwise both try to do it and
you get conflicts/duplicate work).

```lua
-- ruff (Astral's Python linter) LSP config.
-- Base config (cmd, filetypes, root_markers) comes from nvim-lspconfig's
-- shipped lsp/ruff.lua — this file only overrides what differs.
-- Shared on_attach + capabilities come from the wildcard default in
-- lua/plugins/lspconfig.lua.
--
-- Disable ruff LSP's organizeImports so it doesn't conflict with conform's
-- ruff_organize_imports formatter (the single source of truth for import
-- sorting on save). ruff still provides lint diagnostics + code actions.
return {
	init_options = {
		settings = {
			organizeImports = false,
		},
	},
}
```

This merges on top of lspconfig's `lsp/ruff.lua` (verified merge behavior —
the same deep-extend mechanism that confirmed plan 013's `{}` files were
harmless no-ops).

**Verify**: `test -f lsp/ruff.lua && grep -q 'organizeImports' lsp/ruff.lua && echo OK` → OK.

### Step 4: Add `python` to treesitter

In `treesitter_options.ensure_installed`, uncomment the `"python"` line:

Before:
```lua
		"markdown",
		-- "python",
		"rust",
```

After:
```lua
		"markdown",
		"python",
		"rust",
```

**Verify**: `grep -n '"python"' lua/plugins/lspconfig.lua` → one match (no `--`).

### Step 5: Add `python` to conform formatters

In the conform `formatters_by_ft` block, add a `python` entry. Astral's
documented order is **organize imports first, then format**:

```lua
				formatters_by_ft = {
					lua = { "stylua" },
					javascript = { "oxfmt" },
					javascriptreact = { "oxfmt" },
					typescript = { "oxfmt" },
					typescriptreact = { "oxfmt" },
					java = { "google-java-format" },
					python = { "ruff_organize_imports", "ruff_format" },
				},
```

**Verify**: `grep -n 'python = {' lua/plugins/lspconfig.lua` →
`python = { "ruff_organize_imports", "ruff_format" },`.

### Step 6: Parse-check and commit

**Verify**:
```bash
for f in lua/plugins/lspconfig.lua lsp/ruff.lua; do
  nvim --headless -u NONE +"lua local fn,err=loadfile('$f'); assert(fn,err)" +qa && echo "OK $f" || echo "FAIL $f"
done
```
Both print `OK`.

- Stage `lua/plugins/lspconfig.lua` and `lsp/ruff.lua`.
- Commit: `feat: add Python support via astral stack (ruff + ty)`.

**Verify**: `git show --stat HEAD` → exactly two files (1 modified, 1 new).

## Test plan

- **Static (required)**: all grep checks + parse loop.
- **Install (recommended)**: run `:MasonInstallAll` — it should install both
  `ruff` and `ty` (via the three-list wiring you set up). Confirm with
  `:Mason` that both appear as installed.
- **LSP attach (recommended)**: open a `.py` file with some type/lint issues;
  `:LspInfo` should show BOTH `ruff` and `ty` attached. Hover (`K`) on a
  function should show type info from `ty`. Lint diagnostics should be
  sourced from `ruff`.
- **Format-on-save (recommended)**: with `format_on_save` on, saving a `.py`
  file should run `ruff_organize_imports` then `ruff_format` (verify with
  `:ConformInfo`). Imports get sorted, code gets formatted.
- **Type checking (recommended)**: a deliberate type error (e.g.
  `x: int = "string"`) should produce a diagnostic from `ty`.

## Done criteria

ALL must hold:

- [ ] `vim.lsp.enable({...})` list ends with `..., "ruff", "ty" }`.
- [ ] `mason_options.ensure_installed` contains `"ruff"` and `"ty"` (uncommented); `pyright` is gone.
- [ ] `mason_lsp_mapping` contains `ruff = "ruff"` and `ty = "ty"` (no `pyright`).
- [ ] `test -f lsp/ruff.lua` succeeds and it contains `organizeImports = false`.
- [ ] `test ! -e lsp/ty.lua` succeeds (NOT created — redundant).
- [ ] `treesitter_options.ensure_installed` has `"python"` uncommented.
- [ ] conform `formatters_by_ft` has
  `python = { "ruff_organize_imports", "ruff_format" },`.
- [ ] Both files parse (Step 6 loop prints `OK`).
- [ ] `git show --stat HEAD` shows only `lua/plugins/lspconfig.lua` (modified) and `lsp/ruff.lua` (new).
- [ ] `lua/plugins/web-linter.lua` is NOT modified (Python is separate from JS/TS linting).
- [ ] `plans/README.md` status row for 017 updated.

## STOP conditions

Stop and report back (do not improvise) if:

- **`ruff` or `ty` is not a valid `vim.lsp.enable` target** in your
  environment. Both are verified as lspconfig-shipped native `lsp/<name>.lua`
  configs. If `:LspInfo` or `:checkhealth lspconfig` doesn't recognize them,
  report — your lspconfig may be too old (the post-pull lazy-lock pins a recent
  `nvim-lspconfig`; the lockfile bump in `3934b32` matters here).
- **`ruff_format` or `ruff_organize_imports` is not a registered conform
  formatter.** Verified in conform source. If `:ConformInfo` doesn't list them,
  report — conform version may differ.
- **Mason rejects `ruff` or `ty` as a package.** Verified in mason-registry.
  If `:MasonInstall ruff ty` errors, report the error.
- **You're tempted to create `lsp/ty.lua`.** Don't — its defaults are correct.
  Only create it if you find a real setting to override, and report first.
- **You're tempted to add `ruff` to `mason_linters` (the oxlint list).** Don't —
  `ruff` here is an LSP server (linter via LSP), not a standalone nvim-lint
  linter. It goes in `mason_options` + `mason_lsp_mapping`. This is the
  namespace discipline from plan 016.
- Any file at the cited locations doesn't match its excerpt (drift). Report.

## Maintenance notes

- **Why `lsp/ruff.lua` exists but `lsp/ty.lua` doesn't:** ruff needs the
  `organizeImports = false` override to avoid fighting conform; ty has nothing
  to override. This is the corrected discipline from plan 013's review (don't
  create redundant `{}` files — let lspconfig's shipped defaults provide the
  base).
- **ruff LSP serves linting; do NOT also wire nvim-lint for Python.** Double-wiring
  causes duplicate diagnostics. nvim-lint stays JS/TS-only (oxlint).
- **ty is alpha.** If its rough edges bother you, swap `"ty"` → `"pyright"`
  in the enable list + `mason_options`/`mason_lsp_mapping` (and add a
  `lsp/pyright.lua` with `disableOrganizeImports = true` + the
  `python.analysis.ignore = { "*" }` pattern you previously had commented out).
  One-line conceptual change.
- **The two-LSP-per-buffer pattern (ruff + ty) is intentional and matches
  paketo.** Don't try to collapse to one — they do different jobs (lint vs types).
- **Reviewer focus**: confirm (a) enable list has both, (b) mason_options +
  mason_lsp_mapping have both with correct names, (c) `lsp/ruff.lua` has ONLY
  the organizeImports override (not a full cmd/filetypes repeat), (d) no
  `lsp/ty.lua`, (e) web-linter.lua untouched.
- **Lesson**: this plan applies the corrected plan-013 discipline (no
  redundant `{}` files) and the plan-016 namespace discipline (ruff is an LSP
  here, so it goes in mason_options/mason_lsp_mapping, not mason_linters).
  Both lessons came from earlier mistakes this session.
