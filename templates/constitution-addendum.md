
## Autonomous Spec Kit Delivery Governance

- Autonomous execution never implies remote write, merge, bypass,
  cancellation, secret, or provider-administration authority.
- Every run declares `LocalImplementation`, `PublishPR`, or `MergeAndSync` from
  the current request. Missing authority defaults to `LocalImplementation`.
- Optional stages repeat to documented convergence criteria, not a fixed count.
- Evidence is created before implementation and records exact acceptance paths,
  permissions, validation, residual risk, follow-up, and resume state.
- Shared writers are serialized. Project-specific mutable validation tokens
  authorize one explicit invocation per transition.
- Validation helpers receive an explicit repository root and pass only when
  exit status, required output, and structured/error channels are clean.
- Unavailable reviewers remain missing reviews. Provider bypass requires
  separate explicit authority and repository policy; it is never a preset
  default.
- Every Applicable acceptance gate is declared before implementation and must
  pass machine-checkable exact-head execution mapping before merge. Green names,
  aggregate status, approval, or bypass are not technical evidence.
- Workflow learning separates correctness/evidence fixes from efficiency
  preferences and rejects project-specific behavior from portable governance.
