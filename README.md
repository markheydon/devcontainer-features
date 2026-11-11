# Devcontainer Features

![GitHub Actions](https://img.shields.io/github/actions/workflow/status/markheydon/devcontainer-features/publish.yml)
![License](https://img.shields.io/github/license/markheydon/devcontainer-features)

Custom reusable Dev Container features published to GitHub Container Registry.

## Using a feature

In your project’s `devcontainer.json`, add a `features` entry. After publish from this repo’s `main` branch:

```json
"features": {
  "ghcr.io/markheydon/devcontainer-features/copilot-likes:1.0.0": {}
}
```

Use a specific version tag or `latest` per your pinning policy. See [CONTRIBUTING.md](CONTRIBUTING.md) and [CONVENTIONS.md](CONVENTIONS.md) for layout and versioning.

## Features

- **copilot-likes** — Opinionated CLI tools and tweaks that fit common agent-assisted dev workflows ([details](src/copilot-likes/README.md)).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
