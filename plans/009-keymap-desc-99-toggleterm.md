# Plan 009: Add missing `desc` to the 99 and toggleterm keymaps

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md`.
>
> **Drift check (run first)**:
> `git diff --stat f5c7d00..HEAD -- lua/plugins/ai.lua lua/plugins/terminal.lua`
> If either file changed since this plan was written, compare the "Current
> state" excerpts against the live code before proceeding; on a mismatch,
> treat it as a STOP condition.
>
> **Note on plan 008**: plan 008 also edits `lua/plugins/ai.lua` (the
> `md_files` table, around lines 370–372). This plan edits DIFFERENT lines of
> the same file (the `vim.keymap.set` calls at the bottom, lines ~376–399).
> If 008 has already been applied, the `md_files` change is well above the
> edits here and will not conflict. If both are applied to the same branch,
> expect a clean non-overlapping merge. Verify the line numbers by text match,
> not absolute position.

## Status

- **Priority**: P3
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none (independent of 006, 007, 008; edits non-overlapping
  regions of `ai.lua` vs plan 008)
- **Category**: dx / tech-debt
- **Planned at**: commit `f5c7d00`, 2026-06-18
- **Finding**: TECH-8 (partial — vetted subset)

## Why this matters

`AGENTS.md` sets a repo convention: every `vim.keymap.set` call should include
a `desc` field for which-key compatibility. Five keymaps currently omit it:
four `99` keymaps (`<leader>9f`, `<leader>9v`, `<leader>9s`, `<leader>9fd`)
and the toggleterm float keymap (`<leader>tf`). Without `desc`, which-key
shows a blank or auto-generated label for these, and the keybinding inventory
is incomplete. This plan adds concise, accurate descriptions to each.

**Scope correction from the original finding**: an earlier line-based scan
also flagged the rust `<leader>ca` (`lspconfig.lua:177`) and `<leader>fM`
(`lspconfig.lua:260`). Verified during planning — **both already have `desc`**
("Code Action" and "Format file or range (in visual mode)"). Those are
false positives and are NOT edited here. Only the five genuinely-missing ones
are in scope.

## Current state

`lua/plugins/ai.lua` — four `99` keymap calls (around lines 376–399), each
missing the 4th `opts` argument:

```lua
				vim.keymap.set("n", "<leader>9f", function()
					_99.fill_in_function()
				end)
				-- ... (comments)
				vim.keymap.set("v", "<leader>9v", function()
					_99.visual()
				end)

				--- if you have a request you dont want to make any changes, just cancel it
				vim.keymap.set("v", "<leader>9s", function()
					_99.stop_all_requests()
				end)

				--- Example: Using rules + actions for custom behaviors
				--- ... (comment)
				vim.keymap.set("n", "<leader>9fd", function()
					_99.fill_in_function()
				end)
```

`lua/plugins/terminal.lua` line 7:

```lua
			vim.keymap.set('n', '<leader>tf', '<cmd>ToggleTerm direction=float<cr>')
```

### Repo conventions to match

`AGENTS.md` → Keybindings:
> Include `desc` field for which-key compatibility

Exemplars that already follow the convention (do not touch, just match style):
- `lua/plugins/img-clip.lua`:
  `{ "<leader>p", "<cmd>PasteImage<cr>", desc = "Paste image from system clipboard" }`
- `lua/plugins/lspconfig.lua:177-180`:
  `vim.keymap.set("n", "<leader>ca", function() ... end, { desc = "Code Action", buffer = bufnr })`

Description wording should match the README keybindings table where one exists:
- README lists `<leader>tf` | n | "Toggle terminal (float)" — use that text.
- The `99` keys are not in the README keybindings table; use the in-file
  comment intent (see Step 1 for exact text).

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| No desc-less keymaps remain in scope | see Done criteria greps | all return no matches |
| Files parse | `nvim --headless -u NONE +'lua for _,f in ipairs({"lua/plugins/ai.lua","lua/plugins/terminal.lua"}) do local fn,err=loadfile(f); assert(fn,err) end; print("PARSE_OK")' +qa` | prints `PARSE_OK` |

## Scope

**In scope** (the only files you should modify):
- `lua/plugins/ai.lua` — add `{ desc = "…" }` opts to the four `99`
  `vim.keymap.set` calls.
- `lua/plugins/terminal.lua` — add `{ desc = "…" }` to the `<leader>tf` call.

**Out of scope** (do NOT touch):
- `lua/plugins/lspconfig.lua` — the rust `<leader>ca` and `<leader>fM` calls
  already have `desc`; they are not missing it. Do not edit them.
- Any keymap inside a lazy `keys = { ... }` spec table (those use the
  `desc = "…"` field directly, e.g. flash/snacks; they're fine).
- The `99` functional behavior, lhs, or mode — only the missing opts table is
  added.

## Git workflow

- Branch: `advisor/009-keymap-desc`
- Single commit. Message style (conventional commits):
  `style: add desc to 99 and toggleterm keymaps`.

## Steps

### Step 1: Add desc to the four 99 keymaps in ai.lua

For each of the four `99` `vim.keymap.set` calls, add a 4th argument
`{ desc = "…" }`. Use these exact descriptions (derived from the in-file
comments and the `_99` method names):

1. `<leader>9f` (n, `_99.fill_in_function`) →
   `{ desc = "99: Fill in function" }`
2. `<leader>9v` (v, `_99.visual`) →
   `{ desc = "99: Visual selection" }`
3. `<leader>9s` (v, `_99.stop_all_requests`) →
   `{ desc = "99: Stop all requests" }`
4. `<leader>9fd` (n, `_99.fill_in_function`) →
   `{ desc = "99: Fill in function (debug rule)" }`

Example of the target shape for the first one (apply the same pattern to all
four; keep the existing function bodies and modes verbatim):

```lua
				vim.keymap.set("n", "<leader>9f", function()
					_99.fill_in_function()
				end, { desc = "99: Fill in function" })
```

**Verify**:
- `grep -n '<leader>9f"' lua/plugins/ai.lua` → the call now ends (after the
  `end`) with `, { desc = "99: Fill in function" })`. (Check the closing paren
  follows the opts table.)
- Each of the four lhs strings (`<leader>9f`, `<leader>9v`, `<leader>9s`,
  `<leader>9fd`) appears in a `vim.keymap.set` whose call has a `{ desc = ... }`
  arg.

### Step 2: Add desc to the toggleterm keymap in terminal.lua

In `lua/plugins/terminal.lua` line 7, add the opts table. Use the README's
wording ("Toggle terminal (float)"):

Before:
```lua
			vim.keymap.set('n', '<leader>tf', '<cmd>ToggleTerm direction=float<cr>')
```

After:
```lua
			vim.keymap.set('n', '<leader>tf', '<cmd>ToggleTerm direction=float<cr>', { desc = 'Toggle terminal (float)' })
```

(Match the file's existing single-quote style for strings.)

**Verify**: `grep -n "<leader>tf" lua/plugins/terminal.lua` → the line ends
with `, { desc = 'Toggle terminal (float)' })`.

### Step 3: Parse-check and commit

**Verify**:
`nvim --headless -u NONE +'lua for _,f in ipairs({"lua/plugins/ai.lua","lua/plugins/terminal.lua"}) do local fn,err=loadfile(f); assert(fn,err) end; print("PARSE_OK")' +qa`
→ prints `PARSE_OK`.

- Stage `lua/plugins/ai.lua` and `lua/plugins/terminal.lua`.
- Commit: `style: add desc to 99 and toggleterm keymaps`.

**Verify**: `git show --stat HEAD` → exactly two files changed
(`lua/plugins/ai.lua`, `lua/plugins/terminal.lua`).

## Test plan

- **Static (required)**: the Done criteria greps confirm every in-scope call
  now has a `desc`, and both files parse.
- **Optional which-key check** (requires plugins installed): in nvim, press
  `<leader>` and then `9` / `t` and confirm which-key now shows the labels
  instead of blanks. Confirmation only.

## Done criteria

ALL must hold:

- [ ] `grep -n '<leader>9f"' lua/plugins/ai.lua`, `<leader>9v"`, `<leader>9s"`,
  `<leader>9fd"` each show a `vim.keymap.set` whose call includes a
  `{ desc = ... }` argument.
- [ ] `grep -n "<leader>tf" lua/plugins/terminal.lua` shows the call includes
  `{ desc = 'Toggle terminal (float)' }`.
- [ ] `nvim --headless -u NONE +'lua for _,f in ipairs({"lua/plugins/ai.lua","lua/plugins/terminal.lua"}) do local fn,err=loadfile(f); assert(fn,err) end' +qa`
  exits 0.
- [ ] `git show --stat HEAD` shows only `lua/plugins/ai.lua` and
  `lua/plugins/terminal.lua` changed.
- [ ] `lua/plugins/lspconfig.lua` is NOT modified (the rust `<leader>ca` /
  `<leader>fM` false positives stay untouched).
- [ ] `plans/README.md` status row for 009 updated (TODO → DONE).

## STOP conditions

Stop and report back (do not improvise) if:

- Any of the four `99` keymap calls or the `terminal.lua` call does not match
  its excerpt (drift). Report what you see.
- One of the in-scope keymaps already has a `desc` (re-check with
  `grep -A3 'vim.keymap.set' lua/plugins/ai.lua`). If so, skip that one and
  note it; do not overwrite an existing desc.
- Plan 008 has been applied to the same working tree and the `md_files` edit
  is closer to these lines than expected, risking a fuzzy match. Resolve by
  text-match on the `vim.keymap.set` lines only; if a match is ambiguous,
  STOP and report rather than editing the wrong region.
- A `99` method name has changed (`fill_in_function`, `visual`,
  `stop_all_requests`) such that the descriptions no longer describe the
  behavior. Report; do not invent behavior.

## Maintenance notes

- **What interacts with this later**: any new `99` or toggleterm keymap should
  include `desc` from the start (AGENTS.md convention). The smoke test from
  plan 001 does NOT enforce `desc` — a future lint rule (luacheck or a custom
  grep in CI) could, but that's deferred.
- **Reviewer focus**: confirm exactly five `vim.keymap.set` calls gained an
  opts table and nothing else (no lhs/mode/function-body changes), and that
  `lspconfig.lua` was not touched.
- **Vetting note for the record**: the original TECH-8 finding also named
  `lspconfig.lua:177` and `:260`; both were verified to already have `desc`
  and are correctly excluded from this plan.
