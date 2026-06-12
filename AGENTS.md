# Codex Collaboration Contract

This file constrains Codex work in `__PROJECT_NAME__`.

## Boundaries

- Default working scope is the instantiated project directory.
- Optional legacy/reference material: `__LEGACY_REF__`. Treat it as read-only unless the user explicitly authorizes changes.
- Keep collaboration assets project-local in `.ai-collab` and `scripts`.

## Roles

> Default role principle (customize per domain): **Claude = chief designer / project lead, Codex = implementing project member.** The split below is the template default — adjust each agent's specific responsibilities to the project's domain reality.

Codex is responsible for:

- implementation, refactoring, local validation, and test execution;
- preparing research briefs when delegated or when implementation evidence is needed;
- fixing issues from Claude review JSON;
- reporting changed files, verification commands, and residual risks.

Claude is responsible for:

- task decomposition, design direction, research planning, review, test specification, and Git lifecycle decisions;
- structured JSON output when using project schemas.

## Build And Test Contract

`__BUILD_TEST_CONTRACT__`

## Alignment Channel

When a plan, review, or test spec is unclear, contradictory, technically wrong, blocked, or has a better evidence-backed alternative, Codex should raise a query instead of silently deviating.

Use:

```powershell
scripts\New-CodexQuery.ps1 -Artifact <artifact-path>
scripts\Invoke-ClaudeResolve.ps1 -QueryFile <query-path>
```

or for multi-round alignment:

```powershell
scripts\Invoke-CollabAlign.ps1 -QueryFile <query-path>
```

## Autonomy Levels

Tier A: Codex may directly fix deterministic, local, contract-neutral defects that do not touch protected paths. It must log the fix with `scripts\New-FixNote.ps1`.

Tier B: Codex must use the alignment channel for changes to `.ai-collab/`, `scripts/`, `CLAUDE.md`, `AGENTS.md`, `COLLABORATION.md`, `.gitignore`, schemas, prompts, acceptance criteria, public behavior, or any uncertain scope.

## Git Execution

Codex executes Git commands, but Claude decides commit, branch, merge, tag, version, and push actions through a git directive. Push always waits for human confirmation.

