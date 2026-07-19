# Erster autonomer Lauf / First Autonomous Run

[Handbuch / Manual](README.md) | [Berechtigung und Delivery / Authority and delivery](authority-and-delivery.md)

## Deutsch

### Voraussetzungen

Vor dem ersten Lauf muessen folgende Bedingungen erfuellt sein:

1. Das Ziel ist ein Git-Repository mit akzeptierten Spec-Kit-Artefakten oder
   einer eindeutig beschriebenen neuen Feature-Anforderung.
2. Spec Kit `>=0.8.3` ist installiert.
3. `autonomous-run-governance >=0.3.1` ist aktiv.
4. Constitution und Agent-Guidance sind lesbar.
5. Der Arbeitsbaum ist bekannt; fremde Aenderungen sind abgegrenzt.
6. Delivery-Modus und erlaubte Remote-Aktionen sind ausdruecklich genannt.

### Installation

Veröffentlichter Tag:

```bash
specify preset add \
  --from https://github.com/hindermath/spec-kit-preset-autonomous-run-governance/archive/refs/tags/v0.3.1.zip \
  --priority 70
```

Lokaler Entwicklungsstand:

```bash
specify preset add --dev /path/to/autonomous-run-governance --priority 70
```

Pruefung:

```bash
specify preset list
specify preset info autonomous-run-governance
specify preset resolve autonomous-run-state-template
specify preset resolve autonomous-run-readiness-checklist-template
```

Erwartet werden Version `0.3.1`, Prioritaet `70` und genau ein Beitrag je
autonomem Befehl.

### Readiness vor dem Start

Beantworte vor der Delegation:

| Frage | Sichere Antwort |
|---|---|
| Welches Feature? | Eindeutige Nummer, Branch oder Intake-Datei |
| Welche Aenderungen gehoeren dem Lauf? | Benannte Pfade und Artefakte |
| Welche Aenderungen sind fremd? | Read-only erhalten |
| Welcher Delivery-Modus? | Genau einer der drei Modi |
| Welche Gates gelten? | Vor Implementierung deklariert |
| Welche Remote-Rechte gelten jetzt? | Explizit und aktuell |
| Wo liegt Evidence? | Benannter Feature-Pfad |

### Erstes sicheres Beispiel

```text
/speckit.autonomous

Bearbeite Feature 042 vollstaendig nach Constitution und installierten Presets.
Delivery-Modus: LocalImplementation.
Erlaubt: lokale Aenderungen und lokale Validierung.
Nicht erlaubt: Commit, Push, PR, Merge, Bypass oder Provider-Administration.
Bewahre alle fremden Arbeitsbaum-Aenderungen.
```

Der Agent prueft zuerst vorhandene Run-States und darf einen absichtlich
pausierten Lauf nicht als neues Feature ueberschreiben.

### Erwartete Artefakte

- akzeptierte Spec-, Plan-, Tasks- und Checklist-Artefakte,
- `specs/<feature>/autonomous-run-state.json`,
- Run-Evidence und deklarierte Gate-Anforderungen,
- abgeschlossene oder begruendet dispositionierte Tasks,
- finale Validierung fuer den gewaehlten Delivery-Modus.

### Status pruefen

```text
/speckit.autonomous-status
```

Status veraendert keine Datei und startet keinen Lauf. Er meldet Feature,
Branch, Zustand, Drift, Task-Fortschritt, letzte belastbare Operation und den
naechsten exakten Schritt.

## English

### Prerequisites

Before the first run:

1. The target is a Git repository with accepted Spec Kit artifacts or a
   clearly described new feature request.
2. Spec Kit `>=0.8.3` is installed.
3. `autonomous-run-governance >=0.3.1` is active.
4. The constitution and agent guidance are readable.
5. Worktree ownership and unrelated changes are known.
6. Delivery mode and permitted remote actions are explicit.

### Installation

Published tag:

```bash
specify preset add \
  --from https://github.com/hindermath/spec-kit-preset-autonomous-run-governance/archive/refs/tags/v0.3.1.zip \
  --priority 70
```

Development checkout:

```bash
specify preset add --dev /path/to/autonomous-run-governance --priority 70
```

Verify:

```bash
specify preset list
specify preset info autonomous-run-governance
specify preset resolve autonomous-run-state-template
specify preset resolve autonomous-run-readiness-checklist-template
```

Expect version `0.3.1`, priority `70`, and one contribution for each autonomous
command.

### Readiness questions

| Question | Safe answer |
|---|---|
| Which feature? | Unambiguous number, branch, or intake file |
| Which changes belong to the run? | Named paths and artifacts |
| Which changes are unrelated? | Preserve read-only |
| Which delivery mode? | Exactly one of the three modes |
| Which gates apply? | Declared before implementation |
| Which remote authority is current? | Explicit and current |
| Where is evidence stored? | Named feature path |

### First safe example

```text
/speckit.autonomous

Complete feature 042 under the constitution and installed presets.
Delivery mode: LocalImplementation.
Allowed: local edits and local validation.
Not allowed: commit, push, PR, merge, bypass, or provider administration.
Preserve all unrelated worktree changes.
```

The agent first checks existing run state and must not overwrite a deliberately
paused run as a new feature.

### Expected artifacts

- accepted spec, plan, tasks, and checklist artifacts,
- `specs/<feature>/autonomous-run-state.json`,
- run evidence and declared gate requirements,
- completed or explicitly dispositioned tasks,
- final validation for the selected delivery mode.

Use `/speckit.autonomous-status` for a read-only view of feature, branch, state,
drift, task progress, last trustworthy operation, and next exact action.
