# Autonomous Run Retrospective

## Run Identity

| Field | Value |
|---|---|
| Feature and source revision | `[feature/revision]` |
| Delivery evidence | `[path]` |
| Delivery mode | `[mode]` |
| Remote result | `[N/A/PR/merge/sync]` |
| Interruptions and resumes | `[None or stop/status/resume evidence]` |

## Observations

| ID | Observation | Artifact kind | Project exclusions | Generic target rule | Occurrences | Confidence | Permission risk | Reproducible test | Decision |
|---|---|---|---|---|---:|---|---|---|---|
| AR-001 | `[finding]` | `[skill/template/script/etc.]` | `[excluded details]` | `[portable rule]` | `1` | `[Low/Medium/High]` | `[risk]` | `[temporary-project test]` | `[Promote/ObserveAgain/RejectProjectSpecific/Superseded/NoPromotion]` |

Correctness, security, permission, and evidence-integrity defects may be
promoted after one deterministic occurrence. Efficiency preferences need at
least two independent field observations.

## Outcome

- Local non-empty correction: `[paths or None]`
- Portable handoff: `[path or None]`
- Pending observations: `[IDs or None]`
- Rejected project details: `[items or None]`
- Next field gate: `[feature or synthetic test]`
- Resume-state quality: `[Valid/NeedsImprovement/N/A plus evidence]`
