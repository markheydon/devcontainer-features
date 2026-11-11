#!/usr/bin/env bash
# Probe official dev container images for apt/Yarn/git-delta issues (see issue #4).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGES_FILE="${SCRIPT_DIR}/official-base-images.txt"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required." >&2
  exit 1
fi

read_images() {
  grep -v '^\s*#' "${IMAGES_FILE}" | grep -v '^\s*$' || true
}

probe_image() {
  local image="$1"
  echo "================================================================================"
  echo "Image: ${image}"
  echo "--------------------------------------------------------------------------------"

  docker run --rm "${image}" bash -c "$(cat <<'INNER'
set +e
. /etc/os-release 2>/dev/null
echo "OS: ${PRETTY_NAME:-unknown} (VERSION_CODENAME=${VERSION_CODENAME:-n/a}, ID=${ID:-n/a})"

if [ -f /etc/apt/sources.list.d/yarn.list ]; then
  echo "yarn.list: present"
  cat /etc/apt/sources.list.d/yarn.list
else
  echo "yarn.list: absent"
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq 2>&1 | tee /tmp/apt-update.log
apt_rc=$?
echo "apt-get update exit code: ${apt_rc}"
if [ "${apt_rc}" -ne 0 ]; then
  echo "--- apt-get update (filtered) ---"
  grep -E "yarn|NO_PUBKEY|not signed|GPG error" /tmp/apt-update.log || tail -n 20 /tmp/apt-update.log
fi

echo "--- git-delta apt policy ---"
apt-cache policy git-delta 2>/dev/null | head -n 5
INNER
)"
}

failures=0
while IFS= read -r image; do
  if ! probe_image "${image}"; then
      echo "Failed to probe ${image}" >&2
    failures=$((failures + 1))
  fi
done < <(read_images)

if [ "${failures}" -gt 0 ]; then
  echo "Probe completed with ${failures} docker failure(s)." >&2
  exit 1
fi

echo "Probe finished."
