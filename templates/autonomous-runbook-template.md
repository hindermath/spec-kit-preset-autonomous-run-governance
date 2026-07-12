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

## Delivery and Closeout

Unavailable reviewers remain missing. Equivalent push and review-event checks
may be classified as duplicate noise; do not cancel without an explicit safe
concurrency contract.

Use one pre-named causal closeout only when committing current-head facts would
invalidate them or when facts exist only after merge. Keep it evidence-only and
single-commit-capable. Do not require the closeout to write its own provider URL,
reviewed result, or merge fact into itself.

## Resume

Persist completed task state, evidence, last passing gate, current authority,
and next exact action. On resume, recheck repository state and governance, then
continue without regenerating accepted phases unless drift is proven.
