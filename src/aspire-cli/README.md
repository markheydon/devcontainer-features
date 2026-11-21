# Aspire CLI

Dev Container feature that installs the [Aspire CLI](https://aspire.dev/) into the container user’s home directory (`~/.aspire/bin`) using the official installer, runs optional bundle setup, and can align the CLI to the repo’s Aspire SDK pin on first container create.

Unlike `ghcr.io/microsoft/aspire-devcontainer-feature/aspire`, this feature does **not** install under `/usr/local`, which avoids bundle permission issues for non-root users on Microsoft .NET dev container images.

This feature does **not** install a .NET SDK. Use `mcr.microsoft.com/devcontainers/dotnet` or the official `dotnet` feature when you need the SDK.

## What gets installed

| Component | How |
|-----------|-----|
| **Aspire CLI** | Official `https://aspire.dev/install.sh` → `~/.aspire/bin/aspire` |
| **Bundle layout** | Optional `aspire setup --non-interactive` into `ASPIRE_LAYOUT_PATH` (default `~/.aspire/bundle`) |
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
| `bundlePath` | *(empty)* | Directory for `aspire setup`. Empty uses `$HOME/.aspire/bundle` for the container user. |
| `runSetupOnInstall` | `true` | Run `aspire setup --non-interactive` after install or CLI sync. |

## Container environment

The CLI lives under the container user’s home, not `/usr/local/bin`. Feature metadata cannot set `containerEnv` paths that depend on that home directory—the devcontainers spec does not expand `_REMOTE_USER_HOME` in `devcontainer-feature.json` ([devcontainers/cli#391](https://github.com/devcontainers/cli/issues/391)).

For **Aspire VS Code extension**, tasks, or other processes that do not run a login shell, add `remoteEnv` so `~/.aspire/bin` is on `PATH` and layout variables are set:

```json
"remoteEnv": {
  "PATH": "${containerEnv:HOME}/.aspire/bin:${containerEnv:PATH}",
  "ASPIRE_HOME": "${containerEnv:HOME}/.aspire",
  "ASPIRE_LAYOUT_PATH": "${containerEnv:HOME}/.aspire/bundle"
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

`ghcr.io/microsoft/aspire-devcontainer-feature/aspire` installs the CLI for a system-wide layout under `/usr/local`. For Docker-in-Docker and AppHost workflows as a non-root user, bundle extraction under paths the user cannot write reliably is a known pain point. This feature follows the [official installer](https://aspire.dev/install.sh) layout under `~/.aspire` instead.

## Testing

CI runs `test/aspire-cli/test.sh`, which asserts the CLI location, `aspire setup`, and simulates `postCreate` sync against a fixture `sdk.version`. The pin lives in `test/aspire-cli/sync-target-version.txt` (override with `ASPIRE_CLI_SYNC_TARGET_VERSION`). Post-publish smoke writes the same pin into `aspire.config.json` and uses `ASPIRE_CLI_SYNC_VERIFY_ONLY=1` after `devcontainer up`.

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