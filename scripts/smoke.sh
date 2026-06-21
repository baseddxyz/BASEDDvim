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
