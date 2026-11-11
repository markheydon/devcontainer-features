#!/usr/bin/env bash
set -euo pipefail

python_version="${PYTHONVERSION:-3.12}"
sync_script="/usr/local/share/spec-kit/sync-specify-version.sh"

resolve_sync_target_version() {
  if [[ -n "${SPEC_KIT_SYNC_TARGET_VERSION:-}" ]]; then
    printf '%s' "${SPEC_KIT_SYNC_TARGET_VERSION}"
    return 0
  fi
  local pin_file="${REPO_SYNC_PIN:-}"
  if [[ -z "${pin_file}" ]]; then
    pin_file="$(dirname "${BASH_SOURCE[0]}")/sync-target-version.txt"
  fi
  if [[ -f "${pin_file}" ]]; then
    tr -d '[:space:]' < "${pin_file}"
    return 0
  fi
  echo "Set SPEC_KIT_SYNC_TARGET_VERSION or provide test/spec-kit/sync-target-version.txt" >&2
  return 1
}

sync_target_version="$(resolve_sync_target_version)"

check() {
  local label="$1"
  shift
  echo "Checking ${label}"
  "$@"
}

check_specify_not_under_root() {
  local target
  target="$(readlink -f "$(command -v specify)")"
  case "${target}" in /root/*) return 1 ;; esac
}

installed_specify_version() {
  uv tool list 2>/dev/null | awk '/^specify-cli / { sub(/^v/, "", $2); print $2; exit }'
}

read_init_speckit_version() {
  uv run --python "${python_version}" python -c '
import json, pathlib, sys
path = pathlib.Path(".specify/init-options.json")
if not path.is_file():
    sys.exit(1)
data = json.loads(path.read_text(encoding="utf-8"))
v = data.get("speckit_version") if isinstance(data, dict) else None
if not v:
    sys.exit(1)
print(str(v))
'
}

verify_postcreate_sync_result() {
  local expected actual
  expected="$(read_init_speckit_version)"
  actual="$(installed_specify_version)"
  if [[ "${actual}" != "${expected}" ]]; then
    echo "Expected specify-cli ${expected} (from init-options), got ${actual:-<none>}" >&2
    return 1
  fi
}

dev_container_user() {
  if id vscode >/dev/null 2>&1; then
    printf '%s' "vscode"
    return 0
  fi
  if id node >/dev/null 2>&1; then
    printf '%s' "node"
    return 0
  fi
  return 1
}

simulate_postcreate_sync() {
  local before user workspace
  if [[ ! -x "${sync_script}" ]]; then
    echo "Missing executable ${sync_script}" >&2
    return 1
  fi
  before="$(installed_specify_version || true)"
  if [[ -z "${before}" ]]; then
    echo "specify-cli is not installed before sync test" >&2
    return 1
  fi
  if [[ "${before}" == "${sync_target_version}" ]]; then
    echo "Image already has specify-cli ${sync_target_version}; cannot test downgrade sync." >&2
    echo "Update test/spec-kit/sync-target-version.txt to an older PyPI release or rebuild with specifyVersion: latest." >&2
    return 1
  fi
  user="$(dev_container_user)" || {
    echo "No vscode or node user in image; cannot simulate postCreate user" >&2
    return 1
  }
  workspace="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf '${workspace}'" RETURN
  mkdir -p "${workspace}/.specify"
  printf '{"speckit_version": "%s"}\n' "${sync_target_version}" >"${workspace}/.specify/init-options.json"

  if [[ "$(id -un)" == "${user}" ]]; then
    echo "Running sync-specify-version.sh as ${user} (current user)"
    (cd "${workspace}" && "${sync_script}")
  elif [[ "$(id -u)" -eq 0 ]]; then
    if ! command -v sudo >/dev/null 2>&1; then
      echo "sudo is required to run sync as ${user} from root" >&2
      return 1
    fi
    chown -R "${user}:${user}" "${workspace}"
    echo "Running sync-specify-version.sh as ${user} via sudo"
    sudo -u "${user}" -H env \
      PATH="${PATH}" \
      UV_TOOL_DIR="${UV_TOOL_DIR:-/opt/uv/tools}" \
      UV_TOOL_BIN_DIR="${UV_TOOL_BIN_DIR:-/usr/local/bin}" \
      UV_PYTHON_INSTALL_DIR="${UV_PYTHON_INSTALL_DIR:-/opt/uv/python}" \
      UV_PYTHON_BIN_DIR="${UV_PYTHON_BIN_DIR:-/usr/local/bin}" \
      UV_CACHE_DIR="${UV_CACHE_DIR:-/opt/uv/cache}" \
      bash -c "cd '${workspace}' && '${sync_script}'"
  else
    echo "Cannot simulate postCreate: running as $(id -un), expected root or ${user}" >&2
    return 1
  fi
  local after
  after="$(installed_specify_version || true)"
  if [[ "${after}" != "${sync_target_version}" ]]; then
    echo "Expected specify-cli ${sync_target_version} after sync, got ${after:-<none>}" >&2
    return 1
  fi
}

check "uv" which uv
check "sync-specify-version script" test -x /usr/local/share/spec-kit/sync-specify-version.sh
check "specify" which specify
check "specify not under /root" check_specify_not_under_root
check "specify version" specify version
check "Python ${python_version} via uv" \
  uv run --python "${python_version}" python -c 'import sys; assert sys.version_info >= (3, 11)'

if [[ "${SPEC_KIT_SYNC_VERIFY_ONLY:-0}" == "1" ]]; then
  if [[ ! -f .specify/init-options.json ]]; then
    echo "SPEC_KIT_SYNC_VERIFY_ONLY set but .specify/init-options.json is missing" >&2
    exit 1
  fi
  check "postCreate sync (workspace init-options)" verify_postcreate_sync_result
else
  check "postCreate sync (simulate)" simulate_postcreate_sync
fi
