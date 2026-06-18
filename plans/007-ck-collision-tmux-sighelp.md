# Plan 007: Resolve the `<C-k>` collision between tmux-nav and LSP signature help

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md`.
>
> **Drift check (run first)**:
> `git diff --stat f5c7d00..HEAD -- lua/keymaps.lua lua/plugins/tmux.lua README.md`
> If any of those files changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none (independent of 006, 008, 009)
- **Category**: dx
- **Planned at**: commit `f5c7d00`, 2026-06-18
- **Finding**: N3

## Why this matters

`<C-k>` is mapped by two plugins in **the same mode**:
- `vim-tmux-navigator` binds `<C-k>` (normal mode, global) → `TmuxNavigateUp`.
- `keymaps.lsp()` binds `<C-k>` (normal mode, buffer-local in every LSP
  buffer) → `vim.lsp.buf.signature_help`.

Buffer-local maps beat global maps, so in **every code buffer with an LSP
attached**, `<C-k>` stops navigating to the tmux pane above and instead shows
signature help. The h/j/k/l nav cluster is meant to work uniformly everywhere;
losing "up" specifically inside code files is surprising. Both bindings are
documented in `README.md`, so the collision is unintentional.

**Chosen resolution: a mode split, not a key remap.** Signature help is most
useful *while typing a call* (insert mode); tmux navigation is a normal-mode
operation. Moving the signature-help binding from `n` to `i` mode keeps
`<C-k>` on both functions in their natural modes and preserves both
documented bindings with zero new keys. (The alternative — remap signature
help to a free key like `gK` — is noted in STOP/maintenance for the maintainer
who prefers normal-mode sig help.)

## Current state

Three relevant lines:

`lua/keymaps.lua` line 12 — the colliding LSP binding (normal mode):
```lua
		{ "n", "<C-k>", vim.lsp.buf.signature_help, opts },
```

`lua/plugins/tmux.lua` line 14 — the tmux binding (normal mode, global):
```lua
			{ "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
```

`README.md` documents both, both as `n` mode:
```
| `<C-k>` | n | Signature help |          (line 104, under "Code Navigation (LSP)")
...
| `<C-k>` | n | Navigate up |             (line 160, under "Tmux Integration")
```

### Verified free

Confirmed during planning: no existing insert-mode `<C-k>` binding anywhere in
`lua/`, so moving signature help to insert mode will not itself collide.
`vim.lsp.buf.signature_help` works in insert mode (it is the conventional
trigger point — while entering arguments).

### Repo conventions to match

- `keymaps.lua` stores each LSP keymap as a `{ modes, lhs, rhs, opts }` row.
  Change only the mode field of the one row.
- README keybinding rows are `| <key> | <mode> | <description> |`. Update the
  mode cell to match the new mode.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Confirm sig-help now insert mode | `grep -n '<C-k>' lua/keymaps.lua` | line shows `{ "i", "<C-k>", vim.lsp.buf.signature_help, opts },` |
| Confirm tmux binding unchanged | `grep -n '<c-k>' lua/plugins/tmux.lua` | unchanged line 14 |
| README mode cell updated | `grep -n '<C-k>' README.md` | the "Signature help" row shows `\| i \|`; the "Navigate up" row still `\| n \|` |
| Files parse | `nvim --headless -u NONE +'lua local fn,err=loadfile("lua/keymaps.lua"); assert(fn,err); print("PARSE_OK")' +qa` | prints `PARSE_OK` |

## Scope

**In scope** (the only files you should modify):
- `lua/keymaps.lua` — change the `<C-k>` row's mode from `"n"` to `"i"`.
- `README.md` — update the "Signature help" row's mode cell from `n` to `i`.

**Out of scope** (do NOT touch):
- `lua/plugins/tmux.lua` — the tmux binding is correct; the fix is on the LSP
  side.
- Other rows in `keymaps.lua` or other README keybinding rows. (A full
  keybindings-vs-code accuracy audit is a separate, deferred effort.)
- Remapping signature help to a brand-new key (e.g. `gK`). The mode split is
  the chosen resolution. If the maintainer later prefers normal-mode sig help,
  that's a one-line change documented in Maintenance — not this plan.

## Git workflow

- Branch: `advisor/007-ck-conflict`
- Single commit. Message style (conventional commits):
  `fix: move LSP signature help to insert mode to free <C-k> for tmux`.

## Steps

### Step 1: Change the signature-help mode to insert

In `lua/keymaps.lua` line 12, change the mode `"n"` to `"i"` for the
signature-help row only:

Before:
```lua
		{ "n", "<C-k>", vim.lsp.buf.signature_help, opts },
```

After:
```lua
		{ "i", "<C-k>", vim.lsp.buf.signature_help, opts },
```

Leave every other row in the `keymaps` table untouched.

**Verify**: `grep -n '<C-k>' lua/keymaps.lua` → the single match reads
`{ "i", "<C-k>", vim.lsp.buf.signature_help, opts },`.

### Step 2: Update the README mode cell

In `README.md`, the "Code Navigation (LSP)" table has (line ~104):

```
| `<C-k>` | n | Signature help |
```

Change the mode cell `n` → `i`:

```
| `<C-k>` | i | Signature help |
```

Do NOT touch the "Tmux Integration" row (`| <C-k> | n | Navigate up |`) — it
stays normal mode.

**Verify**:
- `grep -n '<C-k>' README.md` → two matches; the "Signature help" row shows
  `| i |`, the "Navigate up" row still shows `| n |`.

### Step 3: Parse-check and commit

**Verify**:
`nvim --headless -u NONE +'lua local fn,err=loadfile("lua/keymaps.lua"); assert(fn,err); print("PARSE_OK")' +qa`
→ prints `PARSE_OK`.

- Stage `lua/keymaps.lua` and `README.md`.
- Commit: `fix: move LSP signature help to insert mode to free <C-k> for tmux`.

**Verify**: `git show --stat HEAD` → exactly two files changed
(`lua/keymaps.lua`, `README.md`).

## Test plan

- **Static (required)**: the grep checks above.
- **Manual runtime check** (cheap, recommended): in nvim with this config and
  any LSP attached, in normal mode press `<C-k>` and confirm tmux navigation
  up fires (or no-op if not in tmux — importantly, it should NOT pop signature
  help). Then in insert mode inside a function call, press `<C-k>` and confirm
  signature help appears. Both behaviors holding = collision resolved.
  (Requires the plugins installed; not a CI gate.)

## Done criteria

ALL must hold:

- [ ] `grep -n '<C-k>' lua/keymaps.lua` shows `{ "i", "<C-k>", vim.lsp.buf.signature_help, opts },`.
- [ ] `grep -n '<c-k>' lua/plugins/tmux.lua` is unchanged (still line 14,
  `TmuxNavigateUp`).
- [ ] `grep -n '<C-k>' README.md` shows the "Signature help" row with `| i |`
  and the "Navigate up" row still `| n |`.
- [ ] `nvim --headless -u NONE +'lua local fn,err=loadfile("lua/keymaps.lua"); assert(fn,err)' +qa`
  exits 0.
- [ ] `git show --stat HEAD` shows only `lua/keymaps.lua` and `README.md`.
- [ ] `plans/README.md` status row for 007 updated (TODO → DONE).

## STOP conditions

Stop and report back (do not improvise) if:

- The `keymaps.lua` row at line 12 does not match the excerpt (drift). Report.
- There is now, or turns out to be, an existing insert-mode `<C-k>` binding
  elsewhere in `lua/` (re-verify with
  `grep -rnE '"i".*<C-k>|<C-k>.*"i"' lua/`). If one exists, the mode split
  would itself collide — STOP and report; do not proceed to a different
  resolution without operator input.
- The README "Signature help" row is not at the expected text (e.g. it was
  reworded). Report the actual line; do not guess which cell to edit.

## Maintenance notes

- **What interacts with this later**: any future mapping of `<C-k>` in insert
  mode (by another plugin or a personal addition) would re-introduce a
  collision. blink.cmp's keymap table (`lua/plugins/blink.lua`) does NOT use
  `<C-k>`, but check there if completion keymaps change.
- **Reviewer focus**: confirm the tmux binding was not touched and only one
  mode character + one README cell changed.
- **Alternative resolution (not taken)**: if the maintainer prefers
  normal-mode signature help, revert this and instead remap signature help to
  a free key. `gK` was verified free during planning and is a recognizable
  nvim convention. That change would be: keep `{ "n", "<C-k>", ... }` → change
  lhs to `"gK"`, and update the README lhs cell accordingly. One-line either
  way; the mode split was chosen because it preserves the documented `<C-k>`
  key for both features.
