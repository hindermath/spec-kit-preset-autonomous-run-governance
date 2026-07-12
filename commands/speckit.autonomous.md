---
description: Execute a complete Spec Kit feature under explicit delivery authority and convergence gates.
---

## User Input

```text
$ARGUMENTS
```

Use the request, repository constitution, agent guidance, current feature
metadata, and accepted feature artifacts as binding input.

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
9. Route out-of-scope findings to named follow-up evidence instead of silently
   expanding the feature.

## Remote Closeout

Remote review converges only when required checks pass and no actionable thread
remains. An unavailable reviewer is missing, never approval. Equivalent push
and review-request check sets may be classified as duplicate noise, but must
not be cancelled without an explicit safe concurrency contract.

Use one pre-named causal closeout only when current-head or post-merge facts
cannot be committed without invalidating themselves. Keep it evidence-only and
single-commit-capable; verify its own terminal provider facts externally.
Never create an empty feature, retrospective, or closeout pull request. If no
eligible diff exists, record that no remote delivery action is required.

On resume, recheck repository state, feature identity, governance, current
authority, completed tasks, evidence, and the last passing gate. Continue from
the next exact action without regenerating accepted phases unless drift exists.

Finish with task and artifact counts, validation, skipped conditions, review
state, follow-ups, remote identifiers when authorized, and exact local/remote
synchronization. Do not start the next feature implicitly.
