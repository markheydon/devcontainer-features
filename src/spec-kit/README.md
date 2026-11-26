# Spec Kit

Dev Container feature that installs [GitHub Spec Kit](https://github.com/github/spec-kit)’s **Specify CLI** together with **uv** and **Python 3.11+** when the base image does not already provide a suitable interpreter.

**Consumer documentation:** [Spec Kit on the docs site](https://markheydon.github.io/devcontainer-features/features/spec-kit/)

## What gets installed

| Component | How |
|-----------|-----|
| **uv** | Pinned release tarball from [astral-sh/uv](https://github.com/astral-sh/uv) → `/usr/local/bin` |
| **Python 3.11+** | When `managedPython` is `auto` or `always` and `python3` on `PATH` is missing, older than 3.11, or lacks a working stdlib, via `uv python install` into `/opt/uv/python` (executables linked under `/usr/local/bin`) |
| **specify** | PyPI package `specify-cli` via `uv tool install`; tool environment under `/opt/uv/tools`, executable in `/usr/local/bin` (usable by the container user, not only `root`) |

`apt`: `ca-certificates`, `curl` (for downloads).

## Testing

CI runs `test/spec-kit/test.sh`, which simulates `postCreate` by running `sync-specify-version.sh` as the container user against a fixture `speckit_version`. The pin lives in `test/spec-kit/sync-target-version.txt` (override with `SPEC_KIT_SYNC_TARGET_VERSION`). Post-publish smoke reads the same file into `.specify/init-options.json` and uses `SPEC_KIT_SYNC_VERIFY_ONLY=1` after `devcontainer up`.

**If sync tests fail** because PyPI `latest` equals the pin or the pin is unavailable: choose an older published `speckit_version` that is still on PyPI and update `test/spec-kit/sync-target-version.txt` (and ensure it stays below `latest` so a downgrade sync is exercised).

## Development in this repository

Unpublished installs use a repo-relative path:

```json
"features": {
  "../src/spec-kit": {}
}
```

See the root [CONTRIBUTING.md](../../CONTRIBUTING.md) for ShellCheck, `./scripts/test-features.sh`, and versioning rules.