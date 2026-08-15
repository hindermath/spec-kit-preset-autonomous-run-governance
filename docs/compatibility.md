# Versionierung und Kompatibilitaet / Versioning and Compatibility

[Handbuch / Manual](README.md)

## Deutsch

### Drei getrennte Versionen

| Ebene | Aktueller Wert | Bedeutung |
|---|---|---|
| Preset-Release | `v0.4.1` | Veroeffentlichtes Paket und ZIP |
| Quellkandidat | `N/A` | Kein neuer unveroeffentlichter Kandidat |
| `preset.yml`-Schema | `schema_version: "1.0"` | Spec-Kit-Presetmanifest |
| Run-State-Vertrag | `schemaVersion: "1.1"` | Autonomer Lifecycle und Closeout |

Diese Werte duerfen nicht miteinander verwechselt werden. Ein
Presetmanifest-Schema `1.0` bedeutet nicht, dass der Run-State ebenfalls
Schema `1.0` verwendet.

### Upgrade auf `v0.4.1`

`v0.4.1` fuehrt eine ausdrueckliche Liefermenge, strukturierte
Phasenergebnisse und Gate-Evidence-Schema 2.0 mit getrenntem Pre-/Post-Merge-
Lebenszyklus ein. Historisches Schema 1.0 bleibt mit explizitem
`--historical` beziehungsweise `-Historical` lesbar, kann aber keine neue
Mergefreigabe erzeugen. Der Patch ersetzt die widerspruechliche Statusangabe
des kurzzeitig veroeffentlichten Tags `v0.4.0`; dessen Laufzeitvertraege bleiben
unveraendert.

### Upgrade auf `v0.3.6`

`v0.3.6` vereinheitlicht den Bash-Testwrapper mit der portablen
Blocked-Semantik für fehlendes oder veraltetes PowerShell 7. Laufzeit-,
Zustands- und Berechtigungsverträge bleiben unverändert.

### Upgrade auf `v0.3.5`

`v0.3.5` korrigiert ausschließlich den Kompositionsnachweis auf zwölf
Routing-Kataloge. Laufzeit-, Zustands- und Berechtigungsvertraege bleiben
unveraendert.

### Upgrade auf `v0.3.4`

`v0.3.4` akzeptiert maschinenlokale Runner-Profile mit Schema `2.0` und bindet
die veröffentlichten `model-routing.json`-Kataloge ein. Mehrdeutige oder
unbekannte Bindungen bleiben blockierend.

### Upgrade auf `v0.3.3`

`v0.3.3` ergaenzt das optionale, policy-gesteuerte Intake-Review-Gate vor der
Feature-Erstellung. Ohne Preset 9 oder aktive Policy bleibt das Ergebnis `N/A`
und das bisherige Verhalten unveraendert.

Nach dem Upgrade:

```bash
specify preset info autonomous-run-governance
specify preset resolve autonomous-run-state-template
specify preset resolve autonomous-run-gate-evidence-template
```

Ein aktiver Lauf wird nicht allein wegen dieses Dokumentations-Patches
regeneriert. Resume prueft dennoch die installierten Versionen und dokumentiert
den No-Delta-Befund.

### Zusammenspiel mit Preset 8

`parallel-autonomous-run-governance` benoetigt in jedem realen
Worker-Repository mindestens Preset 7 `v0.2.2`. Die gemeinsam getestete
aktuelle Kombination ist Preset 7 `v0.4.1` mit Preset 8 `v0.2.6`.

## English

### Three separate versions

| Layer | Current value | Meaning |
|---|---|---|
| Preset release | `v0.4.1` | Published package and ZIP |
| Source candidate | `N/A` | No newer unpublished candidate |
| `preset.yml` schema | `schema_version: "1.0"` | Spec Kit preset manifest |
| Run-state contract | `schemaVersion: "1.1"` | Autonomous lifecycle and closeout |

Do not confuse these values. Preset-manifest schema `1.0` does not imply
run-state schema `1.0`.

### Upgrade to `v0.4.1`

`v0.4.1` introduces an explicit delivery set, structured phase results,
and Gate Evidence schema 2.0 with separate pre- and post-merge lifecycle
snapshots. Historical schema 1.0 remains readable in explicit historical mode
but cannot authorize a new merge. This patch replaces the contradictory status
wording in the briefly published `v0.4.0` tag; its runtime contracts are
unchanged.

### Upgrade to `v0.3.6`

`v0.3.6` aligns the Bash test wrapper with portable blocked semantics for a
missing or outdated PowerShell 7 runtime. Runtime, state, and authority
contracts remain unchanged.

### Upgrade to `v0.3.5`

`v0.3.5` only corrects the composition proof to require twelve routing
catalogs. Runtime, state, and authority contracts remain unchanged.

### Upgrade to `v0.3.4`

`v0.3.4` accepts machine-local runner profiles using schema `2.0` and composes
with the published `model-routing.json` catalogs. Unknown or ambiguous
bindings remain blocking.

### Upgrade to `v0.3.3`

`v0.3.3` adds the optional policy-driven intake-review gate before feature
creation. Without Preset 9 or an active policy, the result is `N/A` and prior
behavior remains unchanged.

After upgrading, inspect the preset and resolve the state and gate-evidence
templates. Do not regenerate an active run merely because of this
documentation patch. Resume still records the compared versions and no-delta
result.

### Relationship with Preset 8

`parallel-autonomous-run-governance` requires at least Preset 7 `v0.2.2` in
every real worker repository. The currently tested pair is Preset 7 `v0.4.1`
with Preset 8 `v0.2.6`.
