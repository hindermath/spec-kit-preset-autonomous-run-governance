
## Autonomous-run Applicability

Specify whether the run changes delivery-set validation, routed-phase result
semantics, or gate-evidence lifecycle. New delivery decisions use schema 2.0;
legacy schema 1.0 is historical audit evidence only.

Record:

- intended delivery mode and its explicit authority source
- repository-local feature identity and accepted input artifacts
- scope boundaries that autonomy must not expand
- user-visible, operational, security, accessibility, and historical evidence
  triggers relevant to the feature
- whether a causal closeout may be required and why
- whether mutable validation tokens exist; otherwise record `N/A`
- acceptance gates with stable IDs, Applicable or `N/A` state, required scope,
  command tokens, optional runner/platform tokens, rationale, and re-evaluation
  trigger
- portable retrospective and follow-up boundaries
- the feature-local run-state path, deliberate-stop behavior, unexpected-
  interruption recovery, and conditions that require explicit resume or block

Do not place provider credentials, transient model names, or implicit merge and
bypass authority in the feature specification.
