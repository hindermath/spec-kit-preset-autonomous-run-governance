# Recovery und Fehlersuche / Recovery and Troubleshooting

[Handbuch / Manual](README.md) | [Kompatibilitaet / Compatibility](compatibility.md)

## Deutsch

### Recovery-Grundsatz

Nach einer Unterbrechung wird kein neuer Lauf erzeugt. Der vorhandene Lauf wird
aus Run-State, Git, Tasks, Evidence und Prozessresultaten rekonstruiert.

| Befund | Behandlung |
|---|---|
| Prozess startete, Ergebnis unbekannt | `NeedsRevalidation` |
| Task abgeschlossen und belegbar | Wiederverwenden |
| Task-Haken und State widersprechen sich | Git, Task und Evidence abgleichen |
| Fremde Arbeitsbaum-Aenderung | Erhalten und abgrenzen |
| Preset- oder Governance-Drift | Mandatory-Rule-Delta pruefen |
| Materialer Konflikt | `Blocked` und stoppen |
| Bewusste Pause | Nur explizites Resume |

### Run verweigert den Start

Pruefe:

1. existiert bereits `PausedByUser`, `Interrupted` oder `Active`,
2. ist das Feature eindeutig,
3. ist der Arbeitsbaum konfliktfrei abgrenzbar,
4. sind Constitution und Presets lesbar,
5. ist der Delivery-Modus aktuell autorisiert.

Status zuerst:

```text
/speckit.autonomous-status
```

### Resume erkennt Drift

Nicht jede Drift verlangt eine Neugenerierung. Zwingende aktuelle
Korrektheits-, Sicherheits-, Berechtigungs- oder Evidence-Regeln werden
minimal in betroffene Plan-, Task- oder Checklist-Eintraege eingearbeitet.
Reine Effizienzpraeferenzen bleiben Retrospektiveninput.

### PR ist gruen, aber nicht mergebar

Ein gruener Checkname reicht nicht. Pruefe:

- exakter PR-Head,
- tatsaechlich ausgefuehrter Befehl und Runner,
- Change Requests und aktuelle Threads,
- Branch-Schutz und Code-Owner-Freigabe,
- Merge-Konflikte,
- aktuelle Merge-Berechtigung.

### Reviewer ist nicht verfuegbar

Nicht verfuegbar bedeutet fehlende Evidence, nicht Zustimmung. Der Lauf bleibt
am Review-Gate, bis eine nach Repository-Policy zulaessige Evidence vorliegt.

### Validator meldet einen Fehler

Den Validator nicht umgehen. Pruefe Schema-Version, Pflichtfelder, Hashes,
vollstaendige Git-SHAs, Status-/Stage-Vokabular und Zeilen fuer jedes
deklariertes Gate. `Deliver` ist eine lesbare Workflow-Ueberschrift, aber kein
gueltiger maschinenlesbarer Stage-Wert.

### Kein eindeutiger aktiver Lauf

Keine Datei erzeugen und kein Feature raten. Status meldet `NoActiveRun` oder
`Blocked` mit den widerspruechlichen Kandidaten.

## English

### Recovery principle

An interruption does not create a new run. Reconstruct the existing run from
run state, Git, tasks, evidence, and process outcomes.

| Finding | Treatment |
|---|---|
| Process started, result unknown | `NeedsRevalidation` |
| Task completed with evidence | Reuse |
| Task checkbox and state disagree | Reconcile Git, task, and evidence |
| Unrelated worktree change | Preserve and isolate |
| Preset or governance drift | Run mandatory-rule delta audit |
| Material conflict | Set `Blocked` and stop |
| Deliberate pause | Explicit resume only |

### Run refuses to start

Check for an existing `PausedByUser`, `Interrupted`, or `Active` run; ambiguous
feature identity; unowned worktree changes; unreadable governance; and missing
current delivery authority. Run `/speckit.autonomous-status` first.

### Resume detects drift

Not every drift requires regeneration. Integrate current mandatory correctness,
security, permission, or evidence rules minimally into affected plan, task, or
checklist entries. Efficiency preferences remain retrospective input.

### PR is green but cannot merge

Check the exact PR head, commands and runners that actually executed, current
change requests and threads, branch protection and code-owner approval, merge
conflicts, and current merge authority.

### Reviewer is unavailable

Unavailable means missing evidence, not approval. The run remains at the review
gate until repository policy has acceptable evidence.

### Validator fails

Do not bypass it. Check schema version, mandatory fields, hashes, full Git
SHAs, state vocabulary, and one row for every declared gate. `Deliver` is a
human-readable workflow heading, not a valid machine stage.

### No unambiguous active run

Create no file and guess no feature. Status reports `NoActiveRun` or `Blocked`
with the conflicting candidates.
