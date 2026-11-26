# Aspire CLI

Dev Container feature that installs the [Aspire CLI](https://aspire.dev/) into the container user’s home directory (`~/.aspire/bin`) using the official installer, runs optional bundle setup, and can align the CLI to the repo’s Aspire SDK pin on first container create.

**Consumer documentation:** [Aspire CLI on the docs site](https://markheydon.github.io/devcontainer-features/features/aspire-cli/)

## What gets installed

| Component | How |
|-----------|-----|
| **Aspire CLI** | Official `https://aspire.dev/install.sh` → `~/.aspire/bin/aspire` |
| **Bundle layout** | Optional `aspire setup --non-interactive` with layout root `ASPIRE_LAYOUT_PATH` (default `~/.aspire`; Aspire 17+ creates `bundle/` as a symlink there) |
| **Shell PATH** | `/etc/profile.d/aspire-cli.sh` and a marked block in the user’s `.bashrc` / `.profile` |

`apt`: `ca-certificates`, `curl`, `python3-minimal` (installer download and create-time SDK pin detection).

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