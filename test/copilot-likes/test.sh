#!/usr/bin/env bash
set -euo pipefail

check() {
  local label="$1"
  shift
  echo "Checking ${label}"
  "$@"
}

check "ripgrep" which rg
check "fd" which fd
check "jq" which jq
if command -v bat >/dev/null 2>&1; then
  check "bat" which bat
else
  check "batcat" which batcat
fi
check "eza" which eza
check "fzf" which fzf
check "tree" which tree
check "direnv" which direnv
check "delta" which delta
