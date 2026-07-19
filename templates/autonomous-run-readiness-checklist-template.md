# Autonomous Run Readiness Checklist

## Authority and Scope

- [ ] Exactly one delivery mode is recorded from current authority.
- [ ] Missing remote authority defaults to `LocalImplementation`.
- [ ] Accepted scope and explicit exclusions are unchanged.
- [ ] Repository constitution, agent guidance, and feature identity agree.
- [ ] The feature-local run state validates and agrees with branch, feature
      metadata, checkpoint history, accepted artifacts, tasks, and evidence.
- [ ] `PausedByUser` requires explicit resume; unexpected interruption and any
      uncertain operation have a documented revalidation boundary.

## Artifact Convergence

- [ ] Clarify has no remaining material planning ambiguity.
- [ ] Requirements and plan-review checklists pass or have accepted dispositions.
- [ ] Tasks are dependency-ordered and name exact evidence paths for delivery.
- [ ] After preset or governance drift, current mandatory correctness, security,
      permission, and evidence-integrity rules were compared with accepted Plan,
      Tasks, and checklists; applicable missing rules were minimally added and
      efficiency-only preferences did not rewrite accepted artifacts.
- [ ] Analyze has no Critical/High finding; Medium findings are resolved or owned.
- [ ] Every implementation task is complete or conditionally evidenced.

## Proof and Validation

- [ ] Evidence existed before the first implementation edit.
- [ ] One representative vertical slice has failing and green proof.
- [ ] Negative matrices preserve each expected failure and ownership boundary.
- [ ] Shared writers were serialized.
- [ ] Every mutable validation-token transition maps to one explicit invocation.
- [ ] Helpers received an explicit repository root.
- [ ] Exit status, required output, and structured/error channels were inspected.
- [ ] Changed documentation, evidence, schemas, and status markers were searched
      for executable validator consumers before any test gate was skipped.
- [ ] The exact intended delivery candidate passed `git diff --cached --check`
      or an equivalent non-mutating local-only check.
- [ ] Staged paths were reconciled with untracked and unstaged repository state;
      unrelated work and any prior local-only index state were preserved.
- [ ] Triggered validation passed; skipped gates have an explicit rationale.
- [ ] Every acceptance gate was declared before implementation in the reviewed
      gate-requirements artifact with stable ID, scope, and required tokens.

## Remote Delivery

- [ ] Remote tasks exist only for the authorized delivery mode.
- [ ] Required review-context checks pass.
- [ ] Every acceptance-specific gate maps to the workflow, job, runner or
      platform, and command that actually executed the required proof.
- [ ] Temporary provider evidence matches the accepted requirements hash and
      exact current reviewed head, and the installed validator passes.
- [ ] Every declared gate has exactly one Primary row; Supplemental evidence
      points to it, and `N/A` includes rationale plus re-evaluation trigger.
- [ ] Executed commands and runners were read from workflow definitions or logs,
      not inferred from green aggregate, workflow, job, or platform-shaped names.
- [ ] Exact-head provider evidence was not committed before merge and therefore
      did not invalidate its own reviewed-head claim.
- [ ] No green aggregate or platform-named tooling job is credited for
      acceptance scope that it did not execute.
- [ ] No actionable review thread remains.
- [ ] Unavailable reviews are recorded as missing, not successful.
- [ ] Duplicate event runs are classified without unauthorized cancellation.
- [ ] Any bypass has separate explicit authority and repository-policy evidence.
- [ ] A causal closeout, if required, was pre-named and is single-commit-capable.
- [ ] No empty feature, retrospective, or closeout pull request is proposed.
- [ ] Merge, cleanup, and default-branch synchronization are proven when required.
- [ ] Schema-1.1 closeout records merge/publication, default-branch sync,
      manifest-declared post-merge actions, and final validation independently.
- [ ] `Completed` is set only after every applicable closeout field is terminal.

## Learning and Finish

- [ ] Resume state and the next exact action are recorded.
- [ ] A graceful stop, if requested, preserved work at a safe boundary and did
      not infer commit, push, rollback, merge, or process-kill authority.
- [ ] Out-of-scope findings have owner, evidence path, and re-evaluation trigger.
- [ ] Retrospective decisions separate portable rules from project specifics.
- [ ] No empty retrospective branch or pull request was created.
- [ ] The next feature was not started implicitly.
