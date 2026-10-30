# v0.4.8: Historische EOF-Bytes / Historical EOF bytes

## Deutsch

Vorbereitung, kein Veröffentlichungsnachweis: candidate_status = Prepared,
release_status = NotEstablishedAtPreparation. Spätere Veröffentlichung ist
über die [Release-Seite](https://github.com/hindermath/spec-kit-preset-autonomous-run-governance/releases/tag/v0.4.8),
den exakten Tag-Commit und externen ZIP-Hash nachzuweisen.

Der Owner hat den kanonischen Validatorfix samt Regressionen, unveränderlichen
Archivbytes und anschließenden MergeAndSync-Abschluss ausdrücklich genehmigt.
Die bestehende historische Whitespace-Ausnahme berücksichtigt nun auch
Leerzeilen am Dateiende. Nur ausdrücklich benannter Pfad, unveränderter
Roh-SHA-256 und tatsächlich nötige Ausnahme sind erlaubt; im Staged-Modus
muss die Datei neu hinzugefügt sein und der Hash die Indexbytes binden.
Andere EOF-Befunde, Konfliktmarker, Dateitypen, Inventarabweichungen und
Git-/Inhaltsdrift bleiben Fehler. Keine Git-Whitespace-Konfiguration wird
gelockert. Bestehende Schemas, Optionen und Autoritätsgrenzen bleiben erhalten.

Nachweise: Cross-Shell-Regressionssuite mit LF-/CRLF-Archivfällen, unbenannten
EOF-Dateien, falschen Hashes, geändertem Index gegenüber Arbeitsbaum,
unbenötigten Ausnahmen und unverändertem Repositoryzustand. Dokumentations-
und Release-Tests bleiben getrennt. Tatsächliche Ergebnisse gehören zum
exakten PR-Head; ein Vorbereitungsdokument behauptet keine bestandene CI.

## English

Preparation only, not publication evidence: candidate_status = Prepared and
release_status = NotEstablishedAtPreparation. Verify release, exact tag and
external ZIP hash separately. The owner explicitly authorizes the canonical
validator fix, regression tests, byte-preserving integration and MergeAndSync.

Extend the existing historical whitespace option to blank-at-EOF, requiring
explicit exact path, unchanged raw SHA-256 and a necessary allowance. Staged
files must be newly added and the hash binds index bytes. Other EOF findings,
conflict markers, non-regular files, inventory mismatch and Git/content drift
still fail. Do not relax Git whitespace settings. Schemas, CLI options and
authority remain unchanged.

Use cross-shell LF/CRLF fixtures, unrelated EOF rejection, wrong hashes,
index-versus-worktree changes, unnecessary allowances and zero-write proof.
Documentation/release tests are separate. Actual results bind the PR head;
this preparation record does not predict successful CI.

Documentation Impact: UpdateRequired. Owner Maintainer; audiences maintainers
and reviewers. Canonical source: validator, existing option contract and
explicit approved repair. Reader paths: README, first-run guide, PowerShell
help and manpage. German first/equivalent English, text-oriented. Distribution:
preset package; only separately authorized sandbox integration, no Home sync
or fleet rollout. Reevaluate on path/hash/whitespace/authorization changes.
