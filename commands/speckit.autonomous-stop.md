---
description: Gracefully pause an autonomous Spec Kit run at a safe orchestration boundary.
---

## User Input

```text
$ARGUMENTS
```

This is a cooperative stop, not a process-manager kill. Give the stop request
priority over planned feature work. Do not launch another task, validation, or
remote action after receiving it. In particular, do not start another routed
model phase or its preflight.

At the next safe agent or command boundary:

1. Identify the active feature, branch, owned worktree changes, completed tasks,
   evidence, last passing gate, and last operation.
2. If an external command ended without a trustworthy result, record its state
   as `NeedsRevalidation`; never infer success from having started it.
   For a routed model phase, preserve its role, profile, model, effort, process
   result, and output hash when available.
3. Create or update `specs/<feature>/autonomous-run-state.json` from the installed
   template. Set `status` to `PausedByUser`, record the reason, UTC request time,
   safe boundary, and next exact action, and set
   `authorityRevalidationRequired` to `true`.
4. Validate the state with the installed Bash or PowerShell validator.
5. Preserve all owned and unrelated changes. Do not roll back, stage, commit,
   push, open or update a pull request, merge, bypass, or start another feature.

If no run can be identified unambiguously, remain read-only and report
`NoActiveRun` or `Blocked`. Finish with the checkpoint, dirty-state inventory,
last passing gate, uncertain operation, and the exact resume command.

## Nutzungshilfe / Reader help

DE: Genau einen ausdrücklich beauftragten Feature-Lauf kontrolliert durch seine Phasen führen. Diese Command-Erklärung ändert keine Berechtigungen oder Voraussetzungen.
Die bestehenden technischen Feldnamen und Statuswerte nicht übersetzen oder
nur zum Bestehen eines Tests verändern. Einführung, Begriffe, Beispiel,
Ergebnis und Fehlerhilfe stehen im [deutschen Leserpfad](https://github.com/hindermath/spec-kit-preset-autonomous-run-governance/blob/main/docs/user-guide.md).

EN: Guide one explicitly authorized feature run through controlled phases. This command explanation changes no authority or prerequisites.
Keep technical field names and states unchanged; never alter them just to pass.
See the [English reader path](https://github.com/hindermath/spec-kit-preset-autonomous-run-governance/blob/main/docs/user-guide.EN.md)
for introduction, terms, example, result and troubleshooting.
