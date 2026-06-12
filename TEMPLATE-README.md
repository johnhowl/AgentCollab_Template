# AgentCollab Template

Reusable Claude/Codex collaboration template.

## Create A New Project

```powershell
.\New-CollabProject.ps1 -TargetDir D:\path\NewProject -ProjectName NewProject
```

Use `-NoGit` if you want to copy the files without initializing Git.

## After Instantiation

Edit these placeholders:

- `__PROJECT_DOMAIN__`: what the project is about.
- `__BUILD_TEST_CONTRACT__`: build, test, and validation commands.
- `__LEGACY_REF__`: optional read-only reference material.

## What The Template Provides

- structured JSON schemas for plan, review, research, tests, summaries, experiments, alignment, and Git decisions;
- Claude prompts for each structured phase;
- Codex/Claude contracts;
- PowerShell orchestration scripts;
- commit guardrails for protected collaboration paths.

