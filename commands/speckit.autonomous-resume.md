---
description: Resume a paused or interrupted autonomous Spec Kit run after a full drift and authority audit.
---

## User Input

```text
$ARGUMENTS
```

Resume only an existing run. Do not create a new feature when an active run
cannot be identified. `PausedByUser` requires this explicit command;
`speckit.autonomous` must not resume it implicitly.

Before any mutation:

1. Validate `specs/<feature>/autonomous-run-state.json` and reconcile it with
   current branch, feature metadata, Git history, accepted-artifact hashes,
   `tasks.md`, evidence, and owned/unrelated worktree changes.
2. Re-read constitution, agent guidance, installed preset versions, and current
   feature prerequisites. Re-evaluate delivery authority; a recorded delivery
   mode is historical evidence, not current permission.
3. Classify drift:
   - no drift: continue from `nextExactAction`;
   - non-material governance or preset drift: rerun the affected readiness or
     Analyze gate before implementation;
   - uncertain in-flight operation: rerun only the affected validation or task;
   - material conflict, unknown dirty changes, missing checkpoint, or ambiguous
     feature identity: set `Blocked` and stop.
4. Preserve accepted Specify, Clarify, Plan, Tasks, and checklist phases unless
   their artifacts actually drifted. Task checkboxes, evidence, and Git history
   take precedence over a stale state index.
5. Set `status` to `Active`, clear the stop fields, retain
   `authorityRevalidationRequired` until current authority is proven, validate
   the updated state, and continue under `speckit.autonomous` convergence rules.

Finish with reconstructed state, drift disposition, current authority, resumed
action, and any gate that was deliberately rerun. Never start the next feature
implicitly.
