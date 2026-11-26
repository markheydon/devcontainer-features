#!/usr/bin/env bash
set -euo pipefail

ASPIRE_CLI_SHARE="/usr/local/share/aspire-cli"
SYNC_ASPIRE_VERSION_SCRIPT="${ASPIRE_CLI_SHARE}/sync-aspire-version.sh"
INSTALLER_URL="https://aspire.dev/install.sh"
PROFILE_SNIPPET_MARKER="# aspire-cli devcontainer feature"

echo "📦 Installing Aspire CLI..."

export DEBIAN_FRONTEND=noninteractive

ASPIRE_CLI_VERSION="${ASPIREVERSION:-latest}"
QUALITY="${QUALITY:-release}"
BUNDLEPATH="${BUNDLEPATH:-}"
RUNSETUPONINSTALL="${RUNSETUPONINSTALL:-true}"

apt-get update
apt-get install -y --no-install-recommends ca-certificates curl python3-minimal
apt-get clean
rm -rf /var/lib/apt/lists/*

ensure_arch() {
    local arch
    arch="$(uname -m)"
    case "${arch}" in
        x86_64 | aarch64 | arm64) ;;
        *)
            echo "Unsupported architecture for Aspire CLI: ${arch}" >&2
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

remote_user_home() {
    if [[ -n "${_REMOTE_USER_HOME:-}" ]]; then
        printf '%s' "${_REMOTE_USER_HOME}"
        return 0
    fi
    local user
    if user="$(container_user_name)"; then
        getent passwd "${user}" | cut -d: -f6
        return 0
    fi
    printf '%s' "/root"
}

run_as_user() {
    local user="$1"
    shift
    if [[ "${user}" == "root" ]] || [[ "$(id -un)" == "${user}" ]]; then
        "$@"
        return $?
    fi
    if command -v runuser >/dev/null 2>&1; then
        runuser -u "${user}" -- "$@"
        return $?
    fi
    if command -v su >/dev/null 2>&1; then
        su -s /bin/bash "${user}" -c "$(printf '%q ' "$@")"
        return $?
    fi
    echo "Cannot run commands as ${user}: need runuser or su." >&2
    return 1
}

resolve_layout_path() {
    local home="$1"
    if [[ -n "${BUNDLEPATH}" ]]; then
        printf '%s' "${BUNDLEPATH}"
        return 0
    fi
    printf '%s' "${home}/.aspire"
}

clear_legacy_bundle_directory() {
    local home="$1"
    local bundle="${home}/.aspire/bundle"
    local versions="${home}/.aspire/versions"
    if [[ -e "${bundle}" && ! -L "${bundle}" && -d "${bundle}" ]]; then
        if [[ -d "${versions}" ]] && compgen -G "${versions}/*" >/dev/null; then
            rm -rf "${bundle}"
            return 0
        fi
        if [[ -z "$(ls -A "${bundle}" 2>/dev/null || true)" ]]; then
            rm -rf "${bundle}"
        fi
    fi
}

normalize_aspire_version() {
    local v="$1"
    v="${v%%+*}"
    printf '%s' "${v}"
}

fetch_installer() {
    local dest="$1"
    curl -fsSL "${INSTALLER_URL}" -o "${dest}"
    chmod 755 "${dest}"
}

installed_cli_version() {
    local aspire_bin="$1"
    if [[ ! -x "${aspire_bin}" ]]; then
        return 0
    fi
    "${aspire_bin}" --version 2>/dev/null | head -n1 | awk '{print $1}'
}

remove_stale_system_aspire() {
    if [[ -e /usr/local/bin/aspire ]]; then
        rm -f /usr/local/bin/aspire
        echo "Removed stale /usr/local/bin/aspire."
    fi
}

install_cli_for_user() {
    local user="$1"
    local home="$2"
    local install_dir="${home}/.aspire/bin"
    local aspire_bin="${install_dir}/aspire"
    local installer
    installer="$(mktemp /tmp/aspire-cli-installer.XXXXXX)"

    mkdir -p "${install_dir}"
    if [[ "${user}" != "root" ]]; then
        chown -R "${user}:${user}" "${home}/.aspire"
    fi

    if [[ "${ASPIRE_CLI_VERSION}" != "latest" ]]; then
        if [[ "${QUALITY}" != "release" ]]; then
            echo "aspire-cli: cannot set quality when aspireVersion is pinned. Use aspireVersion: latest or quality: release." >&2
            exit 1
        fi
        local current
        current="$(installed_cli_version "${aspire_bin}")"
        if [[ -n "${current}" ]] \
            && [[ "$(normalize_aspire_version "${current}")" == "$(normalize_aspire_version "${ASPIRE_CLI_VERSION}")" ]]; then
            echo "Aspire CLI ${ASPIRE_CLI_VERSION} already installed for ${user}."
            rm -f "${installer}"
            return 0
        fi
    fi

    fetch_installer "${installer}"

    if [[ "${ASPIRE_CLI_VERSION}" == "latest" ]]; then
        run_as_user "${user}" env HOME="${home}" bash "${installer}" --skip-path -i "${install_dir}" -q "${QUALITY}"
    else
        run_as_user "${user}" env HOME="${home}" bash "${installer}" --skip-path -i "${install_dir}" --version "${ASPIRE_CLI_VERSION}"
    fi

    rm -f "${installer}"

    if [[ "${user}" != "root" ]]; then
        chown -R "${user}:${user}" "${home}/.aspire"
    fi

    if [[ -x "${aspire_bin}" ]]; then
        run_as_user "${user}" env HOME="${home}" "${aspire_bin}" --version
    else
        echo "Aspire CLI install failed: ${aspire_bin} not found." >&2
        exit 1
    fi
}

run_setup_for_user() {
    local user="$1"
    local home="$2"
    local layout
    layout="$(resolve_layout_path "${home}")"
    local aspire_bin="${home}/.aspire/bin/aspire"

    mkdir -p "${layout}"
    if [[ "${user}" != "root" ]]; then
        chown -R "${user}:${user}" "${home}/.aspire" 2>/dev/null || true
    fi

    case "${RUNSETUPONINSTALL}" in
        true | 1 | yes) ;;
        *)
            return 0
            ;;
    esac

    if [[ ! -x "${aspire_bin}" ]]; then
        echo "Skipping aspire setup: CLI not installed." >&2
        return 0
    fi

    clear_legacy_bundle_directory "${home}"

    run_as_user "${user}" env \
        HOME="${home}" \
        PATH="${home}/.aspire/bin:${PATH}" \
        ASPIRE_HOME="${home}/.aspire" \
        ASPIRE_LAYOUT_PATH="${layout}" \
        "${aspire_bin}" setup --non-interactive
}

write_system_profile() {
    tee /etc/profile.d/aspire-cli.sh >/dev/null <<'EOF'
# aspire-cli devcontainer feature
if [ -n "${HOME:-}" ] && [ -d "${HOME}/.aspire/bin" ]; then
  export ASPIRE_HOME="${HOME}/.aspire"
  if [ -z "${ASPIRE_LAYOUT_PATH:-}" ] || [ "${ASPIRE_LAYOUT_PATH}" = "${HOME}/.aspire/bundle" ]; then
    export ASPIRE_LAYOUT_PATH="${HOME}/.aspire"
  fi
  export PATH="${HOME}/.aspire/bin:${PATH}"
fi
EOF
    chmod 644 /etc/profile.d/aspire-cli.sh
}

remove_old_aspire_cli_snippet() {
    local rc="$1"
    local tmp
    tmp="$(mktemp)"
    awk -v marker="${PROFILE_SNIPPET_MARKER}" '
        $0 == marker { inblock=1; next }
        inblock && /^export ASPIRE_HOME=/ { next }
        inblock && /^export ASPIRE_LAYOUT_PATH=/ { next }
        inblock && /^export PATH=.*\.aspire\/bin:/ { inblock=0; next }
        inblock { next }
        { print }
    ' "${rc}" >"${tmp}"
    mv "${tmp}" "${rc}"
}

append_user_shell_snippet() {
    local home="$1"
    local layout="$2"
    local snippet
    snippet="${PROFILE_SNIPPET_MARKER}
export ASPIRE_HOME=\"\${HOME}/.aspire\"
export ASPIRE_LAYOUT_PATH=\"${layout}\"
export PATH=\"\${HOME}/.aspire/bin:\${PATH}\""

    for rc in "${home}/.bashrc" "${home}/.profile"; do
        if [[ ! -f "${rc}" ]]; then
            touch "${rc}"
        fi
        if grep -Fq "${PROFILE_SNIPPET_MARKER}" "${rc}"; then
            remove_old_aspire_cli_snippet "${rc}"
        fi
        printf '\n%s\n' "${snippet}" >>"${rc}"
    done
}

write_sync_aspire_version_script() {
    mkdir -p "${ASPIRE_CLI_SHARE}"

    tee "${SYNC_ASPIRE_VERSION_SCRIPT}" >/dev/null <<EOF
#!/usr/bin/env bash
set -euo pipefail

ASPIRE_IMAGE_VERSION="${ASPIRE_CLI_VERSION}"
QUALITY="${QUALITY}"
RUNSETUPONINSTALL="${RUNSETUPONINSTALL}"
BUNDLEPATH="${BUNDLEPATH}"
INSTALLER_URL="${INSTALLER_URL}"
EOF

    tee -a "${SYNC_ASPIRE_VERSION_SCRIPT}" >/dev/null <<'EOF'

resolve_layout_path() {
    if [[ -n "${BUNDLEPATH}" ]]; then
        printf '%s' "${BUNDLEPATH}"
        return 0
    fi
    printf '%s' "${HOME}/.aspire"
}

clear_legacy_bundle_directory() {
    local bundle="${HOME}/.aspire/bundle"
    local versions="${HOME}/.aspire/versions"
    if [[ -e "${bundle}" && ! -L "${bundle}" && -d "${bundle}" ]]; then
        if [[ -d "${versions}" ]] && compgen -G "${versions}/*" >/dev/null; then
            rm -rf "${bundle}"
            return 0
        fi
        if [[ -z "$(ls -A "${bundle}" 2>/dev/null || true)" ]]; then
            rm -rf "${bundle}"
        fi
    fi
}

resolve_effective_layout_path() {
    local layout
    layout="$(resolve_layout_path)"
    if [[ -n "${BUNDLEPATH}" ]]; then
        printf '%s' "${layout}"
        return 0
    fi
    if [[ -n "${ASPIRE_LAYOUT_PATH:-}" ]] \
        && [[ "${ASPIRE_LAYOUT_PATH}" != "${HOME}/.aspire/bundle" ]]; then
        layout="${ASPIRE_LAYOUT_PATH}"
    fi
    printf '%s' "${layout}"
}

normalize_aspire_version() {
    local v="$1"
    v="${v%%+*}"
    printf '%s' "${v}"
}

installed_cli_version() {
    local aspire_bin="${HOME}/.aspire/bin/aspire"
    if [[ ! -x "${aspire_bin}" ]]; then
        return 0
    fi
    "${aspire_bin}" --version 2>/dev/null | head -n1 | awk '{print $1}'
}

fetch_installer() {
    local dest="$1"
    curl -fsSL "${INSTALLER_URL}" -o "${dest}"
    chmod 755 "${dest}"
}

read_repo_aspire_version() {
    if ! command -v python3 >/dev/null 2>&1; then
        echo "sync-aspire-version: python3 is required to read repo Aspire SDK pins." >&2
        return 1
    fi
    python3 - <<'PY'
import json, pathlib, re, sys

SKIP_DIRS = {".git", "bin", "obj", "node_modules"}
MAX_DEPTH = 8
versions = set()

def norm(v):
    return v.split("+", 1)[0].strip()

def add(v):
    if v:
        versions.add(norm(v))

def scan_file(path: pathlib.Path) -> None:
    name = path.name.lower()
    if name == "aspire.config.json":
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            return
        if isinstance(data, dict):
            sdk = data.get("sdk")
            if isinstance(sdk, dict) and sdk.get("version"):
                add(str(sdk["version"]))
        return
    if not name.endswith((".cs", ".csproj", ".props", ".targets")):
        return
    try:
        text = path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return
    for match in re.finditer(r"#:package\s+Aspire\.Hosting\.AppHost@([^\s\"']+)", text):
        add(match.group(1))
    for match in re.finditer(r"#:sdk\s+Aspire\.AppHost\.Sdk@([^\s\"']+)", text):
        add(match.group(1))
    for match in re.finditer(r'Sdk="Aspire\.AppHost\.Sdk/([^"]+)"', text):
        add(match.group(1))
    for match in re.finditer(r'<Sdk\s+Name="Aspire\.AppHost\.Sdk"\s+Version="([^"]+)"', text):
        add(match.group(1))
    for match in re.finditer(
        r'<PackageReference\s+Include="Aspire\.Hosting\.AppHost"\s+Version="([^"]+)"', text
    ):
        add(match.group(1))

def walk(root: pathlib.Path, depth: int = 0) -> None:
    if depth > MAX_DEPTH:
        return
    try:
        entries = list(root.iterdir())
    except OSError:
        return
    for entry in entries:
        if entry.is_dir():
            if entry.name in SKIP_DIRS:
                continue
            walk(entry, depth + 1)
        elif entry.is_file():
            scan_file(entry)

walk(pathlib.Path("."))

if not versions:
    sys.exit(0)
if len(versions) > 1:
    print(
        "sync-aspire-version: multiple Aspire SDK versions found: " + ", ".join(sorted(versions)),
        file=sys.stderr,
    )
    sys.exit(2)
print(next(iter(versions)))
PY
}

run_setup_if_enabled() {
    local layout
    layout="$(resolve_effective_layout_path)"
    local aspire_bin="${HOME}/.aspire/bin/aspire"
    case "${RUNSETUPONINSTALL}" in
        true | 1 | yes) ;;
        *) return 0 ;;
    esac
    mkdir -p "${layout}"
    if [[ ! -x "${aspire_bin}" ]]; then
        return 0
    fi
    clear_legacy_bundle_directory
    env PATH="${HOME}/.aspire/bin:${PATH}" ASPIRE_HOME="${HOME}/.aspire" ASPIRE_LAYOUT_PATH="${layout}" \
        "${aspire_bin}" setup --non-interactive
}

reinstall_cli_version() {
    local target_version="$1"
    local install_dir="${HOME}/.aspire/bin"
    local installer
    installer="$(mktemp /tmp/aspire-cli-installer.XXXXXX)"
    fetch_installer "${installer}"
    bash "${installer}" --skip-path -i "${install_dir}" --version "${target_version}"
    rm -f "${installer}"
    run_setup_if_enabled
}

if [[ "${ASPIRE_IMAGE_VERSION}" != "latest" ]]; then
    exit 0
fi

repo_version=""
if ! repo_version="$(read_repo_aspire_version)"; then
    echo "sync-aspire-version: could not determine a single Aspire SDK version from the workspace." >&2
    exit 1
fi
if [[ -z "${repo_version}" ]]; then
    exit 0
fi

current_version="$(installed_cli_version || true)"
if [[ "$(normalize_aspire_version "${current_version}")" == "$(normalize_aspire_version "${repo_version}")" ]]; then
    exit 0
fi

echo "Syncing Aspire CLI to repo version ${repo_version} (image build had ${current_version:-unknown})..."
reinstall_cli_version "${repo_version}"
EOF

    chmod 755 "${SYNC_ASPIRE_VERSION_SCRIPT}"
}

ensure_arch
remove_stale_system_aspire
write_system_profile

target_user="root"
user_home="/root"
if user="$(container_user_name)"; then
    target_user="${user}"
    user_home="$(remote_user_home)"
fi

layout_path="$(resolve_layout_path "${user_home}")"
install_cli_for_user "${target_user}" "${user_home}"
run_setup_for_user "${target_user}" "${user_home}"
append_user_shell_snippet "${user_home}" "${layout_path}"

if [[ "${target_user}" != "root" ]]; then
    chown "${target_user}:${target_user}" "${user_home}/.bashrc" "${user_home}/.profile" 2>/dev/null || true
fi

write_sync_aspire_version_script

echo "✅ Aspire CLI installed."