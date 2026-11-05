# v0.4.9: Geroutete Phasenausfuehrung / Routed phase execution

## Deutsch

Vorbereitung, kein Veroeffentlichungsnachweis: `candidate_status = Prepared`,
`release_status = NotEstablishedAtPreparation`. Erst Release-Seite, exakter
Tag-Commit und externer ZIP-Hash belegen die Veroeffentlichung.

Der normale Phasenrunner verwendet die rollenbezogene Ausfuehrungspolicy aus
Model Routing Governance v0.2.4. Worktree und Prozessarbeitsverzeichnis werden
physisch identisch gebunden; Prompts bleiben im JSON-Transport erhalten.
Implementierungsrollen erhalten nur die vorgesehenen sitzungsgebundenen
Werkzeugrechte. Lesende Fast-Profile erhalten keine Schreibrechte. Native
agy-Fast-Ergebnisse werden nach strikter JSON-Pruefung atomar durch den Host
gespeichert; das Modell muss keine Ergebnisdatei schreiben.

Die gekoppelte Live-Abnahme lief aus der kanonischen v0.2.4-Quelle mit maximal
drei Retries je Harness. Die Read-only-Probe bestand fuer agy, Claude, Codex,
Copilot und OpenCode jeweils im ersten Versuch. C#-Smoke und normaler Runner
bestanden fuer Claude, Codex, Copilot und OpenCode; agys Frontier-Modell war
vor der Aufgabe extern durch HTTP 429 `RESOURCE_EXHAUSTED` blockiert. Ein
frueherer vollstaendiger Fuenf-Harness-Lauf der v0.2.4-Quelle bleibt die
Frontier-Evidence. Die Providergrenze ist dokumentiert und kein stiller
Fallback oder Modellwechsel wurde verwendet.

Offline pruefen Modell-Routing-Integration, native Read-only-Persistenz,
Evidence-Integritaet, Dokumentation, Release-Status und strikte
PSScriptAnalyzer-Regeln das Paket. Dokumentationsentscheidung:
`UpdateRequired`; Owner Preset-Maintainer; Zielgruppen Operatoren und Reviewer;
Distribution Preset-Quelle; kein Home-Sync. Installation und Rollout bleiben
getrennte Freigaben.

## English

Preparation only, not publication evidence: `candidate_status = Prepared` and
`release_status = NotEstablishedAtPreparation`. The release page, exact tag
commit, and external ZIP hash establish publication.

The normal phase runner consumes the role-aware execution policy from Model
Routing Governance v0.2.4. Worktree and process working directory resolve to
the same physical path, and prompts remain intact through JSON transport.
Implementation roles receive only their intended session permissions.
Read-only fast profiles receive no write permission. Native agy-fast results
are strictly validated and persisted atomically by the host, so the model does
not need to write its result file.

The coupled live acceptance used the canonical v0.2.4 source and at most three
retries per harness. The read-only probe passed agy, Claude, Codex, Copilot,
and OpenCode on their first attempts. C# smoke and the normal runner passed for
Claude, Codex, Copilot, and OpenCode; agy's frontier model was externally
blocked before the task by HTTP 429 `RESOURCE_EXHAUSTED`. An earlier complete
five-harness v0.2.4 run remains the frontier evidence. The provider boundary is
documented; no silent fallback or model change was used.

Offline coverage includes model-routing integration, native read-only result
persistence, evidence integrity, documentation, release status, and strict
PSScriptAnalyzer rules. Documentation decision: `UpdateRequired`; owner preset
maintainers; audiences operators and reviewers; distribution preset source;
no Home sync. Installation and rollout remain separate authorizations.

[Structured preparation](release-0.4.9-preparation.json) ·
[Model-routing execution](model-routing-execution.md) ·
[Model Routing Governance v0.2.4](https://github.com/hindermath/spec-kit-preset-model-routing-governance/releases/tag/v0.2.4)
