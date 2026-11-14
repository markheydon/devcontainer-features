---
name: project-documentation
description: Diátaxis-aligned, project-aware documentation for this repository. Use when writing or updating README content, docs/, user guides, tutorials, or technical posts; read GOALS.md and CONVENTIONS.md for placement and conventions.
---

# Project documentation

Expert technical writing for this repository, grounded in the [Diátaxis framework](https://diataxis.fr/) and local project context.

## Guiding principles

1. **Clarity:** Simple, unambiguous language (UK English in this repository).
2. **Accuracy:** Code snippets, commands, and feature ids must match the codebase and published GHCR ids.
3. **User-centricity:** Each document helps a specific reader achieve a specific goal.
4. **Consistency:** Tone and terminology align with GOALS.md, CONVENTIONS.md, and existing docs.

## Document types (Diátaxis)

| Type | Orientation | Use for |
|------|-------------|---------|
| **Tutorial** | Learning | First successful path for newcomers |
| **How-to** | Problem | Steps to solve one specific task |
| **Reference** | Information | Exact behaviour, options, installed tools |
| **Explanation** | Understanding | Concepts, trade-offs, legacy ids, architecture |

## Workflow

1. **Clarify** before drafting (ask if needed):
   - Document type, target audience, user goal, and scope (included vs excluded topics).
2. **Read context:** `GOALS.md`, `CONVENTIONS.md`, `AGENTS.md`; relevant `src/<feature-id>/README.md`.
3. **Propose structure** for substantial docs (outline or TOC); proceed when the task is small and clear.
4. **Choose placement** using [references/document-placement.md](references/document-placement.md).
5. **Draft** in Markdown; use [assets/](assets/) templates when helpful.
6. **Review** with [references/review-checklist.md](references/review-checklist.md).

## Scope boundaries

- This skill is for project documentation, not ADR authoring. Use `create-architectural-decision-record` for `adr/`.
- Do not duplicate ADR process rules here.

## References

- [references/document-placement.md](references/document-placement.md)
- [references/review-checklist.md](references/review-checklist.md)
- [assets/readme-section-template.md](assets/readme-section-template.md)
- [assets/how-to-template.md](assets/how-to-template.md)
- [assets/tutorial-template.md](assets/tutorial-template.md)
- [assets/technical-blog-template.md](assets/technical-blog-template.md)