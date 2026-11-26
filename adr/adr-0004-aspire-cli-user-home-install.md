---
title: "ADR-0004: Install the Aspire CLI into the container user's home"
status: "Accepted"
date: "2026-11-26"
authors: "Mark Heydon (repository owner)"
tags: ["architecture", "decision", "aspire-cli"]
supersedes: ""
superseded_by: ""
---

# ADR-0004: Install the Aspire CLI into the container user's home

## Status

Proposed | **Accepted** | Rejected | Superseded | Deprecated

## Context

Aspire's CLI and bundle layout are per-user. Aspire 17+ uses `~/.aspire` as the layout root and creates `bundle/` as a symlink under that root. Dev containers on Microsoft .NET images run day-to-day as a non-root user (`vscode`) with a writable home. Feature install itself runs as root.

Microsoft publishes [`ghcr.io/microsoft/aspire-devcontainer-feature/aspire`](https://github.com/microsoft/aspire-devcontainer-feature), which installs the same upstream CLI by running [aspire.dev/install.sh](https://aspire.dev/install.sh) as root and copying `aspire` to `/usr/local/bin`. That layout was unreliable for non-root bundle setup on [Potsure](https://github.com/markheydon/potsure) (`mcr.microsoft.com/devcontainers/dotnet`, Docker-in-Docker, AppHost as `vscode`): `aspire` resolved to `/usr/local/bin/aspire`, and bundle files under root-owned paths were not a user-writable layout. See [devcontainer-features#24](https://github.com/markheydon/devcontainer-features/issues/24).

The features spec does not expand `_REMOTE_USER_HOME` inside `containerEnv` ([devcontainers/cli#391](https://github.com/devcontainers/cli/issues/391)), so a home-directory install cannot put `PATH` in feature metadata.

This feature does not provide the .NET SDK. Images or the official `dotnet` feature remain the SDK.

## Decision

`aspire-cli` installs the official Aspire CLI as the container user into that user's `~/.aspire`, and treats Microsoft's feature as a different product for consumers who want a root-installed binary on the default `PATH`.

- **DEC-001**: Download `https://aspire.dev/install.sh` at install time and run it with `--skip-path -i <home>/.aspire/bin` as the container user (`_REMOTE_USER` when set and not root, otherwise `vscode` when that account exists, otherwise root). Aspire does not publish a stable checksum for that URL. Reproducible or stricter supply-chain installs set `aspireVersion` to an exact semver. `quality` applies only when `aspireVersion` is `latest`; combining a pin with a non-release quality fails the install.
- **DEC-002**: Default layout root is `<home>/.aspire` (`ASPIRE_HOME` and `ASPIRE_LAYOUT_PATH`). `bundlePath` overrides the layout root. Before `aspire setup`, remove a legacy non-symlink `<home>/.aspire/bundle` directory when it is empty or when `<home>/.aspire/versions` already contains versions. Default `runSetupOnInstall` runs `aspire setup --non-interactive` after install and after create-time sync (ADR-0003).
- **DEC-003**: Expose the CLI through `/etc/profile.d/aspire-cli.sh` and a marked block in the user's `.bashrc` and `.profile`. Remove a stale `/usr/local/bin/aspire` on install. Document consumer `remoteEnv` for processes that are not login or interactive bash (Aspire VS Code extension, tasks). Do not set home-relative paths via `containerEnv`.
- **DEC-004**: Do not install the .NET SDK, VS Code extensions, or certificate trust. Certificate trust stays a consumer `postStartCommand` (`aspire certs trust --non-interactive`).

## Consequences

### Positive

- **POS-001**: Bundle setup writes a layout the non-root dev user owns, matching Aspire's bundle spec for version 17 and later.
- **POS-002**: Create-time SDK alignment (ADR-0003) reinstalls into the same home directory the user will run.
- **POS-003**: Login and interactive bash pick up `PATH` without `remoteEnv`. Consumers who only use the terminal do not copy extra JSON.
- **POS-004**: Removing `/usr/local/bin/aspire` stops an older root install from shadowing `~/.aspire/bin/aspire` for users who previously applied the Microsoft feature in the same image lineage.

### Negative

- **NEG-001**: Non-interactive tools do not see `~/.aspire/bin` unless the consumer sets `remoteEnv` or runs a login shell. Workflow smoke therefore invokes `aspire run` through a login shell.
- **NEG-002**: The installer URL is unpinned. A compromised or breaking change at `aspire.dev/install.sh` affects every `latest` and pinned install that still downloads that script. The version flag pins the CLI payload, not the installer script.
- **NEG-003**: CLI and bundle state live in the home directory. Rebuilds without a persisted home repeat setup. A persisted home can keep a legacy `bundle/` directory that install only deletes in the cases in DEC-002.
- **NEG-004**: Two Aspire features exist in the ecosystem. Consumers must choose. This repository does not wrap or replace the Microsoft feature id.

## Alternatives Considered

### Depend on Microsoft's `aspire` feature

- **ALT-001**: **Description**: List `ghcr.io/microsoft/aspire-devcontainer-feature/aspire` as the supported way to install the CLI and do not publish `aspire-cli`.
- **ALT-002**: **Rejection Reason**: That feature's root install to `/usr/local/bin` does not provide user-writable bundle setup or create-time alignment to the repo SDK pin. Those are the behaviours this feature exists to provide. Teams that only need the CLI on the default `PATH` should use the Microsoft feature.

### Run the official installer as root into `/usr/local`

- **ALT-003**: **Description**: Keep `aspire` on the default `PATH` by installing as root to `/usr/local/bin`, and run `aspire setup` as root.
- **ALT-004**: **Rejection Reason**: That recreates the Potsure failure mode: bundle and layout files are not owned by `vscode`, and `ASPIRE_LAYOUT_PATH` does not follow the per-user bundle spec.

### Vendor a checksummed CLI tarball

- **ALT-005**: **Description**: Download a versioned Aspire CLI release asset, verify a checksum stored in this repository, and skip `aspire.dev/install.sh`.
- **ALT-006**: **Rejection Reason**: The supported upstream install path is the official installer, including quality channels (`release`, `staging`, `dev`). A vendored tarball would track asset names and checksums on every Aspire release and would drift from installer behaviour (`--skip-path`, install directory, quality).

## Implementation Notes

- **IMP-001**: Implementation is [src/aspire-cli/install.sh](../src/aspire-cli/install.sh) and [src/aspire-cli/devcontainer-feature.json](../src/aspire-cli/devcontainer-feature.json). `installsAfter` common-utils follows ADR-0008.
- **IMP-002**: Tests assert `aspire` is under `~/.aspire/bin` and that `/usr/local/bin/aspire` is absent. CLI 17+ must have `~/.aspire/bundle` as a symlink when setup runs.
- **IMP-003**: A successful install for the default options leaves `aspire --version` working in a login shell as the container user and a completed non-interactive setup. Extension and task scenarios still need the documented `remoteEnv`.

## References

- **REF-001**: [ADR-0003](adr-0003-create-time-version-sync-for-latest.md), [ADR-0008](adr-0008-common-utils-as-soft-installs-after.md)
- **REF-002**: [docs/features/aspire-cli.md](../docs/features/aspire-cli.md); [issue #24](https://github.com/markheydon/devcontainer-features/issues/24)
- **REF-003**: [Aspire bundle spec](https://github.com/microsoft/aspire/blob/main/docs/specs/bundle.md); [devcontainers/cli#391](https://github.com/devcontainers/cli/issues/391)
