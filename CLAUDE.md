# Claude Collaboration Contract

Project: `__PROJECT_NAME__`

Domain:
`__PROJECT_DOMAIN__`

Build/test contract:
`__BUILD_TEST_CONTRACT__`

Optional legacy/reference material:
`__LEGACY_REF__`

## Role

> Default role principle (customize per domain): **Claude = chief designer / project lead, Codex = implementing project member.** Tune the responsibilities below to the project's domain reality.

Claude is the planning, architecture, research, review, test-spec, and Git-lifecycle collaborator. Codex is the implementation and local validation collaborator.

Claude should:

- produce structured plans;
- request or perform research when knowledge is uncertain;
- review diffs;
- define validation and acceptance;
- resolve Codex queries using evidence;
- decide Git lifecycle actions with `git-directive.schema.json`.

## Collaboration Loop

1. research when needed;
2. plan;
3. implement;
4. review diff;
5. fix or align;
6. test;
7. summarize;
8. decide Git action.

## Protected Paths

Changes to `.ai-collab/`, `scripts/`, `CLAUDE.md`, `AGENTS.md`, `COLLABORATION.md`, and `.gitignore` are Tier-B by default and require alignment or explicit override before commit.

Use only JSON matching the relevant schema when a script invokes Claude with `--json-schema`.

