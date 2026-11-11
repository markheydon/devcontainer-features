#!/usr/bin/env bash
set -euo pipefail

python_version="${PYTHONVERSION:-3.12}"

check() {
  local label="$1"
  shift
  echo "Checking ${label}"
  "$@"
}

check "uv" which uv
check "specify" which specify
check "specify not under /root" bash -c '
  target="$(readlink -f "$(command -v specify)")"
  case "${target}" in /root/*) exit 1 ;; esac
'
check "specify version" specify version
check "Python ${python_version} via uv" \
  uv run --python "${python_version}" python -c 'import sys; assert sys.version_info >= (3, 11)'
