# Handbuch Autonomous Run Governance / Autonomous Run Governance Manual

[Zurueck zur Preset-README / Back to the preset README](../README.md)

## Deutsch

Dieses Handbuch erklaert einen einzelnen, ausdruecklich delegierten autonomen
Spec-Kit-Lauf. Es richtet sich an:

- Lernende, die den Ablauf erstmals nachvollziehen,
- Entwicklerinnen und Entwickler, die einen Lauf vorbereiten,
- Operatoren, die Status, Stop oder Resume ausfuehren,
- Reviewer, die Evidence und Remote-Closeout beurteilen,
- Maintainer, die Preset-Versionen und Schemas pflegen.

### Empfohlener Lernpfad

1. [Erster Lauf](getting-started.md)
2. [Berechtigung und Delivery](authority-and-delivery.md)
3. [Lebenszyklus und Operationen](lifecycle-and-operations.md)
4. [Evidence und Closeout](evidence-and-closeout.md)
5. [Recovery und Fehlersuche](recovery-and-troubleshooting.md)
6. [Kompatibilitaet](compatibility.md)

### Schnelleinstieg nach Rolle

| Rolle | Zuerst lesen | Danach |
|---|---|---|
| Lernende | Erster Lauf | Lebenszyklus und Operationen |
| Entwickler | Berechtigung und Delivery | Evidence und Closeout |
| Operator | Lebenszyklus und Operationen | Recovery und Fehlersuche |
| Reviewer | Evidence und Closeout | Kompatibilitaet |
| Maintainer | Kompatibilitaet | Gesamtes Handbuch |

### Grundregeln

- Installation ist keine Ausfuehrungsberechtigung.
- Ein Lauf besitzt genau einen aktuellen Delivery-Modus.
- Der Run-State ist ein Checkpoint, kein Ersatz fuer Git, Tasks oder Evidence.
- Absichtliche Pausen und unerwartete Unterbrechungen sind unterschiedliche
  Zustaende.
- Remote-Erfolg wird fuer den exakten Head und die tatsaechlich ausgefuehrten
  Gates belegt.
- Retrospektiven duerfen portable Erkenntnisse vorbereiten, aber keine
  Veroeffentlichung oder Preset-Aenderung selbst autorisieren.

## English

This manual explains one explicitly delegated autonomous Spec Kit run. Its
audiences are:

- learners following the workflow for the first time,
- developers preparing a run,
- operators using status, stop, or resume,
- reviewers assessing evidence and remote closeout,
- maintainers responsible for preset versions and schemas.

### Recommended learning path

1. [First run](getting-started.md)
2. [Authority and delivery](authority-and-delivery.md)
3. [Lifecycle and operations](lifecycle-and-operations.md)
4. [Evidence and closeout](evidence-and-closeout.md)
5. [Recovery and troubleshooting](recovery-and-troubleshooting.md)
6. [Compatibility](compatibility.md)

### Quick path by role

| Role | Read first | Continue with |
|---|---|---|
| Learner | First run | Lifecycle and operations |
| Developer | Authority and delivery | Evidence and closeout |
| Operator | Lifecycle and operations | Recovery and troubleshooting |
| Reviewer | Evidence and closeout | Compatibility |
| Maintainer | Compatibility | Full manual |

### Core rules

- Installation is not execution authority.
- A run has exactly one current delivery mode.
- Run state is a checkpoint, not a replacement for Git, tasks, or evidence.
- Deliberate pauses and unexpected interruptions are different states.
- Remote success is proven for the exact head and the gates that actually ran.
- Retrospectives may prepare portable learning, but cannot authorize
  publication or preset changes.
