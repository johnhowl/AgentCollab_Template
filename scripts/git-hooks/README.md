# Git hooks

Version-controlled hooks for __PROJECT_NAME__. Installed by pointing Git at this dir:

```
git config core.hooksPath scripts/git-hooks
```

`scripts\Initialize-CollabGit.ps1` does this automatically.

## commit-msg

Blocks commits that touch **protected collaboration paths** unless the commit
message carries an authorization trailer:

- `Aligned-By: <resolution-id>` — backed by a Claude alignment resolution
- `Override: <reason>` — explicit human/Claude authorization

Protected: `.ai-collab/`, `scripts/`, `CLAUDE.md`, `AGENTS.md`,
`COLLABORATION.md`, `.gitignore`.

Rationale: changes to the rules engine, contracts, and public interfaces are
Tier-B — they must go through the alignment channel, not be applied unilaterally.
Tier-A autonomous fixes (deterministic, scope-local, contract-neutral) never
touch these paths, so they are unaffected.

