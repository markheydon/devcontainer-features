# Dev Container Features

Custom [Dev Container features](https://containers.dev/implementors/features/) published to GitHub Container Registry (GHCR) as `ghcr.io/markheydon/devcontainer-features/<feature-id>`.

Use this site when you consume features from other projects. Contributors should still read [CONTRIBUTING.md](https://github.com/markheydon/devcontainer-features/blob/main/CONTRIBUTING.md) and [CONVENTIONS.md](https://github.com/markheydon/devcontainer-features/blob/main/CONVENTIONS.md) in the repository.

## Quick start

1. Choose a base image (official Microsoft dev container images are a good default).
2. Add a feature reference to your `devcontainer.json` `features` block.
3. Prefer the major-version tag `:1` unless you need a pinned semver.

Example:

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/markheydon/devcontainer-features/dev-agent-tools:1": {}
  }
}
```

See [Getting started](guides/getting-started.md) for a fuller walkthrough.

## Features

| Feature | Summary |
|---------|---------|
| [Dev Agent Tools](features/dev-agent-tools.md) | CLI tools and shell defaults for agent-assisted development |
| [Spec Kit](features/spec-kit.md) | uv, Python when needed, and the Specify CLI for GitHub Spec Kit |

## Repository

- [Source on GitHub](https://github.com/markheydon/devcontainer-features)
- [GOALS](https://github.com/markheydon/devcontainer-features/blob/main/GOALS.md) — scope and success criteria for this collection