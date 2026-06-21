# Plan 014: Refine diagnostics to paketo's tiered model (supersedes plan 012's diagnostic choice)

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md`.
>
> **Drift check (run first)**:
> `git diff --stat 2f10ac4..HEAD -- lua/vim-options.lua`
> If `lua/vim-options.lua` changed since this plan was written, compare the
> "Current state" excerpt against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P3
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: dx
- **Planned at**: commit `2f10ac4`, 2026-06-19
- **Supersedes**: the diagnostic-rendering portion of plan 012 (the
  `virtual_lines = true` choice). Plan 012's three lazy-loading changes
  (amp, bufferline, rustaceanvim) are UNAFFECTED and stay.

## Why this matters

Plan 012 (`e0721d5`) enabled blanket `virtual_lines = true` for diagnostics —
the "modern" style that renders every diagnostic inline as multi-line text.
It works, but it's **noisy**: every hint/warn/error on every visible line
expands inline, which crowds the buffer.

`baseddxyz/paketo` (same author's leaner config) uses a more deliberate,
**severity-tiered** model:

```lua
signs       = { priority = 9999, severity = { min = "WARN",  max = "ERROR" } },
underline   = {                       severity = { min = "HINT",  max = "ERROR" } },
virtual_text = { current_line = true, severity = { min = "ERROR", max = "ERROR" } },
virtual_lines = false,
update_in_insert = false,
```

That is: **underlines everything** (so you always see *something* is off),
**signs** for warn+error (gutter priority), **inline text only for ERRORS and
only on the current line** (the loud stuff you act on), and **no inline text
while typing**. Less noise, clearer severity hierarchy.

This is a **preference flip, not a bug fix.** Both styles are valid; the
maintainer (after seeing paketo's approach) prefers the tiered model. Verified
during planning that nvim 0.12.3 accepts paketo's full config (including
`virtual_text.current_line` and `severity` ranges) without error.

## Current state

`lua/vim-options.lua` lines 39–43 (as set by plan 012):

```lua
vim.diagnostic.config({
	virtual_text = false,
	virtual_lines = true,
})
```

### Repo conventions to match

- Diagnostics are configured once in `vim-options.lua` (this block). No other
  file sets `vim.diagnostic.config`.
- paketo's exact tiered values are the target (borrowed verbatim — it's the
  same author's considered choice).

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| virtual_lines off, virtual_text tiered | `grep -n 'virtual_lines\|virtual_text\|signs\|underline\|update_in_insert' lua/vim-options.lua` | all five present with paketo values |
| File parses | `nvim --headless -u NONE +'lua local fn,err=loadfile("lua/vim-options.lua"); assert(fn,err); print("PARSE_OK")' +qa` | prints `PARSE_OK` |
| Config accepted at runtime | see Step 2 verify | prints `DIAG_OK` |

## Scope

**In scope** (the only file you should modify):
- `lua/vim-options.lua` — replace the `vim.diagnostic.config({...})` block.

**Out of scope** (do NOT touch):
- Everything else in `vim-options.lua` (tabs, relativenumber, leader, keymaps,
  the `vim.opt_local.conceallevel` line which is deferred BUG-5).
- Plan 012's three lazy-loading changes (amp/bufferline/rustaceanvim) — they
  live in different files and stay.
- Any diagnostic-consuming plugin (trouble.nvim, mini.notify) — unaffected.

## Git workflow

- Branch: `advisor/014-diagnostics`
- Single commit. Message style (conventional commits):
  `refactor: tier diagnostic display (signs/underline/current-line virtual_text)`.

## Steps

### Step 1: Replace the diagnostic config block

In `lua/vim-options.lua`, replace the current block (lines ~39–43):

```lua
vim.diagnostic.config({
	virtual_text = false,
	virtual_lines = true,
})
```

with:

```lua
-- Tiered diagnostic display (model borrowed from baseddxyz/paketo):
-- - underline everything (HINT..ERROR) so anything off is always visible
-- - signs in the gutter for WARN+ERROR
-- - inline virtual text ONLY for ERROR, ONLY on the current line
-- - no updates while typing (stable view)
vim.diagnostic.config({
	signs = { priority = 9999, severity = { min = "WARN", max = "ERROR" } },
	underline = { severity = { min = "HINT", max = "ERROR" } },
	virtual_lines = false,
	virtual_text = { current_line = true, severity = { min = "ERROR", max = "ERROR" } },
	update_in_insert = false,
})
```

(Tabs for indentation — match the file.)

**Verify**:
- `grep -n 'virtual_lines' lua/vim-options.lua` → `virtual_lines = false,`.
- `grep -c 'current_line = true' lua/vim-options.lua` → 1.
- `grep -c 'update_in_insert' lua/vim-options.lua` → 1.

### Step 2: Confirm the config is accepted at runtime

**Verify**:
`nvim --headless -u NONE +'lua local ok,err=pcall(vim.diagnostic.config, { signs={priority=9999,severity={min="WARN",max="ERROR"}}, underline={severity={min="HINT",max="ERROR"}}, virtual_lines=false, virtual_text={current_line=true,severity={min="ERROR",max="ERROR"}}, update_in_insert=false }); assert(ok,err); print("DIAG_OK")' +qa`
→ prints `DIAG_OK`. (Already verified during planning; re-check here. If it
errors, see STOP conditions.)

### Step 3: Parse-check and commit

**Verify**:
`nvim --headless -u NONE +'lua local fn,err=loadfile("lua/vim-options.lua"); assert(fn,err); print("PARSE_OK")' +qa`
→ prints `PARSE_OK`.

- Stage `lua/vim-options.lua`.
- Commit: `refactor: tier diagnostic display (signs/underline/current-line virtual_text)`.

**Verify**: `git show --stat HEAD` → exactly one file changed
(`lua/vim-options.lua`).

## Test plan

- **Static (required)**: the grep + parse + DIAG_OK checks above.
- **Manual runtime check (recommended, requires plugins)**: open a buffer with
  diagnostics of mixed severities (e.g. a Lua file with lua_ls hints + an
  error). Confirm: underlines on all of them; signs in the gutter for
  warn/error; inline virtual text only on the current line and only for the
  error; typing doesn't flicker the diagnostics.

## Done criteria

ALL must hold:

- [ ] `grep -n 'virtual_lines' lua/vim-options.lua` shows `virtual_lines = false`.
- [ ] `grep -c 'current_line = true' lua/vim-options.lua` returns 1.
- [ ] `grep -c 'update_in_insert' lua/vim-options.lua` returns 1.
- [ ] `grep -c 'severity' lua/vim-options.lua` returns ≥3 (signs/underline/virtual_text each have one).
- [ ] The Step 2 `DIAG_OK` check passes.
- [ ] `nvim --headless -u NONE +'lua local fn,err=loadfile("lua/vim-options.lua"); assert(fn,err)' +qa` exits 0.
- [ ] `git show --stat HEAD` shows only `lua/vim-options.lua`.
- [ ] `plans/README.md` status row for 014 updated, and 012's row notes that
  its diagnostic portion is superseded by 014.

## STOP conditions

Stop and report back (do not improvise) if:

- The Step 2 `DIAG_OK` check fails despite the planning-box verification. If
  nvim rejects the config, report the error verbatim; do not ship a broken
  diagnostic config (revert to the plan-012 `virtual_lines = true` and report).
- The code at the cited block doesn't match the excerpt (drift). Report.
- You're tempted to also "fix" the `vim.opt_local.conceallevel` line below —
  that's deferred BUG-5, out of scope. Leave it.

## Maintenance notes

- **This supersedes plan 012's diagnostic choice only.** Plan 012's commit
  (`e0721d5`) stays in history and still carries the three lazy-loading wins
  (amp, bufferline, rustaceanvim); only its `virtual_lines = true` is reverted
  here.
- **Preference, not correctness.** If the maintainer later wants the "see
  everything inline" style back, flip `virtual_lines = true` and
  `virtual_text = false` — that's plan 012's config. The tiered model here is
  borrowed from paketo deliberately.
- **Reviewer focus**: confirm only the one config block changed and it matches
  paketo's values exactly.
- **Why no `virtual_lines`-and-`virtual_text`-both-on:** they render
  overlapping inline text. The tiered model uses virtual_text (finer-grained,
  supports `current_line` + severity filtering); virtual_lines is off.
