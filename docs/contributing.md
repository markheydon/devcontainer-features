# Contributing

Documentation for **contributors and maintainers** of this feature collection lives in the repository:

- [CONTRIBUTING.md](https://github.com/markheydon/devcontainer-features/blob/main/CONTRIBUTING.md) — adding features, local tests, pull requests
- [CONVENTIONS.md](https://github.com/markheydon/devcontainer-features/blob/main/CONVENTIONS.md) — layout, CI, install script patterns

The [maintainer development container](https://github.com/markheydon/devcontainer-features/blob/main/.devcontainer/README.md) includes ShellCheck, the Dev Container CLI, and scripts for feature tests.

## Optional: build docs locally

```bash
pip install -r docs/requirements.txt
mkdocs build --strict
mkdocs serve
```

Docs deploy automatically from `main` via the **Deploy docs** GitHub Actions workflow after GitHub Pages is enabled for the repository (source: GitHub Actions).