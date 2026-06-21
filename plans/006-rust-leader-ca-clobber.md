# Plan 006: Stop `keymaps.lsp()` from clobbering Rust's `<leader>ca`

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md`.
>
> **Drift check (run first)**:
> `git diff --stat f5c7d00..HEAD -- lua/plugins/lspconfig.lua`
> If `lua/plugins/lspconfig.lua` changed since this plan was written, compare
> the "Current state" excerpt against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none (independent of 007, 008, 009)
- **Category**: bug
- **Planned at**: commit `f5c7d00`, 2026-06-18
- **Finding**: N1

## Why this matters

The `rustaceanvim` `on_attach` sets `<leader>ca` to `vim.cmd.RustLsp("codeAction")`
— rust-analyzer's richer code-action menu (runnables, rebuild proc-macros,
expand macro, etc.). It then calls `keymaps.lsp({ buffer = bufnr })`, which
re-sets the **same** `<leader>ca` to the generic `vim.lsp.buf.code_action`.
Because both are buffer-local and last-set wins, the Rust-specific action is
**silently overwritten**. Rust users — a primary supported language for this
config — get the generic LSP menu and never see rust-analyzer's extras, with
no error to tip them off. The fix is a one-block reorder: apply the generic
LSP keymaps *first*, then the Rust-specific override.

## Current state

`lua/plugins/lspconfig.lua` — the `rustaceanvim` spec's `server.on_attach`
(around lines 175–182). The bug is the ordering: the Rust-specific `<leader>ca`
is set first, then `keymaps.lsp()` clobbers it.

Current code:

```lua
		opts = {
			server = {
				on_attach = function(_, bufnr)
					vim.keymap.set("n", "<leader>ca", function()
						vim.cmd.RustLsp("codeAction")
					end, { desc = "Code Action", buffer = bufnr })
					-- vim.keymap.set(
					-- 	'n',
					-- 	'<leader>dr',
					-- ...
					-- )

					-- lsp keymap
					keymaps.lsp({ buffer = bufnr })
				end,
			},
```

`keymaps.lsp` is defined in `lua/keymaps.lua`. The clobbering entry is:

```lua
		{ { "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts },
```

So after `keymaps.lsp` runs, normal-mode `<leader>ca` is `vim.lsp.buf.code_action`
(overriding the `RustLsp("codeAction")` set above it).

### How the repo does ordering correctly elsewhere

The pattern "apply generic keymaps, then let the specific caller override" is
the natural one and matches how `lspconfig.lua`'s own `default_lspconfig`
applies `keymaps.lsp` once in `on_attach` with no later override (so there's
nothing to clobber). For rustaceanvim the override exists, so it must come
*after* the generic call.

### Repo conventions to match

- Keep the block structure and the `{ desc = "Code Action", buffer = bufnr }`
  option table verbatim.
- Keep the commented-out `<leader>dr` debuggables block in place (it's an
  intentional disabled-alternative; see plan backlog TECH-6 for comment-cruft
  policy — leave it here).

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Confirm order: RustLsp set AFTER keymaps.lsp | `grep -n 'keymaps.lsp\|RustLsp("codeAction")' lua/plugins/lspconfig.lua` | the `keymaps.lsp` line number is LOWER than the `RustLsp("codeAction")` line number |
| File still parses | `nvim --headless -u NONE +'lua local fn,err=loadfile("lua/plugins/lspconfig.lua"); assert(fn,err); print("PARSE_OK")' +qa` | prints `PARSE_OK` |

A full runtime proof (open a Rust project, attach rust-analyzer, press
`<leader>ca`, see the rust-analyzer menu) needs a Rust toolchain + rust-analyzer
installed — heavy and out of scope for verification here. The ordering check +
parse check are sufficient; the change is purely a reorder of two existing,
individually-correct blocks.

## Scope

**In scope** (the only file you should modify):
- `lua/plugins/lspconfig.lua` — reorder the `on_attach` body so
  `keymaps.lsp({ buffer = bufnr })` runs BEFORE the RustLsp `<leader>ca>` set.

**Out of scope** (do NOT touch):
- `lua/keymaps.lua` — the generic `<leader>ca` entry is correct as-is; the
  collision is resolved by ordering, not by changing the shared helper.
- The missing `keymaps.lsp_format` call in this same `on_attach` (it only
  calls `keymaps.lsp`, not `keymaps.lsp_format`). That is a separate, minor
  observation; do not add it here — Rust formatting is handled by conform's
  `format_on_save` and the global `<leader>fM>`.
- Any other plugin's on_attach.

## Git workflow

- Branch: `advisor/006-rust-ca-order`
- Single commit. Message style (conventional commits, per `git log`):
  `fix: apply rustaceanvim <leader>ca after generic LSP keymaps`.

## Steps

### Step 1: Reorder the on_attach body

In `lua/plugins/lspconfig.lua`, inside the `rustaceanvim` `server.on_attach`
function, move the `-- lsp keymap` / `keymaps.lsp({ buffer = bufnr })` block to
BEFORE the `vim.keymap.set("n", "<leader>ca", ...)` RustLsp block. Keep the
commented-out `<leader>dr` debuggables block where it is (it's commented, so
position doesn't matter functionally — leave it adjacent to the RustLsp
mapping for context).

Target shape of the `on_attach` body:

```lua
			on_attach = function(_, bufnr)
				-- lsp keymap (generic first, so the Rust-specific <leader>ca below wins)
				keymaps.lsp({ buffer = bufnr })

				vim.keymap.set("n", "<leader>ca", function()
					vim.cmd.RustLsp("codeAction")
				end, { desc = "Code Action", buffer = bufnr })
				-- vim.keymap.set(
				-- 	'n',
				-- 	'<leader>dr',
				-- 	function()
				-- 		vim.cmd.RustLsp('debuggables')
				-- 	end,
				-- 	{ desc = "Rust debuggables", buffer = bufnr }
				-- )
			end,
```

(Use the live file's exact indentation — tabs. Only the *order* of the two
blocks changes; no tokens are added or removed except the new comment line
noted above, which explains *why* the order matters so a future edit doesn't
re-clobber it.)

**Verify**:
- `grep -n 'keymaps.lsp\|RustLsp("codeAction")' lua/plugins/lspconfig.lua` →
  the `keymaps.lsp` match's line number is **less than** the
  `RustLsp("codeAction")` match's line number. (Both appear; confirm order.)

### Step 2: Parse-check the file

**Verify**:
`nvim --headless -u NONE +'lua local fn,err=loadfile("lua/plugins/lspconfig.lua"); assert(fn,err); print("PARSE_OK")' +qa`
→ prints `PARSE_OK`, exit 0.

### Step 3: Commit

- Stage `lua/plugins/lspconfig.lua`.
- Commit: `fix: apply rustaceanvim <leader>ca after generic LSP keymaps`.

**Verify**: `git show --stat HEAD` → exactly one file changed
(`lua/plugins/lspconfig.lua`).

## Test plan

- **Static (required)**: ordering check + parse check above.
- **Optional runtime proof** (only if a Rust project + rust-analyzer are
  handy): open a Rust file in a Cargo project, wait for `LspAttach`, press
  `<leader>ca`, and confirm rust-analyzer's action menu appears (with entries
  like "Run" / "Debug" for `fn main`, or "Rebuild proc-macros") rather than
  the generic `vim.lsp.buf.code_action` menu. Confirmation only — not required
  to mark the plan done.

## Done criteria

ALL must hold:

- [ ] `grep -n 'keymaps.lsp\|RustLsp("codeAction")' lua/plugins/lspconfig.lua`
  shows the `keymaps.lsp` line number LOWER than the `RustLsp("codeAction")`
  line number.
- [ ] `nvim --headless -u NONE +'lua local fn,err=loadfile("lua/plugins/lspconfig.lua"); assert(fn,err)' +qa`
  exits 0.
- [ ] `git show --stat HEAD` shows only `lua/plugins/lspconfig.lua` changed.
- [ ] `plans/README.md` status row for 006 updated (TODO → DONE).

## STOP conditions

Stop and report back (do not improvise) if:

- The `on_attach` body at the cited location does not match the excerpt (drift).
  Report what you see.
- `keymaps.lsp` is called more than once in this `on_attach`, or the
  `<leader>ca` RustLsp mapping is missing — the fix assumes exactly one of
  each. Report and stop.
- The reorder would require touching the commented `<leader>dr` block's
  *content* (it shouldn't — only its surrounding position). If something about
  the comment block makes a clean reorder impossible, report instead of
  editing the commented code.

## Maintenance notes

- **What interacts with this later**: if `keymaps.lsp` ever gains a new
  Rust-relevant binding, the "generic first, specific override after" ordering
  is what keeps overrides winning. The comment added in Step 1 documents the
  invariant; preserve it.
- **Reviewer focus**: confirm only the two blocks swapped position and the new
  explanatory comment is the only added line. No keymap lhs/lhs-string or
  desc text should have changed.
- **Related deferred item**: this `on_attach` calls `keymaps.lsp` but not
  `keymaps.lsp_format`, so Rust buffers don't get a buffer-local `<leader>fm`.
  Out of scope here (conform `format_on_save` + global `<leader>fM>` cover
  Rust formatting); noted for awareness.
