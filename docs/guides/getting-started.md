# Getting started

This tutorial walks you through referencing a published feature from your own repository.

## Prerequisites

- A project that uses [Development Containers](https://containers.dev/) (VS Code, Cursor, GitHub Codespaces, or the Dev Container CLI).
- Docker available where you build or open the dev container.

## Steps

1. Create or open `.devcontainer/devcontainer.json` in your project.

2. Pick a base image. For a generic Ubuntu environment:

   ```json
   "image": "mcr.microsoft.com/devcontainers/base:ubuntu"
   ```

3. Add a `features` block. For example, [Dev Agent Tools](../features/dev-agent-tools.md):

   ```json
   "features": {
     "ghcr.io/markheydon/devcontainer-features/dev-agent-tools:1": {}
   }
   ```

4. Rebuild the dev container (for example **Dev Containers: Rebuild Container** in the command palette).

5. Verify a tool is on `PATH` inside the container, for example `rg --version`.

## Next steps

- [Versioning and tags](versioning.md) — when to use `:1`, a semver pin, or `:latest`.
- [Common-utils dependency](common-utils.md) — whether you need the official common-utils feature.
- Feature reference pages under **Features** in the navigation.