# Dev Agent Tools

Modern CLI tools and small shell or git defaults that coding agents often assume are installed.

**GHCR:** `ghcr.io/markheydon/devcontainer-features/dev-agent-tools:1`

Implementation detail and maintainer notes: [src/dev-agent-tools/README.md](https://github.com/markheydon/devcontainer-features/blob/main/src/dev-agent-tools/README.md).

## Installed tools

| Tool | Purpose |
|------|---------|
| ripgrep (`rg`) | Fast search |
| `fd` | File find (`fdfind` on Ubuntu, symlinked) |
| `fzf` | Fuzzy finder |
| `jq` | JSON processing |
| `tree` | Directory trees |
| `bat` | Syntax-highlighted file view |
| `git-delta` | Improved diffs; set as git pager |
| `direnv` | Per-directory environment |
| `eza` | Modern `ls` (pinned binary download) |

## Shell configuration

On install, the feature writes `/etc/profile.d/dev-agent-tools.sh`:

- direnv hook for bash
- Aliases: `ll` / `ls` → eza, `cat` → bat, `grep` → rg
- Simple `PS1` when `CURSOR_AGENT` is set (reduces truncation with heavy prompts in Cursor Agent terminals)

## Example `devcontainer.json`

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/markheydon/devcontainer-features/dev-agent-tools:1": {}
  }
}
```

## Legacy id

`ghcr.io/markheydon/devcontainer-features/copilot-likes:1` remains an alias for this feature. See [Legacy feature ids](../guides/legacy-feature-ids.md).

## Caveats

- Debian/Ubuntu images with `apt`.
- Profile aliases apply to login shells that source `/etc/profile.d/`; non-bash shells may not see them.