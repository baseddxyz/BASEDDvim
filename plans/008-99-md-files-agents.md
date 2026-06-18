# Plan 008: Make 99's `md_files` find the repo's actual `AGENTS.md`

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md`.
>
> **Drift check (run first)**:
> `git diff --stat f5c7d00..HEAD -- lua/plugins/ai.lua`
> If `lua/plugins/ai.lua` changed since this plan was written, compare the
> "Current state" excerpt against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none (independent of 006, 007, 009)
- **Category**: bug
- **Planned at**: commit `f5c7d00`, 2026-06-18
- **Finding**: N4

## Why this matters

The `99` plugin (ThePrimeagen/99) is configured with `md_files = { "AGENT.md" }`
— the list of filenames it walks up the directory tree to auto-attach as
context for AI refactors. But this repository's guidelines file is named
**`AGENTS.md`** (plural), and there is **no `AGENT.md`**. So 99's auto-context
discovery finds nothing in this very repo: the project's own agent guidelines
are invisible to `99` requests, defeating the feature. The fix adds
`"AGENTS.md"` so 99 finds the repo's actual file, while keeping `"AGENT.md"`
for other projects that follow 99's documented default.

## Current state

`lua/plugins/ai.lua` — inside the `99` setup call, the `md_files` table
(around lines 370–372):

```lua
						md_files = {
							"AGENT.md",
						},
```

The in-file comment above it (lines 364–369) documents the walk-up behavior
and uses `AGENT.md` as the example, matching 99's own example convention.

### Ground truth from the repo

- `AGENTS.md` exists at the repo root (this is the file the maintainers and
  other agents use — pi, Claude Code, etc.).
- `AGENT.md` does **not** exist (`ls AGENT.md` → "No such file or directory",
  confirmed during planning).
- So `md_files = { "AGENT.md" }` matches zero files in this repo.

### How 99 uses `md_files`

Per the in-file comment: from the originating buffer's path, 99 walks upward
looking for any file whose name is in `md_files`, stopping at the project
root. Listing multiple names means it will match whichever exists.

### Repo conventions to match

- Keep the table literal style (`{ "…", "…" },`).
- The repo standardizes on `AGENTS.md` (plural) — list it first so the local
  convention takes precedence.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Confirm AGENTS.md added | `grep -n 'AGENTS.md\|AGENT.md' lua/plugins/ai.lua` | both `"AGENTS.md"` and `"AGENT.md"` present; `"AGENTS.md"` listed first |
| File parses | `nvim --headless -u NONE +'lua local fn,err=loadfile("lua/plugins/ai.lua"); assert(fn,err); print("PARSE_OK")' +qa` | prints `PARSE_OK` |

A full runtime proof (make a `99` request and confirm `AGENTS.md` content is
injected) requires the `99` plugin + an AI backend configured — out of scope
for verification here. The static check plus the documented walk-up semantics
are sufficient.

## Scope

**In scope** (the only file you should modify):
- `lua/plugins/ai.lua` — add `"AGENTS.md"` as the first entry in `md_files`.

**Out of scope** (do NOT touch):
- The in-file comment that uses `AGENT.md` as its example. It is illustrative
  of 99's walk-up behavior, not a statement about this repo; leaving it avoids
  churn. (If you want it updated, that's a separate docs edit.)
- The repo's `AGENTS.md` filename — do not rename it to `AGENT.md`. The
  plural form is the cross-tool standard (pi/Claude Code/etc.) and was
  intentionally chosen.
- Other `99` config fields (`custom_rules`, `completion`, etc.).

## Git workflow

- Branch: `advisor/008-99-md-files`
- Single commit. Message style (conventional commits):
  `fix: include AGENTS.md in 99 md_files for repo context`.

## Steps

### Step 1: Add `"AGENTS.md"` to md_files

In `lua/plugins/ai.lua`, change the `md_files` table to list `"AGENTS.md"`
first, then `"AGENT.md"`:

Before:
```lua
						md_files = {
							"AGENT.md",
						},
```

After:
```lua
						md_files = {
							"AGENTS.md",
							"AGENT.md",
						},
```

(Indentation is tabs — match the surrounding lines exactly.)

**Verify**:
- `grep -n 'AGENTS.md\|AGENT.md' lua/plugins/ai.lua` → at least two matches
  in the `md_files` block: `"AGENTS.md",` appearing before `"AGENT.md",`.

### Step 2: Parse-check and commit

**Verify**:
`nvim --headless -u NONE +'lua local fn,err=loadfile("lua/plugins/ai.lua"); assert(fn,err); print("PARSE_OK")' +qa`
→ prints `PARSE_OK`.

- Stage `lua/plugins/ai.lua`.
- Commit: `fix: include AGENTS.md in 99 md_files for repo context`.

**Verify**: `git show --stat HEAD` → exactly one file changed
(`lua/plugins/ai.lua`); the diff shows one line added (`"AGENTS.md",`).

## Test plan

- **Static (required)**: the grep + parse checks above.
- **Optional runtime proof** (only if `99` + an AI backend are configured):
  from a buffer in this repo, trigger a `99` request (e.g. `<leader>9f` on a
  function) and inspect 99's debug log (`/tmp/<basename>.99.debug`, per the
  config's logger path) to confirm `AGENTS.md` content appears in the request
  context. Confirmation only — not required to mark the plan done.

## Done criteria

ALL must hold:

- [ ] `grep -n '"AGENTS.md"' lua/plugins/ai.lua` returns a match inside the
  `md_files` table, listed before `"AGENT.md"`.
- [ ] `grep -n '"AGENT.md"' lua/plugins/ai.lua` still returns a match (the
  fallback entry is preserved).
- [ ] `nvim --headless -u NONE +'lua local fn,err=loadfile("lua/plugins/ai.lua"); assert(fn,err)' +qa`
  exits 0.
- [ ] `git show --stat HEAD` shows only `lua/plugins/ai.lua` changed, with a
  one-line addition.
- [ ] `plans/README.md` status row for 008 updated (TODO → DONE).

## STOP conditions

Stop and report back (do not improvise) if:

- The `md_files` block does not match the excerpt (drift). Report what you see.
- The repo has been changed to also contain an `AGENT.md` (re-check with
  `ls AGENT.md AGENTS.md`). If both exist, the plan still works (99 finds
  whichever), but report it so the maintainer can decide on a single source of
  truth.
- The `99` setup signature has changed such that `md_files` is no longer a
  simple list of filenames (e.g. it now expects `{ name = ..., path = ... }`
  entries). Report; do not guess the new shape.

## Maintenance notes

- **What interacts with this later**: if the repo ever standardizes on a
  different guidelines filename, update `md_files` in lockstep. The two-name
  list is deliberately lenient so it works across this repo (AGENTS.md) and
  any project following 99's AGENT.md example.
- **Reviewer focus**: confirm exactly one line was added and order is
  `AGENTS.md` then `AGENT.md`.
- **Related deferred item**: BUG-4 (the same `99` config sets
  `source = "cmp"` but the repo uses blink.cmp, so 99's completion is
  non-functional). That is a separate spike, not touched here.
