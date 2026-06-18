# Plan 002: Fix the `flash.nvim` keymap typo (`tresitter_search`)

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md`.
>
> **Drift check (run first)**:
> `git diff --stat baf9a2c..HEAD -- lua/plugins/flash.lua`
> If `lua/plugins/flash.lua` changed since this plan was written, compare the
> "Current state" excerpt against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none (independent of 001, 003, 004, 005)
- **Category**: bug
- **Planned at**: commit `baf9a2c`, 2026-06-18
- **Finding**: BUG-1

## Why this matters

The `R` keymap (operator-pending + visual modes) calls
`require('flash').tresitter_search()`. That method does not exist — the real
API is `treesitter_search`. So pressing `R` throws
`attempt to call a nil value (method 'tresitter_search')` every time, instead
of performing the "Treesitter Search" the keymap advertises. A one-character
class of typo that a load test cannot catch (the function body only runs on
keypress), which is why it survived.

## Current state

`lua/plugins/flash.lua` — the flash.nvim plugin spec. The bug is on line 10.
The four sibling keymaps (lines 7, 8, 9, 11) call the correct method names and
are fine. Current file in full:

```lua
return {
	{
		'folke/flash.nvim',
		--@type Flash.Config
		opts = {},
		keys = {
			{ 's', mode = {'n', 'x', 'o'}, function() require('flash').jump() end, desc = 'Flash' },
			{ 'S', mode = {'n', 'x', 'o'}, function() require('flash').treesitter() end, desc = 'Flash Treesitter' },
			{ 'r', mode = {'o'}, function() require('flash').remote() end, desc = 'Remote Flash' },
			{ 'R', mode = {'o', 'x'}, function() require('flash').tresitter_search() end, desc = 'Treesitter Search' },
			{ '<c-s>', mode = {'c'}, function() require('flash').toggle() end, desc = 'Toggle Flash Search' },
		},
	}
}
```

The correct API method name is confirmed by the sibling keymap on line 8
(`treesitter()`) and flash.nvim's public API: `jump`, `treesitter`, `remote`,
`treesitter_search`, `toggle`.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Confirm typo gone | `grep -n 'tresitter' lua/plugins/flash.lua` | no matches (exit 1) |
| Confirm correct name present | `grep -n 'treesitter_search' lua/plugins/flash.lua` | one match, line 10 |
| Method exists at runtime | `nvim --headless +'lua assert(type(require("flash").treesitter_search)=="function")' +qa` | exit 0, no output |

The runtime check requires the `flash.nvim` plugin to be installed (it is, per
`lazy-lock.json`). If running in a fresh environment, run
`nvim --headless "+Lazy! sync" +qa` first.

## Scope

**In scope** (the only file you should modify):
- `lua/plugins/flash.lua` — change exactly one token on line 10.

**Out of scope** (do NOT touch):
- The other four keymaps — they are correct.
- `opts = {}` and anything else in the file.
- Any other plugin's keymaps, even though a repo-wide audit of method-name
  typos is tempting; keep this plan surgical.

## Git workflow

- Branch: `advisor/002-flash-typo`
- Single commit. Message style (conventional commits, per `git log`):
  `fix: correct flash treesitter_search keymap typo`.

## Steps

### Step 1: Rename the method call

In `lua/plugins/flash.lua` line 10, change `tresitter_search` to
`treesitter_search` (insert the missing `e` after the `tr`). The line becomes:

```lua
			{ 'R', mode = {'o', 'x'}, function() require('flash').treesitter_search() end, desc = 'Treesitter Search' },
```

Leave the leading whitespace (tabs), the `desc`, and everything else untouched.

**Verify**:
- `grep -n 'tresitter' lua/plugins/flash.lua` → no matches.
- `grep -n 'treesitter_search' lua/plugins/flash.lua` → exactly one match on
  line 10.

### Step 2: Confirm the method resolves at runtime

**Verify**:
`nvim --headless +'lua assert(type(require("flash").treesitter_search)=="function")' +qa`
→ exit 0, no output. (If flash isn't installed in this env, run `Lazy! sync`
first — see STOP conditions.)

### Step 3: Commit

- Stage `lua/plugins/flash.lua`.
- Commit: `fix: correct flash treesitter_search keymap typo`.

**Verify**: `git show --stat HEAD` → exactly one file changed
(`lua/plugins/flash.lua`), one line.

## Done criteria

ALL must hold:

- [ ] `grep -n 'tresitter' lua/plugins/flash.lua` returns no matches.
- [ ] `grep -n 'treesitter_search' lua/plugins/flash.lua` returns one match
  (line 10).
- [ ] `nvim --headless +'lua assert(type(require("flash").treesitter_search)=="function")' +qa`
  exits 0.
- [ ] `git show --stat HEAD` shows only `lua/plugins/flash.lua` changed.
- [ ] `plans/README.md` status row for 002 updated (TODO → DONE).

## STOP conditions

Stop and report back (do not improvise) if:

- The code at `lua/plugins/flash.lua:10` does not match the excerpt above (the
  line has drifted — e.g. someone already fixed it, or the keymap was
  removed). Report what you see.
- The runtime assertion fails because `require("flash").treesitter_search` is
  `nil` even after `Lazy! sync`. That would mean the installed flash.nvim
  version exposes a different API — report the version and stop; do not guess
  an alternate method name.
- Any other keymap in the file also looks wrong. Report it; do not expand
  scope.

## Maintenance notes

- This is the kind of typo a future static check could catch if flash.nvim
  shipped LuaLS type annotations (it does ship `meta/` annotations in some
  versions). If `lazydev.nvim` + flash annotations are ever wired up,
  `lua_ls` would flag `tresitter_search` as an unknown field automatically.
- Reviewer focus: confirm only the single token changed.
