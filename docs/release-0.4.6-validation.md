# Patch 0.4.6: Dokumentationskorrektur / Documentation correction

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
