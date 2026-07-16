# Autonomous Run Governance Preset

Version: `0.2.2`
Requires: `spec-kit >= 0.8.3`
Recommended priority: `70`

## Purpose / Zweck

This optional preset governs a complete delegated Spec Kit feature run from
intake through implementation and, when explicitly authorized, pull-request
delivery and synchronization. It adds lifecycle checkpoints, convergence rules,
evidence contracts, and permission boundaries without changing Spec Kit core.

*Dieses optionale Preset steuert einen vollständig delegierten Spec-Kit-
Feature-Lauf von der Eingabe bis zur Implementierung und, wenn ausdrücklich
autorisiert, bis zur Pull-Request-Auslieferung und Synchronisierung. Es ergänzt
Lebenszyklus-Checkpoints, Konvergenzregeln, Evidence-Verträge und
Berechtigungsgrenzen, ohne Spec Kit Core zu verändern.*

The main quality goal is not merely higher delivery speed. It is more
reviewable work per complete quality cycle: accepted requirements, executable
proof, review convergence, controlled delivery, and reusable learning.

*Das wichtigste Qualitätsziel ist nicht nur eine höhere
Liefergeschwindigkeit. Entscheidend ist mehr überprüfbare Arbeit pro
vollständigem Qualitätszyklus: akzeptierte Anforderungen, ausführbarer
Nachweis, Review-Konvergenz, kontrollierte Auslieferung und wiederverwendbares
Lernen.*

## Audience / Zielgruppen

Use this preset when:

- a maintainer wants to delegate a complete Spec Kit feature without approving
  every normal phase separately;
- a learner should see a repeatable, evidence-first delivery workflow;
- a team needs explicit stop, status, and resume behavior for long agent runs;
- local implementation and remote delivery authority must remain separate;
- several governance presets must compose without duplicating commands or
  silently weakening project rules.

*Dieses Preset eignet sich, wenn:*

- *Maintainer einen vollständigen Spec-Kit-Feature-Lauf delegieren möchten,
  ohne jede normale Phase einzeln freizugeben;*
- *Lernende einen wiederholbaren, Evidence-orientierten Lieferprozess
  nachvollziehen sollen;*
- *ein Team explizites Status-, Stop- und Resume-Verhalten für lange
  Agentenläufe benötigt;*
- *lokale Implementierung und Remote-Auslieferungsrechte getrennt bleiben
  müssen;*
- *mehrere Governance-Presets ohne doppelte Commands oder stille Abschwächung
  der Projektregeln kombiniert werden sollen.*

## What It Provides / Lieferumfang

- `speckit.autonomous` for convergence-based end-to-end feature delivery
- `speckit.autonomous-status` for read-only inspection
- `speckit.autonomous-stop` for a cooperative pause at a safe boundary
- `speckit.autonomous-resume` for audited recovery after pause or interruption
- `speckit.autonomous-retrospective` for classified reusable learning
- Constitution, Spec, Plan, Tasks, and Agent addenda
- runbook, evidence, retrospective, and readiness-checklist templates
- machine-readable run-state, gate-requirements, and exact-head evidence
  templates
- read-only Bash and PowerShell validators
- field evidence from product, audit, closure, stop, and real resume runs

*Das Preset liefert fünf Commands, Addenda für die zentralen Spec-Kit-
Artefakte, Vorlagen für Runbook, Evidence, Retrospektive und Readiness sowie
maschinenlesbare Zustands- und Gate-Verträge mit read-only Bash- und
PowerShell-Validierung.*

## What It Does Not Provide / Nicht enthalten

The preset does not choose a programming language, test framework, CI provider,
branch version scheme, agent vendor, merge strategy, or project architecture.
It does not grant GitHub, GitLab, repository-administration, bypass, merge, or
deployment authority. Repository guidance and the current user instruction
remain authoritative.

*Das Preset wählt keine Programmiersprache, kein Testframework, keinen
CI-Anbieter, kein Branch-Versionsschema, keinen Agent-Anbieter, keine
Merge-Strategie und keine Projektarchitektur. Es erteilt keine GitHub-,
GitLab-, Repository-Administrations-, Bypass-, Merge- oder
Deployment-Berechtigung. Die Repository-Regeln und der aktuelle
Benutzerauftrag bleiben verbindlich.*

## Core Concepts / Grundbegriffe

### Delivery modes / Auslieferungsmodi

| Mode | Local changes | Push | Pull request | Merge and main sync |
|---|---:|---:|---:|---:|
| `LocalImplementation` | Yes | No | No | No |
| `PublishPR` | Yes | Explicit authority required | Explicit authority required | No |
| `MergeAndSync` | Yes | Explicit authority required | Explicit authority required | Explicit authority required |

`LocalImplementation` is the safe default. A mode name describes the requested
workflow but never overrides repository permissions, protected-branch rules,
required checks, or a later stop instruction.

*`LocalImplementation` ist der sichere Standard. Ein Modus beschreibt den
gewünschten Ablauf, überschreibt aber niemals Repository-Berechtigungen,
Branch-Schutz, Pflichtprüfungen oder einen späteren Stop-Auftrag.*

### Convergence / Konvergenz

Optional phases are repeated only while they produce material questions,
findings, or changes:

1. Clarify until no answer would materially change Plan or Tasks.
2. Review Plan and checklists until no blocking planning issue remains.
3. Analyze after Tasks and after material remediation until no Critical or High
   implementation blocker remains.
4. Review remote checks and actionable threads until they converge or an
   explicit external boundary is recorded.

*Optionale Phasen werden nur wiederholt, solange sie wesentliche Fragen,
Findings oder Änderungen erzeugen. Ein Lauf ist nicht deshalb konvergent, weil
ein Command mehrfach ausgeführt wurde, sondern weil keine relevante offene
Entscheidung mehr verbleibt.*

### Safe boundary / Sicherer Haltepunkt

A safe boundary is a point where the current operation has a trustworthy
result, repository state can be inspected, and no half-applied write is
silently treated as complete. Stop is cooperative; it does not claim to kill an
arbitrary external process atomically.

*Ein sicherer Haltepunkt liegt vor, wenn die aktuelle Operation ein
vertrauenswürdiges Ergebnis besitzt, der Repository-Zustand prüfbar ist und
kein halb ausgeführter Schreibvorgang still als abgeschlossen gilt. Stop ist
kooperativ und beendet keinen beliebigen externen Prozess atomar.*

### Exact-head evidence / Exakter Head-Nachweis

Acceptance requirements are declared before implementation. Provider evidence
is collected for the final reviewed commit and validated against the immutable
full head SHA. This prevents a platform-named tooling job from being credited
for a runtime gate it never executed.

*Abnahmeanforderungen werden vor der Implementierung festgelegt.
Provider-Evidence wird für den final geprüften Commit gesammelt und gegen die
vollständige unveränderliche Head-SHA validiert. Dadurch kann ein nach einer
Plattform benannter Tooling-Job nicht fälschlich einen nie ausgeführten
Runtime-Gate erfüllen.*

## Prerequisites / Voraussetzungen

Before installation:

1. Install a compatible GitHub Spec Kit CLI.
2. Ensure the target repository already has a valid Spec Kit integration.
3. Keep the repository's agent guidance and constitution under version control.
4. Decide which remote actions the current run may perform.
5. Install the normal governance presets first when the project uses the
   recommended seven-preset composition.
6. Have `bash` plus Python on macOS/Linux or PowerShell 7 on Windows for the
   bundled validators.

*Vor der Installation müssen eine kompatible Spec-Kit-Version, eine gültige
Projektintegration, versionierte Agent-Guidance und Constitution sowie eine
klare Remote-Berechtigung vorhanden sein. Für die Validatoren werden unter
macOS/Linux Bash und Python oder unter Windows PowerShell 7 benötigt.*

## Installation / Installation

### Published tag / Veröffentlichter Tag

```bash
specify preset add \
  --from https://github.com/hindermath/spec-kit-preset-autonomous-run-governance/archive/refs/tags/v0.2.2.zip \
  --priority 70
```

### Development checkout / Entwicklungs-Checkout

```bash
specify preset add --dev /path/to/autonomous-run-governance --priority 70
```

### Recommended composition / Empfohlene Kombination

Install the normal governance matrix with priorities below `70`, then install
this optional preset last:

| Priority | Preset |
|---:|---|
| 10 | `security-governance` |
| 20 | `architecture-governance` |
| 30 | `isaqb-architecture-governance` |
| 40 | `a11y-governance` |
| 50 | `cross-platform-governance` |
| 60 | `agent-parity-governance` |
| 70 | `autonomous-run-governance` |

*Die normale Governance-Matrix wird zuerst mit niedrigeren Prioritäten
installiert; dieses optionale Preset folgt zuletzt mit Priorität `70`.*

### Verify installation / Installation prüfen

```bash
specify preset list
specify preset info autonomous-run-governance
specify preset resolve
specify check
```

Confirm that each autonomous command or generated skill appears exactly once on
every maintained agent surface. Installation does not start a feature.

*Prüfe, dass jeder autonome Command beziehungsweise Skill auf jeder gepflegten
Agentenoberfläche genau einmal erscheint. Die Installation startet kein
Feature.*

## First Run / Erster Lauf

Start conservatively with local implementation:

```text
$speckit-autonomous

Use the binding intake file `Lastenheft_Example.md`.
Run the complete Spec Kit workflow for the existing repository.
Delivery mode: LocalImplementation.
Do not push, create a pull request, merge, bypass protection, or change remote
settings. Stop after implementation, validation, and the local retrospective.
```

*Der erste Lauf sollte lokal bleiben. Dadurch können Team und Lernende
Artefakte, Konvergenz, Tasks, Evidence und Validierung prüfen, bevor
Remote-Rechte delegiert werden.*

## Complete Prompt Examples / Vollständige Prompt-Beispiele

### Local implementation / Lokale Implementierung

```text
$speckit-autonomous

Execute the next feature from `Lastenheft_Example.md`.
Delivery mode: LocalImplementation.
Run Specify, repeated Clarify, all useful checklists, Plan, Plan review, Tasks,
repeated Analyze, Implement, validation, and retrospective.
Do not perform remote writes.
```

### Publish a pull request / Pull Request veröffentlichen

```text
$speckit-autonomous

Execute the feature from `Lastenheft_Example.md`.
Delivery mode: PublishPR.
You may create the numbered feature branch, commit, push, and open a non-empty
pull request. Do not merge it and do not use an administrative bypass.
```

### Merge and synchronize / Mergen und synchronisieren

```text
$speckit-autonomous

Execute the feature from `Lastenheft_Example.md`.
Delivery mode: MergeAndSync.
You may commit, push, create the feature PR, address actionable review findings,
and merge after all required checks are green and review convergence is proven.
After merge, switch to `main`, fast-forward pull, prune, and prove
`HEAD == origin/main` with a clean working tree.
Administrative bypass is not authorized unless separately and narrowly stated.
```

### Bounded bypass authority / Eng begrenzter Bypass

```text
For this run only, an administrative merge bypass is authorized solely when:
- every required technical check is green on the exact reviewed head;
- there are zero actionable unresolved review threads;
- the only remaining protection is a human-approval rule;
- unavailable reviewer quota is recorded as a missing review;
- no code, evidence, or provider setting is changed to manufacture eligibility.
```

This paragraph is an example of explicit authority, not a preset default.

*Dieser Absatz ist ein Beispiel für eine ausdrückliche Berechtigung und kein
Preset-Standard.*

## Status, Stop, and Resume / Status, Stop und Resume

### Inspect without changes / Read-only Status

```text
$speckit-autonomous-status

Inspect the active autonomous run. Report feature, branch, stage, run status,
last completed safe boundary, pending operation, delivery authority, drift, and
recommended next command. Do not modify files or remote state.
```

### Request a graceful stop / Kontrolliert stoppen

```text
$speckit-autonomous-stop

Pause the active autonomous run at the next safe orchestration boundary.
Record the completed operation and any operation that needs revalidation.
Do not start another Spec Kit phase and do not perform remote actions.
```

You normally do not need to name a future phase. The command applies to the
active run and checkpoints as soon as the current operation can be classified
honestly.

*Normalerweise muss keine zukünftige Phase genannt werden. Der Command gilt für
den aktiven Lauf und setzt den Checkpoint, sobald die aktuelle Operation
verlässlich klassifiziert werden kann.*

### Resume after a deliberate pause / Nach bewusstem Stop fortsetzen

```text
$speckit-autonomous-resume

Resume the paused feature in delivery mode MergeAndSync.
Audit branch, worktree, feature metadata, accepted artifact hashes, preset and
governance drift, incomplete operations, validation state, and current remote
authority before continuing. Preserve accepted scope.
```

### Resume after interruption / Nach unerwarteter Unterbrechung fortsetzen

```text
$speckit-autonomous-resume

Recover the interrupted active feature. Treat any operation without a
trustworthy terminal result as NeedsRevalidation. Reconstruct state from Git,
feature artifacts, run state, provider status, and evidence. Do not repeat a
remote write whose result can first be verified.
```

The general `$speckit-autonomous` command must not silently overwrite an active
or deliberately paused run. Use the explicit resume command.

*Der allgemeine `$speckit-autonomous`-Command darf einen aktiven oder bewusst
pausierten Lauf nicht still überschreiben. Verwende den ausdrücklichen
Resume-Command.*

The generated skill can use `Deliver` as a readable section heading. Do not
write that label into run-state JSON. Use the canonical machine stages
`Publish`, `Review`, or `MergeAndSync` for the matching closeout operation.

*Der erzeugte Skill kann `Deliver` als lesbare Abschnittsüberschrift verwenden.
Dieser Begriff gehört nicht in die Run-State-JSON. Verwende für die jeweilige
Closeout-Operation die kanonischen Maschinenzustände `Publish`, `Review` oder
`MergeAndSync`.*

## Run-State Validation / Run-State-Validierung

Create `specs/<feature>/autonomous-run-state.json` from the supplied template.

macOS/Linux:

```bash
bash .specify/presets/autonomous-run-governance/scripts/validate-autonomous-run-state.sh \
  --state specs/NNN-feature/autonomous-run-state.json
```

Windows:

```powershell
pwsh -NoProfile -File .specify/presets/autonomous-run-governance/scripts/validate-autonomous-run-state.ps1 `
  -State specs/NNN-feature/autonomous-run-state.json
```

Always call installed scripts through `bash` or `pwsh -File`. ZIP extraction or
preset installation may not preserve an executable mode bit.

*Installierte Skripte werden immer über `bash` oder `pwsh -File` aufgerufen.
ZIP-Extraktion oder Preset-Installation muss das Executable-Bit nicht
erhalten.*

## Gate Evidence / Gate-Evidence

### Declare requirements before implementation / Anforderungen vorher festlegen

Copy `autonomous-run-gate-requirements-template.json` into the feature
directory. Each gate states:

- stable gate ID;
- `Applicable` or `N/A`;
- exact required scope;
- command tokens that must appear in executed evidence;
- optional runner or platform tokens;
- rationale and re-evaluation trigger.

*Die Gate-Datei wird vor der Implementierung akzeptiert. Jeder Gate besitzt
eine stabile ID, Applicability, exakten Scope, erforderliche Command- und
gegebenenfalls Plattform-Tokens sowie Begründung und Neubewertungs-Trigger.*

### Collect provider-neutral evidence / Providerneutrale Evidence erfassen

Create the evidence JSON in a temporary directory after all final-head checks
finish. Do not commit it before merge: committing exact-head evidence creates a
new head and invalidates its own claim.

*Die Evidence-JSON wird nach den Prüfungen des finalen Heads in einem
temporären Verzeichnis erzeugt. Sie wird vor dem Merge nicht committet, weil
ein solcher Commit einen neuen Head erzeugt und den eigenen Nachweis
ungültig machen würde.*

macOS/Linux:

```bash
bash .specify/presets/autonomous-run-governance/scripts/validate-autonomous-gate-evidence.sh \
  --requirements specs/NNN-feature/autonomous-gate-requirements.json \
  --evidence /temporary/provider-gate-evidence.json \
  --head "$(git rev-parse HEAD)"
```

Windows:

```powershell
pwsh -NoProfile -File .specify/presets/autonomous-run-governance/scripts/validate-autonomous-gate-evidence.ps1 `
  -Requirements specs/NNN-feature/autonomous-gate-requirements.json `
  -Evidence $env:TEMP/provider-gate-evidence.json `
  -Head (git rev-parse HEAD)
```

The validators check schema, requirements hash, exact head, one Primary row per
gate, Applicability boundaries, required tokens, and Supplemental links. They
do not prove that copied provider data is truthful and do not grant delivery
authority.

*Die Validatoren prüfen Schema, Requirements-Hash, exakten Head, genau eine
Primary-Zeile je Gate, Applicability-Grenzen, erforderliche Tokens und
Supplemental-Verknüpfungen. Sie beweisen nicht die Wahrheit kopierter
Provider-Daten und erteilen keine Auslieferungsrechte.*

## Retrospective Learning / Retrospektives Lernen

After delivery:

```text
$speckit-autonomous-retrospective

Review the completed feature, evidence, checks, review history, stop/resume
behavior, repeated work, and permission boundaries. Classify each observation
as FeatureSpecific, RunbookClarification, SkillCorrection, TemplateCorrection,
AgentPolicyCorrection, ValidationAutomation, PresetFollowUp, or NoPromotion.
Promote correctness and evidence-integrity fixes immediately when proven.
Generalize efficiency preferences only after repeated field evidence.
```

Project-specific behavior remains in the project. A portable rule must identify
the generic problem, bounded target rule, excluded project details,
reproducible test, confidence, and promotion decision.

*Projektspezifisches Verhalten bleibt im Projekt. Eine portable Regel benennt
das allgemeine Problem, die begrenzte Zielregel, ausgeschlossene
Projektdetails, einen reproduzierbaren Test, Vertrauen und
Promotionsentscheidung.*

## Recommended Teaching Sequence / Empfohlene Lernreihenfolge

1. Read a completed Spec, Plan, Tasks, and PR evidence set.
2. Run `LocalImplementation` on a small documentation or test-only feature.
3. Inspect run state with `status`.
4. Stop the run deliberately and review the checkpoint.
5. Resume in `LocalImplementation`.
6. Repeat with `PublishPR`, but let a human merge.
7. Use `MergeAndSync` only after branch protection and evidence gates are
   understood.
8. Compare the retrospective with the final diff and provider history.

*Lernende beginnen mit einem kleinen lokalen Lauf, prüfen Status und Evidence,
testen Stop und Resume und erhalten Remote-Rechte erst schrittweise. Ein
vollautomatischer Merge ist ein später Lernschritt, kein Einstieg.*

## Troubleshooting / Fehlersuche

### The autonomous command appears twice

Inspect installed presets and generated agent surfaces. Remove stale duplicate
integrations, reinstall the preset once, then run `specify check`. Do not delete
context files such as `GEMINI.md` merely because one CLI vendor changed.

*Prüfe installierte Presets und erzeugte Agentenoberflächen. Entferne veraltete
doppelte Integrationen, installiere einmal neu und führe `specify check` aus.*

### The run refuses to start

Check for an existing Active, Paused, or NeedsRevalidation run. Use `status`,
then `resume` if the run belongs to the same feature. Do not delete run state to
bypass the audit.

*Prüfe mit `status`, ob bereits ein aktiver, pausierter oder
neu zu validierender Lauf existiert. Verwende `resume`; lösche den Zustand
nicht, um das Audit zu umgehen.*

### Resume detects preset drift

Compare current mandatory correctness, security, permission, and
evidence-integrity rules with accepted Plan, Tasks, and checklists. Add only an
applicable missing mandatory rule to the affected artifacts, rerun readiness
and Analyze, and preserve accepted scope. Efficiency-only guidance does not
cause retroactive task churn.

*Bei Preset-Drift werden aktuelle Pflichtregeln mit Plan, Tasks und Checklists
verglichen. Nur tatsächlich fehlende anwendbare Pflichtregeln werden minimal
ergänzt; der akzeptierte Scope bleibt stabil.*

### A command ended without a trustworthy result

Record `NeedsRevalidation`. First inspect Git, process, provider, and artifact
state. Re-execute only when the earlier result cannot be proven.

*Fehlt ein vertrauenswürdiges Ergebnis, gilt `NeedsRevalidation`. Prüfe zuerst
Git-, Prozess-, Provider- und Artefaktzustand und wiederhole nur, was nicht
belegt werden kann.*

### The PR is green but merge is blocked

Identify the exact protection rule. A missing approval is not equivalent to a
failed technical gate. Merge only under current explicit authority; an admin
bypass must be separately bounded and recorded.

*Ermittle die konkrete Schutzregel. Eine fehlende Freigabe ist kein
fehlgeschlagener technischer Gate. Merge nur mit aktueller ausdrücklicher
Berechtigung; ein Admin-Bypass muss separat begrenzt und dokumentiert sein.*

### Copilot or another reviewer is unavailable

Record the missing review and its reason. Do not claim a successful review.
Other successful checks do not impersonate the unavailable reviewer.

*Dokumentiere den fehlenden Review und den Grund. Behaupte keinen erfolgreichen
Review; andere grüne Prüfungen ersetzen den nicht verfügbaren Reviewer nicht.*

### Exact-head evidence fails

Check the full head SHA, requirements file hash, exact required scope text,
command tokens, runner tokens, one Primary row per gate, and N/A rationale.
Do not weaken the accepted requirement merely to make evidence pass.

*Prüfe vollständige Head-SHA, Requirements-Hash, exakten Scope-Text,
Command-/Runner-Tokens, eine Primary-Zeile je Gate und N/A-Begründungen.
Schwäche keine akzeptierte Anforderung ab, nur damit Evidence grün wird.*

## Version 0.2.2 / Version 0.2.2

Version 0.2.2 keeps the v0.2.1 lifecycle, permission, mandatory-rule delta, and
exact-head contracts. It turns the short package note into a
learner- and maintainer-facing operating guide and records Feature 029 as the
first field run that combined a third modernization witness, temporary
provider-neutral exact-head evidence, multi-platform runtime proof, and a
narrow review-rule bypass without changing product runtime scope.
It also closes one deterministic state-vocabulary gap by requiring the
canonical `Publish`, `Review`, or `MergeAndSync` stage instead of copying the
human-readable `Deliver` skill heading into run state.

*Version 0.2.2 lässt die Lebenszyklus-, Berechtigungs-, Mandatory-Rule-Delta-
und Exact-Head-Verträge aus v0.2.1. Die bisherige Kurzbeschreibung
wird zu einer Bedien- und Lernanleitung ausgebaut. Feature 029 dokumentiert
erstmals gemeinsam eine dritte Modernisierungsquelle, temporäre
providerneutrale Exact-Head-Evidence, echten Multi-Plattform-Runtime-Nachweis
und einen eng begrenzten Review-Regel-Bypass ohne Änderung des
Produkt-Runtime-Scopes. Zusätzlich wird eine deterministische Lücke im
Zustandsvokabular geschlossen: Im Run State gelten `Publish`, `Review` oder
`MergeAndSync`, nicht die lesbare Skill-Überschrift `Deliver`.*

## Compatibility and Safety Summary / Kompatibilitäts- und Sicherheitsübersicht

- optional and stackable; no Spec Kit core patch required
- Spec Kit `>=0.8.3`
- priority `70` after the standard six-preset matrix
- Bash/Python and PowerShell validator parity
- provider-neutral evidence schema
- agent-vendor-neutral workflow contracts
- no implicit remote rights
- no empty pull requests
- no silent resume
- no self-validating committed exact-head provider evidence
- no automatic weakening of project gates

*Das Preset ist optional, stackbar und anbieterneutral. Es erteilt keine
impliziten Remote-Rechte, erzeugt keine Leer-PRs, setzt pausierte Läufe nicht
still fort, committet keinen selbstentwertenden Exact-Head-Nachweis und
schwächt keine Projekt-Gates automatisch ab.*

## License

MIT. See `LICENSE`.
