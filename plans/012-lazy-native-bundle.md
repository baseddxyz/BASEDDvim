# Plan 012: Lazy-loading hygiene + native `virtual_lines` diagnostics

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md`.
>
> **Drift check (run first)**:
> `git diff --stat c343dc6..HEAD -- lua/plugins/ai.lua lua/plugins/bufferline.lua lua/plugins/lspconfig.lua lua/vim-options.lua`
> If any of those files changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P2
- **Effort**: S (4 small, independent edits across 4 files)
- **Risk**: LOW
- **Depends on**: none
- **Category**: perf / dx
- **Planned at**: commit `c343dc6`, 2026-06-18

## Why this matters

Four small, independent wins bundled into one plan:

1. **`amp.nvim` lazy-loads instead of spawning at startup.** It's `lazy = false`
   with `auto_start = true`, so its AI backend starts on every Neovim launch —
   real startup cost plus a background process even when you won't use AI.
   Lazy-load it on first invocation.
2. **`bufferline.nvim` lazy-loads.** It has no lazy trigger at all, so it loads
   on every startup. It only needs to exist once the UI is up.
3. **`rustaceanvim`'s redundant `lazy = false` is removed.** It already has
   `ft = { "rust" }` which lazy-loads it on Rust files; the explicit
   `lazy = false` contradicts that and is cargo-cult noise. (This is a clarity
   fix, not a behavior change — rustaceanvim stays lazy-loaded via `ft`.)
4. **Enable native `virtual_lines` diagnostics.** `vim.diagnostic.config` in
   `vim-options.lua` has `virtual_text = true` with a commented-out
   `-- virtual_lines = true` you clearly wanted. Native `virtual_lines` is
   verified supported in this nvim (0.12.3). It renders multi-line diagnostics
   inline (modern LSP style).

All four are S-effort, LOW-risk, independent. Bundled to avoid four tiny PRs.

## Current state

### `lua/plugins/ai.lua` lines 231–236 (amp.nvim)

```lua
			{
				"sourcegraph/amp.nvim",
				branch = "main",
				lazy = false,
				opts = { auto_start = true, log_level = "info" },
			},
```

`amp.nvim` is the Sourcegraph AI assistant. The commented-out `keys = {...}`
block below it (lines 238+) shows the maintainer once planned manual triggers.
It has no `cmd`/`keys`/`event`/`ft` today — only the eager `lazy = false`.

### `lua/plugins/bufferline.lua` (full file)

```lua
return {
	{
		'akinsho/bufferline.nvim',
		version = "*",
		dependencies = 'nvim-tree/nvim-web-devicons',
		config = function ()
			vim.opt.termguicolors = true
			require('bufferline').setup{}
		end
	}
}
```

No `event`/`keys`/`cmd`/`ft` → loads at startup.

### `lua/plugins/lspconfig.lua` lines 170–174 (rustaceanvim head)

```lua
	{
		"mrcjkb/rustaceanvim",
		version = false,
		lazy = false,
		ft = { "rust" },
```

`ft = { "rust" }` already lazy-loads; `lazy = false` is contradictory.

### `lua/vim-options.lua` lines 39–44

```lua
vim.diagnostic.config({
	virtual_text = true,
	-- virtual_lines = true,
})

vim.opt_local.conceallevel = 1
```

`virtual_lines = true` is commented out; verified `vim.diagnostic.config({virtual_lines=true})`
is accepted without error in this nvim.

### Repo conventions to match

- Lazy triggers use `event`/`ft`/`cmd`/`keys` (see exemplars throughout
  `lua/plugins/` — e.g. `lspconfig.lua:68` `event = { "BufReadPre", "BufNewFile" }`).
- One plugin spec per entry; keep `opts`/`config` structure as-is.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| amp no longer eager | `grep -n 'lazy = false' lua/plugins/ai.lua` | no `lazy = false` on the amp block (only on rustaceanvim, which P3 also removes — see STOP if rust still has it) |
| amp has a trigger | `grep -nE 'event =|cmd =|keys =' lua/plugins/ai.lua \| grep -A0 amp` | amp spec has `cmd`/`keys`/`event` |
| bufferline has event | `grep -n 'event\|VeryLazy\|VimEnter' lua/plugins/bufferline.lua` | one match |
| rustaceanvim `lazy = false` gone | `grep -n 'lazy = false' lua/plugins/lspconfig.lua` | no matches |
| virtual_lines enabled | `grep -n 'virtual_lines\|virtual_text' lua/vim-options.lua` | `virtual_lines = true` active, `virtual_text` handled per Step 4 |
| Files parse | see Done criteria | exit 0 for each |

## Scope

**In scope** (the only files you should modify):
- `lua/plugins/ai.lua` — convert the `amp.nvim` spec from eager to lazy.
- `lua/plugins/bufferline.lua` — add a lazy `event`.
- `lua/plugins/lspconfig.lua` — remove `lazy = false` from rustaceanvim.
- `lua/vim-options.lua` — enable `virtual_lines`.

**Out of scope** (do NOT touch):
- The rest of `ai.lua` (supermaven, sidekick, 99) — only the amp block changes.
- `rustaceanvim`'s `ft`, `opts`, `on_attach`, etc. — only the `lazy = false` line goes.
- `vim-options.lua`'s other settings (tabs, relativenumber, leader, keymaps,
  the `vim.opt_local.conceallevel` line which is a separate deferred finding).
- Other diagnostic-rendering plugins (trouble.nvim, mini.notify) — unaffected.

## Git workflow

- Branch: `advisor/012-lazy-native`
- One commit covering all four (or per-step commits are fine). Message style
  (conventional commits): `perf: lazy-load amp/bufferline, drop redundant
  rustaceanvim lazy, enable native virtual_lines`.
- Do NOT push or open a PR unless the operator instructed it.

## Steps

### Step 1: Lazy-load amp.nvim

In `lua/plugins/ai.lua`, change the `amp.nvim` spec so it loads on a command
instead of eagerly. Replace:

```lua
			{
				"sourcegraph/amp.nvim",
				branch = "main",
				lazy = false,
				opts = { auto_start = true, log_level = "info" },
			},
```

with:

```lua
			{
				"sourcegraph/amp.nvim",
				branch = "main",
				cmd = { "Amp" },
				opts = { auto_start = true, log_level = "info" },
			},
```

(Drop `lazy = false`; add `cmd = { "Amp" }`. When the user runs `:Amp` for the
first time, amp loads and its `auto_start` then takes over for that session.
`auto_start = true` keeps working — it governs behavior *after* the plugin is
loaded, not whether it loads.)

**Verify**:
- `grep -n 'lazy = false' lua/plugins/ai.lua` → no matches.
- `grep -nA4 'amp.nvim"' lua/plugins/ai.lua` → the amp block shows
  `cmd = { "Amp" }` and no `lazy = false`.

### Step 2: Lazy-load bufferline

In `lua/plugins/bufferline.lua`, add an `event` so it loads once the UI is up.
Replace the whole spec with:

```lua
return {
	{
		'akinsho/bufferline.nvim',
		version = "*",
		event = 'VimEnter',
		dependencies = 'nvim-tree/nvim-web-devicons',
		config = function ()
			vim.opt.termguicolors = true
			require('bufferline').setup{}
		end
	}
}
```

(Adds `event = 'VimEnter'`. Keeps everything else identical. `VimEnter` fires
once after startup completes — bufferline draws the tabline immediately after,
no perceptible delay, but it's no longer on the critical startup path. This is
the documented bufferline convention.)

**Verify**:
- `grep -n "event = 'VimEnter'" lua/plugins/bufferline.lua` → one match.

### Step 3: Drop rustaceanvim's redundant `lazy = false`

In `lua/plugins/lspconfig.lua` lines 170–174, remove the `lazy = false,` line
ONLY. `ft = { "rust" }` already lazy-loads the plugin on Rust files.

Before:
```lua
	{
		"mrcjkb/rustaceanvim",
		version = false,
		lazy = false,
		ft = { "rust" },
```

After:
```lua
	{
		"mrcjkb/rustaceanvim",
		version = false,
		ft = { "rust" },
```

**Verify**:
- `grep -n 'lazy = false' lua/plugins/lspconfig.lua` → no matches.
- `grep -n 'ft = { "rust" }' lua/plugins/lspconfig.lua` → unchanged, one match.

### Step 4: Enable native `virtual_lines`

In `lua/vim-options.lua` lines 39–43, switch from `virtual_text` to
`virtual_lines`. Replace:

```lua
vim.diagnostic.config({
	virtual_text = true,
	-- virtual_lines = true,
})
```

with:

```lua
vim.diagnostic.config({
	virtual_text = false,
	virtual_lines = true,
})
```

**Why `virtual_text = false`:** the two render styles overlap (both try to draw
inline diagnostic text). `virtual_lines` is the newer multi-line inline style;
disabling `virtual_text` avoids duplicate/confusing rendering. If you later
prefer the old style, flip both back.

**Verify**:
- `grep -n 'virtual_lines\|virtual_text' lua/vim-options.lua` →
  `virtual_text = false` and `virtual_lines = true`.
- `nvim --headless -u NONE +'lua vim.diagnostic.config({virtual_lines=true, virtual_text=false}); assert(true); print("DIAG_OK")' +qa`
  → prints `DIAG_OK` (confirms the nvim accepts both options — already verified
  in planning, re-check here).

### Step 5: Parse-check and commit

**Verify** (each parses):
```bash
for f in lua/plugins/ai.lua lua/plugins/bufferline.lua lua/plugins/lspconfig.lua lua/vim-options.lua; do
  nvim --headless -u NONE +"lua local fn,err=loadfile('$f'); assert(fn,err)" +qa && echo "OK $f" || echo "FAIL $f"
done
```
All four should print `OK`.

- Stage all four files.
- Commit: `perf: lazy-load amp/bufferline, drop redundant rustaceanvim lazy, enable native virtual_lines`.

**Verify**: `git show --stat HEAD` → exactly four files changed.

## Test plan

- **Static (required)**: all the grep checks above + the parse loop.
- **Manual startup check (recommended)**: with the full config loaded, time
  startup (`nvim --startuptime /tmp/s.txt +qa; tail -1 /tmp/s.txt`) before and
  after on your machine. Expect a reduction (amp especially). Not a hard gate —
  the lazy-loading is correct by construction; timing is confirmation.
- **amp behavior**: run `:Amp` and confirm it loads + starts (auto_start kicks
  in post-load). If `:Amp` isn't the real command name, see STOP conditions.
- **virtual_lines**: open a buffer with diagnostics (e.g. an intentionally
  wrong Lua file with lua_ls) and confirm diagnostics render as inline
  multi-line virtual lines instead of trailing virtual text.
- **bufferline/rustaceanvim**: confirm the tabline still appears after startup
  and rust LSP still attaches on `.rs` files.

## Done criteria

ALL must hold:

- [ ] `grep -n 'lazy = false' lua/plugins/ai.lua` returns no matches.
- [ ] The amp spec has `cmd = { "Amp" }` (`grep -A4 'amp.nvim"'` shows it).
- [ ] `grep -n "event = 'VimEnter'" lua/plugins/bufferline.lua` returns one match.
- [ ] `grep -n 'lazy = false' lua/plugins/lspconfig.lua` returns no matches.
- [ ] `grep -n 'ft = { "rust" }' lua/plugins/lspconfig.lua` still returns one match.
- [ ] `grep -n 'virtual_lines' lua/vim-options.lua` shows `virtual_lines = true`.
- [ ] All four in-scope files parse (the Step 5 loop prints `OK` for each).
- [ ] `git show --stat HEAD` shows only the four in-scope files.
- [ ] `plans/README.md` status row for 012 updated.

## STOP conditions

Stop and report back (do not improvise) if:

- **`:Amp` is not the correct command name** for amp.nvim. This is the one real
  unknown in the plan (amp.nvim isn't installed on the planning box). If the
  documented entrypoint differs (e.g. `:AmpStart`, or it's key-only), STOP and
  report — pick the right trigger before proceeding. Do not guess a command
  name that doesn't exist (that would make the plugin un-loadable).
- **`virtual_lines` errors in your nvim** despite the planning-box check
  (re-verify: the `DIAG_OK` check in Step 4). If it errors, leave
  `virtual_text = true` and report; do not ship a diagnostic config that breaks
  rendering.
- **`bufferline` fails to draw after `VimEnter` lazy-load** (e.g. tabline blank
  on first window). Report; `VeryLazy` is an alternative event — but confirm
  the problem first, don't pre-emptively switch.
- **`rustaceanvim` stops attaching to `.rs` files** after removing
  `lazy = false`. It shouldn't (`ft` handles it), but if it does, report —
  the `ft` trigger is the correct mechanism; restoring `lazy = false` would
  just re-hide the real issue.
- Any file at the cited locations doesn't match its excerpt (drift). Report.

## Maintenance notes

- **amp `auto_start` semantics**: `auto_start = true` means "start the AI
  backend once amp is loaded", not "load amp at startup". After this plan, amp
  loads on `:Amp`, THEN auto_start runs. If you want amp available without a
  manual `:Amp`, change `cmd` to `event = "VimEnter"` (still lazy vs the old
  eager load) — but that re-introduces startup cost, so the plan defaults to
  the explicit command.
- **virtual_lines vs virtual_text is a preference.** `virtual_lines` is newer
  and renders multi-line diagnostics better; `virtual_text` is the classic
  trailing style. Both native; flip the two booleans to switch.
- **Reviewer focus**: each of the four changes is one-line-ish and surgical.
  Confirm rustaceanvim lost only the `lazy = false` line (not `ft`), and
  virtual_lines/virtual_text are the correct pair (one true, one false).
- **Deferred**: the `vim.opt_local.conceallevel = 1` line right below the
  diagnostic config is a separate finding (BUG-5, deferred) — do not touch it
  here.
