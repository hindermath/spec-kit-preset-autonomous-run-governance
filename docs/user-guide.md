# Nutzungsleitfaden: autonomous-run-governance

<!-- current-package: 0.4.6 -->

[English](user-guide.EN.md) · [Preset-Referenz](../README.md)

Quellkandidat **v0.4.6**. Den tatsächlich veröffentlichten Stand auf der [Release-Seite](https://github.com/hindermath/spec-kit-preset-autonomous-run-governance/releases) prüfen. Dieser Leitfaden erteilt keine Merge-, Release- oder Projektfreigabe.

Inhalt: [Start](#start) · [Beispiel](#example) · [Begriffe](#terms) · [Routing](#routing) · [Fehlerhilfe](#help) · [Referenzen](#references)

<a id="start"></a>

## Start und Zielgruppe

Genau einen ausdrücklich beauftragten Feature-Lauf kontrolliert durch seine Phasen führen.

Für Auszubildende aller vier IHK-IT-Berufe: Fachinformatiker*innen (Anwendungsentwicklung, Systemintegration, Daten- und Prozessanalyse, Digitale Vernetzung), IT-System-Elektroniker*innen, Kaufleute für Digitalisierungsmanagement und Kaufleute für IT-System-Management. Ebenso für Entwickelnde ohne Governance-Spezialwissen. Du musst zum Einstieg keine Hashes bearbeiten oder Modell-IDs erfinden. Technische Bindungen mit der Betreuung prüfen.

Nutze ein bereits mit Spec Kit initialisiertes Ziel-Repository. Lies zuerst Voraussetzungen und Installation in der Preset-Referenz; ersetze Beispielpfade. Eine Vorlage ist ein Starter, kein ausgefüllter Nachweis. Installation ergänzt Anweisungen und Dateien; sie startet kein Feature und erteilt keine Freigabe.

Eingabe: Benenne akzeptierten Intake, Delivery-Modus, lokale Profile und offene menschliche Prüfungen.

<a id="example"></a>

## Ein vollständiges Beispiel

1. Beschreibe den begrenzten Auftrag und vorhandene Dateien. Scope nicht still erweitern.
2. Nutze das folgende Beispiel im Agentenchat. Es ist ein Prompt, kein Shell-Befehl:

~~~text
$speckit-autonomous-status — bestehenden Lauf nur prüfen und nächste erlaubte Aktion erklären. Weder starten, fortsetzen noch mergen.
~~~

3. Run-State, Phase, Blocker und nächste Aktion bleiben nachvollziehbar. Ein gespeicherter Delivery-Modus ist historische Evidence, keine aktuelle Berechtigung.
4. Prüfe Ergebnis und dokumentierte nächste Aktion. Änderungen, Reparatur, Feature-Ausführung und Lieferung brauchen jeweils die passende Autorität. Ein grüner technischer Check ist keine menschliche Abnahme.

Lesende Installationsprüfung im initialisierten Ziel-Repository:

~~~text
specify preset info autonomous-run-governance
specify preset resolve autonomous-runbook-template
~~~

Resolve zeigt die ausgewählte Vorlagenquelle; es füllt die Vorlage nicht aus und führt sie nicht aus.

<a id="terms"></a>

## Begriffe und Nachweise

- **Phase:** Abgegrenzter Teil des Feature-Laufs mit eigenen Eingaben und Nachweisen.
- **Exact Head:** Genau der geprüfte Commit, nicht eine später geänderte Branchspitze.
- **Handoff:** Gebundene Übergabe zwischen Phasen; kein beliebiger Wechsel im laufenden Prozess.

Wo der bestehende Vertrag diese Werte verwendet: Applicable bedeutet anwendbar, nicht bestanden; N/A braucht einen Grund; Open braucht die dokumentierte nächste Aktion und zuständige Person. Diese Erklärung ergänzt keine Schema-Felder. Echte historische Evidence erhalten; Hash oder Freigabe niemals nur zum Bestehen einer Prüfung ändern.

<a id="routing"></a>

## Stabiles Routing und ausdrückliche Aktionen

| Command | Deklarierte Rolle |
|---|---|
| `speckit.specify` | `frontier-reasoning` |
| `speckit.clarify` | `frontier-reasoning` |
| `speckit.checklist` | `frontier-reasoning` |
| `speckit.plan` | `frontier-reasoning` |
| `speckit.tasks` | `frontier-reasoning` |
| `speckit.analyze` | `frontier-reasoning` |
| `speckit.implement` | `long-running-implementation` |
| `speckit.autonomous` | `frontier-reasoning` |
| `speckit.autonomous-retrospective` | `coding-review` |
| `speckit.autonomous-status` | `fast-mechanical` |
| `speckit.autonomous-stop` | `script-only` |
| `speckit.autonomous-resume` | `frontier-reasoning` |

Rollen beschreiben Aufgaben, keinen Modellnamen und keine Qualitätsgarantie. Maßgeblich ist model-routing.json; allgemeine Beispiele wie coding-review ersetzen keine stärkere Command-Anforderung. Der bestehende autonome Runner verwendet die stärkste überlappende Rolle, unabhängig von der Installationspriorität. Die Installation eines Rollenvertrags stellt keinen laufenden Chat um und richtet keine persönlichen Profile ein.

Eine modellfreie Skriptprüfung und eine Agentenbewertung sind verschiedene Tätigkeiten. Modellaufrufe, auch Zugangs-Preflights, können trotz read-only-Verhalten Kontingent verbrauchen. Diese Dokumentation beauftragt keine Probe und keinen Anbieterwechsel. Sie enthält keine neue dynamische Routing-Implementierung.

Dokumentations-Zielkombination: Autonomous **0.4.6**, Parallel **0.2.8**. Die Laufzeit-Mindestanforderung von Parallel bleibt Autonomous **>=0.2.2**. Aktuelle Beispiele sind keine Behauptung eines neuen Live-Kampagnentests.

<a id="help"></a>

## Fehlerhilfe und sichere nächste Aktion

Bei fehlenden Profilen, Review-Drift oder fehlender Lieferautorität stoppen. Ein blockierter Lauf rechtfertigt weder einen Bypass noch eine andere Modellwahl.

Fehlt ein Command oder eine Vorlage, zuerst preset info und das unten verlinkte Manifest prüfen. Mindestwerkzeuge und aktive Installation prüfen. Unklarheit mit der Betreuung klären; weder Policy ändern, Validatoren abschalten noch einen nicht ausgeführten Test behaupten. Eine Schutzsperre bleibt eine Sperre.

Diese Sprach- und Zugänglichkeitsrunde zielt auf CEFR B2 und anwendbare WCAG 2.2 AA. Statische Tests bescheinigen das Ziel nicht. Nicht tatsächlich ausgeführte Screenreader-, Braille- und Nutzendentests bleiben ungeprüft.

<a id="references"></a>

## Vorlagen und Vertiefung

- [`autonomous-runbook-template`](../templates/autonomous-runbook-template.md)
- [`autonomous-run-evidence-template`](../templates/autonomous-run-evidence-template.md)
- [`autonomous-run-state-template`](../templates/autonomous-run-state-template.json)
- [`autonomous-runner-profiles-template`](../templates/autonomous-runner-profiles-template.json)
- [`autonomous-run-gate-requirements-template`](../templates/autonomous-run-gate-requirements-template.json)
- [`autonomous-run-gate-evidence-template`](../templates/autonomous-run-gate-evidence-template.json)
- [`autonomous-phase-result-template`](../templates/autonomous-phase-result-template.json)
- [`autonomous-run-retrospective-template`](../templates/autonomous-run-retrospective-template.md)
- [`autonomous-run-readiness-checklist-template`](../templates/autonomous-run-readiness-checklist-template.md)
- [`autonomous-run-field-validation-summary`](../templates/field-validation-summary.md)

Diese Namen bezeichnen verfügbare Starter; sie sind kein Auftrag, jede Datei anzulegen. Vorhandene passende Evidence weiterverwenden. JSON-Feldnamen bleiben technische Bezeichner, keine zu übersetzenden Schlüssel.

- [Manifest und Voraussetzungen](../preset.yml)
- [Stabiler Command-Rollenvertrag](../model-routing.json)
- [Dokumentationsumfang, Sichtung und Prüfgrenzen](documentation-closeout.md)
