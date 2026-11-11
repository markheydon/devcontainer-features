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
- CI: `devcontainers/action` (validate and publish), ShellCheck, pre-publish feature tests via [scripts/test-features.sh](scripts/test-features.sh) ([feature-test.yml](.github/workflows/feature-test.yml)), post-publish smoke test via `@devcontainers/cli`.

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
# Optional when Docker is available — full matrix: ./scripts/test-features.sh
# devcontainer features test -f <feature-id> -i mcr.microsoft.com/devcontainers/base:ubuntu .
```

See [.devcontainer/README.md](.devcontainer/README.md) for maintainer tooling (ShellCheck, Dev Container CLI, host Docker, [scripts/test-features.sh](scripts/test-features.sh)).

On every PR and push to `main`, GitHub Actions runs ShellCheck ([lint.yml](.github/workflows/lint.yml)), feature validation ([validate.yml](.github/workflows/validate.yml)), and [scripts/test-features.sh](scripts/test-features.sh) per job in [feature-test.yml](.github/workflows/feature-test.yml). After merge, features publish and the post-publish smoke test workflow runs ([test.yml](.github/workflows/test.yml)).

When install behaviour changes:

- Bump the feature `version` in `devcontainer-feature.json`.
- Extend assertions in `test/<feature-id>/test.sh` and keep post-publish smoke jobs in [test.yml](.github/workflows/test.yml) in sync.

All agent-authored pull requests require human review before merge.
