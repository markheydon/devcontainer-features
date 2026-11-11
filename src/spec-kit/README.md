# Spec Kit

Dev Container feature that installs [GitHub Spec Kit](https://github.com/github/spec-kit)’s **Specify CLI** together with **uv** and **Python 3.11+** when the base image does not already provide a suitable interpreter.

Unlike `ghcr.io/devcontainers/features/python`, this feature installs **no** VS Code Python extensions or formatter settings—only what Spec Kit needs to run `specify` in the container.

## What gets installed

| Component | How |
|-----------|-----|
| **uv** | Pinned release tarball from [astral-sh/uv](https://github.com/astral-sh/uv) → `/usr/local/bin` |
| **Python 3.11+** | When `managedPython` is `auto` or `always` and `python3` on `PATH` is missing, older than 3.11, or lacks a working stdlib, via `uv python install` into `/opt/uv/python` (executables linked under `/usr/local/bin`) |
| **specify** | PyPI package `specify-cli` via `uv tool install`; tool environment under `/opt/uv/tools`, executable in `/usr/local/bin` (usable by the container user, not only `root`) |

`apt`: `ca-certificates`, `curl` (for downloads).

## Consumer `devcontainer.json`

**Microsoft dev container base (recommended):** images such as `mcr.microsoft.com/devcontainers/base:ubuntu` already include [common-utils](https://github.com/devcontainers/features/tree/main/src/common-utils); do not list it again.

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/markheydon/devcontainer-features/spec-kit:1": {
      "specifyVersion": "latest"
    }
  }
}
```

Pin `specifyVersion` to a PyPI release (for example `"0.0.47"`) when you need reproducible image builds instead of `latest`.

**Plain or minimal base:** when your image does not already provide common-utils, add it so `installsAfter` ordering is explicit:

```json
{
  "image": "ubuntu:24.04",
  "features": {
    "ghcr.io/devcontainers/features/common-utils:2": {},
    "ghcr.io/markheydon/devcontainer-features/spec-kit:1": {
      "specifyVersion": "latest"
    }
  }
}
```

**With the official Python feature** (VS Code Python tooling + Spec Kit), on the Microsoft base:

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/devcontainers/features/python:1": {
      "version": "3.12"
    },
    "ghcr.io/markheydon/devcontainer-features/spec-kit:1": {
      "specifyVersion": "latest",
      "managedPython": "auto"
    }
  }
}
```

With `managedPython: auto`, a 3.11+ `python3` with a working stdlib from the Python feature skips a second interpreter install.

Metadata sets `installsAfter` [common-utils](https://github.com/devcontainers/features/tree/main/src/common-utils) so common-utils runs before this feature when both are in the `features` block. The Dev Containers CLI treats that as a **soft dependency**: if common-utils is not listed, install order still resolves and this feature installs on its own. On pre-built Microsoft bases you can omit common-utils; see the root [README.md](../../README.md#using-a-feature).

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `specifyVersion` | `latest` | PyPI version of `specify-cli`, or `latest` to upgrade on each image build (`uv tool install --force`). |
| `uvVersion` | `0.13.7` | uv GitHub release tag (no leading `v`). |
| `managedPython` | `auto` | `auto` skips managed Python when `python3` is 3.11+ with a working stdlib; `always` \| `never` — see install script behaviour above. |
| `pythonVersion` | `3.12` | Version passed to `uv python install` when managed Python runs. |

## Container environment

Feature metadata sets these variables so uv keeps tools, interpreters, and caches under `/opt/uv` while exposing binaries on `PATH` via `/usr/local/bin`:

| Variable | Value |
|----------|-------|
| `UV_TOOL_DIR` | `/opt/uv/tools` |
| `UV_TOOL_BIN_DIR` | `/usr/local/bin` |
| `UV_PYTHON_INSTALL_DIR` | `/opt/uv/python` |
| `UV_PYTHON_BIN_DIR` | `/usr/local/bin` |
| `UV_CACHE_DIR` | `/opt/uv/cache` |

When managed Python runs and the Dev Containers lifecycle provides `_REMOTE_USER_HOME`, the install script writes `${_REMOTE_USER_HOME}/.config/uv/.python-version` so the container user’s uv commands prefer the pinned interpreter.

## After the container builds

This feature does **not** run `specify init` or read `.specify/init-options.json`. Initialise or upgrade projects yourself, for example:

```bash
specify init my-project --integration copilot
# or in an existing repo:
specify init --here --force --non-interactive --integration copilot
```

See the [Spec Kit installation guide](https://github.github.io/spec-kit/installation.html).

**Migrating from a custom install script:** replace repo `speckit_version` in `init-options.json` with `specifyVersion` in `devcontainer.json`, or keep `latest`.

## Caveats

- Intended for Debian-family images with `apt` (CI uses `mcr.microsoft.com/devcontainers/base:ubuntu`).
- `specifyVersion: latest` rebuilds may pick up a newer CLI; pin semver for reproducibility.
- Do **not** combine with `ghcr.io/devcontainers-extra/features/uv`; this feature already installs uv.
- Air-gapped environments: pin `specifyVersion` and `uvVersion`, or follow [Spec Kit air-gapped guidance](https://github.github.io/spec-kit/install/air-gapped.html).
- `/opt/uv` is world-writable (`chmod a+rwX`) so a single dev user can share uv caches and tools; avoid combining with unrelated Unix accounts in one container if you need strict filesystem isolation.
- Supported uv tarball architectures: `x86_64`, `aarch64`, `armv7l`. On `armv7l`, `specify-cli` still installs from PyPI wheels and may fail if no wheel exists for that platform.

## Development in this repository

Unpublished installs use a repo-relative path:

```json
"features": {
  "../src/spec-kit": {}
}
```

See the root [CONTRIBUTING.md](../../CONTRIBUTING.md) for ShellCheck, `./scripts/test-features.sh`, and versioning rules.
