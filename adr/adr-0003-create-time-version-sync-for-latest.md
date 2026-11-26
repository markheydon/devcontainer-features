---
title: "ADR-0003: Align latest tool installs to the consumer repository on create"
status: "Accepted"
date: "2026-11-26"
authors: "Mark Heydon (repository owner)"
tags: ["architecture", "decision", "lifecycle"]
supersedes: ""
superseded_by: ""
---

# ADR-0003: Align latest tool installs to the consumer repository on create

## Status

Proposed | **Accepted** | Rejected | Superseded | Deprecated

## Context

Feature install runs while the image is built. The consumer workspace is available later, at container create. `spec-kit` and `aspire-cli` default their tool version to `latest`, which is resolved from PyPI or the Aspire installer at image build. The repository being opened may pin a different Specify or Aspire SDK version (`.specify/init-options.json` `speckit_version`, or a single Aspire SDK pin in `aspire.config.json` and project files). Rebuilding the image for every pin change is the wrong lifecycle: the pin is a property of the workspace, and prebuilt images are shared.

Both features already ship this behaviour. A pinned feature option means the image build is the only install, and create must not override it.

## Decision

When the version option is `latest`, install the current upstream release at image build, and generate a `postCreateCommand` script that reinstalls the workspace pin when it differs. A pinned version option skips that sync.

- **DEC-001**: `spec-kit` writes `/usr/local/share/spec-kit/sync-specify-version.sh` and sets `postCreateCommand` to it. The script reads `.specify/init-options.json`. It no-ops when `specifyVersion` was not `latest`, when the file has no `speckit_version`, or when the installed tool already matches. Conflicting or unreadable input that the script treats as absent does not force a reinstall.
- **DEC-002**: `aspire-cli` writes `/usr/local/share/aspire-cli/sync-aspire-version.sh` and sets `postCreateCommand` to it. The script scans the workspace (bounded depth, skipping `bin`, `obj`, `node_modules`, and `.git`) for one Aspire SDK version. It no-ops when `aspireVersion` was not `latest` or when no pin exists. Multiple distinct pins, or a missing `python3` when a parse is required, fail the create step.
- **DEC-003**: The generated script embeds the install-time options (`managedPython` / `pythonVersion` / `quality` / `bundlePath` / `runSetupOnInstall`) so create-time reinstall follows the same rules as the image build. Sync may re-run setup when that option is enabled. It does not run `specify init` or `aspire certs trust`.
- **DEC-004**: Sync scripts live on the image under `/usr/local/share/<feature-id>/`. They are root-owned feature assets, not files written into the consumer repository.

## Consequences

### Positive

- **POS-001**: A shared image built with `latest` still opens a repository on the CLI version that repository recorded.
- **POS-002**: Pinning the feature option gives a reproducible image with no create-time network install.
- **POS-003**: Option values are baked into the script at install, so create does not re-read feature metadata.
- **POS-004**: Failing closed on several Aspire pins avoids upgrading the CLI to an arbitrary match.

### Negative

- **NEG-001**: `latest` plus an existing pin still contacts PyPI or `aspire.dev` on first create. Air-gapped use requires a pinned feature option.
- **NEG-002**: Spec Kit reinstall needs passwordless `sudo` when `postCreateCommand` runs as a non-root user, because tools live under `/opt/uv` (ADR-0005).
- **NEG-003**: Image-build `latest` and the workspace pin can diverge until create finishes. Tools that run before `postCreateCommand` see the image version.
- **NEG-004**: Aspire's tree walk can miss pins deeper than the depth cap or outside the recognised file patterns, and then leave the image-build CLI in place.

## Alternatives Considered

### Require consumers to pin the feature option

- **ALT-001**: **Description**: Remove `latest` defaults and document only exact `specifyVersion` and `aspireVersion` values.
- **ALT-002**: **Rejection Reason**: Most consumers want current upstream at image build and alignment when the repo already records a version. Forcing a feature-option pin duplicates the pin the repo already has and goes stale independently.

### Reinstall on every container start

- **ALT-003**: **Description**: Use `postStartCommand` to resolve `latest` or the repo pin on every start.
- **ALT-004**: **Rejection Reason**: Start would pay network and install cost repeatedly. `postCreateCommand` runs once per container create, which matches a version change that should persist in that container.

### Read the workspace pin during feature install

- **ALT-005**: **Description**: Detect `speckit_version` or the Aspire SDK pin inside `install.sh` and install that version into the image.
- **ALT-006**: **Rejection Reason**: Feature install runs at image build, before the consumer workspace is the mounted project. A prebuilt image cannot know the next repository's pin. Pre-publish tests also install onto base images without that repository present.

## Implementation Notes

- **IMP-001**: Tests simulate create by running the sync script as the non-root container user. Pins live in `test/spec-kit/sync-target-version.txt` and `test/aspire-cli/sync-target-version.txt` and must stay resolvable and different from current upstream `latest` when the assertion expects a reinstall.
- **IMP-002**: Post-publish smoke for Spec Kit writes the pin into `.specify/init-options.json` on the checkout. Aspire sync smoke uses a separate workspace (ADR-0002) because the scanner walks the tree.
- **IMP-003**: A successful create with `latest` either leaves the CLI unchanged when no single differing pin exists, or reports the repo version after reinstall. A pinned feature option leaves the baked version in place even if the workspace disagrees.

## References

- **REF-001**: [ADR-0002](adr-0002-pre-publish-and-post-publish-testing.md), [ADR-0004](adr-0004-aspire-cli-user-home-install.md), [ADR-0005](adr-0005-spec-kit-shared-uv-toolchain.md)
- **REF-002**: [docs/features/spec-kit.md](../docs/features/spec-kit.md), [docs/features/aspire-cli.md](../docs/features/aspire-cli.md)
- **REF-003**: Dev Container lifecycle hooks (`postCreateCommand` on the feature contribution) in the [Features spec](https://containers.dev/implementors/features/)
