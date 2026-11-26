# Aspire CLI

Dev Container feature that installs the [Aspire CLI](https://aspire.dev/) into the container user’s home directory (`~/.aspire/bin`) using the official installer, runs optional bundle setup, and can align the CLI to the repo’s Aspire SDK pin on first container create.

Unlike `ghcr.io/microsoft/aspire-devcontainer-feature/aspire`, this feature does **not** install under `/usr/local`, which avoids bundle permission issues for non-root users on Microsoft .NET dev container images.

This feature does **not** install a .NET SDK. Use `mcr.microsoft.com/devcontainers/dotnet` or the official `dotnet` feature when you need the SDK.

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

## Consumer `devcontainer.json`

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

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `aspireVersion` | `latest` | Aspire CLI version for the installer, or `latest` for the selected `quality` at image build with repo alignment on create when an SDK pin is found. |
| `quality` | `release` | Installer channel when `aspireVersion` is `latest` (`release`, `staging`, `dev`). Ignored when `aspireVersion` is pinned. |
| `bundlePath` | *(empty)* | Aspire layout root for setup and `ASPIRE_LAYOUT_PATH`. Empty uses `$HOME/.aspire` for the container user. **Migration:** if you previously set this to `…/.aspire/bundle`, point it at the layout root (`…/.aspire`) instead—Aspire 17+ keeps `bundle/` as a symlink under that root. |
| `runSetupOnInstall` | `true` | Run `aspire setup --non-interactive` after install or CLI sync. |

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

You can omit `remoteEnv` when you only use `aspire` from a login or interactive bash terminal (see above).

## After the container builds

With `aspireVersion: latest` (the default), `postCreateCommand` runs `/usr/local/share/aspire-cli/sync-aspire-version.sh`. When the workspace contains a single Aspire SDK pin (for example `aspire.config.json` → `sdk.version`, or `Aspire.Hosting.AppHost` / `Aspire.AppHost.Sdk` in project files) and the installed CLI differs, the script reinstalls that CLI version and re-runs setup when enabled. Sync only runs when `aspireVersion` was `latest` at image build. Multiple conflicting SDK pins or a missing `python3` at create time fail the sync step instead of succeeding silently.

The official installer script is fetched from `https://aspire.dev/install.sh` without a checksum pin (Aspire does not publish a stable checksum for that URL). Pin `aspireVersion` when you need reproducible installs or stricter supply-chain control.

**Certificate trust:** this feature does not run `aspire certs trust`. Add a consumer `postStartCommand` when you need dev HTTPS trust, for example:

```json
"postStartCommand": "aspire certs trust --non-interactive"
```

## Contrast with Microsoft’s Aspire feature

`ghcr.io/microsoft/aspire-devcontainer-feature/aspire` installs the CLI for a system-wide layout under `/usr/local`, copies `aspire` to `/usr/local/bin` for non-login shells, and does not run `aspire setup` at image build. For Docker-in-Docker and AppHost workflows as a non-root user, bundle extraction under paths the user cannot write reliably is a known pain point. This feature follows the [official installer](https://aspire.dev/install.sh) layout under `~/.aspire` instead and runs optional bundle setup with the correct layout root for Aspire 17+.

## Testing

CI runs `test/aspire-cli/test.sh`, which asserts the CLI location, `aspire setup`, a `~/.aspire/bundle` symlink when the CLI is Aspire 17+, an **`aspire run`** bundle smoke (minimal AppHost; sources under `test/aspire-cli/fixtures/run-smoke/`, materialised in `test.sh` on images with the .NET SDK), and simulates `postCreate` sync against a fixture `sdk.version`. The pin lives in `test/aspire-cli/sync-target-version.txt` (override with `ASPIRE_CLI_SYNC_TARGET_VERSION`). Post-publish smoke writes the same pin into `aspire.config.json` and uses `ASPIRE_CLI_SYNC_VERIFY_ONLY=1` after `devcontainer up`.

**If sync tests fail** because release `latest` equals the pin or the pin is unavailable from the installer: choose an older version still published on the Aspire download feeds (for example below current release `17.0.0`) and update `test/aspire-cli/sync-target-version.txt`.

Manual check (with Docker on the host):

```bash
shellcheck src/aspire-cli/install.sh
./scripts/test-features.sh aspire-cli mcr.microsoft.com/devcontainers/dotnet:latest
```

## Development in this repository

Unpublished installs use a repo-relative path:

```json
"features": {
  "../src/aspire-cli": {}
}
```

See the root [CONTRIBUTING.md](../../CONTRIBUTING.md) for ShellCheck, `./scripts/test-features.sh`, and versioning rules.