
## Autonomous Task-shaping Rules

- Start with preflight, evidence creation, and checklist verification tasks.
- Add an early serialized task to create and validate the feature-local
  autonomous-run state. Update it at phase boundaries, graceful stops, hard
  gates, and completion; task checkboxes and evidence remain authoritative.
- Name stable task IDs and exact repository paths. Every remote or delivery task
  names the evidence path that records its result.
- Put a failing or missing proof before implementation when the contract is
  observable. Add a compile/execution-surface review before the first red run.
- Prove one representative vertical slice before repeated rollout.
- Serialize shared evidence, version, workflow, statistics, and agent-guidance
  files; do not mark them parallel.
- Add one prior mutable-token transition for each explicit validation invocation
  when repository policy requires such a token.
- Every helper task passes an explicit repository root and checks exit status,
  required output, and structured/error channels.
- Add trigger-based validation and an explicit disposition for every skipped
  conditional gate.
- Before a documentation- or evidence-only test skip, add a dependency-search
  task for executable validators that read changed paths, markers, schemas, or
  status values; update and run every affected validator in the same slice.
- Before commit or push, add a serialized exact-candidate task: stage only the
  intended paths, run `git diff --cached --check`, reconcile staged paths with
  repository status, and preserve unrelated work. In local-only mode, use an
  equivalent per-file or temporary-index check and restore the original index.
- Add remote tasks only for explicitly authorized modes. `MergeAndSync` includes
  check/review convergence, branch cleanup, and local/default-branch sync proof.
- Before merge, add an acceptance-scope mapping task for every required gate:
  record the workflow, job, runner or platform, and command that executed it.
  Missing technical scope blocks merge and cannot be replaced by bypass.
- Before implementation, add a serialized task to create the accepted
  gate-requirements JSON from the installed template. Give each gate a stable ID,
  Applicable or `N/A` state, exact scope, command tokens, optional runner or
  platform tokens, and any required rationale plus re-evaluation trigger.
- After final remote checks, add a serialized task to create temporary exact-head
  gate evidence, derive commands and runners from definitions or logs, and run
  the installed validator through `bash <validator.sh>` or
  `pwsh -NoProfile -File <validator.ps1>` because installed mode bits are not a
  portable contract. Missing rows, stale heads,
  duplicate Primary rows, unmatched tokens, and unowned Supplemental rows block
  merge. Do not commit the temporary evidence and thereby self-invalidate it.
- Keep current-head verification before merge. Route self-invalidating and true
  post-merge facts to one pre-named, single-commit-capable closeout.
- End with a retrospective task; do not add an empty retrospective branch or PR.
- Make stop/resume tasks explicit when long-running or remotely delivered work
  is in scope. A deliberate pause records `PausedByUser`; uncertain in-flight
  work is `NeedsRevalidation`, never an inferred pass.
