# __PROJECT_NAME__ AI Collaboration Directory

This directory is project-local collaboration infrastructure for Claude and Codex.
It should be copied into a project and then customized for `__PROJECT_DOMAIN__`.

## Contents

- `schemas`: JSON Schema contracts used by Claude structured output.
- `prompts`: Project-neutral prompts for plan, review, research, test, summary, experiment, resolve, and git decisions.
- `skills/project-collaboration`: A local skill describing the generic collaboration workflow.
- `tasks`, `research`, `reviews`, `experiments`, `runs`, and `dialogue` may be created during use.

## Default Flow

1. Claude produces a structured plan.
2. Codex implements and validates locally.
3. Claude reviews the Git diff.
4. Codex fixes or raises a structured query.
5. Claude produces test specs and summaries.
6. Claude decides Git lifecycle actions; Codex executes them.

Customize these placeholders after instantiation:

- `__PROJECT_DOMAIN__`: describe the project domain and user-facing goal.
- `__BUILD_TEST_CONTRACT__`: describe build, test, and verification commands.
- `__LEGACY_REF__`: optional read-only legacy/reference material.

