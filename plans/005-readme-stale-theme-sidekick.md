# Plan 005: Update the stale README (colorscheme + sidekick fork)

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md`.
>
> **Drift check (run first)**:
> `git diff --stat baf9a2c..HEAD -- README.md`
> If `README.md` changed since this plan was written, compare the "Current
> state" excerpt against the live file before proceeding; on a mismatch,
> treat it as a STOP condition.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none (independent of 001–004)
- **Category**: docs
- **Planned at**: commit `baf9a2c`, 2026-06-18
- **Finding**: DOCS-12

## Why this matters

`README.md` advertises a different stack than the code actually ships. Two
factual errors:

1. **Colorscheme**: README lists `monokai-pro.nvim` (machine filter) under
   "Editor UI & Theme", but the active colorscheme is `gruvbox.nvim` —
   `monokai-pro` is commented out in `lua/plugins/colorscheme.lua`. New users
   get wrong theme expectations.
2. **sidekick.nvim fork**: README links `qapquiz/sidekick.nvim`, but commit
   `474e8af` ("chore: change from qapquiz/sidekick.nvim => folke/sidekick.nvim")
   switched the source to `folke/sidekick.nvim`. The README link is stale.

This plan corrects both. It is scoped strictly to these two factual fixes; a
full README/keybindings audit is explicitly out of scope.

## Current state

`README.md` — the two stale lines (line numbers from recon):

Under "### AI & Code Completion":
```
- **[sidekick.nvim](https://github.com/qapquiz/sidekick.nvim)** - CLI integration for AI tools (Claude, etc.)
```

Under "### Editor UI & Theme":
```
- **[monokai-pro.nvim](https://github.com/gthelding/monokai-pro.nvim)** - Monokai Pro colorscheme (machine filter)
```

### Ground truth from the code

- `lua/plugins/colorscheme.lua:15` — the only **active** (uncommented)
  colorscheme spec:
  ```lua
  		"ellisonleao/gruvbox.nvim",
  ```
  with `config` calling `vim.cmd("colorscheme gruvbox")`. All other
  colorschemes (monokai-pro at line 96, tokyonight, evergarden, bamboo,
  aether, koda) are commented out.
- `lua/plugins/ai.lua` — the sidekick spec uses `folke/sidekick.nvim` (the
  `474e8af` commit message confirms the migration from `qapquiz/`).
- README "Installed Language Servers" and "Installed Formatters" sections
  already match the code (`lua_ls`, `ts_ls`, `rust_analyzer`, `gopls`,
  `ruby_lsp`, `jdtls`; `stylua`, `biome`, `google-java-format`) — leave them
  alone.

### Repo conventions to match

- Keep the existing bullet style: `- **[name](url)** - description.`
- Keep descriptions concise and matching the repo's tone.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Stale refs gone | `grep -nE 'qapquiz\|monokai-pro' README.md` | no matches (exit 1) |
| New refs present | `grep -nE 'folke/sidekick\|gruvbox' README.md` | ≥2 matches |
| Confirm monokai not mentioned elsewhere | `grep -ni 'monokai' README.md` | no matches |

## Scope

**In scope** (the only file you should modify):
- `README.md` — two bullets: the sidekick link/owner and the colorscheme
  bullet.

**Out of scope** (do NOT touch, even though related):
- The extensive **Keybindings** tables in README. They are not part of this
  finding and a full accuracy audit is a separate effort. Do not rewrite them.
- `lua/plugins/colorscheme.lua` — the commented-out monokai-pro block is an
  intentional "alternative palette"; leave it (finding TECH-6, deferred).
- Any other README sections (plugins lists for LSP/Completion/etc. are already
  accurate).

## Git workflow

- Branch: `advisor/005-readme-fix`
- Single commit. Message style (conventional commits): `docs: fix stale
  colorscheme and sidekick fork in README`.

## Steps

### Step 1: Fix the sidekick fork reference

In `README.md`, under "### AI & Code Completion", replace:

```
- **[sidekick.nvim](https://github.com/qapquiz/sidekick.nvim)** - CLI integration for AI tools (Claude, etc.)
```

with:

```
- **[sidekick.nvim](https://github.com/folke/sidekick.nvim)** - CLI integration for AI tools (Claude, etc.)
```

(Only the URL owner changes: `qapquiz` → `folke`. Text and description stay the
same.)

**Verify**: `grep -n 'qapquiz' README.md` → no matches.

### Step 2: Fix the colorscheme bullet

In `README.md`, under "### Editor UI & Theme", replace:

```
- **[monokai-pro.nvim](https://github.com/gthelding/monokai-pro.nvim)** - Monokai Pro colorscheme (machine filter)
```

with:

```
- **[gruvbox.nvim](https://github.com/ellisonleao/gruvbox.nvim)** - Gruvbox colorscheme
```

(Repo/URL from `lua/plugins/colorscheme.lua:15`:
`ellisonleao/gruvbox.nvim`.)

**Verify**:
- `grep -n 'monokai' README.md` → no matches (case-insensitive).
- `grep -n 'gruvbox' README.md` → one match on the new bullet.

### Step 3: Commit

- Stage `README.md`.
- Commit: `docs: fix stale colorscheme and sidekick fork in README`.

**Verify**: `git show --stat HEAD` → exactly one file changed (`README.md`).

## Done criteria

ALL must hold:

- [ ] `grep -nE 'qapquiz|monokai-pro' README.md` returns no matches.
- [ ] `grep -ni 'monokai' README.md` returns no matches.
- [ ] `grep -nE 'folke/sidekick|ellisonleao/gruvbox' README.md` returns ≥2
  matches.
- [ ] `git show --stat HEAD` shows only `README.md` changed.
- [ ] `plans/README.md` status row for 005 updated (TODO → DONE).

## STOP conditions

Stop and report back (do not improvise) if:

- The two target lines in `README.md` do not match the excerpts (drift — e.g.
  README was already updated, or reworded). Report what you see.
- You find additional stale entries while editing (e.g. another plugin link
  that no longer matches the code). Report them as a list; do **not** expand
  scope to fix them in this commit.
- The "Keybindings" tables turn out to contain errors — note it for a
  follow-up; do not edit them here.

## Maintenance notes

- **What interacts with this later**: whenever the colorscheme or AI stack
  changes, the README's "Editor UI & Theme" and "AI & Code Completion" bullets
  must be updated in lockstep. The repo has a recurring pattern of the README
  lagging the code (this very finding, plus the `474e8af` sidekick migration
  that didn't update the README). A future contributor should check these two
  sections against `colorscheme.lua` and `ai.lua` on any such change.
- **Reviewer focus**: confirm exactly two bullets changed and no keybindings
  or other sections were touched.
- **Deferred follow-up**: a full README accuracy audit (keybindings tables vs.
  the actual `keys =` specs across `lua/plugins/*.lua`) is worth a separate
  plan if the maintainer wants the docs to be authoritative.
