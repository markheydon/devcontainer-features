# Contributing

Documentation for **contributors and maintainers** of this feature collection lives in the repository:

- [CONTRIBUTING.md](https://github.com/markheydon/devcontainer-features/blob/main/CONTRIBUTING.md) — adding features, local tests, pull requests (including **signed commits** on the default branch)
- [CONVENTIONS.md](https://github.com/markheydon/devcontainer-features/blob/main/CONVENTIONS.md) — layout, CI, install script patterns

The [maintainer development container](https://github.com/markheydon/devcontainer-features/blob/main/.devcontainer/README.md) includes ShellCheck, the Dev Container CLI, and scripts for feature tests.

## Optional: build docs locally

From a host checkout where Docker or Podman can bind-mount the repository:

```bash
./scripts/invoke-mkdocs.sh build    # writes site/ only — no browser
./scripts/invoke-mkdocs.sh serve    # open http://localhost:8000/ (live reload)
./scripts/invoke-mkdocs.sh preview  # open http://localhost:8080/ (static, like CI output)
```

`build` is what CI runs for validation; use `serve` or `preview` when you want to read the site locally (including from a WSL shell with Docker on the same machine).

If Python and pip are available locally:

```bash
pip install -r docs/requirements.txt
mkdocs build --strict
mkdocs serve
```

Docs deploy automatically from `main` via the **Deploy docs** GitHub Actions workflow after GitHub Pages is enabled for the repository (source: GitHub Actions).