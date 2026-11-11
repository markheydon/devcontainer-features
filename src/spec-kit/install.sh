#!/usr/bin/env bash
set -euo pipefail

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

apt-get update
apt-get install -y --no-install-recommends ca-certificates curl
apt-get clean
rm -rf /var/lib/apt/lists/*

python3_meets_minimum() {
    command -v python3 >/dev/null 2>&1 \
        && python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)'
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
    local need_install=0

    case "${MANAGEDPYTHON}" in
        auto)
            if python3_meets_minimum; then
                echo "python3 is already 3.11 or newer; skipping uv python install."
                return 0
            fi
            need_install=1
            ;;
        always)
            need_install=1
            ;;
        never)
            if python3_meets_minimum; then
                return 0
            fi
            echo "managedPython=never but no python3 >= 3.11 found on PATH."
            echo "Add ghcr.io/devcontainers/features/python or set managedPython to auto."
            exit 1
            ;;
        *)
            echo "Invalid managedPython value: ${MANAGEDPYTHON} (use auto, always, or never)."
            exit 1
            ;;
    esac

    if [[ "${need_install}" -eq 1 ]]; then
        mkdir -p "${UV_PYTHON_INSTALL_DIR}"
        echo "Installing Python ${PYTHONVERSION} via uv..."
        uv python install "${PYTHONVERSION}"
        pin_uv_python_version_for_container_user
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
        chown -R "${_REMOTE_USER}:${_REMOTE_USER}" "${uv_config}" 2>/dev/null || true
    fi
}

fix_shared_uv_permissions() {
    mkdir -p "${UV_TOOL_DIR}" "${UV_PYTHON_INSTALL_DIR}"
    chmod -R a+rX "${UV_PREFIX}"

    if [[ -n "${_REMOTE_USER:-}" && "${_REMOTE_USER}" != "root" ]]; then
        chown -R "${_REMOTE_USER}:${_REMOTE_USER}" "${UV_PREFIX}" 2>/dev/null || true
    fi
}

install_specify() {
    mkdir -p "${UV_TOOL_DIR}"
    local package="specify-cli"
    if [[ "${SPECIFYVERSION}" == "latest" ]]; then
        echo "Installing specify-cli (latest from PyPI)..."
        uv tool install --force "${package}"
    else
        echo "Installing specify-cli==${SPECIFYVERSION}..."
        uv tool install --force "${package}==${SPECIFYVERSION}"
    fi
}

install_uv
ensure_python
install_specify
fix_shared_uv_permissions

specify version

echo "✅ Spec Kit installed."
