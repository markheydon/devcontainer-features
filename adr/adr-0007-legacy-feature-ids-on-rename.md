---
title: "ADR-0007: Keep publishing legacy feature ids after a rename"
status: "Accepted"
date: "2026-11-26"
authors: "Mark Heydon (repository owner)"
tags: ["architecture", "decision", "compatibility"]
supersedes: ""
superseded_by: ""
---

# ADR-0007: Keep publishing legacy feature ids after a rename

## Status

Proposed | **Accepted** | Rejected | Superseded | Deprecated

## Context

Feature ids are part of the GHCR reference consumers commit in `devcontainer.json` (ADR-0001). Renaming a folder under `src/` without a compatibility publish breaks every existing reference. The first rename in this repository was `copilot-likes` to `dev-agent-tools`: the old id is not the GitHub Copilot product, and coding agents infer intent from the id string (for example treating `copilot-likes` as a request to remove Copilot). Upstream features have kept legacy ids for years after a rename (`docker-from-docker` beside `docker-outside-of-docker`).

New projects should use the canonical id. Existing projects should keep installing until they edit the file.

## Decision

A renamed feature keeps publishing the previous id through metadata `legacyIds`. The canonical id is the folder name and the `id` field.

- **DEC-001**: `dev-agent-tools` sets `legacyIds` to `copilot-likes`. Publish pushes the same bundle and version tags to both GHCR ids. New examples, `documentationURL`, and the docs site use `dev-agent-tools` only.
- **DEC-002**: Post-publish smoke includes a job that references `copilot-likes:latest` and runs `test/dev-agent-tools/test.sh` (ADR-0002), so a legacy tag that stops updating fails CI.
- **DEC-003**: Removing a `legacyIds` entry is a major compatibility change. It requires an explicit maintainer decision and a superseding ADR. Consumer docs may tell people to migrate, and may suggest an `AGENTS.md` note in consumer repositories so agents do not misread the legacy string. Docs do not delete the legacy publish by themselves.
- **DEC-004**: Later renames in this repository use the same mechanism: one canonical id, every previous id listed in `legacyIds`, smoke coverage for each id that still publishes.

## Consequences

### Positive

- **POS-001**: Existing `devcontainer.json` files that reference `copilot-likes` receive the same install as `dev-agent-tools` on each publish.
- **POS-002**: New configs and agent-written configs can use an id that does not imply the GitHub Copilot product.
- **POS-003**: Smoke on the legacy id detects a publish that updates only the canonical package.

### Negative

- **NEG-001**: Two GHCR names remain for one feature. Agents and humans can still misread `copilot-likes` until consumers migrate.
- **NEG-002**: Each legacy id adds a post-publish job and doubles tag maintenance on the registry for that feature.
- **NEG-003**: The compatibility promise has no scheduled end. The registry will keep growing aliases until a future ADR removes them.

## Alternatives Considered

### Breaking rename

- **ALT-001**: **Description**: Change the feature id to `dev-agent-tools` and stop pushing `copilot-likes`.
- **ALT-002**: **Rejection Reason**: Published references would 404 or freeze on the last old tag. Consumers would need a coordinated edit with no install path during the gap.

### Canonical id remains `copilot-likes`

- **ALT-003**: **Description**: Keep the original id forever and document that it is unrelated to GitHub Copilot.
- **ALT-004**: **Rejection Reason**: The id string is what agents read. Documentation does not stop an automated refactor from treating the key as a Copilot product reference. The canonical id should describe the CLI bundle.

### Repository-level redirect outside `legacyIds`

- **ALT-005**: **Description**: Publish only `dev-agent-tools` and document a manual GHCR copy or a second feature folder that duplicates `install.sh`.
- **ALT-006**: **Rejection Reason**: A second folder drifts. A manual copy is outside `devcontainers/action`. `legacyIds` is the spec mechanism that publishes one bundle to both ids.

## Implementation Notes

- **IMP-001**: Metadata is [src/dev-agent-tools/devcontainer-feature.json](../src/dev-agent-tools/devcontainer-feature.json). Consumer explanation is [docs/guides/legacy-feature-ids.md](../docs/guides/legacy-feature-ids.md).
- **IMP-002**: Smoke job `test-dev-agent-tools-legacy-id` in [test.yml](../.github/workflows/test.yml) must stay until `copilot-likes` is removed from `legacyIds`.
- **IMP-003**: Success is identical assertion results for `:latest` on both ids after publish. New consumer examples do not mention `copilot-likes` except on the legacy-id guide.

## References

- **REF-001**: [ADR-0001](adr-0001-ghcr-feature-publishing.md), [ADR-0002](adr-0002-pre-publish-and-post-publish-testing.md)
- **REF-002**: [docs/guides/legacy-feature-ids.md](../docs/guides/legacy-feature-ids.md); [docs/features/dev-agent-tools.md](../docs/features/dev-agent-tools.md)
- **REF-003**: Features metadata `legacyIds` in the [Dev Container Features spec](https://containers.dev/implementors/features/)
