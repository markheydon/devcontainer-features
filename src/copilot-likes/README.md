# Copilot Likes

Opinionated Dev Container feature with CLI tools and small UX defaults that GitHub Copilot and similar agents often assume are already installed.

## What gets installed

**Packages (apt, Ubuntu/Debian bases)**

| Tool | Notes |
|------|--------|
| ripgrep (`rg`) | Search |
| fd-find | Exposed as `fd` via symlink (Ubuntu naming) |
| fzf | Fuzzy finder |
| jq | JSON |
| tree | Directory listing |
| bat | Pager-friendly `cat`; exposed as `bat` via symlink from `batcat` where needed |
| git-delta | Syntax-highlighted diffs |
| direnv | Per-directory environment |
| curl, unzip | Used to install eza when not already present |

**Binary download**

- [eza](https://github.com/eza-community/eza) v0.23.5 — modern `ls` replacement; zip per architecture (`x86_64`, `aarch64`, `armv7l` → `arm-unknown-linux-gnueabihf`) with SHA-256 verification before install. Unsupported architectures fail the install with a clear message. Bump `EZA_VERSION` and checksums in `install.sh` when upgrading.

**Configuration (re-applied on every install; safe to re-run)**

- System git pager set to `delta` when git is available.
- `/etc/profile.d/copilot-likes.sh`: direnv hook for bash, aliases (`ll`, `ls` → eza; `cat` → bat; `grep` → rg).

## Consumer `devcontainer.json`

Published reference (pin semver or use a major-version tag after publish).

**Microsoft dev container base (recommended):** the base this repo uses in its [maintainer dev container](../../.devcontainer/README.md) already includes [common-utils](https://github.com/devcontainers/features/tree/main/src/common-utils).

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/markheydon/devcontainer-features/copilot-likes:1.0.2": {}
  }
}
```

**Plain or minimal base:** list common-utils when your image does not already provide it:

```json
{
  "image": "ubuntu:24.04",
  "features": {
    "ghcr.io/devcontainers/features/common-utils:2": {},
    "ghcr.io/markheydon/devcontainer-features/copilot-likes:1.0.2": {}
  }
}
```

### `installsAfter` and common-utils

Metadata sets `installsAfter` [common-utils](https://github.com/devcontainers/features/tree/main/src/common-utils) so common-utils is applied before this feature when both appear in your `features` block. The Dev Containers CLI treats that as a **soft dependency**: if common-utils is not listed, install order still resolves and this feature installs on its own.

Omit common-utils when your base is a pre-built Microsoft dev container image (they are [built with common-utils](https://github.com/devcontainers/images/blob/main/src/base-ubuntu/.devcontainer/devcontainer.json)). Re-applying common-utils on top of such images is usually redundant and can fail if you force UID/GID 1000 again—see [Using with dev container images](https://github.com/devcontainers/features/blob/main/src/common-utils/README.md#using-with-dev-container-images) in the upstream feature docs.

For the shared rule across features in this repository, see [README.md](../../README.md#using-a-feature).

## Caveats

- Intended for Debian-family dev container images with `apt` (the repo smoke test uses `mcr.microsoft.com/devcontainers/base:ubuntu`).
- Aliases and direnv apply to login shells that source `/etc/profile.d/`; non-bash shells may not see the aliases.

## Development in this repository

Unpublished installs use a repo-relative path:

```json
"features": {
  "../src/copilot-likes": {}
}
```

See the root [CONTRIBUTING.md](../../CONTRIBUTING.md) for ShellCheck, `devcontainer features test`, and versioning rules.
