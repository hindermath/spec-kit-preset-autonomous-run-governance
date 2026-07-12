---
description: Extract, validate, and classify reusable learning from a completed autonomous Spec Kit run.
---

## User Input

```text
$ARGUMENTS
```

Read the completed feature artifacts, evidence, validation history, remote
closeout, and existing retrospective ledger. Do not alter feature behavior or
rewrite accepted feature artifacts.

For each observation record:

- source feature and immutable evidence path
- observation and failure or efficiency boundary
- artifact kind: command, skill, runbook, addendum, template, checklist,
  evidence structure, script requirement, or project-specific implementation
- project-specific exclusions
- provider-neutral target rule
- occurrence count and confidence
- permission and evidence risks
- reproducible synthetic or temporary-project test
- decision: `Promote`, `ObserveAgain`, `RejectProjectSpecific`, `Superseded`,
  or `NoPromotion`

Correctness, security, permission, and evidence-integrity defects may be fixed
after one deterministic occurrence. Efficiency preferences require at least two
independent field observations before promotion.

Update repository-local workflow surfaces only for a concrete, non-empty
improvement. Keep shared agent guidance synchronized. Produce a portable handoff
only for reusable findings, and never treat the handoff as authority to publish,
merge, bypass, or modify another repository.

Finish with promoted rules, observations still pending, rejected project
details, changed surfaces, validation, and the next field gate. Create no empty
branch or pull request.
