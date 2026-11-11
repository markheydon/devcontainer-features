# Development container

Tooling for authoring features in this repo uses **third-party Dev Container features** (not published from here) so this repository stays focused on your custom features under `src/`.

| Feature | Purpose |
|---|---|
| [common-utils](https://github.com/devcontainers/features/tree/main/src/common-utils) | Required ordering for **copilot-likes** (`installsAfter`) |
| [copilot-likes](../src/copilot-likes) (this repo) | Day-to-day CLI tools — see [feature README](../src/copilot-likes/README.md) |
| [shellcheck](https://github.com/devcontainers-extra/features/tree/main/src/shellcheck) | Lint `install.sh` |
| [node](https://github.com/devcontainers/features/tree/main/src/node) | Runtime for the Dev Container CLI |
| [devcontainers-cli](https://github.com/eliises/devcontainer-features/tree/main/src/devcontainers-cli) | `devcontainer` command |
| [docker-outside-of-docker](https://github.com/devcontainers/features/tree/main/src/docker-outside-of-docker) | `devcontainer up` / `features test` (uses host Docker) |
| [github-cli](https://github.com/devcontainers/features/tree/main/src/github-cli) | `gh` for PRs and releases |
| [cursor-cli](https://github.com/stu-bell/devcontainer-features) | Cursor agent CLI |

**Host requirement:** Docker must be available on the machine (or VM) that forwards the socket—typical on local Dev Containers with Docker Desktop. Without Docker, ShellCheck and editing still work; feature build/test commands need the socket.

See [CONTRIBUTING.md](../CONTRIBUTING.md) for commands to run before a PR.
