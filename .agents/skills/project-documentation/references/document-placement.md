# Document Placement Guide

Use this guide after you have chosen the Diátaxis document type from the project-documentation skill.

## Put content in `README.md` when

- It explains what the repository is, why it exists, and how to get started.
- The primary audience is contributors, maintainers, or evaluators of the repository.
- The content needs to be visible immediately on the repository front page.

## Put content in `docs/` when

- The content is end-user-facing or intended to scale beyond a short repository overview.
- It fits a Diátaxis category such as tutorial, how-to guide, reference, or explanation.
- It will grow over time and benefits from navigation, indexing, or cross-linking.
- **Feature consumers** need options, examples, environment notes, and caveats (`docs/features/<feature-id>.md` is the canonical consumer reference for published GHCR features).

The site is built with MkDocs and published to GitHub Pages (see `mkdocs.yml` and [CONTRIBUTING.md](../../../CONTRIBUTING.md)).

## Put content in `src/<feature-id>/README.md` when

- It documents what the install script places on disk (summary table next to `install.sh`).
- It covers **maintainer** concerns: CI test pins, sync fixtures, unpublished `../src/` paths.
- Link prominently to the matching page on the docs site; do not make this file the primary option reference.

## Put content in another project file when

- It belongs with planning or operational material such as `CONVENTIONS.md`, `GOALS.md`, or `plan/` files.
- It describes internal process, governance, or implementation constraints rather than product or user-facing documentation.

## Decision rules

- Favour `README.md` for orientation and entry points (link to the docs site for consumers).
- Favour `docs/` for substantial user-facing content, especially per-feature reference material.
- Avoid duplicating the same guidance in README, `docs/`, and feature README.
- If a README section is becoming long, task-heavy, or reference-like, move the detail into `docs/` and leave a short summary with a link to the docs site.