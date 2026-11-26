# Aspire CLI

Installs the **Aspire CLI** under the container user’s home via the [official installer](https://aspire.dev/install.sh), with optional bundle setup and create-time alignment to the repo Aspire SDK pin.

Unlike `ghcr.io/microsoft/aspire-devcontainer-feature/aspire`, this feature installs under `~/.aspire` so bundle setup works reliably for non-root users. **Bundle layout root** is `ASPIRE_LAYOUT_PATH` (default `~/.aspire`); Aspire 17+ creates `bundle/` as a symlink under that root, not the layout path itself. It does **not** install a .NET SDK—use `mcr.microsoft.com/devcontainers/dotnet` or the official `dotnet` feature when you need the SDK.

**GHCR:** `ghcr.io/markheydon/devcontainer-features/aspire-cli:1`

## Why not Microsoft’s `aspire` feature?

Consumers often ask why this repository publishes **`aspire-cli`** instead of [`ghcr.io/microsoft/aspire-devcontainer-feature/aspire`](https://github.com/microsoft/aspire-devcontainer-feature). Both install the same upstream CLI from [aspire.dev/install.sh](https://aspire.dev/install.sh); the difference is **layout, user identity, and lifecycle**.

| Topic | Microsoft `aspire` feature | This `aspire-cli` feature |
|--------|----------------------------|---------------------------|
| **CLI on PATH** | Copies `aspire` to **`/usr/local/bin`** (installer runs as root during feature install) | Installs under the **container user’s** `~/.aspire/bin` |
| **Bundle setup** | Does **not** run `aspire setup` at image build | Optional **`aspire setup --non-interactive`** at install and after SDK sync |
| **VS Code / tasks** | Often works without extra `remoteEnv` because of `/usr/local/bin` | Use **`remoteEnv`** or login shells so non-interactive tools see `~/.aspire/bin` |
| **SDK pin alignment** | None | **`sync-aspire-version.sh`** on create when `aspireVersion: latest` and the repo has a single Aspire SDK pin |

**When Microsoft’s feature is enough:** you only need the CLI on PATH, you are fine with `/usr/local`, and you do not need eager bundle setup or create-time CLI/SDK alignment.

**Why we added `aspire-cli`:** validated on [Potsure](https://github.com/markheydon/potsure) with `mcr.microsoft.com/devcontainers/dotnet`, Docker-in-Docker, and AppHost workflows as non-root **`vscode`**. With Microsoft’s feature, `aspire` resolved to **`/usr/local/bin/aspire`** and bundle/setup work under **`/usr/local`** or root-owned paths was unreliable for a user-writable layout. A home-directory install plus explicit setup matches [Aspire’s bundle layout](https://github.com/microsoft/aspire/blob/main/docs/specs/bundle.md) for non-root dev containers. Background: [devcontainer-features#24](https://github.com/markheydon/devcontainer-features/issues/24).

## What gets installed

| Component | How |
|-----------|-----|
| **Aspire CLI** | Official `https://aspire.dev/install.sh` → `~/.aspire/bin/aspire` |
| **Bundle layout** | Optional `aspire setup --non-interactive` with layout root `ASPIRE_LAYOUT_PATH` (default `~/.aspire`; Aspire 17+ creates `bundle/` as a symlink there) |
| **Shell PATH** | `/etc/profile.d/aspire-cli.sh` and a marked block in the user’s `.bashrc` / `.profile` |

`apt`: `ca-certificates`, `curl`, `python3-minimal` (installer download and create-time SDK pin detection).

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `aspireVersion` | `latest` | Aspire CLI version for the installer, or `latest` for the selected `quality` at image build with repo alignment on create when an SDK pin is found. |
| `quality` | `release` | Installer channel when `aspireVersion` is `latest` (`release`, `staging`, `dev`). Ignored when `aspireVersion` is pinned. |
| `bundlePath` | *(empty)* | Aspire layout root for setup and `ASPIRE_LAYOUT_PATH`. Empty uses `$HOME/.aspire` for the container user. See [Upgrading from earlier `aspire-cli` versions](#upgrading-from-earlier-aspire-cli-versions) if you previously used `…/.aspire/bundle` here. |
| `runSetupOnInstall` | `true` | Run `aspire setup --non-interactive` after install or CLI sync. |

## Example `devcontainer.json`

**Microsoft dev container base (recommended):** images such as `mcr.microsoft.com/devcontainers/dotnet:latest` already include [common-utils](https://github.com/devcontainers/features/tree/main/src/common-utils); do not list it again.

```json
{
  "image": "mcr.microsoft.com/devcontainers/dotnet:latest",
  "features": {
    "ghcr.io/markheydon/devcontainer-features/aspire-cli:1": {
      "aspireVersion": "latest"
    }
  }
}
```

Pin `aspireVersion` to a semver (for example `"17.0.0"`) when you need reproducible image builds instead of `latest`.

Login and interactive bash shells pick up `aspire` on `PATH` from `/etc/profile.d/aspire-cli.sh` and the user’s `.bashrc` / `.profile` snippet—no extra `devcontainer.json` configuration required for typical CLI use in the terminal.

**Plain or minimal base:** when your image does not already provide common-utils, add it so `installsAfter` ordering is explicit:

```json
{
  "image": "ubuntu:24.04",
  "features": {
    "ghcr.io/devcontainers/features/common-utils:2": {},
    "ghcr.io/markheydon/devcontainer-features/aspire-cli:1": {}
  }
}
```

Metadata sets `installsAfter` [common-utils](https://github.com/devcontainers/features/tree/main/src/common-utils) so common-utils runs before this feature when both are in the `features` block.

## Container environment

The CLI lives under the container user’s home, not `/usr/local/bin`. Feature metadata cannot set `containerEnv` paths that depend on that home directory—the devcontainers spec does not expand `_REMOTE_USER_HOME` in `devcontainer-feature.json` ([devcontainers/cli#391](https://github.com/devcontainers/cli/issues/391)).

For **Aspire VS Code extension**, tasks, or other processes that do not run a login shell, add `remoteEnv` so `~/.aspire/bin` is on `PATH` and layout variables are set:

```json
"remoteEnv": {
  "PATH": "${containerEnv:HOME}/.aspire/bin:${containerEnv:PATH}",
  "ASPIRE_HOME": "${containerEnv:HOME}/.aspire",
  "ASPIRE_LAYOUT_PATH": "${containerEnv:HOME}/.aspire"
}
```

You can omit `remoteEnv` when you only use `aspire` from a login or interactive bash terminal.

On each feature install, `/etc/profile.d/aspire-cli.sh` treats a stale `ASPIRE_LAYOUT_PATH` of `~/.aspire/bundle` as the layout root `~/.aspire`, and reinstall replaces the marked block in the user’s `.bashrc` / `.profile` so a rebuild picks up the correct value even when `remoteEnv` in `devcontainer.json` is unchanged.

## Upgrading from earlier `aspire-cli` versions

Earlier releases defaulted the layout path to `~/.aspire/bundle`. **Aspire 17+** expects the layout root at `~/.aspire`, with `bundle/` created as a symlink there ([bundle spec](https://github.com/microsoft/aspire/blob/main/docs/specs/bundle.md)).

1. Set **`bundlePath`** (if used) and **`remoteEnv.ASPIRE_LAYOUT_PATH`** to the layout root (`…/.aspire`), not `…/.aspire/bundle`.
2. **Rebuild** the dev container so install rewrites shell snippets and refreshes `/etc/profile.d/aspire-cli.sh`.
3. With a **persisted home volume**, remove a non-symlink `~/.aspire/bundle` directory if setup still reports legacy layout errors. Install removes an empty legacy directory—or one left after versions exist under `~/.aspire/versions`—before `aspire setup` when `runSetupOnInstall` is enabled.

## After the container builds

With `aspireVersion: latest` (the default), `postCreateCommand` runs `/usr/local/share/aspire-cli/sync-aspire-version.sh`. When the workspace contains a single Aspire SDK pin (for example `aspire.config.json` → `sdk.version`, or `Aspire.Hosting.AppHost` / `Aspire.AppHost.Sdk` in project files) and the installed CLI differs, the script reinstalls that CLI version and re-runs setup when enabled. Sync only runs when `aspireVersion` was `latest` at image build. Multiple conflicting SDK pins or a missing `python3` at create time fail the sync step instead of succeeding silently.

Post-publish CI includes a **workflow** smoke job that builds a dev container against a minimal Aspire app workspace and runs `aspire run` from the project root via a login shell (described in the feature README under Testing).

The official installer script is fetched from `https://aspire.dev/install.sh` without a checksum pin (Aspire does not publish a stable checksum for that URL). Pin `aspireVersion` when you need reproducible installs or stricter supply-chain control.

**Certificate trust:** this feature does not run `aspire certs trust`. Add a consumer `postStartCommand` when you need dev HTTPS trust, for example:

```json
"postStartCommand": "aspire certs trust --non-interactive"
```

## Caveats

- Intended for Debian-family images with `apt` and a non-root dev user with a writable home (typical Microsoft dev container images).
- CLI and bundle state live under the container user’s home; persist that volume if you expect upgrades across rebuilds without re-running setup.

## Common-utils

On Microsoft dev container bases, omit common-utils. On plain Ubuntu images, add `ghcr.io/devcontainers/features/common-utils:2` before aspire-cli. See [Common-utils dependency](../guides/common-utils.md).

## Source and contributing

- [Source on GitHub](https://github.com/markheydon/devcontainer-features/tree/main/src/aspire-cli)
- [Report an issue](https://github.com/markheydon/devcontainer-features/issues)
- [Contributing](../contributing.md)