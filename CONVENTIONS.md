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
| `test.yml` | After successful publish, `devcontainer up` and verify tools |

There is no top-level `docs/` folder yet. Use the root README, CONTRIBUTING, and per-feature READMEs. Publish may generate OCI feature documentation when `generate-docs` is enabled.

---

## Feature metadata (`devcontainer-feature.json`)

- **`id`:** Must match the folder name under `src/` (kebab-case).
- **`version`:** Semver. Bump on any change to install-time behaviour (packages added/removed, scripts, architecture handling).
- **`name` / `description`:** User-facing; UK English.
- **`documentationURL`:** Points at this repo tree path for the feature.
- **`installsAfter`:** Declare ordering when another feature must run first (for example `common-utils`).

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

- Consumer reference shape: `ghcr.io/<owner>/devcontainer-features/<feature-id>:<version>` or `:latest` after publish to `main`.
- Do not change `features-namespace` or registry layout without explicit maintainer instruction.
- Metadata validation uses `base-path-to-features: "./src"` in workflows.

---

## Testing

- **Validate:** Caught on every PR via `validate.yml`.
- **ShellCheck:** Caught on every PR via `lint.yml`.
- **Smoke test:** After publish, `test.yml` builds a minimal devcontainer that references the published feature and checks expected binaries (`which`). The workflow is representative of consumer references (published URI, `latest` tag) but does not assert every binary the feature installs. Keep the table below in sync when you extend install behaviour or add CI checks.

| Feature | Asserted in `test.yml` | Installed but not asserted in CI (document in feature README) |
|---------|------------------------|------------------------------------------------------------------|
| `copilot-likes` | `rg`, `fd`, `jq`, `bat`/`batcat`, `eza`, `fzf`, `tree`, `direnv`, `delta` | Profile aliases and `/etc/profile.d` behaviour (not executed in non-login `which` checks) |
| `spec-kit` | `uv`, `specify`, `specify version`, Python ≥3.11 via `uv run` | `uvx`, uv-managed Python when base `python3` < 3.11 (covered indirectly by `specify`) |

When adding tools to a feature, add matching assertions to `test.yml` (or a feature-specific job later if the repo grows).

Manual checks (with Docker on the host; see `.devcontainer/devcontainer.json`):

```bash
# Auto-generated install test for one feature
devcontainer features test -f <feature-id> \
  --base-image mcr.microsoft.com/devcontainers/base:ubuntu

# End-to-end try-out with a devcontainer.json that references ../src/<feature-id>
devcontainer up --workspace-folder .
```

Feature packaging and metadata validation also run in CI ([validate.yml](.github/workflows/validate.yml)). Optional `test/<feature-id>/test.sh` scripts can be added later for richer `devcontainer features test` coverage ([CLI docs](https://github.com/devcontainers/cli/blob/main/docs/features/test.md)).

---

## Documentation

- UK English in docs and comments.
- Keep the root README feature list in sync with folders under `src/`.
- Per-feature README: what gets installed, why, and any caveats (architecture, `installsAfter`).

See `.agents/skills/project-documentation/` for placement guidance.

---

## Security

- No credentials in repo or install scripts.
- Minimise network fetch during install; justify any external URL.
- Do not broaden `apt` installs beyond what the feature advertises without updating docs and version.
