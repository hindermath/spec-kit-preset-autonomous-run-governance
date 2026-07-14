---
description: Gracefully pause an autonomous Spec Kit run at a safe orchestration boundary.
---

## User Input

```text
$ARGUMENTS
```

This is a cooperative stop, not a process-manager kill. Give the stop request
priority over planned feature work. Do not launch another task, validation, or
remote action after receiving it.

At the next safe agent or command boundary:

1. Identify the active feature, branch, owned worktree changes, completed tasks,
   evidence, last passing gate, and last operation.
2. If an external command ended without a trustworthy result, record its state
   as `NeedsRevalidation`; never infer success from having started it.
3. Create or update `specs/<feature>/autonomous-run-state.json` from the installed
   template. Set `status` to `PausedByUser`, record the reason, UTC request time,
   safe boundary, and next exact action, and set
   `authorityRevalidationRequired` to `true`.
4. Validate the state with the installed Bash or PowerShell validator.
5. Preserve all owned and unrelated changes. Do not roll back, stage, commit,
   push, open or update a pull request, merge, bypass, or start another feature.

If no run can be identified unambiguously, remain read-only and report
`NoActiveRun` or `Blocked`. Finish with the checkpoint, dirty-state inventory,
last passing gate, uncertain operation, and the exact resume command.
