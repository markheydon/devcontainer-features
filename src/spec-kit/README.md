# Spec Kit

Dev Container feature that installs [GitHub Spec Kit](https://github.com/github/spec-kit)’s **Specify CLI** together with **uv** and **Python 3.11+** when the base image does not already provide a suitable interpreter.

Unlike `ghcr.io/devcontainers/features/python`, this feature installs **no** VS Code Python extensions or formatter settings—only what Spec Kit needs to run `specify` in the container.

## What gets installed

| Component | How |
|-----------|-----|
| **uv** | Pinned release tarball from [astral-sh/uv](https://github.com/astral-sh/uv) → `/usr/local/bin` |
| **Python 3.11+** | When `managedPython` is `auto` or `always` and `python3` on `PATH` is older than 3.11 (or missing), via `uv python install` |
| **specify** | PyPI package `specify-cli` via `uv tool install` → `/usr/local/bin` |

`apt`: `ca-certificates`, `curl` (for downloads).

## Consumer `devcontainer.json`

**Standalone (recommended):**

```json
{
  "features": {
    "ghcr.io/devcontainers/features/common-utils:2": {},
    "ghcr.io/markheydon/devcontainer-features/spec-kit:1.0.0": {
      "specifyVersion": "latest"
    }
  }
}
```

**With the official Python feature** (VS Code Python tooling + Spec Kit):

```json
{
  "features": {
    "ghcr.io/devcontainers/features/common-utils:2": {},
    "ghcr.io/devcontainers/features/python:1": {
      "version": "3.12"
    },
    "ghcr.io/markheydon/devcontainer-features/spec-kit:1.0.0": {
      "specifyVersion": "latest",
      "managedPython": "auto"
    }
  }
}
```

With `managedPython: auto`, a 3.11+ `python3` from the Python feature skips a second interpreter install.

Metadata sets `installsAfter` [common-utils](https://github.com/devcontainers/features/tree/main/src/common-utils).

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `specifyVersion` | `latest` | PyPI version of `specify-cli`, or `latest` to upgrade on each image build (`uv tool install --force`). |
| `uvVersion` | `0.13.7` | uv GitHub release tag (no leading `v`). |
| `managedPython` | `auto` | `auto` \| `always` \| `never` — see install script behaviour above. |
| `pythonVersion` | `3.12` | Version passed to `uv python install` when managed Python runs. |

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
- Supported uv tarball architectures: `x86_64`, `aarch64`, `armv7l`.

## Development in this repository

Unpublished installs use a repo-relative path:

```json
"features": {
  "../src/spec-kit": {}
}
```

See the root [CONTRIBUTING.md](../../CONTRIBUTING.md) for ShellCheck, `devcontainer features test`, and versioning rules.
