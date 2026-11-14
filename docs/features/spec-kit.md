# Spec Kit

Installs [GitHub Spec Kit](https://github.com/github/spec-kit)’s **Specify CLI** with **uv** and **Python 3.11+** when the base image does not already provide a suitable interpreter.

Unlike `ghcr.io/devcontainers/features/python`, this feature does **not** install VS Code Python extensions—only what Spec Kit needs to run `specify`.

**GHCR:** `ghcr.io/markheydon/devcontainer-features/spec-kit:1`

Full option reference, lifecycle sync, and testing notes: [src/spec-kit/README.md](https://github.com/markheydon/devcontainer-features/blob/main/src/spec-kit/README.md).

## Example `devcontainer.json`

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

Pin `specifyVersion` to a PyPI release when you need reproducible image builds instead of `latest`.

## Common-utils

On Microsoft dev container bases, omit common-utils. On plain Ubuntu images, add `ghcr.io/devcontainers/features/common-utils:2` before spec-kit. See [Common-utils dependency](../guides/common-utils.md).