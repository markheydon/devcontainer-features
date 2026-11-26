# Dev Agent Tools

Modern CLI tools and small shell or git defaults that coding agents often assume are installed. This feature is **not** the GitHub Copilot product—the legacy GHCR id `copilot-likes` exists only for backward compatibility.

**GHCR:** `ghcr.io/markheydon/devcontainer-features/dev-agent-tools:1`

## Options

This feature has **no configurable options** in `devcontainer-feature.json`.

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

- [eza](https://github.com/eza-community/eza) v0.23.5 — modern `ls` replacement; zip per architecture (`x86_64`, `aarch64`, `armv7l` → `arm-unknown-linux-gnueabihf`) with SHA-256 verification before install. Unsupported architectures fail the install with a clear message.

**Configuration (re-applied on every install; safe to re-run)**

- System git pager set to `delta` when git is available.
- `/etc/profile.d/dev-agent-tools.sh`: direnv hook for bash, agent-friendly aliases (`ll`, `ls` → eza; `cat` → bat; `grep` → rg), and a simple `PS1` when `CURSOR_AGENT` is set.

## Shell configuration

On install, the feature writes `/etc/profile.d/dev-agent-tools.sh`:

- direnv hook for bash
- Aliases: `ll` / `ls` → eza, `cat` → bat, `grep` → rg
- Simple `PS1` when `CURSOR_AGENT` is set (reduces truncation with heavy prompts in Cursor Agent terminals)

## Example `devcontainer.json`

Published reference: use the major tag `:1` unless you need a pinned semver. See [Versioning and tags](../guides/versioning.md).

**Canonical id:**

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/markheydon/devcontainer-features/dev-agent-tools:1": {}
  }
}
```

**Legacy id** (still updated via `legacyIds` when published from this repository):

```json
"ghcr.io/markheydon/devcontainer-features/copilot-likes:1": {}
```

Migrate to `dev-agent-tools` when convenient so AI-assisted refactors do not confuse this feature with GitHub Copilot. See [Legacy feature ids](../guides/legacy-feature-ids.md).

**Microsoft dev container base (recommended):** the base images in Microsoft’s dev container catalogue already include [common-utils](https://github.com/devcontainers/features/tree/main/src/common-utils).

**Plain or minimal base:** list common-utils when your image does not already provide it:

```json
{
  "image": "ubuntu:24.04",
  "features": {
    "ghcr.io/devcontainers/features/common-utils:2": {},
    "ghcr.io/markheydon/devcontainer-features/dev-agent-tools:1": {}
  }
}
```

### `installsAfter` and common-utils

Metadata sets `installsAfter` [common-utils](https://github.com/devcontainers/features/tree/main/src/common-utils) so common-utils is applied before this feature when both appear in your `features` block. The Dev Containers CLI treats that as a **soft dependency**: if common-utils is not listed, install order still resolves and this feature installs on its own.

Omit common-utils when your base is a pre-built Microsoft dev container image (they are [built with common-utils](https://github.com/devcontainers/images/blob/main/src/base-ubuntu/.devcontainer/devcontainer.json)). Re-applying common-utils on top of such images is usually redundant and can fail if you force UID/GID 1000 again—see [Using with dev container images](https://github.com/devcontainers/features/blob/main/src/common-utils/README.md#using-with-dev-container-images) in the upstream feature docs.

For the shared rule across features in this collection, see [Common-utils dependency](../guides/common-utils.md).

## Legacy id

`ghcr.io/markheydon/devcontainer-features/copilot-likes:1` remains an alias for this feature. See [Legacy feature ids](../guides/legacy-feature-ids.md).

## Caveats

- Intended for Debian-family dev container images with `apt` (the repo smoke test uses `mcr.microsoft.com/devcontainers/base:ubuntu`).
- Aliases and direnv apply to login shells that source `/etc/profile.d/`; non-bash shells may not see the aliases.

## Common-utils

On Microsoft dev container bases, omit common-utils. On plain Ubuntu images, add `ghcr.io/devcontainers/features/common-utils:2` before dev-agent-tools. See [Common-utils dependency](../guides/common-utils.md).

## Source and contributing

- [Source on GitHub](https://github.com/markheydon/devcontainer-features/tree/main/src/dev-agent-tools)
- [Report an issue](https://github.com/markheydon/devcontainer-features/issues)
- [Contributing](../contributing.md)