# Versioning and tags

After merge to `main`, each feature publishes to GHCR with several tags.

## Major alias (`:1`)

Prefer **`ghcr.io/markheydon/devcontainer-features/<feature-id>:1`** in `devcontainer.json`. Patch releases update `:1` automatically so you do not need to edit consumer configs for bug fixes.

## Exact semver

Pin an exact version from `devcontainer-feature.json` (for example `:1.1.0`) when you need reproducible image builds. Update the pin deliberately when you want new install behaviour.

## `:latest`

CI smoke tests use `:latest`. It tracks the newest publish for that feature id. Avoid `:latest` in production `devcontainer.json` unless you accept floating updates across semver bumps.

## Legacy ids

Some features publish under a **legacy** GHCR id via `legacyIds` in metadata. The legacy id receives the same version tags as the canonical id. See [Legacy feature ids](legacy-feature-ids.md).