# Plan 010: LSP server toggle UI with persisted config

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md`.
>
> **Drift check (run first)**:
> `git diff --stat d9a6fcc..HEAD -- lua/plugins/lspconfig.lua lua/configs/init.lua`
> If `lua/plugins/lspconfig.lua` changed since this plan was written, compare
> the "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P3
- **Effort**: M
- **Risk**: MED (touches the core LSP enable path; additive, but central)
- **Depends on**: none (independent of 001–009)
- **Category**: direction (feature)
- **Planned at**: commit `d9a6fcc`, 2026-06-18
- **Finding**: user-requested feature (not from the audit)

## Why this matters

Today, which LSP servers run is hardcoded: `lspconfig.lua` enables everything
in `mason_options.ensure_installed` unconditionally on every load. There is no
way to turn a server off without editing source. This plan adds a runtime
toggle (`:LspToggle`) backed by a small persisted file, so you can disable a
noisy or slow server (e.g. turn off `gopls` while not on a Go project) without
touching config — and the choice survives restart.

### Five design decisions (locked; overriding requires editing this plan)

1. **Persistence = a JSON "disabled set" at `~/.local/share/nvim/basedddvim-lsp-toggles.json`.**
   Format is a plain array of *disabled* server names, e.g. `["gopls","ts_ls"]`.
   **Why a blacklist (disabled-set), not a whitelist (enabled-set):** a missing
   or empty file means "everything enabled" = today's behavior = **zero
   migration**. A whitelist would silently turn OFF any new server you later add
   to `ensure_installed` until you toggle it on — surprising. Blacklist is the
   safe default. Machine-local (under `stdpath("data")`) on purpose: toggles are
   a per-machine preference, not something to commit.
2. **Scope = global**, all projects. Per-project scoping (via `root_dir`) is far
   more code and not needed for v1.
3. **Effect timing = persist now, takes full effect on next restart.** Disabling
   also calls `vim.lsp.stop_client` for immediate "off" feedback in the current
   session. **Re-enabling requires restart** — there is no `vim.lsp.disable()`
   in Neovim 0.12 (verified: `tostring(vim.lsp.disable) == "false"`), and the
   enable autocommands only register at load. This is a documented v1 limit,
   shown in the UI message.
4. **Coverage = the 4 loop-managed servers only:** `lua_ls`, `ts_ls`, `gopls`,
   `ruby_lsp`. `rust_analyzer` is co-managed by **rustaceanvim** (via
   `vim.g.rustaceanvim`) and **jdtls** is managed by **nvim-jdtls**
   (`start_or_attach` in a FileType autocmd); both bypass the simple
   enable-loop toggle and are **excluded from v1**. The UI lists them as
   "managed by plugin — not toggleable".
5. **`MasonInstallAll` stays orthogonal to toggles.** This is intentional, not
   a bug: `MasonInstallAll` installs *binaries on disk*; the toggle controls
   *whether a server runs*. Three independent layers:
   | Layer | Concern | Controlled by |
   |---|---|---|
   | Installed | server binary on disk | `MasonInstallAll` / Mason |
   | Configured | Neovim knows its cmd/ft/settings | `vim.lsp.config` (always runs) |
   | Enabled | autocmd to auto-start on filetypes | `vim.lsp.enable` (← toggle gates this) |
   `MasonInstallAll` reads the **static** `mason_options.ensure_installed`
   table, NOT the toggle file, so toggling `gopls` off does NOT remove its
   binary — it just stops `vim.lsp.enable("gopls")`. This is a **feature**:
   re-enabling later is instant (no Mason re-download). Do NOT make
   `MasonInstallAll` filter by toggles — that would break the instant-re-enable
   property (see STOP conditions).

## Current state

### The enable loop (`lua/plugins/lspconfig.lua`)

`mason_options.ensure_installed` (lines 20–31) lists the servers; the enable
loop (lines 79–132) iterates them. The relevant tail of the loop:

```lua
			for _, lsp in ipairs(mason_options.ensure_installed) do
				if lsp == "ts_ls" then
					-- ... vim.lsp.config(ts_ls, ...) with Vue plugin ...
				elseif lsp == "pyright" then
					-- ...
				elseif lsp ~= "rust_analyzer" then
					vim.lsp.config(lsp, default_lspconfig(capabilities))
				end

				-- enable LSP
				vim.lsp.enable(lsp)        -- ← line 131: this is what the toggle gates
			end
```

Note: `vim.lsp.enable(lsp)` currently runs for **every** server including
`rust_analyzer` (line 131 is outside the `elseif` chain). The toggle gate must
preserve rust_analyzer's current "always enabled" behavior — see the
`is_disabled` defensive design in Step 2.

### The MasonInstallAll command (`lua/plugins/lspconfig.lua` lines 150–163)

```lua
				vim.api.nvim_create_user_command("MasonInstallAll", function()
					local mason_servers = {}
					for _, mason_server in ipairs(mason_options.ensure_installed) do
						table.insert(mason_servers, mason_lsp_mapping[mason_server])
					end
					vim.cmd("MasonInstall " .. ... )
				end, {})
```

This reads the hardcoded list and must **stay exactly like this** (decision 5).

### Feature-flag precedent (`lua/configs/init.lua:1-2`)

```lua
local M = {
	ai = { enabled = true },
	...
```

That's a *load-time* flag. This feature needs *runtime + persisted* state, which
the repo does not do anywhere yet (verified: no `writefile`/`vim.json`/`stdpath("data")`
usage exists in `lua/`). So this plan introduces the repo's first persistence
pattern — keep it isolated in one new module.

### Repo conventions to match

- New module with functions → top-level `lua/` (like `lua/keymaps.lua`), not
  `lua/configs/` (which holds constants only). So: `lua/lsp-toggles.lua`.
- Module pattern: `local M = {} … return M` (see `lua/keymaps.lua`).
- User commands are created inside a plugin's `config` function (see
  `MasonInstallAll`). `:LspToggle` goes in the lspconfig `config` function.
- `pcall` around anything that can fail (file IO, JSON decode) — see
  `lua/keymaps.lua:29` for the `pcall(require, ...)` exemplar.
- Tabs for indentation (repo standard; no `.stylua.toml`).

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Module loads in plain nvim | `nvim --headless -u NONE +'lua package.path="./lua/?.lua;"..package.path; assert(require("lsp-toggles")); print("OK")' +qa` | prints `OK` |
| JSON round-trip works | see Step 1 verify block | writes `false false true false ROUNDTRIP_OK` to a file |
| Enable-loop file parses | `nvim --headless -u NONE +'lua local fn,err=loadfile("lua/plugins/lspconfig.lua"); assert(fn,err); print("PARSE_OK")' +qa` | prints `PARSE_OK` |

The JSON round-trip test (Step 1) runs in `nvim -u NONE` because it uses only
core APIs (`vim.fn.readfile`, `vim.json`, `vim.fn.writefile`, `vim.fn.stdpath`)
— **no plugins required**. That is the cheap, deterministic core of this plan's
verification. **Important:** `-u NONE` does NOT auto-add `./lua` to the
runtimepath, so every `-u NONE` test that `require`s the module must prepend
`package.path = "./lua/?.lua;" .. package.path` first (shown above and below).
This was confirmed during planning — without the prepend, `require("lsp-toggles")`
fails with `module not found`.

## Scope

**In scope** (the only files you should create or modify):
- `lua/lsp-toggles.lua` (new) — persistence + toggle logic + server list.
- `lua/plugins/lspconfig.lua` — gate `vim.lsp.enable` for toggleable servers;
  add the `:LspToggle` user command.

**Out of scope** (do NOT touch):
- `lua/plugins/java.lua` (jdtls) and the rustaceanvim spec — they are
  non-toggleable by design (decision 4). Do NOT add toggle hooks to them.
- The `MasonInstallAll` command — must stay orthogonal (decision 5).
- `mason_options.ensure_installed` / `mason_lsp_mapping` — unchanged.
- A snacks-specific multi-toggle picker UI is an **optional** Step 5; the
  robust `vim.ui.select` v1 (Step 4) is the committed deliverable.

## Git workflow

- Branch: `advisor/010-lsp-toggle`
- Commit per logical step is fine (module, loop wiring, command/UI). Message
  style (conventional commits): `feat: add :LspToggle with persisted config`.
- Do NOT push or open a PR unless the operator instructed it.

## Steps

### Step 1: Create `lua/lsp-toggles.lua`

Create `lua/lsp-toggles.lua` with this content (tabs for indentation). It is
pure core-API code (testable without plugins):

```lua
-- Persisted LSP server toggle state.
--
-- Stores a "disabled set" (blacklist) as JSON at stdpath("data"). A missing
-- or empty file = everything enabled = the repo's default behavior (zero
-- migration). Only the servers in `toggleable` can ever be gated; rust_analyzer
-- and jdtls are managed by their own plugins and are never disabled here.
local M = {}

local PATH = vim.fn.stdpath("data") .. "/basedddvim-lsp-toggles.json"

-- Servers this feature can toggle. Must match the loop-managed set in
-- lspconfig.lua (i.e. mason_options.ensure_installed MINUS rust_analyzer,
-- which is co-managed by rustaceanvim, and jdtls, which is managed by nvim-jdtls).
M.toggleable = { "lua_ls", "ts_ls", "gopls", "ruby_lsp" }

-- Read the disabled set from disk. Missing/corrupt file = {} (all enabled).
-- Returns a lookup table { server_name = true }.
function M.get_disabled()
	local disabled = {}
	local ok, lines = pcall(vim.fn.readfile, PATH)
	if not ok or not lines or #lines == 0 then
		return disabled
	end
	local ok2, data = pcall(vim.json.decode, table.concat(lines, "\n"))
	if not ok2 or type(data) ~= "table" then
		return disabled
	end
	for _, name in ipairs(data) do
		if type(name) == "string" then
			disabled[name] = true
		end
	end
	return disabled
end

-- True only if `name` is toggleable AND currently disabled. Non-toggleable
-- servers (rust_analyzer, jdtls) always return false, so the enable loop
-- enables them unconditionally — preserving current behavior.
function M.is_disabled(name)
	if not vim.tbl_contains(M.toggleable, name) then
		return false
	end
	return M.get_disabled()[name] == true
end

-- Persist the given disabled list (array of names). Creates the data dir if needed.
function M._write(disabled_list)
	vim.fn.mkdir(vim.fs.dirname(PATH), "p")
	local json = vim.json.encode(disabled_list)
	vim.fn.writefile({ json }, PATH)
end

-- Flip `name`'s state, persist, return the new "is disabled?" boolean.
function M.toggle(name)
	if not vim.tbl_contains(M.toggleable, name) then
		vim.notify("lsp-toggles: '" .. name .. "' is not toggleable", vim.log.levels.WARN)
		return false
	end
	local disabled = M.get_disabled()
	local list = {}
	for srv, _ in pairs(disabled) do
		list[#list + 1] = srv
	end
	if disabled[name] then
		-- enable: omit from list
		M._write(vim.tbl_filter(function(s)
			return s ~= name
		end, list))
		return false
	else
		-- disable: add to list
		list[#list + 1] = name
		M._write(list)
		return true
	end
end

return M
```

**Verify** (run from the repo root). `-u NONE` does NOT add `./lua` to the
runtimepath, so the prepend below is required (confirmed during planning):

```bash
nvim --headless -u NONE +'lua package.path="./lua/?.lua;"..package.path; local T=require("lsp-toggles"); local f=io.open(os.getenv("HOME").."/.lsp-spike-out","w"); local function b(x) return x and "true" or "false" end; f:write(b(T.is_disabled("rust_analyzer")).." "..b(T.is_disabled("gopls")).." "); T.toggle("gopls"); f:write(b(T.is_disabled("gopls")).." "); T.toggle("gopls"); f:write(b(T.is_disabled("gopls")).." ROUNDTRIP_OK\n"); f:close()' +qa
cat ~/.lsp-spike-out && rm ~/.lsp-spike-out
```

Expected output (writes to a file because headless `print` capture is
unreliable — also confirmed during planning; file IO is the ground truth):
```
false false true false ROUNDTRIP_OK
```

Read each value as a contract assertion:
- 1st `false` = `is_disabled("rust_analyzer")` → **the critical guard.**
  rust_analyzer is non-toggleable, so `is_disabled` must return `false` and the
  enable loop enables it unconditionally (preserving current behavior). If you
  see `true` here, STOP — the `tbl_contains` guard is broken.
- 2nd `false` = `is_disabled("gopls")` before any toggle (default enabled).
- 3rd `true` = after `toggle("gopls")` → now disabled, persisted to disk.
- 4th `false` = after a second `toggle("gopls")` → re-enabled, removed from
  the disabled set.

The persisted file at `~/.local/share/nvim/basedddvim-lsp-toggles.json` should
end as `[]` (empty array) after the round-trip, or be absent — either is
correct (`get_disabled` decodes both to "all enabled").

### Step 2: Gate the enable loop

In `lua/plugins/lspconfig.lua`, require the module near the top (next to
`local keymaps = require("keymaps")`):

```lua
local lsp_toggles = require("lsp-toggles")
```

Then change the enable call at the bottom of the loop (line ~131). Replace:

```lua
				-- enable LSP
				vim.lsp.enable(lsp)
```

with:

```lua
				-- enable LSP (toggleable servers can be disabled via :LspToggle;
				-- rust_analyzer is non-toggleable so is_disabled returns false for it)
				if not lsp_toggles.is_disabled(lsp) then
					vim.lsp.enable(lsp)
				end
```

Leave `vim.lsp.config(...)` calls above UNCHANGED for every server — config is
cheap and means re-enabling a toggled-off server later needs no re-configuration.

**Verify**:
- `nvim --headless -u NONE +'lua local fn,err=loadfile("lua/plugins/lspconfig.lua"); assert(fn,err); print("PARSE_OK")' +qa`
  → prints `PARSE_OK`.
- `grep -n 'lsp_toggles.is_disabled\|vim.lsp.enable' lua/plugins/lspconfig.lua`
  → `is_disabled` appears once, guarding `vim.lsp.enable`.

### Step 3: Add the `:LspToggle` user command + immediate `stop_client`

Still in the `lspconfig` `config = function()`, after the enable loop (and after
the mason dependency block, anywhere at the top level of the config function),
register the command:

```lua
			-- :LspToggle [server] — toggle a server on/off (persisted).
			-- No arg opens a picker. Disabling stops its clients now; enabling
			-- takes full effect on next restart (no vim.lsp.disable in 0.12).
			vim.api.nvim_create_user_command("LspToggle", function(opts)
				local name = opts.args
				if name == "" then
					require("lsp-toggles").pick()
					return
				end
				local now_disabled = require("lsp-toggles").toggle(name)
				if now_disabled then
					vim.lsp.stop_client(vim.lsp.get_clients({ name = name }))
					vim.notify("LSP '" .. name .. "' disabled (restart to fully stop; re-enable via :LspToggle)", vim.log.levels.INFO)
				else
					vim.notify("LSP '" .. name .. "' enabled — restart Neovim to attach", vim.log.levels.INFO)
				end
			end, {
				nargs = "?",
				complete = function()
					return require("lsp-toggles").toggleable
				end,
				desc = "Toggle an LSP server on/off (persisted)",
			})
```

**Verify**:
- File parses: same `loadfile` check → `PARSE_OK`.
- `grep -n 'create_user_command("LspToggle"' lua/plugins/lspconfig.lua` → one match.

### Step 4: Add the picker (robust v1 using `vim.ui.select`)

Add a `pick` function to `lua/lsp-toggles.lua` (snacks overrides `vim.ui.select`
to render a nice picker, so this is both robust AND pretty with zero snacks
API risk):

```lua
-- Open a picker to toggle one server. Uses vim.ui.select so it works with any
-- provider (snacks.nvim overrides it for a nicer UI — see lua/plugins/snacks.lua).
function M.pick()
	local disabled = M.get_disabled()
	local items = {}
	for _, name in ipairs(M.toggleable) do
		items[#items + 1] = {
			name = name,
			label = string.format("[%s] %s", disabled[name] and "x" or " ", name),
		}
	end
	-- Also surface the non-toggleable ones, read-only, for discoverability.
	local note = { label = "— rust_analyzer / jdtls: managed by plugin (not toggleable)", name = "" }
	table.insert(items, note)

	vim.ui.select(items, {
		prompt = "Toggle LSP server (select to flip; re-invoke for another):",
		format_item = function(item)
			return item.label
		end,
	}, function(choice)
		if not choice or choice.name == "" then
			return
		end
		local now_disabled = M.toggle(choice.name)
		if now_disabled then
			vim.lsp.stop_client(vim.lsp.get_clients({ name = choice.name }))
		end
		vim.notify(
			"LSP '" .. choice.name .. "' " .. (now_disabled and "disabled" or "enabled")
				.. " — restart for full effect",
			vim.log.levels.INFO
		)
	end)
end
```

**Verify**:
- `nvim --headless -u NONE +'lua package.path="./lua/?.lua;"..package.path; local T=require("lsp-toggles"); assert(type(T.pick)=="function"); print("OK")' +qa`
  (from repo root) → prints `OK`.
- File parses.

### Step 5 (OPTIONAL enhancement — skip if anything is unclear): snacks.picker multi-toggle

The v1 above is single-toggle-per-invocation. If you want a picker that stays
open and flips multiple servers before confirming, this step investigates
`Snacks.picker`. **This is a spike with a fallback** — if the API is awkward,
ship Step 4 as the deliverable and record the finding.

Spike approach: `Snacks.picker.pick({ items = ..., format = ..., actions = { ["<CR>"] = function(picker, item) ... flip and refresh ... end } })`.
The risk: the exact `actions`/refresh API differs across snacks versions. Read
`~/.local/share/nvim/lazy/snacks.nvim/lua/snacks/picker/` on a machine where
the config runs before deciding.

**Escape hatch**: if after 30 minutes the snacks multi-toggle isn't clean, STOP
enhancing, keep Step 4, and note in `plans/README.md` that the multi-toggle is
deferred. Step 4 fully satisfies the feature request.

### Step 6: Commit

- Stage `lua/lsp-toggles.lua` and `lua/plugins/lspconfig.lua`.
- Commit: `feat: add :LspToggle with persisted config`.

**Verify**: `git show --stat HEAD` → only those two files (plus optionally a
3rd if you did Step 5 in a separate file — you didn't; Step 5 edits
`lsp-toggles.lua`).

## Test plan

- **Module JSON round-trip (required, plugin-free)**: Step 1 verify block.
- **Enable-loop gating logic (required)**: temporarily add a fake disabled
  entry by toggling a server in a headless nvim, then confirm the loop would
  skip it. Lightweight version: `nvim --headless -u NONE +'lua package.path="./lua/?.lua;"..package.path; require("lsp-toggles").toggle("gopls"); print(require("lsp-toggles").is_disabled("gopls"))' +qa`
  → `true`; then clean up with another toggle. (This proves persistence; the
  loop wiring is verified by parse + grep.)
- **Manual runtime check (recommended, requires plugins)**: with the full
  config loaded, run `:LspToggle gopls`, confirm the notify message and that
  any running gopls client stops (`:LspInfo` or `:lua print(#vim.lsp.get_clients({name="gopls"}))`).
  Restart, open a Go file, confirm gopls does NOT attach. `:LspToggle gopls`
  again, restart, confirm it DOES attach.
- **MasonInstallAll orthogonality (recommended)**: after toggling gopls off,
  run `:MasonInstallAll` — it should still install/update gopls (no error), and
  gopls should STILL not auto-start (toggle won). Confirms decision 5.

## Done criteria

ALL must hold:

- [ ] `lua/lsp-toggles.lua` exists; from repo root
  `nvim --headless -u NONE +'lua package.path="./lua/?.lua;"..package.path; assert(require("lsp-toggles")); print("OK")' +qa`
  prints `OK`.
- [ ] The Step 1 round-trip verify prints `false false true false ROUNDTRIP_OK`
  (rust_analyzer=false is the key assertion: non-toggleable servers are never
  disabled).
- [ ] `lua/plugins/lspconfig.lua` parses (`loadfile` → exits 0) and
  `vim.lsp.enable` is guarded by `lsp_toggles.is_disabled`.
- [ ] `:LspToggle` command is registered (`grep` shows one `create_user_command("LspToggle"`).
- [ ] `MasonInstallAll` command body is UNCHANGED (decision 5):
  `git diff d9a6fcc..HEAD -- lua/plugins/lspconfig.lua` shows the MasonInstallAll
  loop (`for _, mason_server in ipairs(mason_options.ensure_installed)`) untouched.
- [ ] `git show --stat HEAD` shows only `lua/lsp-toggles.lua` and
  `lua/plugins/lspconfig.lua`.
- [ ] `lua/plugins/java.lua` and the rustaceanvim spec are NOT modified
  (decision 4).
- [ ] `plans/README.md` status row for 010 updated.

## STOP conditions

Stop and report back (do not improvise) if:

- **The Step 1 round-trip does not print exactly `false false true false`.**
  In particular if `is_disabled("rust_analyzer")` returns `true`, the defensive
  guard is wrong and the loop would disable rust — STOP and report; do not
  "fix" it by special-casing rust in the loop (the guard is the right place).
- **`vim.json` / `vim.fn.writefile` / `vim.fs.dirname` are unavailable in your
  nvim** (re-check: the box this was planned on is nvim 0.12.3 and they are
  core). If something is missing, report; do not swap in a different
  persistence mechanism without operator input.
- **You are tempted to make `MasonInstallAll` respect the toggle.** Do not.
  Re-read decision 5: orthogonality is the point (instant re-enable). If the
  operator later wants a separate `:MasonInstallEnabled`, that's a different
  plan.
- **The snacks.picker multi-toggle (Step 5) proves fragile.** Take the escape
  hatch: ship Step 4 and report that Step 5 is deferred. Do not ship a
  fragile custom picker.
- **`vim.lsp.get_clients({ name = ... })` errors in your nvim version.** Report;
  the stop_client call is a nice-to-have, not load-bearing (restart is the real
  mechanism). It can be wrapped in pcall if needed, but ask first.

## Maintenance notes

- **What interacts with this later**:
  - Adding a new server to `mason_options.ensure_installed`: if it's
    loop-managed (not rust/jdtls), ALSO add it to `M.toggleable` in
    `lsp-toggles.lua` or it won't appear in the toggle UI (it'll still work,
    just not be toggleable). The two lists are intentionally separate so
    rust_analyzer stays in `ensure_installed` but out of `toggleable`.
  - The persistence file is machine-local and gitignored-adjacent (under
    `stdpath("data")`, outside the repo) — it will NOT be committed and will
    differ per machine. That's by design (decision 1).
- **Reviewer focus**:
  - The `is_disabled` defensive guard (non-toggleable → false) is the
    load-bearing safety check. Confirm it.
  - `MasonInstallAll` body must be byte-identical to before (decision 5).
  - The two-list invariant: `toggleable ⊆ ensure_installed \ {rust_analyzer,
    jdtls}`.
- **Known v1 limits (documented in UI messages)**:
  - Re-enabling requires restart (no `vim.lsp.disable` in 0.12).
  - rust_analyzer and jdtls are not toggleable.
  - Toggles are global, not per-project.
- **Deferred follow-ups** (out of scope here):
  - snacks multi-toggle picker (Step 5 escape hatch).
  - Per-project toggles via `root_dir`.
  - Toggle UI for rust/jdtls (needs plugin-specific hooks: a `vim.g.rustaceanvim`
    disable flag, a `attach_jdtls` short-circuit).
