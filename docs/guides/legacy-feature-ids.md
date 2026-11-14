# Legacy feature ids

Dev Container Features can rename their canonical id without breaking existing consumer configs.

## How it works

Metadata includes a `legacyIds` array listing previous feature ids. When published, the same install bundle is pushed to GHCR under **both** the canonical id and each legacy id (with matching version tags).

[Dev Agent Tools](../features/dev-agent-tools.md) uses this pattern:

| GHCR id | Role |
|---------|------|
| `dev-agent-tools` | Canonical id — use in new projects |
| `copilot-likes` | Legacy id — still updated; not related to the GitHub Copilot product |

## Why migrate off legacy ids

AI coding agents often infer intent from `devcontainer.json` keys. A legacy id such as `copilot-likes` can be misread as “remove GitHub Copilot” during unrelated migrations.

Switch to the canonical id when you touch the file:

```json
"ghcr.io/markheydon/devcontainer-features/dev-agent-tools:1": {}
```

Legacy references keep working until maintainers remove `legacyIds` in a future major policy change (upstream still publishes `docker-from-docker` years after renaming to `docker-outside-of-docker`).

## Optional agent hint

In consumer repositories, add a short note to `AGENTS.md` or project rules, for example: “`copilot-likes` in devcontainer features refers to the Dev Agent Tools CLI bundle, not GitHub Copilot.”