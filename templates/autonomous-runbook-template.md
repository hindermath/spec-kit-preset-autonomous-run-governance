# Autonomous Spec Kit Runbook

## Authority

| Mode | Authorized outcome | Forbidden without new authority |
|---|---|---|
| `LocalImplementation` | Local artifacts, implementation, and validation | Commit, push, PR, merge, provider changes |
| `PublishPR` | Local outcome plus commit, push, and PR work | Merge, bypass, provider administration |
| `MergeAndSync` | Publish, converge reviews/checks, policy-compliant merge, cleanup, local sync | Undelegated bypass, destructive provider actions, next feature |

Default: `LocalImplementation`.

## Preflight

- clean or explicitly owned working tree
- current feature identity and accepted artifacts
- constitution and agent guidance
- installed preset stack and repository prerequisites
- complete feature checklists
- explicit delivery mode and hard stop conditions
- validated feature-local autonomous-run state and safe stop boundary

## Stage Order

1. Specify
2. Clarify to convergence
3. requirements and feature checklists
4. Plan
5. plan review and remediation
6. Tasks
7. Analyze and remediation to convergence
8. Implement and task-state updates
9. triggered local validation and evidence completion
10. authorized delivery closeout
11. retrospective and portable handoff

The word `Deliver` may appear as a generated skill heading, but it is not a
machine-state stage. Persist `Publish` while publishing, `Review` while
converging provider checks and review threads, and `MergeAndSync` during the
authorized merge and default-branch synchronization.

## Convergence

- Clarify: no answer would materially alter plan, tasks, validation, acceptance,
  or scope.
- Checklists: every item passes or has an accepted disposition.
- Analyze: no Critical/High issue; every Medium is fixed or accepted with owner.
- Implement: every task is complete or conditionally evidenced.
- Remote: required checks pass and no actionable thread remains.

## Proof and Validation

Create evidence before implementation. Deliver one representative vertical
slice with failing and green proof. Group negative cases only when each
expected failure and ownership boundary remains visible.

Use repository-defined validation. Pass the repository root explicitly to
helpers. A successful result needs the expected exit status, required output,
and no fatal structured/error-channel signal. When a mutable token is required,
one transition covers exactly one invocation.

Do not classify a Markdown, status, schema, or evidence change as test-free
from its file type alone. Search the repository for executable validators that
read changed paths, markers, schemas, or state values. Update and run every
affected validator before recording a skipped executable gate.

Before an authorized commit, stage only the intended candidate, run
`git diff --cached --check`, and reconcile staged paths with repository status.
This closes the untracked-file gap in `git diff --check` without absorbing
unrelated work. In `LocalImplementation`, use an equivalent per-file or
temporary-index check and restore the prior index state.

## Delivery and Closeout

Unavailable reviewers remain missing. Equivalent push and review-event checks
may be classified as duplicate noise; do not cancel without an explicit safe
concurrency contract.

Map every acceptance-specific gate to the workflow, job, runner or platform,
and command that executed it. Green status and platform-shaped names are not
evidence for commands the job did not run. Missing required scope blocks merge;
a permission or ruleset bypass cannot supply technical proof.

Before implementation, create a reviewed gate-requirements JSON artifact from
the installed template. Use stable gate IDs and declare Applicable gates with
required command tokens plus any runner or platform tokens. `N/A` gates require
a rationale and re-evaluation trigger.

After final checks, inspect workflow definitions or job logs and create the
provider-neutral evidence JSON in a temporary location. Hash the accepted
requirements, bind every row to the full current reviewed head, and run the
installed validator through `bash <validator.sh>` or
`pwsh -NoProfile -File <validator.ps1>`. Preset installation may not preserve
executable mode bits. Exactly one Primary row is required per gate; explicitly
linked Supplemental rows are allowed. Missing, stale,
contradictory, empty, or token-mismatched evidence blocks merge.

Do not commit the temporary exact-head evidence before merge: that commit would
create a different head and invalidate its own claim. Record the immutable run
and validator result through the causal-closeout boundary when a durable
post-delivery record is required.

Use one pre-named causal closeout only when committing current-head facts would
invalidate them or when facts exist only after merge. Keep it evidence-only and
single-commit-capable. Do not require the closeout to write its own provider URL,
reviewed result, or merge fact into itself.

## Resume

Persist `specs/<feature>/autonomous-run-state.json` at logical phase boundaries,
graceful stops, hard gates, and completion. The state index records task and
accepted-artifact hashes, checkpoint commit, last passing gate, last operation,
and next exact action. Tasks, evidence, and Git remain authoritative.

Use `speckit.autonomous-status` for a read-only inspection. A deliberate stop
uses `speckit.autonomous-stop`, records `PausedByUser`, preserves all work, and
performs no implicit commit or remote action. It takes effect at the next safe
agent or command boundary; it is not an atomic process-manager kill.

Use `speckit.autonomous-resume` for `PausedByUser`. After an unexpected
interruption, `speckit.autonomous` may continue only after reconciling state,
Git, feature metadata, accepted-artifact hashes, tasks, evidence, governance,
current authority, and any operation marked `NeedsRevalidation`. Do not
regenerate accepted phases unless drift is proven.

When installed preset or governance versions changed, compare their current
mandatory correctness, security, permission, and evidence-integrity rules with
the accepted Plan, Tasks, and checklists. If an applicable rule is missing,
amend only those affected entries in place and rerun readiness plus Analyze
before implementation. Preserve accepted scope and decisions; a new efficiency
preference is retrospective input, not authority for retroactive task churn.
Record the compared versions and delta disposition in evidence. Material
conflict, unknown dirty changes, or ambiguous feature identity sets `Blocked`
and stops.
