---
title: "ADR-0005: Ship Spec Kit as a shared uv toolchain without the Python feature"
status: "Accepted"
date: "2026-11-26"
authors: "Mark Heydon (repository owner)"
tags: ["architecture", "decision", "spec-kit"]
supersedes: ""
superseded_by: ""
---

# ADR-0005: Ship Spec Kit as a shared uv toolchain without the Python feature

## Status

Proposed | **Accepted** | Rejected | Superseded | Deprecated

## Context

GitHub Spec Kit's Specify CLI is a Python tool installed with uv. Many consumers want `specify` on a Dev Container image and do not want the VS Code Python extension stack that `ghcr.io/devcontainers/features/python` installs. Microsoft .NET images often ship `python3-minimal`: the interpreter can be 3.11 or newer and still lack stdlib modules Specify needs (for example `uuid`). G3 says to compose official features where they match the need, and to avoid a second full language stack where they do not.

uv's default tool and cache directories sit in the installing user's home. Feature install runs as root, while `postCreateCommand` and later `uv` commands run as the container user. A root-only store would make create-time reinstall and day-to-day `specify` fail for `vscode`.

## Decision

`spec-kit` installs a pinned uv, an optional uv-managed Python, and `specify-cli` into a shared prefix that the container user can update.

- **DEC-001**: Install uv from the Astral GitHub release tarball for `uvVersion` (default a pinned semver with no leading `v`). Verify the upstream `.sha256` asset before copying `uv` and `uvx` to `/usr/local/bin`. Unsupported `uname -m` values fail the install.
- **DEC-002**: Keep uv state under `/opt/uv` via `UV_TOOL_DIR`, `UV_PYTHON_INSTALL_DIR`, and `UV_CACHE_DIR`. Put tool and Python executables on `/usr/local/bin` (`UV_TOOL_BIN_DIR`, `UV_PYTHON_BIN_DIR`). Set those variables in feature `containerEnv`. After install, `chown` `/opt/uv` to the container user when that user exists, and `chmod -R a+rwX` the prefix so create-time sync can restore write access.
- **DEC-003**: `managedPython` defaults to `auto`. Skip `uv python install` when `python3` on `PATH` is 3.11 or newer and passes a stdlib probe (`json`, `shutil`, `sys`, `uuid`). `always` installs `pythonVersion` (default `3.12`). `never` fails if that probe fails, and the error tells the consumer to add the official Python feature or switch to `auto`. When managed Python installs and `_REMOTE_USER_HOME` is set, write `<home>/.config/uv/.python-version`.
- **DEC-004**: Install PyPI package `specify-cli` with `uv tool install`. Do not run `specify init`. Do not depend on `ghcr.io/devcontainers/features/python` or `ghcr.io/devcontainers-extra/features/uv`. Consumers may add the official Python feature themselves; `auto` then skips a second interpreter when the probe passes. Create-time reinstall (ADR-0003) uses passwordless `sudo` when the create user is not root.

## Consequences

### Positive

- **POS-001**: A base image gains `specify` without VS Code Python extensions or a second uv feature.
- **POS-002**: The stdlib probe avoids using `python3-minimal` on .NET images for Specify, and avoids a redundant interpreter when a healthy `python3` is already present.
- **POS-003**: Checksum verification on the uv tarball matches the repository rule for third-party GitHub downloads.
- **POS-004**: `/usr/local/bin` binaries are on the default `PATH` for non-login commands, unlike the Aspire home-directory layout (ADR-0004).

### Negative

- **NEG-001**: `/opt/uv` is world-writable. A container with several Unix users does not isolate uv caches or tool environments.
- **NEG-002**: Create-time sync requires passwordless `sudo` on images where create runs as non-root. Plain bases without common-utils or equivalent sudo fail that reinstall.
- **NEG-003**: `armv7l` can install the uv tarball and still fail `specify-cli` if PyPI has no matching wheel.
- **NEG-004**: Pinned `uvVersion` lags upstream until a feature release bumps it. That is deliberate; floating uv would change the toolchain without a version bump.

## Alternatives Considered

### Require the official Python feature

- **ALT-001**: **Description**: Document `ghcr.io/devcontainers/features/python` as a hard dependency and install only `specify-cli` with the system interpreter.
- **ALT-002**: **Rejection Reason**: That feature installs IDE integrations this feature's description excludes. `python3-minimal` on .NET images would still fail the stdlib probe, so a managed interpreter would remain necessary. Composition stays optional via `managedPython: auto`.

### Use `devcontainers-extra` uv and per-user uv directories

- **ALT-003**: **Description**: Depend on `ghcr.io/devcontainers-extra/features/uv` and leave `UV_TOOL_DIR` at the uv default under `$HOME`.
- **ALT-004**: **Rejection Reason**: A second uv feature conflicts with the copy this feature must own (version pin and checksum). A root install into `$HOME` would store tools in `/root`, which tests explicitly reject, and create-time sync running as `vscode` would not see them.

### Install uv with the upstream `curl | sh` installer

- **ALT-005**: **Description**: Run Astral's install script from the network without a checked checksum.
- **ALT-006**: **Rejection Reason**: The repository forbids unpinned remote installers when a versioned, checksummed asset exists. The uv release tarball provides both. The Aspire installer exception (ADR-0004) does not apply here.

## Implementation Notes

- **IMP-001**: Implementation is [src/spec-kit/install.sh](../src/spec-kit/install.sh) and [src/spec-kit/devcontainer-feature.json](../src/spec-kit/devcontainer-feature.json).
- **IMP-002**: Tests assert `uv`, `specify` on `/usr/local/bin` (not under `/root`), `specify version`, Python 3.11 or newer via `uv run`, and the sync script path. `PYTHONVERSION` in CI must match the feature's `pythonVersion` default.
- **IMP-003**: A default install on `mcr.microsoft.com/devcontainers/base:ubuntu` and on the .NET image leaves `specify version` working for the container user. Combining with `devcontainers-extra` uv is unsupported.

## References

- **REF-001**: [ADR-0003](adr-0003-create-time-version-sync-for-latest.md), [ADR-0004](adr-0004-aspire-cli-user-home-install.md), [ADR-0008](adr-0008-common-utils-as-soft-installs-after.md)
- **REF-002**: [GOALS.md](../GOALS.md) G3; [docs/features/spec-kit.md](../docs/features/spec-kit.md)
- **REF-003**: [Spec Kit installation](https://github.github.io/spec-kit/installation.html); [uv releases](https://github.com/astral-sh/uv/releases)
