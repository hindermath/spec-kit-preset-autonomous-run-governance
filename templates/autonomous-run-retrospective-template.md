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

## Nutzungshilfe / Reader help

DE: Genau einen ausdrücklich beauftragten Feature-Lauf kontrolliert durch seine Phasen führen. Diese Vorlage ist ein auszufüllender Starter, kein bestandener Nachweis. Vorhandene passende Evidence weiterverwenden.
Die bestehenden technischen Feldnamen und Statuswerte nicht übersetzen oder
nur zum Bestehen eines Tests verändern. Einführung, Begriffe, Beispiel,
Ergebnis und Fehlerhilfe stehen im [deutschen Leserpfad](https://github.com/hindermath/spec-kit-preset-autonomous-run-governance/blob/main/docs/user-guide.md).

EN: Guide one explicitly authorized feature run through controlled phases. This template is a starter to complete, not passed evidence. Reuse suitable existing evidence.
Keep technical field names and states unchanged; never alter them just to pass.
See the [English reader path](https://github.com/hindermath/spec-kit-preset-autonomous-run-governance/blob/main/docs/user-guide.EN.md)
for introduction, terms, example, result and troubleshooting.
