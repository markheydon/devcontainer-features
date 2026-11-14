> Coding and design conventions for this repository.

# Conventions

**Project:** devcontainer-features  
**Last updated:** 2026-11-11

When in doubt, follow this file. Rare cross-feature policy changes may warrant an ADR if the user asks to record them.

---

## Project structure

```
src/
└── <feature-id>/
    ├── devcontainer-feature.json
    ├── install.sh
    └── README.md          # optional but recommended
```

CI workflows live under `.github/workflows/`:

| Workflow | Purpose |
|---|---|
| `validate.yml` | `devcontainers/action` validate-only on PR and `main` |
| `lint.yml` | ShellCheck on install scripts |
| `publish.yml` | Publish features to GHCR on push to `main` |
| `feature-test.yml` | On PR and `main`, `./scripts/test-features.sh` per feature × base image (matrix; subset of [scripts/official-base-images.txt](scripts/official-base-images.txt)) |
| `test.yml` | After successful publish, `devcontainer up` and verify tools |

Consumer-facing documentation lives under `docs/` (MkDocs; [GitHub Pages](https://markheydon.github.io/devcontainer-features/) via [.github/workflows/pages.yml](.github/workflows/pages.yml)). The root README links to the site; per-feature READMEs under `src/` remain install-adjacent references. Publish may still generate OCI feature documentation when `generate-docs` is enabled.

---

## Feature metadata (`devcontainer-feature.json`)

- **`id`:** Must match the folder name under `src/` (kebab-case).
- **`version`:** Semver. Bump on any change to install-time behaviour (packages added/removed, scripts, architecture handling).
- **`name` / `description`:** User-facing; UK English.
- **`documentationURL`:** Points at this repo tree path for the feature.
- **`installsAfter`:** Declare ordering when another feature must run first (for example `common-utils`). Keep this in metadata even when many consumers can omit the dependency. In the feature README, state when consumers **must** add the named feature (plain or minimal bases) and when they **may omit** it (pre-built `devcontainers/*` images that already include common-utils). Do not remove `installsAfter` from JSON to “simplify” consumer configs.

---

## Install scripts (`install.sh`)

- Shebang: `#!/usr/bin/env bash`
- Start with `set -e` (add `set -o pipefail` when piping matters).
- Set `export DEBIAN_FRONTEND=noninteractive` when using `apt-get`.
- Prefer distribution packages via `apt-get` where available.
- Handle Ubuntu binary renames with symlinks when needed (for example `fdfind` → `fd`, `batcat` → `bat`).
- For architecture-specific downloads, switch on `uname -m` and fail on unsupported arches with a clear message.
- Scripts must be safe to run more than once (re-run apt, guard expensive downloads with `command -v`).
- Avoid secrets, tokens, or user-specific paths in scripts.
- Prefer pinned versions or checksums for any `curl`/`wget` download; avoid `curl | bash` without explicit pinning.

Run ShellCheck locally (provided by the repo’s [development container](.devcontainer/README.md)):

```bash
shellcheck src/**/install.sh
```

---

## Versioning and publishing

- Consumer reference shape: `ghcr.io/<owner>/devcontainer-features/<feature-id>:<version>` after publish to `main`. Prefer the major alias (`:1`) in README examples; pin exact semver only when documenting reproducibility.
- Do not change `features-namespace` or registry layout without explicit maintainer instruction.
- Metadata validation uses `base-path-to-features: "./src"` in workflows.

---

## Testing

- **Validate:** Caught on every PR via `validate.yml`.
- **ShellCheck:** Caught on every PR via `lint.yml`.
- **Feature tests (PR / `main`):** [feature-test.yml](.github/workflows/feature-test.yml) runs `./scripts/test-features.sh <feature-id> <base-image>` for each matrix combination. The workflow matrix defines which images CI uses; [scripts/official-base-images.txt](scripts/official-base-images.txt) is the default list for a full local matrix via `./scripts/test-features.sh` with no arguments. Assertions live in `test/<feature-id>/test.sh`.
- **Smoke test:** After publish, `test.yml` builds a minimal devcontainer that references the published feature and runs the same `test.sh` scripts. The workflow is representative of consumer references (published URI, `latest` tag). Keep the table below in sync when you extend install behaviour or add CI checks.

| Feature | Asserted in `test/<feature-id>/test.sh` | Installed but not asserted in CI (document in feature README) |
|---------|------------------------|------------------------------------------------------------------|
| `dev-agent-tools` | `rg`, `fd`, `jq`, `bat`/`batcat`, `eza`, `fzf`, `tree`, `direnv`, `delta` | Profile aliases, `CURSOR_AGENT` prompt, and `/etc/profile.d` behaviour (not executed in non-login `which` checks) |
| `spec-kit` | `uv`, `specify`, `specify version`, `specify` not under `/root`, Python ≥3.11 via `uv run`, `sync-specify-version.sh` on disk, simulated postCreate sync as non-root; smoke uses `.specify/init-options.json` + `SPEC_KIT_SYNC_VERIFY_ONLY` | `uvx`, `/opt/uv` layout, shared permissions, and remaining `managedPython` branches (see [spec-kit README](src/spec-kit/README.md)) |

When adding tools to a feature, add matching assertions to `test/<feature-id>/test.sh` and keep the post-publish smoke jobs in [test.yml](.github/workflows/test.yml) in sync (or a feature-specific job later if the repo grows).

**spec-kit postCreate sync:** Feature tests exercise downgrade sync via `test/spec-kit/sync-target-version.txt`. [scripts/test-features.sh](scripts/test-features.sh) passes that value as `SPEC_KIT_SYNC_TARGET_VERSION` and sets `PYTHONVERSION` to match the feature’s `pythonVersion` default (keep both in sync with [src/spec-kit/devcontainer-feature.json](src/spec-kit/devcontainer-feature.json)). The post-publish smoke job reads the same pin into `.specify/init-options.json`. If PyPI `latest` drifts, update the pin — see [src/spec-kit/README.md](src/spec-kit/README.md#testing).

Official Microsoft base images for install testing are listed in [scripts/official-base-images.txt](scripts/official-base-images.txt) (keep [feature-test.yml](.github/workflows/feature-test.yml) in sync). Probe apt/Yarn/`git-delta` behaviour on those images without installing a feature:

```bash
./scripts/probe-base-images.sh
```

Manual checks (with Docker on the host; see `.devcontainer/devcontainer.json`):

```bash
# Local matrix (recommended in the maintainer dev container)
./scripts/test-features.sh
./scripts/test-features.sh <feature-id> mcr.microsoft.com/devcontainers/php:latest

# Direct CLI (works when the Docker host shares the CLI workspace path)
devcontainer features test -f <feature-id> \
  -i mcr.microsoft.com/devcontainers/base:ubuntu

# End-to-end try-out with a devcontainer.json that references ../src/<feature-id>
devcontainer up --workspace-folder .
```

Feature packaging and metadata validation also run in CI ([validate.yml](.github/workflows/validate.yml)). Post-install assertions live in `test/<feature-id>/test.sh` ([CLI docs](https://github.com/devcontainers/cli/blob/main/docs/features/test.md)).

---

## Documentation

- UK English in docs and comments.
- Keep the root README feature list in sync with folders under `src/`.
- Per-feature README: what gets installed, why, and any caveats (architecture, `installsAfter`). Consumer `devcontainer.json` examples use GHCR major tags (`:1`), not patch semver, unless the text is about pinning.

See `.agents/skills/project-documentation/` for Diátaxis and placement guidance.

---

## Security

- No credentials in repo or install scripts.
- Minimise network fetch during install; justify any external URL.
- Do not broaden `apt` installs beyond what the feature advertises without updating docs and version.
