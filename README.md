# Dev Container Features

![GitHub Actions](https://img.shields.io/github/actions/workflow/status/markheydon/devcontainer-features/publish.yml)
![License](https://img.shields.io/github/license/markheydon/devcontainer-features)

Custom, reusable [Dev Container features](https://containers.dev/implementors/features/) published to GitHub Container Registry (GHCR). Each feature is a small install script plus metadata under `src/<feature-id>/`, so consumer projects can opt in from `devcontainer.json` without maintaining a bespoke Dockerfile for every tool.

**Consumer documentation:** [markheydon.github.io/devcontainer-features](https://markheydon.github.io/devcontainer-features/)

Project scope and goals: [GOALS.md](GOALS.md). Layout, CI, and install conventions: [CONVENTIONS.md](CONVENTIONS.md).

## Using a feature

Reference a published image after merge to `main`:

```json
"features": {
  "ghcr.io/markheydon/devcontainer-features/dev-agent-tools:1": {}
}
```

After publish, GHCR provides the exact semver from `devcontainer-feature.json` and a major-version alias (`:1`). **Prefer `:1` in `devcontainer.json`** so patch releases do not require doc or consumer updates. Pin an exact semver (for example `:1.1.0`) only when you need reproducible builds; avoid `:latest` unless you accept floating updates across majors.

The legacy id `copilot-likes` still publishes alongside `dev-agent-tools` for backward compatibility—it is not the GitHub Copilot product. See the [legacy feature ids guide](https://markheydon.github.io/devcontainer-features/guides/legacy-feature-ids/).

While developing in this repository, point at a local feature folder instead of GHCR — see [CONTRIBUTING.md](CONTRIBUTING.md#testing-locally).

Some features declare `installsAfter` in metadata (for example **dev-agent-tools** and **spec-kit** list [common-utils](https://github.com/devcontainers/features/tree/main/src/common-utils)). List that dependency in your `features` block **only when your base image does not already include it**. Official Microsoft dev container images such as [`mcr.microsoft.com/devcontainers/base:ubuntu`](https://github.com/devcontainers/images/blob/main/src/base-ubuntu/README.md) are built with common-utils already applied; listing it again adds an extra feature layer with little benefit. If you omit the dependency, the Dev Containers CLI still resolves install order—it treats `installsAfter` as a soft dependency when the named feature is not requested. See the [docs site](https://markheydon.github.io/devcontainer-features/guides/common-utils/) for examples.

## Features

| Feature | Description |
|---------|-------------|
| [dev-agent-tools](src/dev-agent-tools/README.md) · [docs](https://markheydon.github.io/devcontainer-features/features/dev-agent-tools/) | Opinionated CLI tools, git diff defaults, and shell aliases for agent-assisted workflows |
| [spec-kit](src/spec-kit/README.md) · [docs](https://markheydon.github.io/devcontainer-features/features/spec-kit/) | Self-contained GitHub Spec Kit toolchain (uv, Python when needed, Specify CLI) without VS Code Python extensions |

## Contributing

Pull requests welcome. Workflow, local checks, and versioning: [CONTRIBUTING.md](CONTRIBUTING.md).

Maintainers use the development container in [.devcontainer/](.devcontainer/README.md) (ShellCheck, Dev Container CLI, host Docker for [scripts/test-features.sh](scripts/test-features.sh) and `devcontainer up` try-outs).

Optional docs build: `pip install -r docs/requirements.txt && mkdocs build --strict`.

## Licence

This project is licensed under the terms in [LICENSE](LICENSE).