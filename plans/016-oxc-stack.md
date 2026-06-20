# Plan 016: Switch JS/TS linting + formatting to the oxc stack (oxlint + oxfmt)

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md`.
>
> **Drift check (run first)**:
> `git diff --stat 28819ec..HEAD -- lua/plugins/web-linter.lua lua/plugins/lspconfig.lua`
> If either file changed since this plan was written, compare the "Current
> state" excerpts against the live code before proceeding; on a mismatch,
> treat it as a STOP condition.

## Status

- **Priority**: P1 (fixes a live regression)
- **Effort**: S
- **Risk**: LOW (tool swap; both oxc tools verified real in nvim-lint, conform, AND mason)
- **Depends on**: none
- **Category**: bug / dx
- **Planned at**: commit `28819ec`, 2026-06-19
- **Supersedes**: plan 003 (which introduced the regression by renaming `biomejs` → `biome`)

## Why this matters

### The regression (P1 — must fix)
Plan 003 (commit `b021096`) renamed the nvim-lint linter from `biomejs` to
`biome` on the *assumption* that the linter name matched the Mason package
name. That assumption was **wrong**: nvim-lint ships exactly one Biome
linter, registered as `biomejs` (file `lua/lint/linters/biomejs.lua`, verified
in nvim-lint source). `biome` is the *Mason package* name (the binary) — a
different namespace. The result is a live error on every JS/TS buffer read:

```
lua/lint.lua:82: Linter with name `biome` not available
```

This was the MED-confidence risk I flagged in plan 003 and proceeded past
without verifying the linter name against nvim-lint's source — exactly the
verification discipline I'd applied elsewhere this session. My mistake.

### The resolution: switch to oxc (user's choice)
Rather than revert to `biomejs`, the maintainer chose to switch the whole
JS/TS toolchain to the **oxc** stack (oxlint for linting, oxfmt for
formatting). This both fixes the regression AND upgrades to faster,
ESLint-compatible tooling.

### Verified real (all three namespaces checked, no assumptions)

| Tool | nvim-lint name | conform name | Mason package | Status |
|---|---|---|---|---|
| **oxlint** (linter) | `oxlint` ✓ (`lua/lint/linters/oxlint.lua`) | — | `oxlint` ✓ (mason-registry) | Stable, widely used |
| **oxfmt** (formatter) | — | `oxfmt` ✓ (`lua/conform/formatters/oxfmt.lua`) | `oxfmt` ✓ (mason-registry `@0.55.0`) | **Pre-1.0** — see caveat |

**oxfmt caveat (honest):** `oxfmt` is pre-1.0 (npm `0.x`). Its formatting
output may change between minor bumps, which can reformat an entire repo on
upgrade. The maintainer has accepted this tradeoff for a personal config. If
that becomes painful, reverting the formatter to biome is a one-line change
(documented in Maintenance).

oxfmt's config-file detection (from conform source): `.oxfmtrc.json`,
`.oxfmtrc.jsonc`, `oxfmt.config.ts`, `vite.config.{ts,js}`.

## Current state

### `lua/plugins/web-linter.lua` (the regression — full file)

```lua
local linters = {
	-- web
	'biome',
}

return {
	{
		'mfussenegger/nvim-lint',
		ft = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
		opts = {
			-- Events to trigger linter
			events = { "BufWritePost", "BufReadPost", "InsertLeave" },
			linters_by_ft = {
				javascript = { 'biome' },
				javascriptreact = { 'biome' },
				typescript = { 'biome' },
				typescriptreact = { 'biome' },
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
				opts.events,
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
```

(The `opts.events` wiring from plan 003 is CORRECT — keep it. Only the linter
name and the Mason install list change.)

### `lua/plugins/lspconfig.lua` conform block (lines ~196–207)

```lua
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
```

Note: `typescript = { "biome" }` is inconsistent with the others (`biome-check`)
— this is deferred finding TECH-7. The oxc swap makes TECH-7 moot (all four
filetypes get the same formatter).

### `lua/plugins/lspconfig.lua` formatter install list (line ~46)

```lua
local mason_formatters = {
	ensure_installed = { "biome", "stylua" },
}
```

This drives `MasonInstallAll`. With the formatter swap, `biome` → `oxfmt`.
`stylua` (Lua) and `google-java-format` (Java, conform-only, not in this list)
are unchanged.

### `lua/plugins/lspconfig.lua` `mason_lsp_mapping` (lines ~28–40)

Contains `stylua = "stylua"` but NOT `biome` — biome was never in the LSP
mapping (it's a formatter/linter, not an LSP server). **Do not add oxfmt or
oxlint here either** — this table maps LSP server names to Mason packages;
formatters/linters are separate. (This is the namespace distinction plan 003
got wrong on the linter side; be precise here.)

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| No `biome`/`biomejs` left in web-linter | `grep -nE 'biome' lua/plugins/web-linter.lua` | no matches |
| oxlint present in web-linter | `grep -n 'oxlint' lua/plugins/web-linter.lua` | ≥4 matches (install list + 4 by_ft) |
| No `biome` left in conform formatters | `grep -nE 'biome' lua/plugins/lspconfig.lua` | only `stylua = "stylua"`-adjacent if any; the 4 biome entries gone |
| oxfmt present in conform | `grep -n 'oxfmt' lua/plugins/lspconfig.lua` | 4 matches + 1 in ensure_installed |
| mason_formatters updated | `grep -n 'ensure_installed' lua/plugins/lspconfig.lua` | shows `{ "oxfmt", "stylua" }` |
| Files parse | see Done criteria | exit 0 each |

## Scope

**In scope** (the only files you should modify):
- `lua/plugins/web-linter.lua` — rename `biome` → `oxlint` (4 by_ft entries + the `linters` install list).
- `lua/plugins/lspconfig.lua` — replace the 4 biome conform formatters with `oxfmt`; update `mason_formatters.ensure_installed`.

**Out of scope** (do NOT touch):
- `lua = { "stylua" }` and `java = { "google-java-format" }` conform entries —
  unrelated languages, keep them.
- `mason_lsp_mapping` (LSP server → Mason package map) — oxlint/oxfmt are
  NOT LSP servers; they don't belong here.
- `mason_options.ensure_installed` (LSP servers list) — unchanged.
- `nvim-lint` plugin spec structure (ft, opts.events, autocmd, deps) — keep
  plan 003's wiring intact; only the names change.
- The `<leader>fM` conform-format keymap — unchanged.

## Git workflow

- Branch: `advisor/016-oxc-stack`
- Single commit. Message style (conventional commits):
  `fix: switch JS/TS lint+format to oxc stack (oxlint + oxfmt), fixes biome regression`.

## Steps

### Step 1: Switch the linter to oxlint in `web-linter.lua`

Change `biome` → `oxlint` in **two places**: the `linters` install list (line 3)
and all four `linters_by_ft` entries (lines 14–17).

The top of the file becomes:
```lua
local linters = {
	-- web
	'oxlint',
}
```

The `linters_by_ft` block becomes:
```lua
				linters_by_ft = {
					javascript = { 'oxlint' },
					javascriptreact = { 'oxlint' },
					typescript = { 'oxlint' },
					typescriptreact = { 'oxlint' },
				},
```

Leave `opts.events`, the config function, the autocmd, and dependencies
unchanged (plan 003's wiring was correct; only the names were wrong).

**Verify**:
- `grep -nE 'biome' lua/plugins/web-linter.lua` → no matches.
- `grep -c 'oxlint' lua/plugins/web-linter.lua` → 5 (1 install list + 4 by_ft).

### Step 2: Switch the formatter to oxfmt in `lspconfig.lua` conform block

Replace the four biome entries in `formatters_by_ft` with `oxfmt`. This also
resolves the TECH-7 inconsistency (all four web filetypes now use the same
formatter).

Before:
```lua
				formatters_by_ft = {
					lua = { "stylua" },
					javascript = { "biome-check" },
					javascriptreact = { "biome-check" },
					typescript = { "biome" },
					typescriptreact = { "biome-check" },
					java = { "google-java-format" },
				},
```

After:
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

**Verify**:
- `grep -nE 'biome' lua/plugins/lspconfig.lua` in the conform block → no
  `biome-check`/`biome` formatter entries (only `stylua`/`oxfmt`/`google-java-format` remain).
- `grep -c 'oxfmt' lua/plugins/lspconfig.lua` → 5 (4 formatters + 1 in ensure_installed, set next).

### Step 3: Update the Mason formatter install list

In `lua/plugins/lspconfig.lua` line ~46, replace `"biome"` with `"oxfmt"`:

Before:
```lua
local mason_formatters = {
	ensure_installed = { "biome", "stylua" },
}
```

After:
```lua
local mason_formatters = {
	ensure_installed = { "oxfmt", "stylua" },
}
```

**Verify**: `grep -n 'ensure_installed = { "oxfmt"' lua/plugins/lspconfig.lua` → one match.

### Step 4: Parse-check and commit

**Verify**:
```bash
for f in lua/plugins/web-linter.lua lua/plugins/lspconfig.lua; do
  nvim --headless -u NONE +"lua local fn,err=loadfile('$f'); assert(fn,err)" +qa && echo "OK $f" || echo "FAIL $f"
done
```
Both print `OK`.

- Stage both files.
- Commit: `fix: switch JS/TS lint+format to oxc stack (oxlint + oxfmt), fixes biome regression`.

**Verify**: `git show --stat HEAD` → exactly two files changed.

## Test plan

- **Static (required)**: all grep checks + parse loop above.
- **Linter registration (recommended, requires plugins)**: load the config,
  run `:lua print(vim.inspect(vim.tbl_keys(require('lint').linters)))` —
  `oxlint` should be present. Open a `.ts` file with a lint error; confirm
  diagnostics appear with `source = "oxlint"` and NO "Linter not available"
  error (that's the regression proof — gone).
- **Formatter (recommended, requires plugins)**: run `:MasonInstallAll` (or
  `:MasonInstall oxlint oxfmt`); open a `.ts` file, run `:ConformInfo` —
  `oxfmt` should be the selected formatter. Trigger format (`<leader>fM>` or
  write — `format_on_save`); confirm it formats without error.
- **Mason orthogonality**: `:MasonInstallAll` installs both `oxlint` and
  `oxfmt` (via `mason_formatters.ensure_installed` and the web-linter's own
  install loop). Neither tool should be in `mason_lsp_mapping`.

## Done criteria

ALL must hold:

- [ ] `grep -nE 'biome' lua/plugins/web-linter.lua` returns no matches.
- [ ] `grep -c 'oxlint' lua/plugins/web-linter.lua` returns 5.
- [ ] The conform `formatters_by_ft` block has `oxfmt` for all four web
  filetypes (no `biome`/`biome-check` entries).
- [ ] `grep -n 'ensure_installed = { "oxfmt"' lua/plugins/lspconfig.lua` returns one match.
- [ ] `lua = { "stylua" }` and `java = { "google-java-format" }` are unchanged.
- [ ] `mason_lsp_mapping` does NOT contain `oxlint` or `oxfmt` (they aren't LSP servers).
- [ ] Both files parse (Step 4 loop prints `OK` each).
- [ ] `git show --stat HEAD` shows only the two in-scope files.
- [ ] `plans/README.md` status row for 016 updated, plan 003 marked superseded,
  and TECH-7 marked moot (resolved by the uniform oxfmt swap).

## STOP conditions

Stop and report back (do not improvise) if:

- **`oxlint` is not a registered nvim-lint linter** in your environment. This
  was verified against nvim-lint source (`lua/lint/linters/oxlint.lua` exists
  at the lazy-lock commit). If a re-check (`:lua print(require('lint').linters.oxlint ~= nil)`)
  shows nil, report — the linter file may have been renamed in a newer nvim-lint.
  Do not fall back to `biome` (that's the regression); report and let the
  operator decide.
- **`oxfmt` is not a registered conform formatter.** Verified in conform source
  (`lua/conform/formatters/oxfmt.lua`). If a re-check shows it's gone, report.
- **Mason rejects `oxlint` or `oxfmt` as a package name.** Verified in
  `mason-org/mason-registry` (both exist). If `:MasonInstall oxlint oxfmt`
  errors, report the error — do not guess alternate names.
- You're tempted to add `oxlint`/`oxfmt` to `mason_lsp_mapping`. Don't — that
  table is LSP-server→package only. This is the exact namespace confusion that
  caused the original regression.
- Any file at the cited locations doesn't match its excerpt (drift). Report.

## Maintenance notes

- **Why this is correct where plan 003 was wrong:** plan 003 conflated the
  Mason package name (`biome`) with the nvim-lint linter name (`biomejs`). For
  oxc the two namespaces happen to align (`oxlint`/`oxfmt` in both), but the
  discipline matters: each namespace was checked independently against its
  own source (nvim-lint source for linter names, conform source for formatter
  names, mason-registry for package names).
- **oxfmt is pre-1.0.** A future `oxfmt` minor bump may reformat codebases.
  If that churn becomes unwanted, revert Step 2's conform entries to
  `biome-check`/`biome` (and Step 3's install list back to `biome`) — biome
  is stable post-1.0. The linter (oxlint) is independent and unaffected.
- **TECH-7 (the `typescript = { "biome" }` vs `biome-check` inconsistency)
  is now moot** — all four web filetypes uniformly use `oxfmt`. Record it
  resolved-by-016 in the index.
- **Reviewer focus**: confirm (a) no `biome`/`biomejs` anywhere in the two
  files, (b) `oxlint` x5 in web-linter, `oxfmt` x5 in lspconfig, (c) the LSP
  mapping table is untouched, (d) `opts.events`/autocmd structure from 003
  preserved.
- **Lesson (on the record)**: plan 003's regression is the negative example
  that proves the verification discipline. Every other plan this session that
  checked the actual source/behavior (007 digraphs, 010 `package.path`, 013
  wildcard-merge, 015 `before_init`) avoided shipping a bug; plan 003 skipped
  the linter-name check and shipped one. Plans 016+ must verify tool names in
  EACH namespace they touch.
