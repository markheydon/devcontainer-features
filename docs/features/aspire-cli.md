# Aspire CLI

Installs the **Aspire CLI** under the container user’s home via the [official installer](https://aspire.dev/install.sh), with optional bundle setup and create-time alignment to the repo Aspire SDK pin.

Unlike `ghcr.io/microsoft/aspire-devcontainer-feature/aspire`, this feature installs under `~/.aspire` so bundle setup works reliably for non-root users. It does **not** install a .NET SDK—use `mcr.microsoft.com/devcontainers/dotnet` or the official `dotnet` feature when you need the SDK.

**GHCR:** `ghcr.io/markheydon/devcontainer-features/aspire-cli:1`

Full option reference, `remoteEnv` guidance, and testing notes: [src/aspire-cli/README.md](https://github.com/markheydon/devcontainer-features/blob/main/src/aspire-cli/README.md).

## Example `devcontainer.json`

```json
{
  "image": "mcr.microsoft.com/devcontainers/dotnet:latest",
  "features": {
    "ghcr.io/markheydon/devcontainer-features/aspire-cli:1": {
      "aspireVersion": "latest"
    }
  },
  "remoteEnv": {
    "PATH": "${containerEnv:HOME}/.aspire/bin:${containerEnv:PATH}",
    "ASPIRE_HOME": "${containerEnv:HOME}/.aspire",
    "ASPIRE_LAYOUT_PATH": "${containerEnv:HOME}/.aspire/bundle"
  }
}
```

Pin `aspireVersion` when you need reproducible image builds instead of `latest`.

Add `remoteEnv` (see example) so integrated terminals and the Aspire VS Code extension see `~/.aspire/bin` on `PATH`; login shells also use profile snippets from the feature.

With `aspireVersion: latest`, create-time sync can align the CLI to a single SDK pin in the workspace (for example `aspire.config.json`). Pin `aspireVersion` to skip that step.

## Common-utils

On Microsoft dev container bases, omit common-utils. On plain Ubuntu images, add `ghcr.io/devcontainers/features/common-utils:2` before aspire-cli. See [Common-utils dependency](../guides/common-utils.md).