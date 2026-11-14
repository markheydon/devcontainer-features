# Goals

**Project:** markheydon/devcontainer-features  
**Owner:** Mark Heydon  
**Last updated:** 2026-11-11

---

## Why This Exists

Developers need small, opinionated Dev Container features that complement official images without maintaining a full custom Dockerfile for every repo. This repository publishes reusable features to GitHub Container Registry so consumer `devcontainer.json` files can opt in with a single features block.

---

## Goals

- **G1:** Every feature validates with `devcontainers/action` and publishes predictably to `ghcr.io/markheydon/devcontainer-features/<feature-id>`.
- **G2:** Every `install.sh` is idempotent and fails fast (`set -e`, clear errors).
- **G3:** Dependencies stay minimal and justified — extend or compose [devcontainers/features](https://github.com/devcontainers/features) rather than reimplementing them.
- **G4:** CI testing stays representative: pre-publish installs from `src/` on official Microsoft base images, and the post-publish smoke test references published feature URIs the way consumers do in `devcontainer.json`.

---

## Success Looks Like

- New features follow the `src/<id>/` layout and pass validate, ShellCheck, feature tests ([feature-test.yml](.github/workflows/feature-test.yml)), publish, and post-publish smoke test.
- Root README and per-feature READMEs list what is installed, consumer references (including `installsAfter`), and caveats.
- Consumers can pin versions or use `latest` without surprise breaking changes undocumented in release notes or version bumps.

---

## Kill Criteria

- A feature is redundant with an official devcontainers feature or base image capability — remove or stop publishing rather than duplicate maintenance.
- Upstream spec or GHCR constraints make a feature unmaintainable without disproportionate effort.

---

## Scope

### In scope

- Custom Dev Container features under `src/`.
- Validate, lint, pre-publish feature tests on official base images, publish, and post-publish smoke-test automation in `.github/workflows/`.
- Documentation for contributors and feature consumers (README, CONTRIBUTING, per-feature README, and the MkDocs site under `docs/`).

### Out of scope

Do not implement without an explicit scope change.

- General-purpose dotfiles or shell profiles unrelated to devcontainers.
- Full language stacks or runtimes better served by official features (Node, Python, .NET, etc.).
- Non-devcontainer provisioning (bare metal, cloud Terraform, Kubernetes operators).
- A marketplace of arbitrary Dockerfiles unrelated to the features spec.

---

## Revision History

| Date | Change | Reason |
|---|---|---|
| 2026-11-11 | Initial goals for devcontainer-features | Lean governance setup |
