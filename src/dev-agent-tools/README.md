# Dev Agent Tools

Opinionated Dev Container feature with CLI tools and small UX defaults that coding agents often assume are already installed. This feature is **not** the GitHub Copilot product—the legacy GHCR id `copilot-likes` exists only for backward compatibility.

**Consumer documentation:** [Dev Agent Tools on the docs site](https://markheydon.github.io/devcontainer-features/features/dev-agent-tools/)

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
- `/etc/profile.d/dev-agent-tools.sh`: direnv hook for bash, agent-friendly aliases (`ll`, `ls` → eza; `cat` → bat; `grep` → rg), and a simple `PS1` when `CURSOR_AGENT` is set.

## Development in this repository

Unpublished installs use a repo-relative path:

```json
"features": {
  "../src/dev-agent-tools": {}
}
```

See the root [CONTRIBUTING.md](../../CONTRIBUTING.md) for ShellCheck, `./scripts/test-features.sh`, and versioning rules.