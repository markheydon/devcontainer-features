---
title: "ADR-0006: Publish consumer feature reference on the MkDocs site"
status: "Accepted"
date: "2026-11-26"
authors: "Mark Heydon (repository owner)"
tags: ["architecture", "decision", "documentation"]
supersedes: ""
superseded_by: ""
---

# ADR-0006: Publish consumer feature reference on the MkDocs site

## Status

Proposed | **Accepted** | Rejected | Superseded | Deprecated

## Context

Each feature needs a stable place for options, `devcontainer.json` examples, `installsAfter` guidance, and caveats. The file beside `install.sh` is what maintainers open while changing install behaviour, and it is a poor canonical URL: GitHub blob links move with branches, and `devcontainers/action` can also emit OCI documentation when `generate-docs` is true (ADR-0001). Consumers arrive from GHCR feature metadata `documentationURL`, which should be a single page per feature id. Issue #27 split consumer reference from maintainer notes.

## Decision

The published MkDocs site is the canonical consumer reference. Per-feature READMEs under `src/` stay install-adjacent and maintainer-oriented.

- **DEC-001**: Consumer reference for a feature is `docs/features/<feature-id>.md`, published at `https://markheydon.github.io/devcontainer-features/features/<feature-id>/`. `documentationURL` in `devcontainer-feature.json` points at that URL.
- **DEC-002**: `src/<feature-id>/README.md` summarises what the install script places on disk, links to the docs site, and holds maintainer testing notes (sync pins, local `../src` paths, CI job names). Option tables and consumer examples live on the site. Examples on the site use the GHCR major tag (`:1`) unless the paragraph is about pinning.
- **DEC-003**: The root [README.md](../README.md) orients contributors and links to the site. It is not the option reference. GitHub Pages deploys on changes to `docs/**`, `mkdocs.yml`, and the pages workflow, via `mkdocs build --strict`.
- **DEC-004**: OCI docs generated at publish remain a side effect of `generate-docs`. They do not replace the site. UK English applies to both trees.

## Consequences

### Positive

- **POS-001**: `documentationURL` is stable across feature refactors that do not change the feature id.
- **POS-002**: Consumer text can use MkDocs navigation, and `--strict` fails the pages build on broken links.
- **POS-003**: Maintainers can document unpublished test paths in `src/` without presenting them as the consumer contract.
- **POS-004**: The site can explain cross-feature guides (versioning, common-utils, legacy ids) once, with feature pages linking to them.

### Negative

- **NEG-001**: Behaviour changes need a docs page update as well as the install script and, when options change, metadata. Drift shows up as stale GHCR `documentationURL` content until `main` deploys pages.
- **NEG-002**: Pages deploy only when docs paths change. A feature publish that forgets the docs tree leaves the previous site live beside a new OCI artifact.
- **NEG-003**: Three surfaces can still repeat a sentence (root README, feature page, `src` README). Placement rules reduce that; they do not delete the temptation.

## Alternatives Considered

### Canonical README beside `install.sh`

- **ALT-001**: **Description**: Put the full option reference in `src/<feature-id>/README.md` and set `documentationURL` to the GitHub blob on `main`.
- **ALT-002**: **Rejection Reason**: Those files mix maintainer test procedure with consumer reference, and GitHub blob URLs are a weak contract for metadata. The site scales to guides and cross-links that a single README does not.

### Rely on `generate-docs` OCI output only

- **ALT-003**: **Description**: Treat the documentation embedded by `devcontainers/action` as the only consumer docs and stop maintaining `docs/features/`.
- **ALT-004**: **Rejection Reason**: Generated OCI docs do not host the cross-feature guides or the narrative that distinguishes this `aspire-cli` from Microsoft's feature. The site is already the URL in `documentationURL`.

## Implementation Notes

- **IMP-001**: Site config is [mkdocs.yml](../mkdocs.yml). Deploy workflow is [.github/workflows/pages.yml](../.github/workflows/pages.yml). Placement rules are in [.agents/skills/project-documentation/references/document-placement.md](../.agents/skills/project-documentation/references/document-placement.md).
- **IMP-002**: A new feature adds `docs/features/<feature-id>.md`, a nav entry, `documentationURL`, and a short `src/<feature-id>/README.md` in the same change.
- **IMP-003**: Success is `mkdocs build --strict` on `main` and a `documentationURL` that resolves to the feature page. Architectural decisions stay in `adr/`, not on the consumer site.

## References

- **REF-001**: [ADR-0001](adr-0001-ghcr-feature-publishing.md)
- **REF-002**: [GOALS.md](../GOALS.md) success criteria (2026-11-26, docs split #27); [CONVENTIONS.md](../CONVENTIONS.md) documentation section
- **REF-003**: [MkDocs Material](https://squidfunk.github.io/mkdocs-material/); GitHub Pages
