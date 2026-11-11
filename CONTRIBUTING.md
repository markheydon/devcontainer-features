# Contributing

Pull requests welcome.

## Adding a feature

1. Create a new folder under `src/<feature-id>` (kebab-case; must match feature `id` in JSON).
2. Add:
   - `devcontainer-feature.json`
   - `install.sh`
   - `README.md` (recommended — packages and binaries, `installsAfter`, consumer JSON example, caveats)
3. Ensure `install.sh` is idempotent and uses `set -e` (see [CONVENTIONS.md](CONVENTIONS.md)).
4. Add a row to the **Features** table in the root [README.md](README.md).

## Before you open a PR

From the [development container](.devcontainer/README.md) (rebuild after feature changes there):

```bash
shellcheck src/**/install.sh
```

Optional, when Docker is available on the host (see `docker-outside-of-docker` in [devcontainer.json](.devcontainer/devcontainer.json)):

```bash
# Recommended: full matrix (or one feature / one image)
./scripts/test-features.sh
./scripts/test-features.sh <feature-id>
./scripts/test-features.sh <feature-id> mcr.microsoft.com/devcontainers/php:latest
```

That script installs from `src/` using the Dev Container CLI, then runs `test/<feature-id>/test.sh`. In the maintainer dev container, plain `devcontainer features test` often fails after a successful build because of bind-mount paths; the script still runs the assertions in the built image (see [.devcontainer/README.md](.devcontainer/README.md)).

On a host where `devcontainer features test` completes end-to-end, you can call it directly:

```bash
devcontainer features test -f <feature-id> \
  -i mcr.microsoft.com/devcontainers/base:ubuntu
```

Run tests once per changed feature (`feature-id` matches the folder under `src/`). Image list: [scripts/official-base-images.txt](scripts/official-base-images.txt). To investigate apt/Yarn issues on those bases without installing a feature:

```bash
./scripts/probe-base-images.sh
```

CI runs **feature tests** on every feature against all listed official images ([feature-test.yml](.github/workflows/feature-test.yml)).

CI also runs:

- **Validate** — [validate.yml](.github/workflows/validate.yml) (`devcontainers/action` on `./src`)
- **ShellCheck** — [lint.yml](.github/workflows/lint.yml)

After merge to `main`, features **publish** to GHCR ([publish.yml](.github/workflows/publish.yml)) and a **smoke test** runs ([test.yml](.github/workflows/test.yml)).

## Versioning

Bump the feature **`version`** in `devcontainer-feature.json` whenever install-time behaviour changes (packages, scripts, downloads, or assertions consumers rely on).

If you add tools that should be verified in CI, extend `test/<feature-id>/test.sh` and keep the post-publish smoke test ([test.yml](.github/workflows/test.yml)) in sync.

## Project intent

See [GOALS.md](GOALS.md) for what belongs in this repository and what does not.

## Testing locally

### Try a feature you are editing

Point a throwaway `devcontainer.json` at the feature under test. Unpublished work uses a repo-relative path:

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "../src/<feature-id>": {}
  }
}
```

Then:

```bash
devcontainer up --workspace-folder path/to/that-folder
devcontainer exec --workspace-folder path/to/that-folder <command>
```

Published features use `ghcr.io/markheydon/devcontainer-features/<feature-id>:<version>` instead.

### This repo’s own dev container

The maintainer dev container installs ShellCheck and the Dev Container CLI via established community features—it does **not** add a bespoke `src/shellcheck`-style feature. Details: [.devcontainer/README.md](.devcontainer/README.md).
