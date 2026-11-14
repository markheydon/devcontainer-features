# Development container

Tooling for authoring features in this repo uses **third-party Dev Container features** (not published from here) so this repository stays focused on your custom features under `src/`.

| Feature | Purpose |
|---|---|
| [dev-agent-tools](../src/dev-agent-tools) (this repo) | Day-to-day CLI tools — see [feature README](../src/dev-agent-tools/README.md) |
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

See [CONTRIBUTING.md](../CONTRIBUTING.md) for commands to run before a PR.
