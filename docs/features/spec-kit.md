# Spec Kit

Installs [GitHub Spec Kit](https://github.com/github/spec-kit)’s **Specify CLI** with **uv** and **Python 3.11+** when the base image does not already provide a suitable interpreter.

Unlike `ghcr.io/devcontainers/features/python`, this feature does **not** install VS Code Python extensions—only what Spec Kit needs to run `specify`.

**GHCR:** `ghcr.io/markheydon/devcontainer-features/spec-kit:1`

## What gets installed

| Component | How |
|-----------|-----|
| **uv** | Pinned release tarball from [astral-sh/uv](https://github.com/astral-sh/uv) → `/usr/local/bin` |
| **Python 3.11+** | When `managedPython` is `auto` or `always` and `python3` on `PATH` is missing, older than 3.11, or lacks a working stdlib, via `uv python install` into `/opt/uv/python` (executables linked under `/usr/local/bin`) |
| **specify** | PyPI package `specify-cli` via `uv tool install`; tool environment under `/opt/uv/tools`, executable in `/usr/local/bin` (usable by the container user, not only `root`) |

`apt`: `ca-certificates`, `curl` (for downloads).

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `specifyVersion` | `latest` | PyPI version of `specify-cli`, or `latest` to take the current PyPI release at image build and then match `speckit_version` from `.specify/init-options.json` on container create when present. |
| `uvVersion` | `0.13.7` | uv GitHub release tag (no leading `v`). |
| `managedPython` | `auto` | `auto` skips managed Python when `python3` is 3.11+ with a working stdlib; `always` \| `never` — see install behaviour above. |
| `pythonVersion` | `3.12` | Version passed to `uv python install` when managed Python runs. |

## Example `devcontainer.json`

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

Metadata sets `installsAfter` [common-utils](https://github.com/devcontainers/features/tree/main/src/common-utils) so common-utils runs before this feature when both are in the `features` block. The Dev Containers CLI treats that as a **soft dependency**: if common-utils is not listed, install order still resolves and this feature installs on its own. On pre-built Microsoft bases you can omit common-utils; see [Getting started](../guides/getting-started.md).

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

This feature does **not** run `specify init`. With `specifyVersion: latest` (the default), a `postCreateCommand` runs `/usr/local/share/spec-kit/sync-specify-version.sh`. When `.specify/init-options.json` defines `speckit_version` and the installed CLI differs, the script reinstalls `specify-cli` at that version so the container matches the repo. Sync only runs when `specifyVersion` was `latest` at image build. The script is generated at install time with your `managedPython` and `pythonVersion` options, so create-time reinstall uses the same Python selection rules as the initial install. Initialise or upgrade projects yourself, for example:

```bash
specify init my-project --integration copilot
# or in an existing repo:
specify init --here --force --non-interactive --integration copilot
```

See the [Spec Kit installation guide](https://github.github.io/spec-kit/installation.html).

**Migrating from a custom install script:** replace repo `speckit_version` in `init-options.json` with `specifyVersion` in `devcontainer.json`, or keep `latest`.

## Base image expectations

- **Debian-family** images with `apt` (CI uses `mcr.microsoft.com/devcontainers/base:ubuntu`).
- **Microsoft .NET images** (`mcr.microsoft.com/devcontainers/dotnet:*`) often ship `python3-minimal` only. That interpreter can be 3.11+ but lacks stdlib modules `specify-cli` needs (for example `uuid`). With default `managedPython: auto`, the feature detects this via a stdlib probe and runs `uv python install` instead of using system `python3`.
- **Non-root create:** `postCreateCommand` runs version sync as the container user. Reinstalling `specify-cli` under `/opt/uv` uses **passwordless `sudo`** when the user is not root. Official Microsoft dev container images (and `common-utils`) typically provide this; plain minimal images may need `common-utils` or equivalent sudo configuration.
- **`installsAfter` `common-utils`:** metadata only orders features when both are present; on plain bases, add `ghcr.io/devcontainers/features/common-utils` explicitly (see examples above).

## Caveats

- `specifyVersion: latest` takes the current PyPI release at image build; when `.specify/init-options.json` exists, container create may reinstall `speckit_version` from that file. Pin semver for fully reproducible images.
- Do **not** combine with `ghcr.io/devcontainers-extra/features/uv`; this feature already installs uv.
- Air-gapped environments: pin `specifyVersion` and `uvVersion` so create-time sync is skipped, or follow [Spec Kit air-gapped guidance](https://github.github.io/spec-kit/install/air-gapped.html). Default `latest` with an existing `.specify/init-options.json` still fetches from PyPI on first create unless you pin.
- `/opt/uv` is world-writable (`chmod a+rwX`) so a single dev user can share uv caches and tools; avoid combining with unrelated Unix accounts in one container if you need strict filesystem isolation.
- Create-time version sync reinstalls `specify-cli` under `/opt/uv` using `sudo` when the dev container runs `postCreateCommand` as a non-root user (typical on Microsoft bases and Aspire images).
- Supported uv tarball architectures: `x86_64`, `aarch64`, `armv7l`. On `armv7l`, `specify-cli` still installs from PyPI wheels and may fail if no wheel exists for that platform.

## Common-utils

On Microsoft dev container bases, omit common-utils. On plain Ubuntu images, add `ghcr.io/devcontainers/features/common-utils:2` before spec-kit. See [Common-utils dependency](../guides/common-utils.md).

## Source and contributing

- [Source on GitHub](https://github.com/markheydon/devcontainer-features/tree/main/src/spec-kit)
- [Report an issue](https://github.com/markheydon/devcontainer-features/issues)
- [Contributing](../contributing.md)