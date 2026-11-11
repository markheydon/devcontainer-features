# Dev Container Features

![GitHub Actions](https://img.shields.io/github/actions/workflow/status/markheydon/devcontainer-features/publish.yml)
![License](https://img.shields.io/github/license/markheydon/devcontainer-features)

Custom, reusable [Dev Container features](https://containers.dev/implementors/features/) published to GitHub Container Registry (GHCR). Each feature is a small install script plus metadata under `src/<feature-id>/`, so consumer projects can opt in from `devcontainer.json` without maintaining a bespoke Dockerfile for every tool.

Project scope and goals: [GOALS.md](GOALS.md). Layout, CI, and install conventions: [CONVENTIONS.md](CONVENTIONS.md).

## Using a feature

Reference a published image after merge to `main`:

```json
"features": {
  "ghcr.io/markheydon/devcontainer-features/copilot-likes:1.0.1": {}
}
```

Registry tags include the semver from `devcontainer-feature.json` (for example `1.0.0`) and, after publish, a major-version alias such as `:1`. Pin an exact semver if you need reproducible builds; use `:latest` or a major tag only if your team accepts floating updates.

While developing in this repository, point at a local feature folder instead of GHCR — see [CONTRIBUTING.md](CONTRIBUTING.md#testing-locally).

Some features declare `installsAfter` in metadata (for example **copilot-likes** expects [common-utils](https://github.com/devcontainers/features/tree/main/src/common-utils)). Add those dependencies to your `features` block when the feature README or JSON metadata says so.

## Features

| Feature | Description |
|---------|-------------|
| [copilot-likes](src/copilot-likes/README.md) | Opinionated CLI tools, git diff defaults, and shell aliases that match what many agent-assisted workflows assume are present |

## Contributing

Pull requests welcome. Workflow, local checks, and versioning: [CONTRIBUTING.md](CONTRIBUTING.md).

Maintainers use the development container in [.devcontainer/](.devcontainer/README.md) (ShellCheck, Dev Container CLI, host Docker for `devcontainer up` / `features test`).

## Licence

This project is licensed under the terms in [LICENSE](LICENSE).
