# Patch 0.4.6: Dokumentationskorrektur / Documentation correction

## Veröffentlichungsabschluss / Publication closeout

| Feld / Field | Wert / Value | Bedeutung / Meaning |
|---|---|---|
| `candidate_status` | `HistoricalCandidate` | Ursprünglicher Vorbereitungsstand / original preparation state |
| `release_status` | `Published` | Reguläres Release, geprüft zum angegebenen Zeitpunkt / regular release checked as of the timestamp |

Tag: [v0.4.6](https://github.com/hindermath/spec-kit-preset-autonomous-run-governance/tree/v0.4.6). Release-Commit / release commit:
`130a69dc483fa27e3835640c87feb40b446bf4cc`. [GitHub Release](https://github.com/hindermath/spec-kit-preset-autonomous-run-governance/releases/tag/v0.4.6), veröffentlicht / published:
`2026-10-23T21:29:32.0000000+00:00`. Nachgeprüft / rechecked: `2026-10-24T10:55:46.9905630+00:00`.

[Unverändertes Tag-Archiv / unchanged tag archive](https://github.com/hindermath/spec-kit-preset-autonomous-run-governance/archive/refs/tags/v0.4.6.zip)
mit SHA-256 / with SHA-256: `db7450ff1e1fcf26aae4a98fac3504464a2fa1e9bf7db23ffdbe1b89c5ec8b04`.
[Maschinenlesbarer Status und Quellen / machine-readable status and sources](release-0.4.6-publication.json).

Das Paket ist veröffentlicht. Der folgende historische Vorbereitungstext
behält seinen damaligen Prüfbereich; seine Statuswörter gelten nicht als
aktueller Veröffentlichungsstand. Dieser spätere Dokumentationsnachlauf auf
main ändert weder Tag noch ZIP. Er ersetzt keine technische, fachliche oder
menschliche Freigabe und behauptet keine Consumer-Installation oder Katalogaufnahme.

<div lang="en">

The package is published. The historical preparation text below retains its
original assessment scope; its status words do not describe current publication.
This later documentation follow-up on main changes neither tag nor ZIP.
It replaces no technical, professional or human approval and claims no consumer
installation or catalogue acceptance.

</div>

Bezug / Tracking: [#342: Veröffentlichungsstatus](https://github.com/hindermath/home-baseline/issues/342)
und / and [#343: Verbesserungsprofile](https://github.com/hindermath/home-baseline/issues/343).

## Historischer Validierungsstand / Historical validation state

Unveränderter ursprünglicher Text / unchanged original text:

<!-- historical-candidate:start -->

**Vorbereitung zur Sichtung, nicht veröffentlicht / Prepared for review, not published.**

README und deutscher/englischer Erstlauf verwenden denselben Beispielstand 0.4.6 und einzeilige Installationsbefehle. Runner, Routing, Evidence-Vertrag und Berechtigungen bleiben unverändert.

*README and both first-run language paths use version 0.4.6 and single-line installation commands. Runner, routing, evidence and authority contracts are unchanged.*

Documentation Impact: `UpdateRequired`. Owner: Thorsten Hindermann.
Zielgruppe: IT-Auszubildende aller vier IHK-IT-Berufe und Fachinformatik-Fachrichtungen
sowie Entwickelnde ohne Governance-Spezialwissen. DE zuerst, EN danach; B2 und
anwendbare WCAG 2.2 AA bleiben Zielmaßstab, keine durch Tests erteilte Abnahme.
Leserpfad: README → aktueller Ablauf → Fehlerhilfe → dieser Nachweis.
Kanonische Quellen: README, verlinkte Erstlaufanleitung soweit vorhanden,
preset.yml und tests/test-release-documentation.ps1. Bestehende Anker erhalten.

Dieser Patch behebt den für dieses stabile Preset bestätigten Dokumentations-
widerspruch. Keine neue Routing-Entwicklung, keine neuen Gates oder Berechtigungen.
Bei Authoring werden nur aktuelle Generator-Metadaten gebunden und bekannte
0.3.8-Receipts ausdrücklich erhalten; Schema- und Negativprüfungen bleiben streng.
Bei Statistics bleiben Methodik und internes Mess-Evidence-Format unverändert;
die Paketversion ist nicht mit deren historischer Formatversion gleichzusetzen.

Geplant: neue Dokumentationsregression, einschlägige bestehende lokale Tests
und konfigurierte native PR-CI. Tatsächliche Ergebnisse und Grenzen stehen im PR.
Dieser Vorbereitungstext behauptet keine noch nicht abgeschlossenen Prüfungen.
Exakter Head und Diff sind fachlich zu sichten. Kein Merge und keine Veröffentlichung
durch diesen Auftrag. Keine neuen Tags oder ZIPs; alte Releases bleiben unverändert.

Nach späterer gesonderter Freigabe: Merge, neues Tag-ZIP, SHA-256 und exakter
Release-Commit extern in den Release-Notes binden, Paket in einem isolierten
Testprojekt prüfen. Statistics darf die Prüfsumme seines eigenen ZIPs nicht
in dasselbe ZIP einbetten; fehlende externe Hash-Evidence bleibt blockierend.

English: This candidate fixes this stable preset's confirmed documentation
inconsistency. Audience includes the four IHK IT occupations/all IT-specialist
tracks and non-specialist developers. German first, equivalent English, B2 and
applicable WCAG 2.2 AA remain targets, not automated certification. README,
first-run guide where present, manifest and documentation regression are canonical.
Authoring binds current generator metadata while explicitly retaining known
0.3.8 schema-2 receipts; negative/schema gates remain strict. Statistics package
version does not change its historical internal measurement-evidence format.

Actual local tests, native CI, exact head and remaining limits are recorded in
the PR, not presumed here. Human diff review is still required. No merge, release,
tag/archive changes, model calls, installations into consumers, Home Runtime
sync, rollout or community submission. All require separate authority.
A later release must externally bind its actual archive hash and commit and
verify that archive in an isolated project; existing archives remain unchanged.

Distribution: preset source/documentation plus candidate metadata only.
Keine zentrale Profil-/Source-Lock-Änderung oder Installation in Level 0/Piloten.
Re-Evaluation nach Review, geändertem Head oder gesondert beauftragter Veröffentlichung.
<!-- historical-candidate:end -->

## Verbesserungsprofil / Improvement profile

Vergleich / comparison: [v0.4.4 → v0.4.6](https://github.com/hindermath/spec-kit-preset-autonomous-run-governance/compare/f718c00d405260706709be2fd64f59aadfac9312...130a69dc483fa27e3835640c87feb40b446bf4cc).

Ausgang / from: f718c00d405260706709be2fd64f59aadfac9312. Ziel / to: 130a69dc483fa27e3835640c87feb40b446bf4cc.

### v0.4.5: Regressionsprüfung / Regression

DE: **Vorher:** Routing-Tests durften nicht von privaten Profilen oder echten Modellzugängen abhängen. **Änderung:** Isolierte Routing-Fixtures und verständlichere Bedienhinweise wurden ergänzt; in 0.4.6 wurden Erstlauf und Kompatibilität konsistent gemacht. **Nutzen:** Tests sind besser reproduzierbar. Runner-Verhalten und Ausführungsautorität bleiben im Vergleich unverändert.

<div lang="en">

EN: **Before:** Routing tests must not depend on private profiles or real model access. **Change:** Isolated routing fixtures and clearer usage guidance were added; 0.4.6 aligned first-run and compatibility guidance. **Benefit:** Tests are more reproducible. Runner behavior and execution authority remain unchanged in this comparison.

</div>

Quellen / sources: [tests/test-model-routing.ps1](https://github.com/hindermath/spec-kit-preset-autonomous-run-governance/blob/8026572a37f967d2603f8a942d5bfd1ccbf2dca2/tests/test-model-routing.ps1), [README.md](https://github.com/hindermath/spec-kit-preset-autonomous-run-governance/blob/8026572a37f967d2603f8a942d5bfd1ccbf2dca2/README.md).

### v0.4.6: Bedienbarkeit und Dokumentation / Usability and documentation

DE: **Vorher:** Ein kurzer README-Einstieg erklärte die vollständigen Leserpfade und Grenzen noch nicht gleichwertig. **Änderung:** Deutsch-/Englisch-Leitfäden, Command-/Vorlagen-Erklärungen und Dokumentationsregressionen wurden ergänzt. Frühere Einstiegsverbesserungen und der letzte Patch werden getrennt ausgewiesen. **Nutzen:** Lernende finden Voraussetzungen, Beispiel, Ergebnis und Fehlerhilfe. Neue Textklarheit ist keine neue Runtime-Funktion oder menschliche Abnahme.

<div lang="en">

EN: **Before:** The short README entry did not yet explain the complete reader journey and limits equally. **Change:** German/English guides, command/template explanations and documentation regressions were added. Earlier entry-point improvements and the final patch are reported separately. **Benefit:** Learners can find prerequisites, an example, its result and troubleshooting. Clearer text is not a new runtime feature or human acceptance.

</div>

Quellen / sources: [docs/user-guide.md](https://github.com/hindermath/spec-kit-preset-autonomous-run-governance/blob/130a69dc483fa27e3835640c87feb40b446bf4cc/docs/user-guide.md), [docs/user-guide.EN.md](https://github.com/hindermath/spec-kit-preset-autonomous-run-governance/blob/130a69dc483fa27e3835640c87feb40b446bf4cc/docs/user-guide.EN.md), [tests/test-documentation-closeout.ps1](https://github.com/hindermath/spec-kit-preset-autonomous-run-governance/blob/130a69dc483fa27e3835640c87feb40b446bf4cc/tests/test-documentation-closeout.ps1).

### Zwischenstände / Intermediate versions

| Tag | Commit | Änderungsspanne / Change range |
|---|---|---|
| [v0.4.5](https://github.com/hindermath/spec-kit-preset-autonomous-run-governance/tree/v0.4.5) | 8026572a37f967d2603f8a942d5bfd1ccbf2dca2 | [v0.4.4 → v0.4.5](https://github.com/hindermath/spec-kit-preset-autonomous-run-governance/compare/v0.4.4...v0.4.5) |
| [v0.4.6](https://github.com/hindermath/spec-kit-preset-autonomous-run-governance/tree/v0.4.6) | 130a69dc483fa27e3835640c87feb40b446bf4cc | [v0.4.5 → v0.4.6](https://github.com/hindermath/spec-kit-preset-autonomous-run-governance/compare/v0.4.5...v0.4.6) |

Zugehörige PRs / related PRs: [#22](https://github.com/hindermath/spec-kit-preset-autonomous-run-governance/pull/22), [#21](https://github.com/hindermath/spec-kit-preset-autonomous-run-governance/pull/21), [#25](https://github.com/hindermath/spec-kit-preset-autonomous-run-governance/pull/25), [#24](https://github.com/hindermath/spec-kit-preset-autonomous-run-governance/pull/24).

### Nachweise und Grenzen / Evidence and limits

Der Quellcode der verlinkten Tests belegt ihre Implementierung, nicht ihre Ausführung. Für den früheren exakten PR-Head e65ecf42d36b24082d96d5b1d939c44e2e0f5eab sind 0 erfolgreiche Check-Runs erneut lesend nachgewiesen. Details und native Runner-Namen stehen im JSON-Nachweis; [damaliger PR](https://github.com/hindermath/spec-kit-preset-autonomous-run-governance/pull/25). Das ist historische Evidence, kein Pass des neuen Dokumentations-Heads.

<div lang="en">

Linked test code proves implementation, not execution. 0 successful check runs were rechecked for the earlier exact PR head; see the JSON for native runner names and links. These are historical results, not passes for the new documentation head.

</div>

Historische Feldtests behalten ihre eigene Version. Ein besserer Leserpfad ist keine neue Runtime-Funktion. Die Fachverträge, Rollen, Prioritäten und menschlichen Entscheidungsrechte bleiben in diesem Nachlauf unverändert. Keine neue Routing-Entwicklung, Modellprobe, Produkt-, Risiko-, Konformitäts-, WCAG- oder Zertifizierungsfreigabe.

<div lang="en">

Historical field tests retain their own version. A clearer reader path is not a new runtime feature. This follow-up changes no professional contracts, roles, priorities or human decision rights. It grants no new routing development, model probe, product, risk, compliance, WCAG or certification acceptance.

</div>

### Dokumentationsauswirkung / Documentation impact

UpdateRequired. Owner: Thorsten Hindermann. Quelle / source: unveränderliche Tags, echte Release-/Archivnachweise und verlinkte Testläufe / immutable tags, actual release/archive evidence and linked check runs. Leserpfad / reader path: README → DE/EN-Leitfaden → dieser Nachweis → Quellen und nächste sichere Aktion / this record → sources and next safe action. Zielgruppe / audience: alle vier IHK-IT-Berufe, alle vier Fachinformatik-Fachrichtungen und Entwickelnde ohne Spezialwissen / all four IT occupations and IT specialist disciplines, plus non-specialist developers. Deutsch zuerst, gleichwertiges Englisch, CEFR B2 und anwendbare WCAG 2.2 AA sind Prüfziele, keine automatische Abnahme / German first, equivalent English, B2 and applicable WCAG 2.2 AA are review targets, not automatic acceptance. Distribution: source-only; kein Home-Sync / no Home sync. Re-Evaluation: Tag-, Release-, Evidence-, Quellen- oder Scope-Drift / tag, release, evidence, source or scope drift.

Neue lokale Prüfungen und native CI werden im neuen PR am tatsächlichen Head nachgewiesen. Nächste Aktion: gesammelte menschliche Sichtung; vorher kein Merge. / New local checks and native CI are recorded in the new PR at its actual head. Next action: collected human review; no merge beforehand.
