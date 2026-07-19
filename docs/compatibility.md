# Versionierung und Kompatibilitaet / Versioning and Compatibility

[Handbuch / Manual](README.md)

## Deutsch

### Drei getrennte Versionen

| Ebene | Aktueller Wert | Bedeutung |
|---|---|---|
| Preset-Release | `v0.3.1` | Veroeffentlichtes Paket und ZIP |
| `preset.yml`-Schema | `schema_version: "1.0"` | Spec-Kit-Presetmanifest |
| Run-State-Vertrag | `schemaVersion: "1.1"` | Autonomer Lifecycle und Closeout |

Diese Werte duerfen nicht miteinander verwechselt werden. Ein
Presetmanifest-Schema `1.0` bedeutet nicht, dass der Run-State ebenfalls
Schema `1.0` verwendet.

### Upgrade auf `v0.3.1`

`v0.3.1` ist ein Dokumentations-Patch. Es aendert keine Befehls-, Lifecycle-,
Evidence-, Berechtigungs- oder Validatorsemantik gegenueber `v0.3.0`.

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
aktuelle Kombination ist Preset 7 `v0.3.1` mit Preset 8 `v0.2.2`.

## English

### Three separate versions

| Layer | Current value | Meaning |
|---|---|---|
| Preset release | `v0.3.1` | Published package and ZIP |
| `preset.yml` schema | `schema_version: "1.0"` | Spec Kit preset manifest |
| Run-state contract | `schemaVersion: "1.1"` | Autonomous lifecycle and closeout |

Do not confuse these values. Preset-manifest schema `1.0` does not imply
run-state schema `1.0`.

### Upgrade to `v0.3.1`

`v0.3.1` is a documentation patch. It changes no command, lifecycle, evidence,
authority, or validator semantics from `v0.3.0`.

After upgrading, inspect the preset and resolve the state and gate-evidence
templates. Do not regenerate an active run merely because of this
documentation patch. Resume still records the compared versions and no-delta
result.

### Relationship with Preset 8

`parallel-autonomous-run-governance` requires at least Preset 7 `v0.2.2` in
every real worker repository. The currently tested pair is Preset 7 `v0.3.1`
with Preset 8 `v0.2.2`.
