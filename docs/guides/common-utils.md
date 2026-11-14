# Common-utils dependency

Several features in this collection declare `installsAfter` [common-utils](https://github.com/devcontainers/features/tree/main/src/common-utils) in `devcontainer-feature.json`.

## Soft dependency

The Dev Containers CLI treats `installsAfter` as a **soft** dependency. If common-utils is not in your `features` block, install order still resolves and the feature installs on its own.

## When to omit common-utils

Official Microsoft dev container images (for example `mcr.microsoft.com/devcontainers/base:ubuntu`) are **built with common-utils already applied**. Listing common-utils again is usually redundant and can fail if you force UID/GID 1000 on top of an image that already configured users.

## When to add common-utils

Use a plain base (for example `ubuntu:24.04`) and add both features explicitly:

```json
{
  "image": "ubuntu:24.04",
  "features": {
    "ghcr.io/devcontainers/features/common-utils:2": {},
    "ghcr.io/markheydon/devcontainer-features/dev-agent-tools:1": {}
  }
}
```

See [Using with dev container images](https://github.com/devcontainers/features/blob/main/src/common-utils/README.md#using-with-dev-container-images) in the upstream common-utils documentation.