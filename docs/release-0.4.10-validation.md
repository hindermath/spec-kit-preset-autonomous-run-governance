# v0.4.10: NUL-sicheres Git-Inventar / NUL-safe Git inventory

Documentation Impact: **UpdateRequired**. Owner: Preset maintainers.

## Deutsch

Vorbereitung, kein Veröffentlichungsnachweis: `candidate_status = Prepared`,
`release_status = NotEstablishedAtPreparation`. Erst Release-Seite, exakter
Tag-Commit und extern geprüfter ZIP-Hash belegen die Veröffentlichung.

Patch v0.4.10 verarbeitet die von Git gelieferten Dateilisten NUL-sicher.
Damit werden auch versionierte Pfade mit Zeilenumbrüchen oder anderen
ungewöhnlichen Zeichen vollständig geprüft. Zuvor konnte die zeilenbasierte
Zwischenverarbeitung solche Pfade teilen oder aus dem beabsichtigten
Dateiinventar verlieren. Der Negativtest verwendet einen ungewöhnlichen
Dateinamen und weist nach, dass dessen Inhalt tatsächlich in die Prüfung
einfließt.

Rollen, Berechtigungsgrenzen, Run-State-Schema und Modell-Routing bleiben
unverändert. Der Patch ergänzt keine neue Befugnis und schwächt keinen
fail-closed Befund ab. Kanonische Quellen sind `preset.yml`, der Runner unter
`scripts/` und der Testvertrag. Zielgruppen sind Operatoren und Reviewer;
Distribution ist die Preset-Quelle. Re-Evaluation erfolgt bei Änderungen an
Git-Inventar, Evidence-Integrität oder Paketversion.

## English

Preparation only, not publication evidence: `candidate_status = Prepared` and
`release_status = NotEstablishedAtPreparation`. Publication requires the
release page, exact tag commit and an externally verified ZIP hash.

Patch v0.4.10 processes Git path lists with NUL delimiters. Tracked paths that
contain newlines or other unusual characters are therefore validated in full.
Previously, line-based intermediate processing could split such paths or drop
them from the intended-file inventory. A negative regression fixture uses an
unusual file name and proves that its content actually reaches validation.

Roles, authority boundaries, the run-state schema and model routing remain
unchanged. The patch grants no new authority and weakens no fail-closed result.
Canonical sources are `preset.yml`, the runner under `scripts/`, and the test
contract. Audiences are operators and reviewers; distribution is the preset
source. Re-evaluate when Git inventory handling, evidence integrity, or the
package version changes.

[Structured preparation](release-0.4.10-preparation.json) ·
[Git path inventory](git-path-inventory.md)
