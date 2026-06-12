# Project Collaboration Skill

Use this project-local skill for Claude/Codex collaboration in `__PROJECT_NAME__`.

## Scope

- Work stays inside the current project unless the user explicitly expands scope.
- Project-specific domain context belongs in `__PROJECT_DOMAIN__`.
- Build and validation expectations belong in `__BUILD_TEST_CONTRACT__`.
- Optional legacy/reference material belongs in `__LEGACY_REF__` and should be treated as read-only unless explicitly authorized.

## Workflow

1. Clarify whether the task is research, design, implementation, testing, review, or Git lifecycle work.
2. Use structured artifacts under `.ai-collab` for plans, reviews, research, tests, summaries, and alignment.
3. Codex implements and validates locally.
4. Claude reviews diffs and decides Git lifecycle actions.
5. Codex may challenge unclear or incorrect instructions through the alignment channel.

## Autonomy Boundary

Codex may directly fix Tier-A issues: deterministic, local, contract-neutral defects. It must record the fix in `FIXLOG.md`.

Tier-B changes require alignment: collaboration rules, scripts, schemas, public contracts, test expectations, behavior changes, or uncertain scope.

