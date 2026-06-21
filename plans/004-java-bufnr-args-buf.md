# Plan 004: Fix undefined `bufnr` in the jdtls `LspAttach` callback

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md`.
>
> **Drift check (run first)**:
> `git diff --stat baf9a2c..HEAD -- lua/plugins/java.lua`
> If `lua/plugins/java.lua` changed since this plan was written, compare the
> "Current state" excerpt against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none (independent of 001, 002, 003, 005)
- **Category**: bug
- **Planned at**: commit `baf9a2c`, 2026-06-18
- **Finding**: BUG-2

## Why this matters

In `java.lua`, the `LspAttach` autocmd callback calls
`keymaps.lsp({ buffer = bufnr })` and `keymaps.lsp_format({ buffer = bufnr })`,
but **`bufnr` is never defined in that scope**. It is not a parameter and not
a local. With `buffer = nil`, `vim.keymap.set` drops the buffer scoping and
binds the LSP keys (`gd`, `K`, `<leader>rn`, `<leader>ca`, etc.) to the
**current window globally** instead of to the Java buffer that jdtls attached
to — so the keymaps land on whatever buffer was focused when jdtls attached,
and leak beyond Java files. The correct value is `args.buf`, the buffer number
Neovim passes to every `LspAttach` callback (see `:help LspAttach`).

## Current state

`lua/plugins/java.lua` — the `nvim-jdtls` plugin spec. The bug is inside the
`LspAttach` autocmd registered in the `config` function. Relevant excerpt
(line numbers are approximate; rely on the text match):

```lua
			-- Setup keymap and dap after the lsp is fully attached.
			-- https://github.com/mfussenegger/nvim-jdtls#nvim-dap-configuration
			-- https://neovim.io/doc/user/lsp.html#LspAttach
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					if client and client.name == "jdtls" then
						local keymaps = require("keymaps")
						keymaps.lsp({ buffer = bufnr })
						keymaps.lsp_format({ buffer = bufnr })

						-- User can set additional keymaps in opts.on_attach
						if opts.on_attach then
							opts.on_attach(args)
						end
					end
				end,
			})
```

The callback's only parameter is `args` (an autocmd event object). Per
`:help LspAttach`, the buffer number is `args.buf`. `bufnr` is an undefined
global read here (resolves to `nil`).

### How the repo does this correctly elsewhere

`lua/plugins/lspconfig.lua` does the same thing right — its `on_attach`
receives `bufnr` as a real parameter:

```lua
local default_lspconfig = function(capabilities)
	return {
		on_attach = function(_, bufnr)
			keymaps.lsp({ buffer = bufnr })
			keymaps.lsp_format({ buffer = bufnr })
		end,
		...
```

There, `bufnr` is the second argument to `on_attach`, so it is defined. In
`java.lua` the equivalent context is an autocmd callback, which does **not**
receive a `bufnr` parameter — it receives `args`, and the buffer is `args.buf`.
That is the only change needed.

### Repo conventions to match

- `keymaps.lsp({ buffer = bufnr })` / `keymaps.lsp_format({ buffer = bufnr })`
  is the established pattern (see `lspconfig.lua` and `lua/keymaps.lua`). Keep
  the call shape identical; only the source of the buffer number changes.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Confirm bare `bufnr` gone | `grep -n 'bufnr' lua/plugins/java.lua` | no matches (exit 1) |
| Confirm `args.buf` present | `grep -n 'args.buf' lua/plugins/java.lua` | ≥2 matches (the two keymap calls) |
| Parse-check file | `nvim --headless -u NONE +'lua local fn,err=loadfile("lua/plugins/java.lua"); assert(fn,err)' +qa` | exit 0, no output |

A full runtime proof (open a `.java` file, let jdtls attach, assert the keymaps
are buffer-local) requires a JDK project and jdtls installed — heavy and out of
scope for verification here. The static checks above plus comparison to the
known-good `lspconfig.lua` pattern are sufficient evidence; the optional
runtime check is described in "Test plan" for whoever wants it.

## Scope

**In scope** (the only file you should modify):
- `lua/plugins/java.lua` — replace `bufnr` with `args.buf` in the two keymap
  calls inside the `LspAttach` callback.

**Out of scope** (do NOT touch):
- The `opts.on_attach(args)` call further down — it correctly passes `args`;
  not a bug.
- The `attach_jdtls` function, the `FileType` autocmd, and everything else in
  the file.
- Other files. `lspconfig.lua` and `rustaceanvim` already do this correctly.

## Git workflow

- Branch: `advisor/004-java-bufnr`
- Single commit. Message style (conventional commits): `fix: scope jdtls LSP
  keymaps to args.buf in LspAttach`.

## Steps

### Step 1: Replace `bufnr` with `args.buf`

Inside the `LspAttach` callback in `lua/plugins/java.lua`, change both
occurrences of `{ buffer = bufnr }` to `{ buffer = args.buf }`:

```lua
					local keymaps = require("keymaps")
					keymaps.lsp({ buffer = args.buf })
					keymaps.lsp_format({ buffer = args.buf })
```

Change nothing else (not the `client` lookup, not the `opts.on_attach(args)`
line, not the comments).

**Verify**:
- `grep -n 'bufnr' lua/plugins/java.lua` → no matches.
- `grep -n 'args.buf' lua/plugins/java.lua` → at least 2 matches on the two
  keymap calls.

### Step 2: Parse-check the file

**Verify**:
`nvim --headless -u NONE +'lua local fn,err=loadfile("lua/plugins/java.lua"); assert(fn,err)' +qa`
→ exit 0, no output. (This confirms the edit didn't break Lua syntax. It does
NOT execute the file's top-level `return`, so it won't trigger plugin loads.)

### Step 3: Commit

- Stage `lua/plugins/java.lua`.
- Commit: `fix: scope jdtls LSP keymaps to args.buf in LspAttach`.

**Verify**: `git show --stat HEAD` → exactly one file changed
(`lua/plugins/java.lua`); `git show HEAD` shows only the two `bufnr`→`args.buf`
edits.

## Test plan

- **Static (required, see Done criteria)**: `grep` and parse checks above.
- **Optional runtime proof** (only if a Java project + jdtls are handy): open a
  `.java` file in a project with a build file jdtls recognizes, wait for
  `LspAttach`, then run
  `:lua print(vim.inspect(vim.tbl_map(function(m) return m.lhs end, vim.api.nvim_buf_get_keymap(0, "n"))))`
  — `gd`, `K`, `gr`, etc. should be listed as buffer-local keymaps for *that*
  buffer, and switching to a non-Java buffer should NOT carry them. Before the
  fix they leak globally; after it they are scoped to the Java buffer. This is
  confirmation only — not required to mark the plan done.

## Done criteria

ALL must hold:

- [ ] `grep -n 'bufnr' lua/plugins/java.lua` returns no matches.
- [ ] `grep -n 'args.buf' lua/plugins/java.lua` returns ≥2 matches.
- [ ] `nvim --headless -u NONE +'lua local fn,err=loadfile("lua/plugins/java.lua"); assert(fn,err)' +qa`
  exits 0.
- [ ] `git show HEAD` shows only the two `bufnr` → `args.buf` edits in
  `lua/plugins/java.lua`; no other file changed.
- [ ] `plans/README.md` status row for 004 updated (TODO → DONE).

## STOP conditions

Stop and report back (do not improvise) if:

- The code at the `LspAttach` callback does not match the excerpt (drift —
  e.g. someone already fixed it, or the callback signature changed). Report
  what you see.
- `bufnr` appears anywhere else in `java.lua` for a legitimate reason (it
  doesn't today, but if a future edit added one, do not blindly delete it —
  report and ask).
- The parse check fails after the edit — report the exact error; do not
  "fix" surrounding code to make it parse.

## Maintenance notes

- **What interacts with this later**: if jdtls on_attach logic is ever
  consolidated with the `lspconfig.lua` `on_attach` helper, remember the
  buffer-number source differs by context (`on_attach(_, bufnr)` vs
  autocmd `args.buf`). A future `luacheck` step (see plan 001's deferred
  follow-up) would catch undefined-global reads like this one automatically —
  that is the highest-leverage guard against recurrence.
- **Reviewer focus**: confirm exactly two tokens changed and the keymaps are
  now scoped to `args.buf`, not applied globally.
