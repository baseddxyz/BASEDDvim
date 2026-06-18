# Plan 003: Fix nvim-lint linter name (`biomejs` → `biome`) and honor `opts.events`

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md`.
>
> **Drift check (run first)**:
> `git diff --stat baf9a2c..HEAD -- lua/plugins/web-linter.lua`
> If `lua/plugins/web-linter.lua` changed since this plan was written, compare
> the "Current state" excerpt against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none (independent of 001, 002, 004, 005)
- **Category**: bug
- **Planned at**: commit `baf9a2c`, 2026-06-18
- **Finding**: BUG-3

## Why this matters

`web-linter.lua` registers JS/TS linting under the linter name `'biomejs'`, but
nvim-lint has no linter by that name — the linter nvim-lint ships (and the
Mason package this file installs, see line 3) is registered as `'biome'`.
Because nvim-lint silently skips unknown linter names, `lint.try_lint()` runs
**nothing** for JavaScript/TypeScript. The entire `nvim-lint` setup is a
no-op — with no error to tip you off. Separately, the file declares
`opts.events = { "BufWritePost", "BufReadPost", "InsertLeave" }` but the
`config` function ignores it and hardcodes `{ 'BufWritePost', 'BufEnter' }`,
so the declared event list is misleading dead config.

## Current state

`lua/plugins/web-linter.lua` — the nvim-lint plugin spec. Current file in
full:

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
				javascript = { 'biomejs' },
				javascriptreact = { 'biomejs' },
				typescript = { 'biomejs' },
				typescriptreact = { 'biomejs' },
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
				{ 'BufWritePost', 'BufEnter' },
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

Note the Mason install list at line 3 uses `'biome'` (the correct package
name) — so the tool gets installed correctly, but it is never wired to a
linter name that nvim-lint recognizes. The fix is to make `linters_by_ft`
match the registered linter name `'biome'`.

### Repo conventions to match

- The `mason_lsp_mapping` style in `lua/plugins/lspconfig.lua` shows the
  repo's pattern of keeping names consistent between Mason packages and their
  consumers.
- Keep the existing structure (top-level `local linters`, `opts` table,
  `config = function(_, opts)`). Do not restructure.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Confirm bad name gone | `grep -n 'biomejs' lua/plugins/web-linter.lua` | no matches (exit 1) |
| Confirm good name present | `grep -n "'biome'" lua/plugins/web-linter.lua` | 5 matches (1 install list + 4 by_ft) |
| Linter registered | `nvim --headless +'lua assert(require("lint").linters.biome ~= nil)' +qa` | exit 0, no output |

The runtime check requires `nvim-lint` (and its `biome` linter module) to be
installed. Per `lazy-lock.json` nvim-lint is a plugin; `biome` is installed via
Mason by this very file. In a fresh env run `nvim --headless "+Lazy! sync" +qa`
and ensure `:MasonInstall biome` has run.

## Scope

**In scope** (the only file you should modify):
- `lua/plugins/web-linter.lua` — rename the 4 `'biomejs'` entries to
  `'biome'`, and wire `opts.events` into the autocmd.

**Out of scope** (do NOT touch):
- `lua/plugins/lspconfig.lua` — the conform formatter table there also uses
  biome (`biome` vs `biome-check` inconsistency, finding TECH-7). That is a
  *formatter* concern in a different file; it is deferred, not part of this
  plan. Do not "fix" it here.
- The Mason auto-install loop (lines 21–26). It already installs `biome`
  correctly.

## Git workflow

- Branch: `advisor/003-linter-biome-name`
- Single commit. Message style (conventional commits): `fix: use correct
  nvim-lint 'biome' linter name and honor configured events`.

## Steps

### Step 1: Rename the linter (the actual bug)

In `lua/plugins/web-linter.lua`, change every occurrence of `{ 'biomejs' }` in
the `linters_by_ft` table to `{ 'biome' }`. There are four (javascript,
javascriptreact, typescript, typescriptreact). The table becomes:

```lua
			linters_by_ft = {
				javascript = { 'biome' },
				javascriptreact = { 'biome' },
				typescript = { 'biome' },
				typescriptreact = { 'biome' },
			},
```

**Verify**:
- `grep -n 'biomejs' lua/plugins/web-linter.lua` → no matches.
- `grep -n "'biome'" lua/plugins/web-linter.lua` → 5 matches (the existing
  `'biome'` in the `linters` list at line 3, plus the 4 you just changed).

### Step 2: Honor `opts.events` in the autocmd

The `opts.events` field is currently dead config. Wire it into the autocmd so
the declared events are actually used (and so the option isn't misleading).
Replace the hardcoded event list in the `nvim.api.nvim_create_autocmd` call
with `opts.events`:

Before:
```lua
			vim.api.nvim_create_autocmd(
				{ 'BufWritePost', 'BufEnter' },
				{
					callback = function()
						lint.try_lint()
					end
				}
			)
```

After:
```lua
			vim.api.nvim_create_autocmd(
				opts.events,
				{
					callback = function()
						lint.try_lint()
					end
				}
			)
```

`opts.events` is `{ "BufWritePost", "BufReadPost", "InsertLeave" }` (line 12),
which is a reasonable lint trigger set and matches the file's own comment
("Events to trigger linter"). This makes linting also run on read and on
leaving insert mode, which is the intended behavior the option was declaring.

**Verify**:
- `grep -n 'BufEnter' lua/plugins/web-linter.lua` → no matches (the hardcoded
  `'BufEnter'` is gone; `opts.events` does not contain it).
- `grep -n 'opts.events' lua/plugins/web-linter.lua` → 2 matches (the
  declaration on line 12 and the autocmd use).

### Step 3: Confirm the linter resolves at runtime

**Verify**:
`nvim --headless +'lua assert(require("lint").linters.biome ~= nil)' +qa`
→ exit 0, no output. (Requires nvim-lint installed; run `Lazy! sync` first if
needed — see STOP conditions.)

### Step 4: Commit

- Stage `lua/plugins/web-linter.lua`.
- Commit: `fix: use correct nvim-lint 'biome' linter name and honor configured events`.

**Verify**: `git show --stat HEAD` → exactly one file changed.

## Done criteria

ALL must hold:

- [ ] `grep -n 'biomejs' lua/plugins/web-linter.lua` returns no matches.
- [ ] `grep -n "'biome'" lua/plugins/web-linter.lua` returns 5 matches.
- [ ] `grep -n 'opts.events' lua/plugins/web-linter.lua` returns 2 matches
  (declaration + autocmd use); `'BufEnter'` no longer appears hardcoded.
- [ ] `nvim --headless +'lua assert(require("lint").linters.biome ~= nil)' +qa`
  exits 0.
- [ ] `git show --stat HEAD` shows only `lua/plugins/web-linter.lua` changed.
- [ ] `plans/README.md` status row for 003 updated (TODO → DONE).

## STOP conditions

Stop and report back (do not improvise) if:

- The code at the cited lines does not match the excerpts (drift). Report what
  you see.
- `require("lint").linters.biome` is `nil` even after `Lazy! sync` and
  `:MasonInstall biome`. That would mean this nvim-lint version registers the
  linter under a different name — run
  `nvim --headless +'lua print(vim.inspect(vim.tbl_keys(require("lint").linters)))' +qa`
  and report the keys; do not guess.
- Step 2's change to `opts.events` causes a load error (e.g. `opts` shape
  differs). Report; do not revert to hardcoding silently — ask the operator.

## Maintenance notes

- **Related but separate**: `lspconfig.lua`'s conform formatter table mixes
  `biome` and `biome-check` across JS/TS filetypes (finding TECH-7, deferred).
  If that is later reconciled, keep the *linter* name (here, `biome`) and the
  *formatter* name (there, `biome`/`biome-check`) distinct in your head — they
  are different tools' registrations.
- **Reviewer focus**: confirm Step 2 didn't accidentally change which events
  fire beyond what `opts.events` declares, and that no other autocmd was
  touched.
- Wiring `opts.events` (rather than deleting the misleading field) was chosen
  over removal because the repo's convention is to keep trigger config in the
  `opts` table; if the maintainer prefers fewer events, they can edit the one
  `opts.events` line.
