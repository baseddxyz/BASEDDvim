# Plan 015: Resolve ts_ls Vue plugin path per-attach (fix N2)

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md`.
>
> **Drift check (run first)**:
> `git diff --stat 98f2e3a..HEAD -- lsp/ts_ls.lua`
> If `lsp/ts_ls.lua` changed since this plan was written, compare the
> "Current state" excerpt against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: MED (touches how the Vue plugin path resolves at LSP attach; a
  subtle bug here silently breaks `.vue` TS support)
- **Depends on**: plan 013 (the file `lsp/ts_ls.lua` was created by 013)
- **Category**: bug
- **Planned at**: commit `98f2e3a`, 2026-06-19
- **Finding**: N2 (now isolated to one file by plan 013)

## Why this matters

`lsp/ts_ls.lua` (created by plan 013) resolves the `@vue/typescript-plugin`
location once at config load:

```lua
location = vim.fn.getcwd() .. "/node_modules/@vue/typescript-plugin",
```

`vim.fn.getcwd()` runs when the config table is evaluated (once, at startup).
So the path is **frozen to the launch directory**. Consequences:
- Open a `.vue` file in project B after launching from project A → Vue TS
  plugin points at project A's `node_modules` → silent mis-resolution or no
  Vue support.
- Use `:cd` to switch projects → same problem.
- Launch nvim from `$HOME` then open a project → the plugin points at
  `~/node_modules/...` (almost certainly nonexistent).

The fix resolves the path **per-attach**, from the project root the LSP client
already computed, so each workspace gets its own correct plugin location.

## Current state

`lsp/ts_ls.lua` (full file, post plan 013):

```lua
-- ts_ls (typescript-language-server) config, with @vue/typescript-plugin for .vue support.
-- Shared on_attach + capabilities come from the wildcard default set in
-- lua/plugins/lspconfig.lua.
--
-- NOTE (deferred N2): the `location` below is resolved once at config load
-- via vim.fn.getcwd(), so it is frozen to the launch dir. Moving it here
-- isolates the bug; a per-attach fix via `before_init` is a follow-up.
return {
	filetypes = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
		"vue",
	},
	init_options = {
		plugins = {
			{
				name = "@vue/typescript-plugin",
				location = vim.fn.getcwd() .. "/node_modules/@vue/typescript-plugin",
				languages = {
					"javascript",
					"javascriptreact",
					"typescript",
					"typescriptreact",
					"vue",
				},
			},
		},
	},
}
```

### Verified API contract (nvim 0.12.3 — read from the runtime source)

The fix hinges on `before_init`. The authoritative contract is in
`runtime/lua/vim/lsp/client.lua`:

- **Line 564**: `initializationOptions = config.init_options,` builds the
  `init_params` table during client start.
- **Lines 571–577**: `_run_callbacks({self._before_init_cb}, ..., init_params, config)`
  calls `before_init(params, config)` AFTER that build, passing BOTH the
  already-built `init_params` AND the original `config`.
- **Line ~585**: `rpc.request('initialize', init_params, ...)` sends
  `init_params` (the FIRST arg to `before_init`) to the server.

**Two things that follow (the subtle part — confirmed with the advisor model):**

1. **You MUST mutate `params.initializationOptions` (the first arg), NOT
   `config.init_options`.** Line 564 is a *reference* copy, so mutating
   `config.init_options` would technically be visible for THIS attach — but
   it's the **wrong pattern**: the `config` table is shared across attaches, so
   mutating it leaks the resolved path into subsequent attaches (different
   project gets the previous project's path, or races on concurrent attaches).
   Mutating `params` is per-attach and side-effect-free. A future nvim that
   deep-copies `init_options` would silently break the `config` approach too;
   mutating `params` is correct by definition.
2. **The root is already in `params` — don't recompute.** `before_init`'s first
   arg already contains the resolved workspace root: `params.rootUri`
   (a `file://` URI) or `params.rootPath` (deprecated but present). Reusing it
   avoids a second `vim.fs.root` walk and guarantees agreement with whatever
   `root_dir` lspconfig computed. Verified `vim.uri_to_fname` exists (0.12) to
   parse `rootUri`.

### Edge cases the fix must handle

- **Plugin not installed** (plain JS/TS project without Vue): don't inject a
  nonexistent path. Check `vim.fn.isdirectory(plugin_path) == 1` first; if
  absent, skip the Vue entry (types_ls tolerates a missing plugin gracefully).
  Prefer checking `<root>/node_modules/@vue/typescript-plugin/package.json`
  exists (a dir can exist empty after a failed `npm install`).
- **`params.initializationOptions` or `.plugins` may be nil**: the static
  `init_options` table sets them, but be defensive — another config layer
  could clear them.

### Repo conventions to match

- `lsp/<name>.lua` returns a config table (not a module). `before_init`,
  `root_dir`, `on_attach`, `on_init`, `on_exit`, `commands` may be functions;
  everything else is a plain table (native LSP constraint — verified with the
  advisor: `init_options` as a function is NOT supported).
- Tabs for indentation.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| No `getcwd` left in ts_ls.lua | `grep -n 'getcwd' lsp/ts_ls.lua` | no matches |
| `before_init` present | `grep -n 'before_init' lsp/ts_ls.lua` | one match |
| File parses | `nvim --headless -u NONE +'lua local fn,err=loadfile("lsp/ts_ls.lua"); assert(fn,err); print("PARSE_OK")' +qa` | prints `PARSE_OK` |
| Static `location` under init_options gone | `grep -n 'location =' lsp/ts_ls.lua` | no matches in the static init_options block (only inside before_init) |

## Scope

**In scope** (the only file you should modify):
- `lsp/ts_ls.lua` — replace the static `location` with a `before_init` that
  resolves the plugin path per-attach from `params.rootUri`/`rootPath`.

**Out of scope** (do NOT touch):
- `lua/plugins/lspconfig.lua` — the wildcard defaults and enable list are
  correct; ts_ls's specifics now live entirely in `lsp/ts_ls.lua`.
- The other `lsp/*.lua` files.
- `root_dir` in this file — it's not set here (nvim-lspconfig's ts_ls default
  provides it). Do NOT add a custom `root_dir`; reusing `params.rootUri`
  sidesteps the need (advisor-recommended).
- Any formatter/linter config (conform, nvim-lint).

## Git workflow

- Branch: `advisor/015-ts-ls-vue-path`
- Single commit. Message style (conventional commits):
  `fix: resolve ts_ls Vue plugin path per-attach via before_init`.

## Steps

### Step 1: Rewrite `lsp/ts_ls.lua`

Replace the entire contents of `lsp/ts_ls.lua` with:

```lua
-- ts_ls (typescript-language-server) config, with @vue/typescript-plugin for .vue support.
-- Shared on_attach + capabilities come from the wildcard default set in
-- lua/plugins/lspconfig.lua.
--
-- The Vue plugin `location` is resolved PER-ATTACH in before_init from the
-- workspace root the LSP client already computed (params.rootUri), NOT frozen
-- at config load. This fixes N2: the old code used vim.fn.getcwd() at load
-- time, which froze the path to the launch dir and broke .vue support when
-- opening a different project or after :cd.
return {
	filetypes = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
		"vue",
	},
	-- Static plugin scaffolding; the `location` is injected per-attach below.
	init_options = {
		plugins = {},
	},
	-- Mutate params.initializationOptions (NOT config.init_options): params is
	-- the actual initialize payload sent to the server, and mutating it is
	-- per-attach (config is shared across attaches; mutating it would leak).
	before_init = function(params, config)
		-- Reuse the workspace root the client already resolved. Prefer rootUri
		-- (file:// URI), fall back to rootPath (deprecated but present).
		local root
		if params.rootUri then
			root = vim.uri_to_fname(params.rootUri)
		elseif params.rootPath then
			root = params.rootPath
		end
		if not root or root == "" then
			return
		end

		-- Only inject the Vue plugin if it's actually installed in this project
		-- (check package.json, not just the dir — a failed npm install can leave
		-- an empty dir). Plain JS/TS projects without Vue skip this cleanly.
		local plugin_path = root .. "/node_modules/@vue/typescript-plugin"
		local marker = plugin_path .. "/package.json"
		if vim.fn.filereadable(marker) ~= 1 then
			return
		end

		-- Defensive: ensure the plugins table exists on the params being sent.
		params.initializationOptions = params.initializationOptions or {}
		params.initializationOptions.plugins = params.initializationOptions.plugins or {}

		table.insert(params.initializationOptions.plugins, {
			name = "@vue/typescript-plugin",
			location = plugin_path,
			languages = {
				"javascript",
				"javascriptreact",
				"typescript",
				"typescriptreact",
				"vue",
			},
		})
	end,
}
```

**Verify**:
- `grep -n 'getcwd' lsp/ts_ls.lua` → no matches.
- `grep -n 'before_init' lsp/ts_ls.lua` → one match.
- `grep -n 'vim.uri_to_fname' lsp/ts_ls.lua` → one match.

### Step 2: Parse-check

**Verify**:
`nvim --headless -u NONE +'lua local fn,err=loadfile("lsp/ts_ls.lua"); assert(fn,err); print("PARSE_OK")' +qa`
→ prints `PARSE_OK`.

### Step 3: Commit

- Stage `lsp/ts_ls.lua`.
- Commit: `fix: resolve ts_ls Vue plugin path per-attach via before_init`.

**Verify**: `git show --stat HEAD` → exactly one file changed (`lsp/ts_ls.lua`).

## Test plan

- **Static (required)**: the grep checks + parse check above.
- **Structural sanity (recommended, plugin-free)**: load the file in a throwaway
  nvim and call the returned `before_init` with a fake `params` table to confirm
  it injects/doesn't-inject correctly:
  ```bash
  nvim --headless -u NONE +'lua local cfg = dofile("lsp/ts_ls.lua"); local params = { rootUri = "file:///nonexistent" }; local ok, err = pcall(cfg.before_init, params, {}); local f=io.open("/tmp/n2.txt","w"); f:write("before_init_runs="..tostring(ok).."\n"); f:write("err="..tostring(err).."\n"); f:write("plugins_count="..#(params.initializationOptions and params.initializationOptions.plugins or {})); f:close()' +qa
  cat /tmp/n2.txt
  ```
  Expected (because the marker file doesn't exist):
  `before_init_runs=true`, `err=nil`, `plugins_count=0` (graceful skip — proves
  the existence check + defensive init work without erroring).
- **Manual runtime check (requires the plugin)**: in a real Vue project with
  `@vue/typescript-plugin` installed, open a `.vue` file, run
  `:lua print(vim.inspect(vim.lsp.get_clients({name="ts_ls"})[1].config.init_options.plugins))`
  — the Vue entry should appear with a path under THIS project's `node_modules`.
  Then `:cd` to a different Vue project, open a `.vue` file, re-check — the path
  should reflect the NEW project. (This is the N2 proof: path now follows the
  workspace, not the launch dir.)
- **Plain-TS regression check**: open a `.ts` file in a project WITHOUT the Vue
  plugin. ts_ls should attach normally with no Vue-plugin warning (the
  `filereadable` check skips injection).

## Done criteria

ALL must hold:

- [ ] `grep -n 'getcwd' lsp/ts_ls.lua` returns no matches.
- [ ] `grep -n 'before_init' lsp/ts_ls.lua` returns one match.
- [ ] `grep -n 'vim.uri_to_fname' lsp/ts_ls.lua` returns one match.
- [ ] `nvim --headless -u NONE +'lua local fn,err=loadfile("lsp/ts_ls.lua"); assert(fn,err)' +qa`
  exits 0.
- [ ] The structural sanity check prints `before_init_runs=true`,
  `plugins_count=0` (graceful skip on a non-existent root).
- [ ] `git show --stat HEAD` shows only `lsp/ts_ls.lua` changed.
- [ ] `plans/README.md` status row for 015 updated, and N2 removed from the
  deferred backlog (now fixed).

## STOP conditions

Stop and report back (do not improvise) if:

- **`before_init`'s first arg does NOT contain `rootUri` or `rootPath`** in
  your environment. This is the LSP-standard `InitializeParams` and was
  confirmed from the nvim runtime source, but if a re-check shows neither is
  present, the root-resolution approach fails — STOP and report; do not fall
  back to `vim.fn.getcwd()` (that's the original bug) or to recomputing via
  `vim.fs.root` without operator input.
- **The structural sanity check errors** (the `pcall` returns `false`). The
  before_init must run without error even when the root has no Vue plugin —
  if it throws, the defensive init is incomplete; report rather than patching
  blindly.
- **You're tempted to mutate `config.init_options` instead of `params`.**
  Don't. Re-read "Verified API contract" point 1: mutating config leaks across
  attaches and is forward-fragile. Mutating params is correct.
- **You're tempted to make `init_options` a function.** Don't — the native LSP
  client does not invoke `init_options(params)`; only `before_init`,
  `root_dir`, `on_attach`, etc. may be functions.
- The code at the cited locations doesn't match the excerpt (drift). Report.

## Maintenance notes

- **Why `params` not `config`** (on the record): line 564 of
  `client.lua` is a reference copy, so mutating `config.init_options` would
  appear to work for a single attach — but it mutates shared config state,
  leaking the resolved path across attaches (different project inherits the
  previous path) and racing on concurrent attaches. Mutating `params` is
  per-attach. This is the subtle correctness property; preserve it.
- **The `filereadable` check is load-bearing for plain-JS/TS projects.** Without
  it, every TS file would inject a Vue plugin path pointing at a likely-absent
  dir, and typescript-language-server would warn on startup. Keep the
  `package.json`-not-just-dir check (failed npm installs leave empty dirs).
- **If you later add another ts_ls plugin** (e.g. a tailwind LSP plugin via
  `init_options.plugins`), it goes in the static `init_options.plugins = {}`
  table OR is appended in `before_init` alongside the Vue entry — both work
  because the static table is the default and `before_init` only appends.
- **Reviewer focus**: confirm (a) `getcwd` is gone, (b) `before_init` mutates
  `params` not `config`, (c) the `filereadable` guard is present, (d) the
  defensive `or {}` chains on params.
- **Lesson**: the N2 fix was de-risked by (1) reading the nvim runtime source
  for the `before_init` contract rather than assuming, and (2) consulting the
  advisor model on the `params`-vs-`config` mutation subtlety, which caught a
  real cross-attach leak the source read alone wouldn't have surfaced. This
  matches the discipline that caught the plan-007 digraph and plan-010
  `package.path` gaps.
