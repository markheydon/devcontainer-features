---
title: "ADR-0008: Declare common-utils with installsAfter and let consumers omit it on Microsoft images"
status: "Accepted"
date: "2026-11-26"
authors: "Mark Heydon (repository owner)"
tags: ["architecture", "decision", "dependencies"]
supersedes: ""
superseded_by: ""
---

# ADR-0008: Declare common-utils with installsAfter and let consumers omit it on Microsoft images

## Status

Proposed | **Accepted** | Rejected | Superseded | Deprecated

## Context

`dev-agent-tools`, `spec-kit`, and `aspire-cli` assume a Debian-family image with `apt`, curl's CA certificates where they download files, and usually a non-root user with passwordless `sudo` and a writable home. The official [common-utils](https://github.com/devcontainers/features/tree/main/src/common-utils) feature provides that baseline on plain images such as `ubuntu:24.04`. Official Microsoft dev container images (`mcr.microsoft.com/devcontainers/base`, `dotnet`, `python`, and similar) are already built with common-utils applied. Listing it again adds a feature layer and can fail when a consumer forces UID or GID 1000 onto an image that already created the user.

The Dev Containers CLI treats `installsAfter` as a soft dependency: if the named feature is absent from the `features` block, install order still resolves and this feature still installs. G3 prefers composing common-utils to reimplementing user setup inside every `install.sh`.

## Decision

Every feature in this repository lists `ghcr.io/devcontainers/features/common-utils` in `installsAfter`, and consumer docs tell Microsoft-image users to omit common-utils from their `features` block.

- **DEC-001**: Metadata keeps `installsAfter` even though many consumers never list common-utils. Do not remove the field to shorten consumer examples.
- **DEC-002**: On pre-built `mcr.microsoft.com/devcontainers/*` images, examples omit common-utils. On plain or minimal bases, examples include `ghcr.io/devcontainers/features/common-utils:2` in the same `features` block so order is explicit.
- **DEC-003**: Feature install scripts do not create the `vscode` user, install sudo policy, or clone common-utils. They accept the user common-utils (or the Microsoft image) already created, and fall back to root when no non-root user is present.
- **DEC-004**: A future feature that needs common-utils follows the same metadata-plus-docs pattern. A feature that truly cannot install without common-utils must say so in its consumer page and still use `installsAfter` rather than a hard failure that only mentions a missing binary.

## Consequences

### Positive

- **POS-001**: Microsoft-image users get one features entry. Plain Ubuntu users get a defined order when they add common-utils.
- **POS-002**: Soft dependency matches the CLI, so omitting common-utils on a rich base image still installs the feature.
- **POS-003**: User and sudo setup stay upstream. This repository does not fork that behaviour per feature.
- **POS-004**: Spec Kit create-time sync can assume passwordless `sudo` on the images this policy recommends (ADR-0005).

### Negative

- **NEG-001**: On a plain image, omitting common-utils still "succeeds" the features resolution and can fail later (no sudo for Spec Kit sync, no non-root home for Aspire). The failure is downstream of install order, so metadata alone does not protect that user.
- **NEG-002**: Docs must keep two examples per feature. A single copy-paste snippet would be wrong for one of the two bases.
- **NEG-003**: `installsAfter` does not pin the common-utils major. Consumers who add it choose `:2` in examples today; metadata does not enforce that tag.

## Alternatives Considered

### Always require common-utils in the consumer features block

- **ALT-001**: **Description**: Document a hard dependency and fail `install.sh` when common-utils markers are absent.
- **ALT-002**: **Rejection Reason**: Microsoft images already include it. Forcing a second install duplicates users and has caused UID 1000 conflicts. The CLI's soft `installsAfter` is the supported way to order features only when both are requested.

### Drop `installsAfter` and mention common-utils only in prose

- **ALT-003**: **Description**: Remove `installsAfter` from `devcontainer-feature.json` so metadata matches the shortest Microsoft-image example.
- **ALT-004**: **Rejection Reason**: Plain bases would then have no machine-readable order. When both features are listed, common-utils must run first so the non-root user exists before Aspire and Spec Kit `chown` and sudo assumptions. Prose does not enforce that order.

### Vendor a minimal user-setup snippet in each install.sh

- **ALT-005**: **Description**: Create a `vscode` user and sudoers entry inside each feature when they are missing.
- **ALT-006**: **Rejection Reason**: That reimplements common-utils and will drift from upstream UID, shell, and sudo policy. G3 forbids that duplication.

## Implementation Notes

- **IMP-001**: All three `devcontainer-feature.json` files under `src/` set the same `installsAfter` entry. Consumer wording is [docs/guides/common-utils.md](../docs/guides/common-utils.md). The maintainer image [.devcontainer/devcontainer.json](../.devcontainer/devcontainer.json) omits common-utils because its base image already includes it.
- **IMP-002**: Pre-publish tests use Microsoft images from `official-base-images.txt` and therefore do not add common-utils. A plain-Ubuntu path is a documented consumer configuration, not the CI matrix.
- **IMP-003**: A change that deletes `installsAfter` is a policy change and needs a superseding ADR. Success for this decision is metadata present on every feature and docs that show both the omit case and the explicit case.

## References

- **REF-001**: [ADR-0004](adr-0004-aspire-cli-user-home-install.md), [ADR-0005](adr-0005-spec-kit-shared-uv-toolchain.md)
- **REF-002**: [GOALS.md](../GOALS.md) G3; [CONVENTIONS.md](../CONVENTIONS.md) feature metadata; [docs/guides/common-utils.md](../docs/guides/common-utils.md)
- **REF-003**: [common-utils](https://github.com/devcontainers/features/tree/main/src/common-utils), including its notes on using dev container images that already include the feature
