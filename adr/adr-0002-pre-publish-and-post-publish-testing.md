---
title: "ADR-0002: Test from source before publish and from GHCR after publish"
status: "Accepted"
date: "2026-11-26"
authors: "Mark Heydon (repository owner)"
tags: ["architecture", "decision", "testing"]
supersedes: ""
superseded_by: ""
---

# ADR-0002: Test from source before publish and from GHCR after publish

## Status

Proposed | **Accepted** | Rejected | Superseded | Deprecated

## Context

Install scripts can pass on a maintainer laptop and still fail once packaged, or pass packaging and still fail the way a consumer references GHCR. G4 requires both: pre-publish installs from `src/` on official Microsoft base images, and a post-publish smoke test that uses published feature URIs. The maintainer dev container uses Docker-outside-of-Docker, where `devcontainer features test` can build a feature image and then fail because the CLI bind-mounts a `/tmp` path that exists only inside the dev container, not on the Docker host. Aspire CLI create-time sync walks the workspace tree for SDK pins, so a smoke job whose workspace is this features repository does not represent a consumer Aspire repo.

## Decision

Keep two test stages with different inputs and the same assertion scripts under `test/<feature-id>/test.sh`.

- **DEC-001**: On pull request and on `main`, [feature-test.yml](../.github/workflows/feature-test.yml) runs [scripts/test-features.sh](../scripts/test-features.sh) for each feature against a matrix subset of [scripts/official-base-images.txt](../scripts/official-base-images.txt). The script installs from `./src` via `devcontainer features test`. When that CLI fails after a successful image build solely because a bind source path does not exist, the script runs `test/<feature-id>/test.sh` with `docker run` against the built image.
- **DEC-002**: After a successful Publish Features run, [test.yml](../.github/workflows/test.yml) starts a dev container whose `features` block references `ghcr.io/<owner>/devcontainer-features/<feature-id>:latest` and executes the same `test.sh`. `dev-agent-tools` is also smoked under the legacy id `copilot-likes` (ADR-0007).
- **DEC-003**: Aspire post-publish coverage is two jobs with workspaces that are not this repository checkout. Sync smoke uses an ephemeral directory containing only `aspire.config.json` (the pin from `test/aspire-cli/sync-target-version.txt`) plus a generated `devcontainer.json`. Workflow smoke copies `test/aspire-cli/fixtures/run-smoke` and checks `aspire run` from that project root. Spec Kit smoke may use the repository checkout because it only reads `.specify/init-options.json` written for the job.
- **DEC-004**: Scenario and duplicate-feature passes inside `devcontainer features test` stay skipped (`--skip-scenarios`, `--skip-duplicated`). Behavioural checks live in `test.sh`. The CI matrix is the representative subset; a full local run of `./scripts/test-features.sh` uses every image in `official-base-images.txt`.

## Consequences

### Positive

- **POS-001**: Pull requests fail before publish when an install breaks on a supported Microsoft base image.
- **POS-002**: Post-publish jobs fail when the OCI artifact, tag, or consumer-shaped `devcontainer up` path breaks, which source installs cannot see.
- **POS-003**: The bind-mount fallback keeps pre-publish tests runnable in the maintainer dev container and on GitHub-hosted runners with one script.
- **POS-004**: Aspire sync smoke cannot pass by accident because the features tree contains no Aspire SDK pin, and it cannot fail because unrelated files in this repository match the scanner.

### Negative

- **NEG-001**: Two stages duplicate CLI setup and wall-clock time. Post-publish jobs run only after merge, so a GHCR-only defect is caught late.
- **NEG-002**: `:latest` smoke tracks the newest publish. A pin file that equals current upstream `latest` makes the sync assertion a no-op unless maintainers move the pin.
- **NEG-003**: The matrix is a subset. Images listed only in `official-base-images.txt` are untested until someone runs the full script.
- **NEG-004**: The Docker-outside-of-Docker fallback depends on recognising the CLI's bind-mount error text.

## Alternatives Considered

### Only `devcontainer features test` on pull requests

- **ALT-001**: **Description**: Treat a green features-test matrix as sufficient and drop [test.yml](../.github/workflows/test.yml).
- **ALT-002**: **Rejection Reason**: That never references the published URI, so a namespace, tag, or packaging regression ships to consumers. It also fails closed in Docker-outside-of-Docker when the image build succeeded and only the CLI's `/tmp` bind is missing.

### Only post-publish smoke

- **ALT-003**: **Description**: Skip the pre-publish matrix and rely on `devcontainer up` against GHCR after merge.
- **ALT-004**: **Rejection Reason**: Defects reach `main` and GHCR before any install assertion runs, and smoke uses `:latest` on one base image per job rather than the matrix.

### Aspire smoke against this repository as `workspace-folder`

- **ALT-005**: **Description**: Point `devcontainer up --workspace-folder` at the features checkout for Aspire jobs, as the Spec Kit job does.
- **ALT-006**: **Rejection Reason**: Aspire sync scans the workspace to depth 8 for a single SDK pin. This repository is not an Aspire app. A checkout workspace either skips sync or fails on unrelated matches. The runnable `aspire run` check needs the fixture app, which is a different tree from the pin-only sync workspace.

## Implementation Notes

- **IMP-001**: New install behaviour extends `test/<feature-id>/test.sh` and the matching post-publish job in the same change.
- **IMP-002**: Sync pins stay in `test/<feature-id>/sync-target-version.txt`. Pre-publish passes them as environment variables; post-publish writes them into the consumer-shaped config file for that feature.
- **IMP-003**: A publish that consumers can install is successful when both the matrix on `main` and the subsequent smoke workflow pass. Aspire sync and workflow jobs are both required.

## References

- **REF-001**: [ADR-0001](adr-0001-ghcr-feature-publishing.md), [ADR-0003](adr-0003-create-time-version-sync-for-latest.md), [ADR-0007](adr-0007-legacy-feature-ids-on-rename.md)
- **REF-002**: [GOALS.md](../GOALS.md) G4; [CONVENTIONS.md](../CONVENTIONS.md) testing section
- **REF-003**: [Dev Container CLI feature tests](https://github.com/devcontainers/cli/blob/main/docs/features/test.md)
