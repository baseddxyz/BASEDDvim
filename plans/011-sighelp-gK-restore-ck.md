# Plan 011: Switch signature help to `gK` and restore `<C-k>` to tmux-navigate-up

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md`.
>
> **Drift check (run first)**:
> `git diff --stat be48dcc..HEAD -- lua/keymaps.lua README.md`
> If either file changed since this plan was written, compare the "Current
> state" excerpts against the live code before proceeding; on a mismatch,
> treat it as a STOP condition.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: bug (corrects a defect introduced by plan 007)
- **Planned at**: commit `be48dcc`, 2026-06-18
- **Supersedes**: plan 007's mode-split resolution

## Why this matters

Plan 007 resolved the `<C-k>` collision (tmux-navigate-up vs LSP signature
help) by moving signature help from `n` to `i` mode. That fix was flawed: it
**shadowed Vim's built-in insert-mode digraph key** (`i_CTRL-K`, `:help i_CTRL-K`
— `<C-k>e'` types `é`, etc.), which is a core editing feature, not an optional
plugin. So 007 traded a cross-plugin collision for a collision with a built-in.

This plan corrects it with the cleanest resolution (Option 3 from the 007
review): **keep `<C-k>` for tmux navigation everywhere (normal mode, as the
tmux plugin defines it), and move LSP signature help to `gK` in normal mode.**
Both features win in their natural form, insert mode stays free for digraphs,
and `gK` is a recognizable nvim convention (verified free during planning).

The user confirmed they DO use tmux navigation (`<C-h/j/k/l>`), which makes
this the right resolution over a simple revert.

## Current state

`lua/keymaps.lua` line 12 — currently the flawed mode split from plan 007:

```lua
		{ "i", "<C-k>", vim.lsp.buf.signature_help, opts },
```

`README.md` line 104 — currently documents the flawed state:

```
| `<C-k>` | i | Signature help |
```

`lua/plugins/tmux.lua` line 14 — unchanged and correct (do not touch):

```lua
			{ "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
```

### Why the fix is fully isolated to keymaps.lua

`signature_help` appears in exactly ONE place in the repo — line 12 of
`keymaps.lua` (verified: `grep -rn signature_help lua/` → only that line). All
three LSP on_attach callers get the binding through the shared
`keymaps.lsp({...})` helper:
- `lua/plugins/lspconfig.lua:56` (generic on_attach)
- `lua/plugins/lspconfig.lua:178` (rustaceanvim on_attach)
- `lua/plugins/java.lua:139` (jdtls LspAttach)

So changing the one row in `keymaps.lua` propagates the `gK` binding to all
LSP buffers automatically. No other file needs a binding edit.

### Verified free

`gK` is not used anywhere in `lua/` or `README.md` (confirmed during planning).
It is a recognizable nvim convention (some configs use `gK` for signature help
or hover alternatives).

### Repo conventions to match

- `keymaps.lua` rows are `{ mode, lhs, rhs, opts }`. Change the mode and lhs of
  the one row; keep `vim.lsp.buf.signature_help` and `opts` verbatim.
- README keybinding rows are `| <key> | <mode> | <description> |`.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| `<C-k>` row reverted to tmux-only (no LSP row) | `grep -n '<C-k>' lua/keymaps.lua` | no matches |
| `gK` row present in normal mode | `grep -n '"gK"' lua/keymaps.lua` | one match: `{ "n", "gK", vim.lsp.buf.signature_help, opts },` |
| File parses | `nvim --headless -u NONE +'lua local fn,err=loadfile("lua/keymaps.lua"); assert(fn,err); print("PARSE_OK")' +qa` | prints `PARSE_OK` |
| tmux binding untouched | `grep -n '<c-k>' lua/plugins/tmux.lua` | unchanged line 14 |
| README sig-help row updated | `grep -n 'Signature help' README.md` | line shows `\| \`gK\` \| n \|` |

## Scope

**In scope** (the only files you should modify):
- `lua/keymaps.lua` — change the one signature-help row from
  `{ "i", "<C-k>", ... }` to `{ "n", "gK", ... }`.
- `README.md` — change the "Signature help" row from
  `| \`<C-k>\` | i | Signature help |` to `| \`gK\` | n | Signature help |`.

**Out of scope** (do NOT touch):
- `lua/plugins/tmux.lua` — the tmux `<c-k>` binding is correct and should stay.
- The three `keymaps.lsp(...)` call sites (lspconfig, rustaceanvim, jdtls) —
  they pick up the `gK` binding via the shared helper; no edit needed.
- Other rows in `keymaps.lua` or other README keybinding rows.
- Digraphs (`i_CTRL-K`) — no mapping touches insert mode after this plan, so
  the built-in digraph is automatically restored. Do NOT add an explicit
  digraph mapping.

## Git workflow

- Branch: `advisor/011-sighelp-gK`
- Single commit. Message style (conventional commits):
  `fix: move LSP signature help to gK, restore <C-k> for tmux-nav`.
- Do NOT push or open a PR unless the operator instructed it.

## Steps

### Step 1: Change the signature-help row in keymaps.lua

In `lua/keymaps.lua` line 12, change both the mode and the lhs:

Before:
```lua
		{ "i", "<C-k>", vim.lsp.buf.signature_help, opts },
```

After:
```lua
		{ "n", "gK", vim.lsp.buf.signature_help, opts },
```

Leave every other row in the `keymaps` table and the rest of the file
untouched.

**Verify**:
- `grep -n '<C-k>' lua/keymaps.lua` → no matches (the LSP `<C-k>` row is gone;
  tmux's `<c-k>` lives in `tmux.lua`, not here).
- `grep -n '"gK"' lua/keymaps.lua` → one match reading
  `{ "n", "gK", vim.lsp.buf.signature_help, opts },`.

### Step 2: Update the README signature-help row

In `README.md` line ~104, change the "Signature help" row:

Before:
```
| `<C-k>` | i | Signature help |
```

After:
```
| `gK` | n | Signature help |
```

Do NOT touch the "Tmux Integration" `| <C-k> | n | Navigate up |` row (~line 160)
— it stays.

**Verify**:
- `grep -n 'Signature help' README.md` → the row shows `` `gK` `` and `| n |`.
- `grep -n '<C-k>' README.md` → only the "Navigate up" row (one match).

### Step 3: Parse-check and commit

**Verify**:
`nvim --headless -u NONE +'lua local fn,err=loadfile("lua/keymaps.lua"); assert(fn,err); print("PARSE_OK")' +qa`
→ prints `PARSE_OK`.

- Stage `lua/keymaps.lua` and `README.md`.
- Commit: `fix: move LSP signature help to gK, restore <C-k> for tmux-nav`.

**Verify**: `git show --stat HEAD` → exactly two files changed
(`lua/keymaps.lua`, `README.md`); the `lua/keymaps.lua` diff is exactly one
token-pair change (`"i"`→`"n"` and `"<C-k>"`→`"gK"`).

## Test plan

- **Static (required)**: the grep checks above.
- **Manual runtime check** (cheap, recommended, requires plugins):
  1. In a code buffer with an LSP attached, normal mode, press `gK` → signature
     help popup appears.
  2. Press `<C-k>` in normal mode → tmux pane moves up (or no-ops outside tmux;
     importantly it does NOT pop signature help).
  3. In insert mode, press `<C-k>` then a digraph (e.g. `e'`) → the digraph
     character (`é`) is inserted, confirming the built-in is restored.
  All three holding = collision resolved cleanly. Requires the plugins
  installed; not a CI gate.

## Done criteria

ALL must hold:

- [ ] `grep -n '<C-k>' lua/keymaps.lua` returns no matches.
- [ ] `grep -n '"gK"' lua/keymaps.lua` returns one match:
  `{ "n", "gK", vim.lsp.buf.signature_help, opts },`.
- [ ] `grep -n '<c-k>' lua/plugins/tmux.lua` unchanged (line 14, `TmuxNavigateUp`).
- [ ] `grep -n 'Signature help' README.md` shows `` `gK` `` and `| n |`.
- [ ] `grep -n '<C-k>' README.md` shows only the "Navigate up" row.
- [ ] `nvim --headless -u NONE +'lua local fn,err=loadfile("lua/keymaps.lua"); assert(fn,err)' +qa`
  exits 0.
- [ ] `git show --stat HEAD` shows only `lua/keymaps.lua` and `README.md`.
- [ ] `plans/README.md` status row for 011 updated (TODO → DONE), and plan
  007's maintenance notes reference 011 (see Maintenance below).

## STOP conditions

Stop and report back (do not improvise) if:

- The `keymaps.lua` row at line 12 does not match the excerpt (drift). Report.
- `gK` turns out to already be in use somewhere (re-check with
  `grep -rn '"gK"' lua/ README.md`). If it is, this plan's resolution collides
  — STOP and report; do not pick a different key without operator input.
- `signature_help` is found bound anywhere else besides `keymaps.lua:12`
  (re-check `grep -rn signature_help lua/`). The plan assumes the single
  binding; if there's another, the tmux-nav restoration would be incomplete
  for that buffer. Report.
- The README "Signature help" row is not at the expected text (reworded, etc.).
  Report the actual line; do not guess the cell to edit.

## Maintenance notes

- **This supersedes plan 007's resolution.** Plan 007's file should be updated
  (by the operator or a follow-up) to note that its mode-split approach was
  replaced by 011's `gK` remap because 007 shadowed `i_CTRL-K` digraphs. The
  007 commit (`a1c7abf`) stays in history as a reverted approach.
- **What interacts with this later**: any future mapping of `gK` (by another
  plugin or personal addition) would re-introduce a collision on signature
  help. Check `lua/plugins/blink.lua` and any new plugin's keymaps. `<C-k>`
  in insert mode must stay free for digraphs — do NOT map it in insert mode
  anywhere.
- **Reviewer focus**: confirm only the one `keymaps.lua` row changed
  (mode + lhs), the tmux binding was untouched, and no insert-mode mapping was
  introduced. The diff for `keymaps.lua` should be exactly two tokens changed
  on one line.
- **Lesson recorded**: plan 007's "verified free" check only looked for
  existing *user* mappings, not built-in Vim features. `i_CTRL-K` is a
  built-in digraph entry that a user mapping shadows. Future "is this key
  free?" checks must include built-in mode-specific features (`:help i_*`,
  `:help c_*`, etc.), not just `grep` for existing mappings. This is noted
  here so the vetting gap is on the record.
