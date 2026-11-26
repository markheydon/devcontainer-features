---
title: "ADR-0001: Publish features to GHCR under the repository-owner namespace"
status: "Accepted"
date: "2026-11-26"
authors: "Mark Heydon (repository owner)"
tags: ["architecture", "decision", "publishing"]
supersedes: ""
superseded_by: ""
---

# ADR-0001: Publish features to GHCR under the repository-owner namespace

## Status

Proposed | **Accepted** | Rejected | Superseded | Deprecated

## Context

This repository exists so consumer `devcontainer.json` files can opt into small install scripts without a bespoke Dockerfile per repository (G1). The Dev Container Features specification distributes features as OCI artifacts. Consumers need a stable registry path, predictable version tags, and a publish step that runs only from the default branch. The namespace and OCI layout are costly to change once external repositories reference them.

## Decision

Publish every feature under `src/<feature-id>/` to GitHub Container Registry with `devcontainers/action` on push to `main`.

- **DEC-001**: Registry is `ghcr.io`. Feature namespace is `${{ github.repository_owner }}/devcontainer-features`, so the consumer reference is `ghcr.io/<owner>/devcontainer-features/<feature-id>:<tag>`.
- **DEC-002**: `base-path-to-features` is `./src`. Publish authenticates with `GITHUB_TOKEN` and `packages: write`. `generate-docs` stays enabled for the OCI annotation the action writes; the canonical consumer reference is the MkDocs site (ADR-0006).
- **DEC-003**: Each publish emits the semver from `devcontainer-feature.json` and the major-version alias (`:1` while versions stay in the `1.x` line). Consumer examples and `documentationURL` guidance use the major alias. Exact semver is for reproducible builds. `:latest` is reserved for post-publish smoke (ADR-0002).
- **DEC-004**: Changing `features-namespace`, the registry, or the OCI layout requires an explicit maintainer instruction and a superseding ADR.

## Consequences

### Positive

- **POS-001**: One features block entry is enough for consumers after merge to `main`.
- **POS-002**: The major alias absorbs patch releases without consumer config edits.
- **POS-003**: Namespace follows the GitHub repository owner, so a fork can publish under its own owner without editing the workflow body.
- **POS-004**: Publish is gated on `main`, matching the validate, lint, and pre-publish test workflows that run on pull requests first.

### Negative

- **NEG-001**: GHCR paths are a public contract. Renames need `legacyIds` (ADR-0007) or they break existing `devcontainer.json` files.
- **NEG-002**: `:1` moves when any `1.x` release ships. Consumers who need a frozen install must pin exact semver themselves.
- **NEG-003**: `generate-docs` output can drift from the MkDocs site if both are treated as canonical.

## Alternatives Considered

### Publish only from the local `src/` tree with no registry

- **ALT-001**: **Description**: Consumers would set feature references to a clone path or a git URL of this repository.
- **ALT-002**: **Rejection Reason**: That fails G1. External projects cannot depend on a stable feature id, and CI cannot smoke-test the same URI consumers use.

### Docker Hub or a registry other than GHCR

- **ALT-003**: **Description**: Push the same OCI artifacts to Docker Hub or another registry.
- **ALT-004**: **Rejection Reason**: `GITHUB_TOKEN` already grants GHCR package write on this repository. A second registry adds credentials and a second source of truth for tags.

### Prefer `:latest` in consumer examples

- **ALT-005**: **Description**: Document `ghcr.io/<owner>/devcontainer-features/<feature-id>:latest` as the default reference.
- **ALT-006**: **Rejection Reason**: `:latest` floats across major bumps. The major alias gives patch updates inside a chosen major without that jump.

## Implementation Notes

- **IMP-001**: Workflow is [.github/workflows/publish.yml](../.github/workflows/publish.yml). Permissions are `contents: read` and `packages: write`.
- **IMP-002**: Feature `version` in `devcontainer-feature.json` bumps when install-time behaviour changes, so the semver tag and `:1` alias move together.
- **IMP-003**: Success is a GHCR package per feature id after merge, with the semver tag matching metadata. Smoke tests (ADR-0002) must resolve `:latest` for that id.

## References

- **REF-001**: [ADR-0002](adr-0002-pre-publish-and-post-publish-testing.md), [ADR-0006](adr-0006-consumer-docs-on-github-pages.md), [ADR-0007](adr-0007-legacy-feature-ids-on-rename.md)
- **REF-002**: [GOALS.md](../GOALS.md) G1; [CONVENTIONS.md](../CONVENTIONS.md) versioning and publishing
- **REF-003**: [Dev Container Features distribution](https://containers.dev/implementors/features-distribution/); [devcontainers/action](https://github.com/devcontainers/action)
