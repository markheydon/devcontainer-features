#!/usr/bin/env bash
set -euo pipefail

sync_script="/usr/local/share/aspire-cli/sync-aspire-version.sh"

aspire_user_home() {
  if id vscode >/dev/null 2>&1; then
    getent passwd vscode | cut -d: -f6
    return 0
  fi
  if id node >/dev/null 2>&1; then
    getent passwd node | cut -d: -f6
    return 0
  fi
  printf '%s' "${HOME}"
}

ASPIRE_USER_HOME="$(aspire_user_home)"
export PATH="${ASPIRE_USER_HOME}/.aspire/bin:${PATH}"
export ASPIRE_HOME="${ASPIRE_USER_HOME}/.aspire"
export ASPIRE_LAYOUT_PATH="${ASPIRE_LAYOUT_PATH:-${ASPIRE_USER_HOME}/.aspire}"

resolve_sync_target_version() {
  if [[ -n "${ASPIRE_CLI_SYNC_TARGET_VERSION:-}" ]]; then
    printf '%s' "${ASPIRE_CLI_SYNC_TARGET_VERSION}"
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
  echo "Set ASPIRE_CLI_SYNC_TARGET_VERSION or provide test/aspire-cli/sync-target-version.txt" >&2
  return 1
}

sync_target_version="$(resolve_sync_target_version)"

check() {
  local label="$1"
  shift
  echo "Checking ${label}"
  "$@"
}

normalize_aspire_version() {
  local v="$1"
  v="${v%%+*}"
  printf '%s' "${v}"
}

installed_aspire_version() {
  if ! command -v aspire >/dev/null 2>&1; then
    return 0
  fi
  aspire --version 2>/dev/null | head -n1 | awk '{print $1}'
}

read_config_sdk_version() {
  python3 -c '
import json, pathlib, sys
p = pathlib.Path("aspire.config.json")
if not p.is_file():
    sys.exit(1)
data = json.loads(p.read_text(encoding="utf-8"))
sdk = data.get("sdk") if isinstance(data, dict) else None
v = sdk.get("version") if isinstance(sdk, dict) else None
if not v:
    sys.exit(1)
print(v)
'
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
  local before user workspace aspire_bin layout home_layout
  if [[ ! -x "${sync_script}" ]]; then
    echo "Missing executable ${sync_script}" >&2
    return 1
  fi
  before="$(installed_aspire_version || true)"
  if [[ -z "${before}" ]]; then
    echo "Aspire CLI is not installed before sync test" >&2
    return 1
  fi
  if [[ "$(normalize_aspire_version "${before}")" == "$(normalize_aspire_version "${sync_target_version}")" ]]; then
    echo "Image already has Aspire CLI ${sync_target_version}; cannot test version sync." >&2
    echo "Update test/aspire-cli/sync-target-version.txt to an older installer version." >&2
    return 1
  fi
  user="$(dev_container_user)" || {
    echo "No vscode or node user in image; cannot simulate postCreate user" >&2
    return 1
  }
  workspace="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf '${workspace}'" RETURN
  printf '{"sdk": {"version": "%s"}}\n' "${sync_target_version}" >"${workspace}/aspire.config.json"

  aspire_bin="$(command -v aspire || true)"
  home_layout="${HOME}/.aspire"
  if [[ -z "${aspire_bin}" ]]; then
    aspire_bin="${HOME}/.aspire/bin/aspire"
  fi

  if [[ "$(id -un)" == "${user}" ]]; then
    echo "Running sync-aspire-version.sh as ${user} (current user)"
  (
      cd "${workspace}"
      env PATH="$(dirname "${aspire_bin}"):${PATH}" \
        ASPIRE_HOME="${HOME}/.aspire" \
        ASPIRE_LAYOUT_PATH="${home_layout}" \
        "${sync_script}"
    )
  elif [[ "$(id -u)" -eq 0 ]]; then
    if ! command -v sudo >/dev/null 2>&1; then
      echo "sudo is required to run sync as ${user} from root" >&2
      return 1
    fi
    chown -R "${user}:${user}" "${workspace}"
    user_home="$(getent passwd "${user}" | cut -d: -f6)"
    echo "Running sync-aspire-version.sh as ${user} via sudo"
    sudo -u "${user}" -H env \
      PATH="${user_home}/.aspire/bin:${PATH}" \
      ASPIRE_HOME="${user_home}/.aspire" \
      ASPIRE_LAYOUT_PATH="${user_home}/.aspire" \
      HOME="${user_home}" \
      bash -c "cd '${workspace}' && '${sync_script}'"
  else
    echo "Cannot simulate postCreate: running as $(id -un), expected root or ${user}" >&2
    return 1
  fi
  local after
  after="$(installed_aspire_version || true)"
  if [[ "$(normalize_aspire_version "${after}")" != "$(normalize_aspire_version "${sync_target_version}")" ]]; then
    echo "Expected Aspire CLI ${sync_target_version} after sync, got ${after:-<none>}" >&2
    return 1
  fi
}

verify_postcreate_sync_result() {
  local expected actual
  expected="$(read_config_sdk_version)"
  actual="$(installed_aspire_version || true)"
  if [[ "$(normalize_aspire_version "${actual}")" != "$(normalize_aspire_version "${expected}")" ]]; then
    echo "Expected Aspire CLI ${expected} (from aspire.config.json), got ${actual:-<none>}" >&2
    return 1
  fi
}

check_aspire_not_system_local() {
  if [[ -x /usr/local/bin/aspire ]]; then
    echo "Unexpected /usr/local/bin/aspire on PATH" >&2
    return 1
  fi
}

check_aspire_under_home() {
  local resolved
  resolved="$(readlink -f "$(command -v aspire)")"
  case "${resolved}" in
    */.aspire/bin/aspire) ;;
    *)
      echo "Expected aspire under a user .aspire/bin layout, got ${resolved}" >&2
      return 1
      ;;
  esac
}

aspire_cli_major_version() {
  local version
  version="$(installed_aspire_version || true)"
  if [[ -z "${version}" ]]; then
    return 1
  fi
  printf '%s' "${version%%.*}"
}

check_bundle_symlink_for_aspire_17() {
  local major bundle
  major="$(aspire_cli_major_version || true)"
  if [[ -z "${major}" ]] || [[ "${major}" -lt 17 ]]; then
    return 0
  fi
  bundle="${ASPIRE_USER_HOME}/.aspire/bundle"
  if [[ ! -L "${bundle}" ]]; then
    if [[ -d "${bundle}" ]]; then
      echo "Expected ${bundle} to be a symlink for Aspire 17+, got a directory" >&2
    else
      echo "Expected ${bundle} symlink for Aspire 17+, not found" >&2
    fi
    return 1
  fi
}

# Mirror of test/aspire-cli/fixtures/run-smoke/ (same tree on disk for review; this hook
# materialises it because feature tests are often piped into bash -c without the repo mount).
write_run_smoke_fixture() {
  local dest="$1"
  mkdir -p "${dest}/AppHost"
  cat >"${dest}/aspire.config.json" <<'JSON'
{
  "appHost": {
    "path": "AppHost/Program.cs",
    "language": "csharp"
  },
  "sdk": {
    "version": "17.0.0"
  }
}
JSON
  cat >"${dest}/AppHost/Program.cs" <<'CS'
#:package Aspire.Hosting.AppHost@17.0.0

var builder = DistributedApplication.CreateBuilder(args);
builder.Build().Run();
CS
}

check_aspire_run_bundle_smoke() {
  local major logfile fixture_dir
  major="$(aspire_cli_major_version || true)"
  if [[ -z "${major}" ]] || [[ "${major}" -lt 17 ]]; then
    return 0
  fi
  if ! command -v dotnet >/dev/null 2>&1; then
    echo "Skipping aspire run smoke: dotnet SDK not on this base image" >&2
    return 0
  fi
  fixture_dir="$(mktemp -d)"
  logfile="$(mktemp)"
  # shellcheck disable=SC2064
  trap 'rm -rf "${fixture_dir:-}" "${logfile:-}"' RETURN
  write_run_smoke_fixture "${fixture_dir}"
  local run_status=0
  set +e
  (
    cd "${fixture_dir}"
    timeout 180 env \
      PATH="${PATH}" \
      ASPIRE_HOME="${ASPIRE_HOME}" \
      ASPIRE_LAYOUT_PATH="${ASPIRE_LAYOUT_PATH}" \
      aspire run
  ) >"${logfile}" 2>&1
  run_status=$?
  set -e
  if [[ "${run_status}" -ne 0 && "${run_status}" -ne 124 ]]; then
    echo "aspire run exited with status ${run_status}:" >&2
    cat "${logfile}" >&2
    return 1
  fi
  if grep -qiE 'Bundle extraction failed|layout validation failed|Failed to rename legacy directory' "${logfile}"; then
    echo "aspire run hit a bundle layout failure:" >&2
    cat "${logfile}" >&2
    return 1
  fi
  if grep -qi 'Invalid cross-device link' "${logfile}"; then
    echo "aspire run hit bundle migration failure:" >&2
    cat "${logfile}" >&2
    return 1
  fi
  echo "aspire run passed bundle phase (log excerpt):"
  head -n 20 "${logfile}"
}

check "sync script" test -x "${sync_script}"
check "aspire on PATH" command -v aspire
check "aspire not under /usr/local/bin" check_aspire_not_system_local
check "aspire under user home" check_aspire_under_home
check "aspire --version" aspire --version
check "bundle symlink (Aspire 17+)" check_bundle_symlink_for_aspire_17

layout="${ASPIRE_LAYOUT_PATH:-${ASPIRE_USER_HOME}/.aspire}"
check "aspire setup" env ASPIRE_LAYOUT_PATH="${layout}" aspire setup --non-interactive
check "aspire run (bundle smoke)" check_aspire_run_bundle_smoke

if [[ "${ASPIRE_CLI_SYNC_VERIFY_ONLY:-0}" == "1" ]]; then
  if [[ ! -f aspire.config.json ]]; then
    echo "ASPIRE_CLI_SYNC_VERIFY_ONLY set but aspire.config.json is missing" >&2
    exit 1
  fi
  check "postCreate sync (workspace aspire.config.json)" verify_postcreate_sync_result
else
  check "postCreate sync (simulate)" simulate_postcreate_sync
fi