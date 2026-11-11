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

Published reference (pin semver or use a major-version tag after publish):

```json
{
  "features": {
    "ghcr.io/devcontainers/features/common-utils:2": {},
    "ghcr.io/markheydon/devcontainer-features/copilot-likes:1.0.1": {}
  }
}
```

This feature’s metadata sets `installsAfter` [common-utils](https://github.com/devcontainers/features/tree/main/src/common-utils). Include it (or an equivalent base feature your image already provides) so install order is valid.

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
