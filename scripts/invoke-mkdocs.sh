#!/usr/bin/env bash
# Build or preview the MkDocs consumer site via Docker/Podman (no local Python/MkDocs required).
# Usage: ./scripts/invoke-mkdocs.sh [build|serve|preview] [--runtime docker|podman] [--serve-port N] [--preview-port N]

set -euo pipefail

COMMAND="build"
RUNTIME=""
SERVE_PORT=8000
PREVIEW_PORT=8080
MKDOCS_IMAGE="${MKDOCS_IMAGE:-docker.io/library/python:3.12-slim}"
NGINX_IMAGE="${NGINX_IMAGE:-docker.io/library/nginx:alpine}"

usage() {
    cat <<'EOF'
Usage: invoke-mkdocs.sh [build|serve|preview] [options]

Commands:
  build     mkdocs build --strict to site/ (default; matches CI; no browser URL)
  serve     Dev server with live reload at http://localhost:SERVE_PORT (default 8000)
  preview   Production build, then static site at http://localhost:PREVIEW_PORT (default 8080)

Options:
  --runtime RUNTIME   Container runtime: docker or podman (auto-detected if omitted)
  --serve-port PORT   Host port for serve (default: 8000)
  --preview-port PORT Host port for preview (default: 8080)
  -h, --help          Show this help

Environment:
  MKDOCS_IMAGE        Python image for build/serve (default: python:3.12-slim)
  NGINX_IMAGE         Image for preview static serve (default: nginx:alpine)

Examples:
  ./scripts/invoke-mkdocs.sh build
  ./scripts/invoke-mkdocs.sh serve
  ./scripts/invoke-mkdocs.sh preview --preview-port 9080

Viewing: use serve or preview in a browser. build only writes site/ on disk.
On WSL2, http://localhost:PORT usually works from Windows browsers as well.
EOF
}

print_view_url() {
    local port="$1"
    local mode="$2"
    echo ""
    echo "  View the site:  http://127.0.0.1:${port}/"
    echo "  (also try)      http://localhost:${port}/"
    echo ""
    echo "  Press Ctrl+C in this terminal to stop the ${mode} server."
    echo ""
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        build|serve|preview)
            COMMAND="$1"
            shift
            ;;
        --runtime)
            RUNTIME="${2:-}"
            shift 2
            ;;
        --serve-port)
            SERVE_PORT="${2:-}"
            shift 2
            ;;
        --preview-port)
            PREVIEW_PORT="${2:-}"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "error: unknown argument '$1'" >&2
            usage >&2
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SITE_OUTPUT="$REPO_ROOT/site"
REQUIREMENTS="$REPO_ROOT/docs/requirements.txt"

resolve_runtime() {
    if [[ -n "$RUNTIME" ]]; then
        if ! command -v "$RUNTIME" >/dev/null 2>&1; then
            echo "error: container runtime '$RUNTIME' not found on PATH" >&2
            exit 1
        fi
        return
    fi

    if command -v podman >/dev/null 2>&1; then
        RUNTIME="podman"
    elif command -v docker >/dev/null 2>&1; then
        RUNTIME="docker"
    else
        echo "error: no container runtime found. Install Podman or Docker, or pass --runtime." >&2
        exit 1
    fi
}

volume_mount() {
    local host_path="$1"
    local container_path="$2"
    local opts="${3:-}"

    if [[ "$RUNTIME" == "podman" ]]; then
        if [[ -n "$opts" ]]; then
            opts="${opts},Z"
        else
            opts="Z"
        fi
    fi

    if [[ -n "$opts" ]]; then
        printf '%s:%s:%s' "$host_path" "$container_path" "$opts"
    else
        printf '%s:%s' "$host_path" "$container_path"
    fi
}

ensure_repo_layout() {
    if [[ ! -f "$REQUIREMENTS" ]]; then
        echo "error: docs/requirements.txt not found at $REQUIREMENTS" >&2
        exit 1
    fi
    if [[ ! -f "$REPO_ROOT/mkdocs.yml" ]]; then
        echo "error: mkdocs.yml not found at $REPO_ROOT/mkdocs.yml" >&2
        exit 1
    fi
}

verify_container_mount() {
    if ! "$RUNTIME" run --rm \
        -v "$(volume_mount "$REPO_ROOT" /w)" \
        -w /w \
        "$MKDOCS_IMAGE" \
        test -f docs/requirements.txt; then
        echo "error: $RUNTIME cannot read docs/requirements.txt via mount of $REPO_ROOT" >&2
        cat <<'EOF' >&2
hint: Bind mounts must use a path the container runtime on the Docker host can see.
      Run this script from a normal host checkout, or install MkDocs locally:
        pip install -r docs/requirements.txt && mkdocs build --strict
      Maintainer dev containers using docker-outside-of-docker often cannot mount /workspaces.
EOF
        exit 1
    fi
}

mkdocs_build() {
    echo "Building MkDocs site (mkdocs build --strict)..."
    if ! "$RUNTIME" run --rm \
        -v "$(volume_mount "$REPO_ROOT" /w)" \
        -w /w \
        "$MKDOCS_IMAGE" \
        bash -ec 'pip install -q -r docs/requirements.txt && mkdocs build --strict'; then
        echo "error: MkDocs build failed. Fix errors above." >&2
        exit 1
    fi

    if [[ ! -f "$SITE_OUTPUT/index.html" ]]; then
        echo "error: expected $SITE_OUTPUT/index.html after build." >&2
        exit 1
    fi
}

ensure_repo_layout
resolve_runtime
verify_container_mount

case "$COMMAND" in
    build)
        mkdocs_build
        echo "Done. Static HTML: $SITE_OUTPUT"
        echo ""
        echo "  build does not start a web server. To view in a browser, run:"
        echo "    ./scripts/invoke-mkdocs.sh serve    → http://localhost:${SERVE_PORT}/ (live reload)"
        echo "    ./scripts/invoke-mkdocs.sh preview  → http://localhost:${PREVIEW_PORT}/ (nginx, like CI output)"
        echo ""
        ;;
    serve)
        echo "Starting MkDocs dev server (live reload)..."
        print_view_url "$SERVE_PORT" "dev"
        "$RUNTIME" run --rm -it -p "${SERVE_PORT}:8000" \
            -v "$(volume_mount "$REPO_ROOT" /w)" \
            -w /w \
            "$MKDOCS_IMAGE" \
            bash -ec "pip install -q -r docs/requirements.txt && mkdocs serve --dev-addr 0.0.0.0:8000"
        ;;
    preview)
        mkdocs_build
        echo "Serving static build from $SITE_OUTPUT ..."
        print_view_url "$PREVIEW_PORT" "preview"
        "$RUNTIME" run --rm -it -p "${PREVIEW_PORT}:80" \
            -v "$(volume_mount "$SITE_OUTPUT" /usr/share/nginx/html ro)" \
            "$NGINX_IMAGE"
        ;;
esac