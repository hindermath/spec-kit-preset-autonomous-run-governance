---
description: Inspect the active autonomous Spec Kit run without changing repository state.
---

## User Input

```text
$ARGUMENTS
```

Inspect only. Do not create, modify, stage, commit, push, merge, or regenerate
files. Do not start or resume a feature.

Locate the current feature through repository metadata and the active branch.
When present, read `specs/<feature>/autonomous-run-state.json`, `tasks.md`, run
evidence, Git status, and the accepted feature artifacts. Run the installed
state validator through `bash <validator.sh>` or
`pwsh -NoProfile -File <validator.ps1>`.

Report:

- feature path, branch, delivery mode, stage, and status
- state-schema validity and whether feature metadata agrees
- checkpoint commit and whether it exists in current history
- accepted-artifact and task hashes, completed task count, and detected drift
- last passing gate, last operation, and next exact action
- owned, unrelated, staged, unstaged, and untracked worktree boundaries
- whether authority must be revalidated before local or remote continuation
- one of `ReadyToStart`, `ReadyToResume`, `PausedByUser`, `Interrupted`,
  `Blocked`, `Completed`, or `NoActiveRun`

Treat missing or contradictory state as a finding, not permission to recreate a
feature. A status pass grants no implementation or remote authority.
