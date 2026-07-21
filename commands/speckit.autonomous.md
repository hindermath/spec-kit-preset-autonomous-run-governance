---
description: Execute a complete Spec Kit feature under explicit delivery authority and convergence gates.
---

## User Input

```text
$ARGUMENTS
```

Use the request, repository constitution, agent guidance, current feature
metadata, and accepted feature artifacts as binding input.

Before creating a feature, inspect repository metadata and
`specs/<feature>/autonomous-run-state.json`. A valid `PausedByUser` state MUST
stop this command and direct the user to `speckit.autonomous-resume`. A valid
`Interrupted` state may resume only after the full drift, operation, governance,
and authority audit defined by that command. Never overwrite an active run with
a new feature.

Before branch or feature creation, inspect whether `intake-review-governance`
is installed and repository policy marks intake review as required. If absent
or inactive, record `N/A`; Preset 9 is not a hidden dependency. If active,
require exactly one current result for the binding intake and validate its
normalized SHA-256. Only `Ready` or human-approved
`ReadyWithAcceptedRisks` passes. Missing evidence, drift, ambiguity, open
blocking findings, or unanswered questions stops before Specify. Add the
accepted result and target hashes to `acceptedArtifacts`.

## Authority Gate

Determine exactly one delivery mode from explicit current authority:

- `LocalImplementation`: implement and validate locally; no remote writes.
- `PublishPR`: additionally commit, push, and create or update a pull request.
- `MergeAndSync`: additionally converge remote checks/reviews, merge under the
  repository policy, clean branches, and synchronize local default branch.

Default to `LocalImplementation` when remote authority is absent or ambiguous.
Never infer merge, bypass, cancellation, secret access, or provider-admin
authority from general autonomy.

## Orchestration

1. Preflight repository state, feature identity, governance, prerequisites, and
   checklists. Stop for a material conflict, destructive ambiguity, missing
   required authority, or failed hard gate.
2. Execute Specify, repeated Clarify, requirements checklists, Plan,
   plan-review remediation, Tasks, repeated Analyze, Implement, validation, and
   the authorized delivery closeout in dependency order.
3. Converge by outcome, not repetition count. Clarification has no material
   planning ambiguity; checklists pass or carry accepted dispositions; Analyze
   has no Critical/High finding and every Medium is fixed or accepted with an
   owner; implementation tasks are complete or conditionally evidenced.
4. Create evidence before the first implementation edit. Name exact evidence
   paths for remote and delivery tasks. Keep scope, decisions, commands,
   results, skipped triggers, residual risk, permissions, and resume state
   current.
   Create `specs/<feature>/autonomous-run-state.json` from the installed state
   template and update it at logical phase boundaries, graceful stops, hard
   gates, and completion. Validate every persisted transition.
   The generated skill heading `Deliver` is a workflow section, not a valid
   machine-state stage. During remote closeout record `Publish`, `Review`, or
   `MergeAndSync` according to the current operation; never persist `Deliver`.
   Schema `1.1` records merge or publication, default-branch synchronization,
   manifest-declared post-merge actions, and final validation separately.
5. Prove one representative vertical slice and its failing/green contract
   before broad repetition. Group negative cases only when every expected
   failure and ownership boundary remains explicit.
6. Serialize shared evidence, version, workflow, statistics, and agent-guidance
   writers. If a mutable validation token is required, one transition covers
   exactly one explicit invocation.
7. Pass repository roots explicitly to validation helpers. A pass needs the
   expected exit status, required output, and a clean structured/error channel.
8. Before classifying a change as documentation- or evidence-only and skipping
   executable tests, search for validators that read the changed paths, markers,
   schemas, or status values. Update and run every affected validator in the
   same change.
9. Validate the exact delivery candidate before every authorized commit. Stage
   only intended paths, run `git diff --cached --check`, and reconcile the
   staged path inventory with repository status so intended untracked or
   unstaged files cannot escape validation. Preserve unrelated work. In
   `LocalImplementation`, use a per-file or temporary-index equivalent and
   restore the original index state.
10. Route out-of-scope findings to named follow-up evidence instead of silently
   expanding the feature.
11. Before implementation, resolve the preset's gate-requirements template and
   declare every acceptance gate in a reviewed feature artifact. Applicable
   gates name required command tokens and any runner or platform tokens; `N/A`
   gates name their rationale and re-evaluation trigger.
12. Before merge, generate provider-neutral gate evidence for the exact current
   reviewed head in a temporary location and run the installed validator through
   `bash <validator.sh>` or `pwsh -NoProfile -File <validator.ps1>`; installers
   may not preserve executable mode bits. Every gate needs exactly one Primary row;
   supplemental rows must point to that primary evidence. Missing, stale,
   contradictory, empty, or token-mismatched evidence blocks merge.

## Remote Closeout

Remote review converges only when required checks pass and no actionable thread
remains. An unavailable reviewer is missing, never approval. Equivalent push
and review-request check sets may be classified as duplicate noise, but must
not be cancelled without an explicit safe concurrency contract.

Before merge, map every acceptance-specific gate to the workflow, job, runner
or platform, and command that actually executed it. A green aggregate or a
platform-named job proves only its executed scope. Missing required proof
blocks merge and cannot be replaced by a permission or ruleset bypass.

Derive `executedCommand` and `runnerOrPlatform` from the workflow definition or
job log, not from a check, workflow, or job name. The read-only validator checks
the accepted requirements hash, full reviewed head, gate completeness,
Applicable/N/A boundaries, required command and runner tokens, and Primary versus
Supplemental evidence. Its successful exit grants no remote authority.

Keep exact-head provider evidence temporary during the merge decision. Committing
that evidence would create a new head and invalidate its own reviewed-head claim.
Use the existing causal-closeout boundary for post-delivery facts.

Use one pre-named causal closeout only when current-head or post-merge facts
cannot be committed without invalidating themselves. Keep it evidence-only and
single-commit-capable; verify its own terminal provider facts externally.
Never create an empty feature, retrospective, or closeout pull request. If no
eligible diff exists, record that no remote delivery action is required.

On unexpected interruption, reconstruct the run from state, Git, tasks, and
evidence. Mark an operation without a trustworthy result `NeedsRevalidation`.
Recheck repository state, feature identity, governance, current authority,
completed tasks, evidence, and the last passing gate. Continue from the next
exact action without regenerating accepted phases unless drift exists. A
deliberate `PausedByUser` state never resumes through this command; it requires
`speckit.autonomous-resume`.

A user stop or pause request has priority over orchestration. Do not start new
work after it. At the next safe boundary, follow `speckit.autonomous-stop`; do
not treat a prompt command as an atomic external-process kill.

Finish with task and artifact counts, validation, skipped conditions, review
state, follow-ups, remote identifiers when authorized, and exact local/remote
synchronization. Set `Completed` only when every applicable schema-1.1 closeout
field is terminal and final validation is `Completed`. Do not start the next
feature implicitly.
