# __PROJECT_NAME__ Collaboration Guide

This project uses a Claude/Codex commander-worker workflow.

## Roles

- Claude: planning, architecture, research direction, review, test specification, summary, and Git lifecycle decisions.
- Codex: implementation, local validation, test execution, and Git command execution.

Codex is not a passive executor. It should raise evidence-backed objections through the alignment channel when instructions are unclear, technically wrong, blocked, or incomplete.

## Project Placeholders

- Domain: `__PROJECT_DOMAIN__`
- Build/test contract: `__BUILD_TEST_CONTRACT__`
- Optional legacy/reference material: `__LEGACY_REF__`

Fill these in after creating a project from the template.

## Standard Flow

```powershell
scripts\Invoke-CollabLoop.ps1 -Objective "<task objective>"
```

Manual steps:

| Step | Command | Artifact |
| --- | --- | --- |
| research | `scripts\New-ResearchBrief.ps1 -Topic "..."` | `.ai-collab\research\*.md` |
| plan | `scripts\Invoke-ClaudePlan.ps1 -Objective "..."` | `.ai-collab\tasks\*-task-plan.json` |
| review | `scripts\Invoke-ClaudeReview.ps1` | `.ai-collab\reviews\*-review.json` |
| test spec | `scripts\Invoke-ClaudeTestSpec.ps1 -Objective "..."` | `.ai-collab\tasks\*-test-spec.json` |
| summary | `scripts\Invoke-ClaudeSummary.ps1 -Objective "..." -TestLog <log>` | `.ai-collab\reviews\*-summary.json` |
| git directive | `scripts\Invoke-ClaudeGitPlan.ps1 -Objective "..."` | `.ai-collab\tasks\*-git-directive.json` |

## Alignment

```powershell
scripts\New-CodexQuery.ps1 -Artifact <artifact-path>
scripts\Invoke-CollabAlign.ps1 -QueryFile <query-path>
```

If the alignment does not converge, escalate to a human.

## Git Guardrail

Run `scripts\Initialize-CollabGit.ps1` to initialize Git and install hooks. Commits touching protected collaboration paths must include one of these trailers:

```text
Aligned-By: <resolution-id>
Override: <reason>
```

