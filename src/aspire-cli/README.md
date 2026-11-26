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

CI splits three concerns (all driven by `test/aspire-cli/test.sh`):

1. **Install and layout** — [feature-test.yml](../../.github/workflows/feature-test.yml) / `./scripts/test-features.sh`: CLI under `~/.aspire/bin`, bundle symlink when CLI ≥ 17, `aspire setup`, and simulated `postCreate` sync in an isolated temp workspace (`ASPIRE_CLI_SYNC_TARGET_VERSION` from `test/aspire-cli/sync-target-version.txt`).
2. **Post-publish sync** — [test.yml](../../.github/workflows/test.yml) job `test-aspire-cli-sync`: ephemeral workspace with only `.devcontainer` and pin `aspire.config.json`; `devcontainer up` then `ASPIRE_CLI_SYNC_VERIFY_ONLY=1`.
3. **Developer workflow** — [test.yml](../../.github/workflows/test.yml) job `test-aspire-cli-workflow`: ephemeral workspace copied from `test/aspire-cli/fixtures/run-smoke/` (minimal AppHost); `devcontainer up` then `ASPIRE_CLI_WORKFLOW_VERIFY=1` runs `aspire run` from the project root via a login shell (no extra path env).

**If sync tests fail** because release `latest` equals the pin or the pin is unavailable from the installer: choose an older version still published on the Aspire download feeds (for example below current release `17.0.0`) and update `test/aspire-cli/sync-target-version.txt`.

Manual checks (with Docker on the host):

```bash
shellcheck src/aspire-cli/install.sh
./scripts/test-features.sh aspire-cli mcr.microsoft.com/devcontainers/dotnet:latest
```

`./scripts/test-features.sh` covers install, layout, and simulated sync only. **`aspire run`** workflow coverage runs in post-publish job `test-aspire-cli-workflow` (fixture `test/aspire-cli/fixtures/run-smoke/`, `ASPIRE_CLI_WORKFLOW_VERIFY=1`).

## Development in this repository

Unpublished installs use a repo-relative path:

```json
"features": {
  "../src/aspire-cli": {}
}
```

See the root [CONTRIBUTING.md](../../CONTRIBUTING.md) for ShellCheck, `./scripts/test-features.sh`, and versioning rules.