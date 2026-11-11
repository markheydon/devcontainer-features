---
name: code-review
description: >-
  Review devcontainer feature changes (install.sh, metadata, CI, docs) as a
  principal maintainer would for pull request approval: bugs, security,
  idempotency, versioning, and maintainability. Use when the user runs
  /code-review or loop-code-review, asks for a code review, or wants findings on
  a branch, PR, or local diff before merge. Read-only unless the user
  explicitly asks to implement fixes.
---

# Code review

Review as a maintainer of a Dev Container features collection. Treat the change set like a pull request from another experienced contributor.

Focus only on issues that would influence your decision to **approve or reject** the pull request. Findings must be the primary focus, ordered by severity. Do not make code changes unless the user explicitly asks for them.

For drift against [GOALS.md](../../GOALS.md), feature inventory parity, or scope boundaries, use the `goals-review` skill instead — do not duplicate that audit here unless a finding also blocks merge on correctness or security grounds.

For automated Bugbot or security-focused subagent reviews, use `/review-bugbot` and `/review-security` unless the user wants this review only.

## Scope

Decide what to diff before reading code:

| User intent | Diff |
| --- | --- |
| Default (branch work, PR, “review my changes”) | Changes since merge-base with the repository default branch (usually `main`), including committed, staged, and unstaged edits |
| “Uncommitted”, “dirty”, “working tree” only | Staged + unstaged diff only |
| Named PR, branch, or GitHub link | Check out that head branch locally when needed, then use the branch diff row above |

Repository path: use the git root that contains the changes.

If there is no diff, say so in one sentence and stop.

## Focus on finding

1. Bugs or logic errors in `install.sh` (wrong paths, missing symlinks, broken architecture branches).
2. Security concerns: secrets in scripts, unpinned remote downloads, overly broad `apt` installs, unsafe `curl | bash`.
3. Violations of [CONVENTIONS.md](../../CONVENTIONS.md) and [GOALS.md](../../GOALS.md): missing `set -e`, non-idempotent installs, folder/id mismatch.
4. Metadata mistakes: `devcontainer-feature.json` `id` not matching folder, forgotten **version bump** when install behaviour changed, wrong `documentationURL` or `installsAfter`.
5. CI gaps: ShellCheck failures, validate workflow paths, missing assertions in `test/<feature-id>/test.sh` or [feature-test.yml](../../.github/workflows/feature-test.yml) matrix for new binaries, and drift between post-publish smoke jobs in [test.yml](../../.github/workflows/test.yml) and those scripts.
6. GHCR consumer contract: feature id or publish namespace changes that break existing `devcontainer.json` references without migration notes.
7. Documentation drift: README or feature README not updated when behaviour changes.

## Do not comment on

- Shell style nits that ShellCheck and convention already cover unless they hide a real bug.
- Personal naming preferences for feature ids.
- Unrelated features not touched by the change set.
- Whole-repo goals inventory (use `goals-review`).

## How to review

1. Establish the diff (see **Scope**).
2. Read changed `install.sh`, `devcontainer-feature.json`, workflows, and docs together.
3. Mentally re-run the install: apt packages, downloads, symlinks, idempotency guards.
4. When install behaviour changes, confirm semver bump and test workflow updates.
5. When unsure, run `shellcheck` on changed scripts before reporting.

Meaningful changes should pass ShellCheck locally and match the gates in [CONTRIBUTING.md](../../CONTRIBUTING.md) and [AGENTS.md](../../AGENTS.md). Use that when judging whether a finding blocks approval.

## Output

Lead with findings. Keep summary and praise minimal.

For each issue, provide:

- **Severity** — Critical, High, Medium, or Low.
- **Location** — `path/to/file:line` (or code citation when reporting in chat).
- **Why it matters** — tie to approve/reject risk.
- **Suggested improvement** — concrete, actionable fix direction (do not implement unless asked).

Present issues in a compact markdown table sorted by severity (highest first):

| Severity | Location | Why it matters | Suggested improvement |
| --- | --- | --- | --- |
| … | … | … | … |

Use UK English in prose.

## Closing

End with a brief explanation of overall merge readiness (approve, approve with nits, or reject) based only on the issues above.

If no significant issues are found, say so explicitly. Mention residual risks only when they are material to approval.

## After the review

- Do not implement fixes, commit, or push unless the user explicitly asks.
- If the user asks to fix findings, apply minimal correct diffs per CONVENTIONS, then run ShellCheck on changed scripts before claiming the review is clear.
