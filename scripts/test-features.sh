#!/usr/bin/env bash
# Install features from ./src on official base images and run test/<feature>/test.sh.
# Works in the maintainer dev container (docker-outside-of-docker), where plain
# `devcontainer features test` often fails after a successful build because the
# CLI bind-mounts /tmp paths that do not exist on the Docker host.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
IMAGES_FILE="${SCRIPT_DIR}/official-base-images.txt"

# Set TEST_FEATURES_VERBOSE=1 to print full test and CLI output per case.
VERBOSE="${TEST_FEATURES_VERBOSE:-0}"

usage() {
  cat <<EOF
Usage: $(basename "$0") [feature-id] [base-image]

Install every feature under src/ (or one feature) on each image in
scripts/official-base-images.txt (or one base image) and run test/<feature-id>/test.sh.

Examples:
  $(basename "$0")
  $(basename "$0") copilot-likes
  $(basename "$0") copilot-likes mcr.microsoft.com/devcontainers/php:latest
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if ! command -v devcontainer >/dev/null 2>&1; then
  echo "devcontainer CLI is required." >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required." >&2
  exit 1
fi

read_images() {
  grep -v '^\s*#' "${IMAGES_FILE}" | grep -v '^\s*$' || true
}

read_features() {
  find "${REPO_ROOT}/src" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort
}

resolve_features() {
  if [[ -n "${1:-}" ]]; then
    if [[ ! -d "${REPO_ROOT}/src/${1}" ]]; then
      echo "Unknown feature: ${1}" >&2
      exit 1
    fi
    echo "$1"
    return
  fi
  read_features
}

resolve_images() {
  if [[ -n "${1:-}" ]]; then
    echo "$1"
    return
  fi
  read_images
}

short_image_label() {
  local ref="$1"
  ref="${ref#mcr.microsoft.com/devcontainers/}"
  printf '%s' "${ref}"
}

# summary records: feature<TAB>image<TAB>status<TAB>note<TAB>logfile
declare -a SUMMARY_RECORDS=()

record_result() {
  local feature="$1"
  local image="$2"
  local status="$3"
  local note="$4"
  local logfile="${5:-}"
  SUMMARY_RECORDS+=("${feature}"$'\t'"${image}"$'\t'"${status}"$'\t'"${note}"$'\t'"${logfile}")
}

run_assertions() {
  local feature="$1"
  local image_ref="$2"
  local test_script="${REPO_ROOT}/test/${feature}/test.sh"
  local assert_log="${3:-}"

  if [[ ! -x "${test_script}" && ! -f "${test_script}" ]]; then
    echo "Missing test script: ${test_script}" >&2
    return 1
  fi

  local -a docker_env=()
  if [[ "${feature}" == "spec-kit" ]]; then
    docker_env=(-e "PYTHONVERSION=3.12")
  fi

  if [[ "${VERBOSE}" == "1" ]]; then
    docker run --rm "${docker_env[@]}" "${image_ref}" /bin/bash -c "$(cat "${test_script}")"
  else
    docker run --rm "${docker_env[@]}" "${image_ref}" /bin/bash -c "$(cat "${test_script}")" \
      >"${assert_log}" 2>&1
  fi
}

# Prints human-readable pass/fail line; sets RESULT_NOTE and returns 0/1.
run_combo() {
  local feature="$1"
  local base_image="$2"
  local log assert_log
  log="$(mktemp)"
  assert_log="$(mktemp)"
  trap 'rm -f "${log}" "${assert_log}"' RETURN

  local label
  label="$(short_image_label "${base_image}")"
  echo "  .. ${feature} @ ${label}"

  local -a cli_quiet=()
  if [[ "${GITHUB_ACTIONS:-}" != "true" ]]; then
    cli_quiet=(-q)
  fi

  set +e
  devcontainer features test \
    --skip-scenarios \
    --skip-duplicated \
    "${cli_quiet[@]}" \
    -f "${feature}" \
    -i "${base_image}" \
    "${REPO_ROOT}" >"${log}" 2>&1
  local cli_rc=$?
  set -e

  if [[ "${cli_rc}" -eq 0 ]]; then
    echo "  OK  ${feature} @ ${label}"
    record_result "${feature}" "${base_image}" "PASS" "devcontainer features test" ""
    return 0
  fi

  local uid_image
  uid_image="$(grep -oE 'vsc-[0-9]+-[a-f0-9]+-features-uid' "${log}" | tail -1 || true)"

  if [[ -z "${uid_image}" ]] || ! docker image inspect "${uid_image}" >/dev/null 2>&1; then
    local fail_log
    fail_log="$(mktemp "${TMPDIR:-/tmp}/feature-test-fail.XXXXXX")"
    cp "${log}" "${fail_log}"
    {
      echo "  FAIL  ${feature} @ ${label}  (install or image build)"
      if [[ "${VERBOSE}" == "1" ]]; then
        tail -n 40 "${fail_log}" >&2
      fi
    } >&2
    record_result "${feature}" "${base_image}" "FAIL" "install or image build" "${fail_log}"
    trap - RETURN
    rm -f "${log}" "${assert_log}"
    return 1
  fi

  if ! grep -q 'bind source path does not exist' "${log}"; then
    local fail_log
    fail_log="$(mktemp "${TMPDIR:-/tmp}/feature-test-fail.XXXXXX")"
    cp "${log}" "${fail_log}"
    {
      echo "  FAIL  ${feature} @ ${label}  (devcontainer features test)"
      if [[ "${VERBOSE}" == "1" ]]; then
        tail -n 40 "${fail_log}" >&2
      fi
    } >&2
    record_result "${feature}" "${base_image}" "FAIL" "devcontainer features test" "${fail_log}"
    trap - RETURN
    rm -f "${log}" "${assert_log}"
    return 1
  fi

  if run_assertions "${feature}" "${uid_image}" "${assert_log}"; then
    echo "  OK  ${feature} @ ${label}"
    record_result "${feature}" "${base_image}" "PASS" "install + test/${feature}/test.sh" ""
    return 0
  fi

  local fail_log
  fail_log="$(mktemp "${TMPDIR:-/tmp}/feature-test-fail.XXXXXX")"
  cat "${assert_log}" >"${fail_log}"
  {
    echo "  FAIL  ${feature} @ ${label}  (test/${feature}/test.sh)"
    if [[ "${VERBOSE}" == "1" ]]; then
      cat "${fail_log}" >&2
    fi
  } >&2
  record_result "${feature}" "${base_image}" "FAIL" "test/${feature}/test.sh" "${fail_log}"
  return 1
}

print_summaries() {
  local grand_pass=0 grand_fail=0

  echo ""
  echo "Feature test summary"
  echo "===================="

  for feature in "${features[@]}"; do
    local pass=0 fail=0
    local -a detail_lines=()

    for record in "${SUMMARY_RECORDS[@]}"; do
      IFS=$'\t' read -r rec_feature rec_image rec_status rec_note rec_log <<<"${record}"
      if [[ "${rec_feature}" != "${feature}" ]]; then
        continue
      fi
      local lbl
      lbl="$(short_image_label "${rec_image}")"
      if [[ "${rec_status}" == "PASS" ]]; then
        pass=$((pass + 1))
        detail_lines+=("    PASS   ${lbl}")
      else
        fail=$((fail + 1))
        detail_lines+=("    FAIL   ${lbl}  (${rec_note})")
      fi
    done

    grand_pass=$((grand_pass + pass))
    grand_fail=$((grand_fail + fail))

    echo ""
    printf '%s\n' "${feature}"
    printf '  %d passed, %d failed\n' "${pass}" "${fail}"
    if ((${#detail_lines[@]} > 0)); then
      printf '%s\n' "${detail_lines[@]}"
    fi
  done

  local grand_total=$((grand_pass + grand_fail))
  echo ""
  echo "Total"
  printf '  %d passed, %d failed (%d cases)\n' "${grand_pass}" "${grand_fail}" "${grand_total}"

  if [[ "${grand_fail}" -gt 0 ]]; then
    echo ""
    echo "Failed cases"
    for record in "${SUMMARY_RECORDS[@]}"; do
      IFS=$'\t' read -r rec_feature rec_image rec_status rec_note rec_log <<<"${record}"
      if [[ "${rec_status}" != "FAIL" ]]; then
        continue
      fi
      printf '  - %s @ %s (%s)\n' "${rec_feature}" "$(short_image_label "${rec_image}")" "${rec_note}"
      if [[ -n "${rec_log}" && -f "${rec_log}" ]]; then
        printf '    log: %s\n' "${rec_log}"
        if [[ "${VERBOSE}" != "1" ]]; then
          echo "    --- last 25 lines ---"
          tail -n 25 "${rec_log}" | sed 's/^/    /'
        fi
      fi
    done
  fi
}

FEATURE_ARG="${1:-}"
IMAGE_ARG="${2:-}"

mapfile -t features < <(resolve_features "${FEATURE_ARG}")
mapfile -t images < <(resolve_images "${IMAGE_ARG}")

echo "Running ${#features[@]} feature(s) × ${#images[@]} image(s) ..."
echo ""

set +e
for feature in "${features[@]}"; do
  for base_image in "${images[@]}"; do
    run_combo "${feature}" "${base_image}" || true
  done
done
set -e

print_summaries

failures=0
for record in "${SUMMARY_RECORDS[@]}"; do
  IFS=$'\t' read -r _ _ rec_status _ _ <<<"${record}"
  if [[ "${rec_status}" == "FAIL" ]]; then
    failures=$((failures + 1))
  fi
done

if [[ "${failures}" -gt 0 ]]; then
  exit 1
fi
