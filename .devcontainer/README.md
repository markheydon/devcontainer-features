# Development container

Tooling for authoring features in this repo uses **third-party Dev Container features** (not published from here) so this repository stays focused on your custom features under `src/`.

| Feature | Purpose |
|---|---|
| [dev-agent-tools](../src/dev-agent-tools) (GHCR `:1` in [devcontainer.json](devcontainer.json)) | Day-to-day CLI tools — see [feature README](../src/dev-agent-tools/README.md) |
| [shellcheck](https://github.com/devcontainers-extra/features/tree/main/src/shellcheck) | Lint `install.sh` |
| [node](https://github.com/devcontainers/features/tree/main/src/node) | Runtime for the Dev Container CLI |
| [devcontainers-cli](https://github.com/eliises/devcontainer-features/tree/main/src/devcontainers-cli) | `devcontainer` command |
| [docker-outside-of-docker](https://github.com/devcontainers/features/tree/main/src/docker-outside-of-docker) | `devcontainer up` / `features test` (uses host Docker) |
| [github-cli](https://github.com/devcontainers/features/tree/main/src/github-cli) | `gh` for PRs and releases |
| [cursor-cli](https://github.com/stu-bell/devcontainer-features) | Cursor agent CLI |

The base image `mcr.microsoft.com/devcontainers/base:ubuntu` already includes [common-utils](https://github.com/devcontainers/features/tree/main/src/common-utils) and git, so we do not list common-utils again. **dev-agent-tools** `installsAfter` is satisfied without an extra feature layer.

**Host requirement:** Docker must be available on the machine (or VM) that forwards the socket—typical on local Dev Containers with Docker Desktop. Without Docker, ShellCheck and editing still work; feature build/test commands need the socket.

### Feature tests inside this dev container

This image uses **docker-outside-of-docker**: the `devcontainer features test` command can **build and install** a feature successfully, then fail launching the test container because it bind-mounts a path under `/tmp` that exists only inside this dev container, not on the Docker host.

Use the repo helper instead of calling the CLI directly:

```bash
./scripts/test-features.sh
```

It is what [feature-test.yml](../.github/workflows/feature-test.yml) runs per matrix job (`<feature-id> <base-image>`). With no arguments it exercises every `src/*` feature × every image in [scripts/official-base-images.txt](../scripts/official-base-images.txt) (often a superset of the CI matrix). In this dev container it falls back to running `test/<feature-id>/test.sh` inside the built image when the CLI bind mount fails.

### MkDocs consumer site

CI builds docs with `mkdocs build --strict` ([pages.yml](../.github/workflows/pages.yml)). On a **host** checkout with Docker or Podman, use:

```bash
./scripts/invoke-mkdocs.sh build
```

With **docker-outside-of-docker**, the host daemon often cannot bind-mount `/workspaces/...`, so this helper may fail inside the dev container even though feature tests work. Use a host-path clone, or install MkDocs with pip when Python is available.

See [CONTRIBUTING.md](../CONTRIBUTING.md) for commands to run before a PR.

### Docker-outside-of-docker vs Docker-in-Docker

This dev container uses **[docker-outside-of-docker](https://github.com/devcontainers/features/tree/main/src/docker-outside-of-docker)** (DooD): the `docker` CLI inside the container talks to the **host** Docker daemon. Images and containers created by `./scripts/test-features.sh` or `devcontainer features test` are stored on the **host**, not inside the dev container filesystem.

| Mode | Where images live | When you remove this dev container |
|------|-------------------|-----------------------------------|
| **DooD** (current) | Host Docker | Test/build images **usually remain** on the host until you prune them |
| **DinD** ([docker-in-docker](https://github.com/devcontainers/features/tree/main/src/docker-in-docker)) | Daemon (and graph) inside the dev container (often privileged) | Images built only through that in-container daemon **typically go away** with the container, unless you mount a persistent volume for Docker data |

DinD can reduce long-term disk use on the host when you frequently build many feature-test images locally, but it needs **privileged** mode, is slower for nested builds, and has different socket/path behaviour. DooD is the common choice for feature authors who want the host to cache layers between sessions.

To reclaim space with DooD, prune on the host (for example `docker image prune -a` when you are sure nothing else needs those images). Switching this repo’s maintainer dev container to DinD would be a deliberate change (update [devcontainer.json](devcontainer.json) and re-verify `./scripts/test-features.sh`).
