# Plan 001: Add a headless load smoke test and CI workflow

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md`.
>
> **Drift check (run first)**: this plan creates **new** files
> (`scripts/smoke.sh`, `.github/workflows/smoke.yml`); there is no existing
> content to drift against. Confirm the repo has no existing `scripts/` or
> `.github/` content that collides:
> `ls scripts .github 2>/dev/null` → either "No such file" or only unrelated
> files.

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: LOW
- **Depends on**: none
- **Category**: dx / tests
- **Planned at**: commit `baf9a2c`, 2026-06-18
- **Finding**: DX-9 (no verification baseline)

## Why this matters

BASEDDvim currently has **no automated way to know the config even loads** —
no tests, no CI, no smoke script. To check anything you must open nvim by
hand. That gap is exactly how three runtime bugs shipped (see plans 002–004)
and why nothing guards future changes. This plan establishes the baseline: a
one-command headless load check plus a GitHub Action that runs it on every
push.

**Honest scope note (important):** a *load-only* smoke test does **not** catch
the three runtime bugs in plans 002–004 — those live in a keymap function
body, a table string, and a callback closure, none of which execute at load
time. What this baseline *does* catch: broken `require()`s, syntax that only
errors at load, bad top-level calls, and future regressions of that class. It
is the prerequisite for a healthy repo and the model for the per-plan
verifications. Do not oversell it as catching the bugs.

## Current state

- The repo is a lazy.nvim config installed at `~/.config/nvim` (per `README.md`
  install instructions). Entry point `init.lua` requires `vim-options` then
  sets up lazy with `{ import = "plugins" }`.
- There is **no** `scripts/` directory and **no** `.github/` directory today.
- Verified recon facts (determined on a nvim 0.12.3 box, 2026-06-18):
  1. `nvim --headless -u NONE +qa` → exit code `0`, empty output. (clean baseline)
  2. **`nvim --headless -u <bad-config> +qa` exits `0` even when the config
     errors at load.** A bad `require()` printed `Error in <file>:`, `E5113:`,
     and `stack traceback:` but the process still returned 0.
     → **Conclusion: exit code is unreliable; the smoke test MUST inspect
     output for error patterns.**
  3. Loading with `-u <file>` also pulls in the host machine's real
     `~/.config/nvim` (noise was observed from `/home/moshi/.config/nvim/plugin/*.lua`).
     → The smoke test must run against an **isolated** config dir so the host's
     personal config does not leak in and create false failures.

### Repo conventions to match

- Shell scripts: simple, `set -uo pipefail`, an informational final `echo`.
- No existing CI / formatter / linter config to mirror. Use a standard,
  widely-used Vim setup action for CI (`rhysd/action-setup-vim@v1`).
- New top-level dirs are fine (`scripts/`, `.github/workflows/`).

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Make script executable | `chmod +x scripts/smoke.sh` | exit 0 |
| Run smoke locally | `./scripts/smoke.sh` | prints `OK: config loaded cleanly`, exit 0 |
| Parse-check the script | `bash -n scripts/smoke.sh` | exit 0, no output |
| Validate workflow YAML | `python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/smoke.yml'))"` | exit 0, no output |

(`nvim` is the only runtime tool. `python3` is used only for a one-off YAML
sanity check during this plan; it is not a runtime dependency.)

## Scope

**In scope** (the only files you should create):
- `scripts/smoke.sh` (new)
- `.github/workflows/smoke.yml` (new)

**Out of scope** (do NOT touch):
- `init.lua`, anything under `lua/` — this plan adds tooling, it does not
  change config behavior.
- Any attempt to make the smoke test exercise keymaps, LSP, or linting. That
  belongs in the bug-fix plans (002–004), not here.

## Git workflow

- Branch: `advisor/001-smoke-ci`
- One commit is fine (two small new files). Message style — the repo uses
  conventional commits (see `git log --oneline`): `ci: add headless config
  smoke test`.
- Do NOT push or open a PR unless the operator instructed it.

## Steps

### Step 1: Create `scripts/smoke.sh`

Create `scripts/smoke.sh` with exactly this content:

```bash
#!/usr/bin/env bash
# Headless load smoke test for BASEDDvim.
#
# Loads the full config in a clean, isolated Neovim instance and fails if
# Neovim emits any error patterns while doing so.
#
# Why inspect output (not exit code): `nvim --headless +qa` returns 0 even
# when the config errors at load time, so the exit code is not a reliable
# signal. We grep for Neovim's own error markers instead.
#
# Limitations: this is a LOAD test. It will not catch bugs that only trigger
# on a keypress, on opening a specific filetype, or inside an LSP callback.
# See plans/002..004 for those.
set -uo pipefail

# Isolate the config so the host machine's personal ~/.config/nvim does not
# leak in and create false failures. Point XDG_CONFIG_HOME at this repo's
# parent layout: <TMP>/nvim -> <repo>.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISOLATED="$(mktemp -d)"
trap 'rm -rf "$ISOLATED"' EXIT
ln -s "$REPO_ROOT" "$ISOLATED/nvim"

LOG="$(mktemp)"

XDG_CONFIG_HOME="$ISOLATED" nvim --headless "+qa" >"$LOG" 2>&1

# Neovim error markers. Tuned to Neovim's exact output formats observed in
# recon: "Error in <file>:", "E5xxx:" codes, "stack traceback:", and the
# common nil-access messages.
if grep -nE 'Error in |E5[0-9]{3}:|stack traceback:|attempt to (call|index) a nil value' "$LOG"; then
  echo "FAIL: errors detected while loading BASEDDvim config" >&2
  echo "--- captured output ---" >&2
  cat "$LOG" >&2
  exit 1
fi

echo "OK: config loaded cleanly"
```

**Verify**:
- `bash -n scripts/smoke.sh` → exit 0, no output (syntax OK).
- `chmod +x scripts/smoke.sh` → exit 0.

### Step 2: Run the smoke test locally

**Verify**: `./scripts/smoke.sh` → prints exactly `OK: config loaded cleanly`,
exit code 0.

If it FAILS here on a clean checkout, the most likely cause is that the
executor's machine doesn't have the lazy plugins cloned yet. In that case,
first run `nvim --headless "+Lazy! sync" +qa` once (with the same isolated
`XDG_CONFIG_HOME`) to populate `~/.local/share/nvim/lazy`, then re-run
`./scripts/smoke.sh`. (See STOP conditions.)

### Step 3: Create `.github/workflows/smoke.yml`

Create `.github/workflows/smoke.yml` with exactly this content:

```yaml
name: smoke

on:
  push:
  pull_request:

jobs:
  smoke:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Neovim
        uses: rhysd/action-setup-vim@v1
        with:
          neovim: true
          version: stable

      - name: Install plugins (lazy.nvim)
        run: |
          ISOLATED="$(mktemp -d)"
          ln -s "$PWD" "$ISOLATED/nvim"
          XDG_CONFIG_HOME="$ISOLATED" nvim --headless "+Lazy! sync" +qa

      - name: Smoke test
        run: scripts/smoke.sh
```

**Verify**:
- `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/smoke.yml'))"` →
  exit 0, no output (valid YAML).
- `grep -n 'smoke.sh' .github/workflows/smoke.yml` → one match in the
  `Smoke test` step.

### Step 4: Commit and report

- Stage `scripts/smoke.sh` and `.github/workflows/smoke.yml`.
- Commit: `ci: add headless config smoke test`.
- Report the local `./scripts/smoke.sh` output in the PR/verdict.

**Verify**: `git status --porcelain` → only the two new files staged/committed;
nothing under `lua/` or `init.lua` changed.

## Done criteria

Machine-checkable. ALL must hold:

- [ ] `scripts/smoke.sh` exists, is executable (`ls -l scripts/smoke.sh` shows
  `x` bits), and `bash -n scripts/smoke.sh` exits 0.
- [ ] `./scripts/smoke.sh` prints `OK: config loaded cleanly` and exits 0.
- [ ] `.github/workflows/smoke.yml` exists and parses as valid YAML.
- [ ] `git status --porcelain` shows no changes to `init.lua` or `lua/`.
- [ ] `plans/README.md` status row for 001 updated (TODO → DONE).

## STOP conditions

Stop and report back (do not improvise) if:

- `./scripts/smoke.sh` fails even after running `Lazy! sync` in the isolated
  config dir — the config may have a genuine load error (which would itself be
  a new finding; report it, do not patch it here).
- The smoke output contains matching error lines that are clearly **benign
  plugin noise** rather than real errors (e.g. a plugin printing the literal
  word "error" in normal output). Report the lines; do not silently loosen the
  grep. The operator will decide whether to tune the pattern.
- `nvim --headless "+Lazy! sync" +qa` hangs for more than ~2 minutes — likely a
  plugin prompting interactively. Report which plugin; do not modify any
  `lua/plugins/*.lua` to work around it in this plan.
- `rhysd/action-setup-vim@v1` is unavailable or the chosen `version: stable`
  is too old for `vim.lsp.enable` (needs Neovim 0.11+). Report; the operator
  will pin a different version.

## Maintenance notes

- **What future changes interact with this**: any new plugin added under
  `lua/plugins/` is automatically covered by the load smoke. Bug fixes that
  need *runtime* verification (keymaps, filetype handlers, LSP callbacks)
  should add their own targeted checks — do not assume the load smoke covers
  them.
- **Reviewer focus**: confirm the grep pattern wasn't loosened just to make
  the test pass; a green run with a gutted pattern is worse than no test.
- **Deferred follow-ups** (out of scope here): a `luacheck` step would
  statically catch undefined globals (e.g. it would flag the `bufnr` bug in
  plan 004). Not added now because luacheck isn't in the toolchain; consider
  `:MasonInstall luacheck` + a `.luacheckrc` as a separate plan.
