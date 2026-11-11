# Agent Instructions

Repository-specific operating rules for AI coding agents.

## Core Context

Read before non-trivial changes:

- `GOALS.md`
- `CONVENTIONS.md`
- `CONTRIBUTING.md`

Optional: `adr/` only when present and an architectural decision is in scope (use the ADR skill).

## Language

UK English in documentation, comments, and user-facing text.

## Tech Stack

- Bash install scripts (`install.sh`) per [Dev Container Features](https://containers.dev/implementors/features/).
- Feature metadata in `devcontainer-feature.json` under `src/<feature-id>/`.
- CI: `devcontainers/action` (validate and publish), ShellCheck, post-publish smoke test via `@devcontainers/cli`.

## Skills

Project skills live in `.agents/skills/`.

| Skill | Use when |
|---|---|
| `code-review` | Reviewing install scripts, metadata, or CI-related changes before merge |
| `goals-review` | Drift check against GOALS.md and feature inventory |
| `create-architectural-decision-record` | Creating an ADR (only when user asks or policy needs recording) |
| `documentation-writer` | Diátaxis-aligned documentation |
| `project-documentation` | Project-aware docs placement |

## Task Routing

- **Features** (`src/**/install.sh`, `src/**/devcontainer-feature.json`): `CONVENTIONS.md`.
- **Documentation** (`**/*.md` except `adr/`): documentation skills.
- **ADRs** (`adr/*.md`): ADR skill only.

## Not Allowed Without Explicit Instruction

- Change GHCR publish namespace, OCI layout, or `features-namespace` in [.github/workflows/publish.yml](.github/workflows/publish.yml).
- Add unpinned remote downloads (`curl | bash`) without checksums or version pins.
- Weaken `set -e` or idempotency patterns on install scripts.
- Modify CI/CD behaviour.
- Commit secrets or API keys.

## Pull Request Workflow

Follow [CONTRIBUTING.md](CONTRIBUTING.md).

Before opening a PR (local checks mirror CI where possible):

```bash
shellcheck src/**/install.sh
# Optional when Docker is available (development container includes the CLI):
# devcontainer features test -f <feature-id> --base-image mcr.microsoft.com/devcontainers/base:ubuntu
```

See [.devcontainer/README.md](.devcontainer/README.md) for maintainer tooling (ShellCheck, Dev Container CLI, host Docker).

On every PR and push to `main`, GitHub Actions runs ShellCheck ([lint.yml](.github/workflows/lint.yml)) and feature validation ([validate.yml](.github/workflows/validate.yml)). After merge, features publish and the post-publish test workflow runs ([test.yml](.github/workflows/test.yml)).

When install behaviour changes:

- Bump the feature `version` in `devcontainer-feature.json`.
- Extend the post-publish test assertions if new binaries or tools should be verified.

All agent-authored pull requests require human review before merge.
