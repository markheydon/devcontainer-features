#!/usr/bin/env bash
set -euo pipefail

SPEC_KIT_SHARE="/usr/local/share/spec-kit"
SYNC_SPECIFY_VERSION_SCRIPT="${SPEC_KIT_SHARE}/sync-specify-version.sh"

echo "📦 Installing Spec Kit (uv, Python when needed, specify-cli)..."

export DEBIAN_FRONTEND=noninteractive

SPECIFYVERSION="${SPECIFYVERSION:-latest}"
UVVERSION="${UVVERSION:-0.13.7}"
MANAGEDPYTHON="${MANAGEDPYTHON:-auto}"
PYTHONVERSION="${PYTHONVERSION:-3.12}"

UV_PREFIX="/opt/uv"
export UV_TOOL_DIR="${UV_PREFIX}/tools"
export UV_TOOL_BIN_DIR="/usr/local/bin"
export UV_PYTHON_INSTALL_DIR="${UV_PREFIX}/python"
export UV_PYTHON_BIN_DIR="/usr/local/bin"
export UV_CACHE_DIR="${UV_PREFIX}/cache"

apt-get update
apt-get install -y --no-install-recommends ca-certificates curl
apt-get clean
rm -rf /var/lib/apt/lists/*

python3_is_healthy() {
    command -v python3 >/dev/null 2>&1 \
        && python3 -c 'import json, shutil, sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)'
}

managed_python_requested() {
    case "${MANAGEDPYTHON}" in
        always) return 0 ;;
        never) return 1 ;;
        auto)
            if python3_is_healthy; then
                return 1
            fi
            return 0
            ;;
        *)
            echo "Invalid managedPython value: ${MANAGEDPYTHON} (use auto, always, or never)."
            exit 1
            ;;
    esac
}

container_user_name() {
    if [[ -n "${_REMOTE_USER:-}" && "${_REMOTE_USER}" != "root" ]]; then
        printf '%s' "${_REMOTE_USER}"
        return 0
    fi
    if id -u vscode >/dev/null 2>&1; then
        printf '%s' "vscode"
        return 0
    fi
    return 1
}

install_uv() {
    if command -v uv >/dev/null 2>&1; then
        installed_uv_version="$(uv --version 2>/dev/null | awk 'NR==1 { print $2 }')"
        if [[ "${installed_uv_version}" == "${UVVERSION}" ]]; then
            echo "uv ${UVVERSION} already installed."
            return 0
        fi
        echo "Replacing uv with pinned version ${UVVERSION}..."
    fi

    ARCH="$(uname -m)"
    case "${ARCH}" in
        x86_64)
            UV_ARCH="x86_64-unknown-linux-gnu"
            ;;
        aarch64 | arm64)
            UV_ARCH="aarch64-unknown-linux-gnu"
            ;;
        armv7l)
            UV_ARCH="armv7-unknown-linux-gnueabihf"
            ;;
        *)
            echo "Unsupported architecture for uv: ${ARCH}"
            exit 1
            ;;
    esac

    UV_ASSET="uv-${UV_ARCH}.tar.gz"
    UV_BASE_URL="https://github.com/astral-sh/uv/releases/download/${UVVERSION}"
    mkdir -p /tmp/uv-install
    cd /tmp/uv-install

    curl -fsSL "${UV_BASE_URL}/${UV_ASSET}.sha256" -o "${UV_ASSET}.sha256"
    curl -fsSL "${UV_BASE_URL}/${UV_ASSET}" -o "${UV_ASSET}"
    sha256sum -c "${UV_ASSET}.sha256"

    tar -xzf "${UV_ASSET}"
    install -m 755 "./uv-${UV_ARCH}/uv" /usr/local/bin/uv
    if [[ -f "./uv-${UV_ARCH}/uvx" ]]; then
        install -m 755 "./uv-${UV_ARCH}/uvx" /usr/local/bin/uvx
    fi

    cd /
    rm -rf /tmp/uv-install
    uv --version
}

ensure_python() {
    if [[ "${MANAGEDPYTHON}" == "never" ]]; then
        if python3_is_healthy; then
            return 0
        fi
        echo "managedPython=never but no usable python3 >= 3.11 found on PATH."
        echo "Add ghcr.io/devcontainers/features/python or set managedPython to auto."
        exit 1
    fi

    if ! managed_python_requested; then
        echo "python3 is already 3.11+ with a working stdlib; skipping uv python install."
        return 0
    fi

    mkdir -p "${UV_PYTHON_INSTALL_DIR}"
    echo "Installing Python ${PYTHONVERSION} via uv..."
    uv python install "${PYTHONVERSION}"
    pin_uv_python_version_for_container_user
}

tool_install_python_args() {
    if managed_python_requested; then
        echo --python
        echo "${PYTHONVERSION}"
        return 0
    fi
    if ! python3_is_healthy; then
        echo "System python3 is not usable for uv tool install; install managed Python first." >&2
        exit 1
    fi
}

pin_uv_python_version_for_container_user() {
    if [[ -z "${_REMOTE_USER_HOME:-}" ]]; then
        return 0
    fi
    local uv_config="${_REMOTE_USER_HOME}/.config/uv"
    mkdir -p "${uv_config}"
    echo "${PYTHONVERSION}" >"${uv_config}/.python-version"
    if [[ -n "${_REMOTE_USER:-}" && "${_REMOTE_USER}" != "root" ]]; then
        if ! chown -R "${_REMOTE_USER}:${_REMOTE_USER}" "${uv_config}"; then
            echo "Warning: could not chown ${uv_config} to ${_REMOTE_USER}." >&2
        fi
    fi
}

fix_shared_uv_permissions() {
    mkdir -p "${UV_TOOL_DIR}" "${UV_PYTHON_INSTALL_DIR}" "${UV_CACHE_DIR}"
    local user
    if user="$(container_user_name)"; then
        if ! chown -R "${user}:${user}" "${UV_PREFIX}"; then
            echo "Warning: could not chown ${UV_PREFIX} to ${user}; relying on group-writable permissions." >&2
        fi
    fi
    chmod -R a+rwX "${UV_PREFIX}"
}

install_specify_cli() {
    local version="$1"
    mkdir -p "${UV_TOOL_DIR}"
    local package="specify-cli"
    local -a python_args=()
    mapfile -t python_args < <(tool_install_python_args)

    if [[ "${version}" == "latest" ]]; then
        echo "Installing specify-cli (latest from PyPI)..."
        uv tool install --force "${python_args[@]}" "${package}"
        return 0
    fi

    echo "Installing specify-cli==${version}..."
    uv tool install --force "${python_args[@]}" "${package}==${version}"
}

install_specify() {
    install_specify_cli "${SPECIFYVERSION}"
}

write_sync_specify_version_script() {
    mkdir -p "${SPEC_KIT_SHARE}"

    tee "${SYNC_SPECIFY_VERSION_SCRIPT}" > /dev/null <<EOF
#!/usr/bin/env bash
set -euo pipefail

SPECIFYVERSION="${SPECIFYVERSION}"
PYTHONVERSION="${PYTHONVERSION}"
MANAGEDPYTHON="${MANAGEDPYTHON}"

export UV_TOOL_DIR="${UV_TOOL_DIR}"
export UV_TOOL_BIN_DIR="${UV_TOOL_BIN_DIR}"
export UV_PYTHON_INSTALL_DIR="${UV_PYTHON_INSTALL_DIR}"
export UV_PYTHON_BIN_DIR="${UV_PYTHON_BIN_DIR}"
export UV_CACHE_DIR="${UV_CACHE_DIR}"
EOF

    tee -a "${SYNC_SPECIFY_VERSION_SCRIPT}" > /dev/null <<'EOF'
json_python_cmd() {
    if command -v uv >/dev/null 2>&1; then
        printf '%s' "uv run --python ${PYTHONVERSION} python"
        return 0
    fi
    if command -v python3 >/dev/null 2>&1 \
        && python3 -c 'import json, pathlib, sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)' 2>/dev/null; then
        printf '%s' 'python3'
        return 0
    fi
    return 1
}

python3_is_healthy() {
    command -v python3 >/dev/null 2>&1 \
        && python3 -c 'import json, shutil, sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)'
}

sync_tool_python_args() {
    case "${MANAGEDPYTHON}" in
        always)
            printf '%s\n' --python "${PYTHONVERSION}"
            ;;
        never)
            ;;
        auto)
            if ! python3_is_healthy; then
                printf '%s\n' --python "${PYTHONVERSION}"
            fi
            ;;
    esac
}

read_repo_speckit_version() {
    local py_cmd
    py_cmd="$(json_python_cmd)" || return 0
    # shellcheck disable=SC2086
    ${py_cmd} -c 'import json, pathlib, sys
path = pathlib.Path(".specify/init-options.json")
if not path.is_file():
    sys.exit(0)
try:
    data = json.loads(path.read_text(encoding="utf-8"))
except (json.JSONDecodeError, OSError):
    sys.exit(0)
if isinstance(data, dict):
    version = data.get("speckit_version")
    if version:
        print(str(version))' \
        || return 0
}

installed_specify_version() {
    if ! command -v uv >/dev/null 2>&1; then
        return 0
    fi
    uv tool list 2>/dev/null | awk '/^specify-cli / { sub(/^v/, "", $2); print $2; exit }'
}

if [[ "${SPECIFYVERSION}" != "latest" ]]; then
    exit 0
fi

repo_version="$(read_repo_speckit_version || true)"
current_version="$(installed_specify_version || true)"

if [[ -z "${repo_version}" ]]; then
    exit 0
fi

if [[ "${current_version}" == "${repo_version}" ]]; then
    exit 0
fi

echo "Syncing specify-cli to repo version ${repo_version} (image build had ${current_version:-unknown})..."
python_args=()
mapfile -t python_args < <(sync_tool_python_args)

uv tool install --force "${python_args[@]}" "specify-cli==${repo_version}"
EOF

    chmod 755 "${SYNC_SPECIFY_VERSION_SCRIPT}"
}

install_uv
ensure_python
fix_shared_uv_permissions
write_sync_specify_version_script
install_specify

specify version
fix_shared_uv_permissions

echo "✅ Spec Kit installed."
