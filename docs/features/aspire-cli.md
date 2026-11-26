# Aspire CLI

Installs the **Aspire CLI** under the container user’s home via the [official installer](https://aspire.dev/install.sh), with optional bundle setup and create-time alignment to the repo Aspire SDK pin.

Unlike `ghcr.io/microsoft/aspire-devcontainer-feature/aspire`, this feature installs under `~/.aspire` so bundle setup works reliably for non-root users. It does **not** install a .NET SDK—use `mcr.microsoft.com/devcontainers/dotnet` or the official `dotnet` feature when you need the SDK.

**Why not Microsoft’s `aspire` feature?** Microsoft’s feature puts the CLI on **`/usr/local/bin`** and skips image-time bundle setup. `aspire-cli` keeps the CLI in the **container user’s home**, runs optional **`aspire setup`**, and can align the CLI to a repo SDK pin on create—intended for DinD/AppHost workflows validated in [issue #24](https://github.com/markheydon/devcontainer-features/issues/24). Full comparison: [Why not Microsoft’s aspire feature?](https://github.com/markheydon/devcontainer-features/blob/main/src/aspire-cli/README.md#why-not-microsofts-aspire-feature) in the feature README.

**GHCR:** `ghcr.io/markheydon/devcontainer-features/aspire-cli:1`

Full option reference, PATH notes, and testing: [src/aspire-cli/README.md](https://github.com/markheydon/devcontainer-features/blob/main/src/aspire-cli/README.md).

## Example `devcontainer.json`

```json
{
  "image": "mcr.microsoft.com/devcontainers/dotnet:latest",
  "features": {
    "ghcr.io/markheydon/devcontainer-features/aspire-cli:1": {
      "aspireVersion": "latest"
    }
  }
}
```

Pin `aspireVersion` when you need reproducible image builds instead of `latest`.

Login and interactive bash terminals get `aspire` on `PATH` from profile snippets installed by the feature. Add optional `remoteEnv` when you need the Aspire VS Code extension or other non-login processes to resolve `aspire`—see [Container environment](https://github.com/markheydon/devcontainer-features/blob/main/src/aspire-cli/README.md#container-environment) in the feature README.

With `aspireVersion: latest`, create-time sync can align the CLI to a single SDK pin in the workspace (for example `aspire.config.json`). Pin `aspireVersion` to skip that step.

## Common-utils

On Microsoft dev container bases, omit common-utils. On plain Ubuntu images, add `ghcr.io/devcontainers/features/common-utils:2` before aspire-cli. See [Common-utils dependency](../guides/common-utils.md).