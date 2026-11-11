---
name: goals-review
description: Audit the repository (or a PR diff) against GOALS.md, CONVENTIONS.md, and AGENTS.md. Use when the user asks for a goals review, drift check, project health audit, or whether work still aligns with G1–G4.
---

# Goals review

Run a structured audit to detect drift from project intent. This is a **read-only review** unless the user explicitly asks you to fix findings.

## Required reading (always)

Read these before assessing:

1. [GOALS.md](../../GOALS.md) — G1–G4, scope, kill criteria
2. [CONVENTIONS.md](../../CONVENTIONS.md) — layout, install scripts, CI
3. [AGENTS.md](../../AGENTS.md) — skills routing and allowed actions

## Scope of review

Determine scope from user context:

| Trigger | Scope |
|---------|--------|
| No extra context | Whole repository health check |
| PR number or branch | `git diff main...HEAD` plus parity checks for changed features |
| `@`-mentioned paths | Those paths against relevant goals |

When reviewing code changes, run `shellcheck src/**/install.sh` if scripts changed and report pass/fail. Note that full `devcontainers/action` validate runs in CI.

## Feature inventory (mandatory for whole-repo checks)

Enumerate every feature under `src/`:

```bash
find src -mindepth 1 -maxdepth 1 -type d
```

For each feature id, verify:

| Feature | devcontainer-feature.json | install.sh | README | version | Status |
|---------|---------------------------|------------|--------|---------|--------|
| `copilot-likes` | present | present | optional | semver | OK / drift |

Checklist per feature:

- [ ] Folder name matches `id` in `devcontainer-feature.json`
- [ ] `install.sh` exists, uses `set -e`, and appears idempotent
- [ ] `version` bumped if install behaviour changed in the diff under review
- [ ] Root README lists the feature (if the feature is public)

## Map findings to goals

### G1 — Validate and publish

- [ ] [validate.yml](../../.github/workflows/validate.yml) uses `base-path-to-features: "./src"`
- [ ] [publish.yml](../../.github/workflows/publish.yml) publish settings match CONVENTIONS (namespace, `generate-docs`)
- [ ] No undocumented change to GHCR layout or feature ids

### G2 — Idempotent, fail-fast installs

- [ ] No install script omits `set -e` without strong justification
- [ ] Downloads are pinned or checksum-verified where used
- [ ] Ubuntu rename symlinks documented or consistent with existing features

### G3 — Minimal, justified dependencies

- [ ] New packages/tools belong in feature scope per GOALS.md (not duplicate official devcontainers features)
- [ ] No scope creep into full language stacks or dotfiles

### G4 — Representative smoke test

- [ ] [test.yml](../../.github/workflows/test.yml) references published feature URI and asserts tools the feature installs
- [ ] When install behaviour adds binaries, smoke test includes `which` checks (or gap flagged)

### Scope boundaries (from GOALS.md)

- [ ] Work does not expand into out-of-scope areas (non-devcontainer provisioning, arbitrary Dockerfiles, etc.)

### Documentation

- [ ] UK English in changed docs
- [ ] CONTRIBUTING and CONVENTIONS still accurate if workflows or layout changed

## Output format

Produce a concise report:

```markdown
# Goals review — <scope>

**Verdict:** Aligned | Minor drift | Significant drift

## Summary
<2–4 sentences>

## Feature inventory
<table from mandatory pass>

## Findings

| ID | Severity | Goal | Finding | Evidence |
|----|----------|------|---------|----------|
| F1 | high/medium/low | G2 | ... | file:line or diff |

## Passing checks
- Bullet list of goals/areas with no issues found

## Recommended actions
1. Ordered list — fixes first, then preventive measures
```

Severity guide:

- **high** — violates scope, goal, or consumer contract; should block merge
- **medium** — inconsistency or doc/test drift; fix soon
- **low** — style, minor doc gap, or improvement opportunity

Do not file GitHub issues unless the user asks. Do not edit code unless the user asks you to remediate findings.
