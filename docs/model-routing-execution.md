# Model-Routing-Ausfuehrung / Model-routing execution

Documentation impact: `UpdateRequired`. Owner: preset maintainers.
Audience: autonomous-run operators. Source-only distribution; no Home sync.

DE: Der normale Phasenrunner kann die Ausfuehrungspolicy aus
`model-routing-governance/scripts/execution-policy.psm1` unter `RoutingRoot`
laden. Sie bindet Worktree und `PWD` an denselben physischen Pfad, transportiert
Prompts JSON-sicher und ergaenzt Rechte gemaess der bestehenden Profilrolle.
Preflight und rein lesende Profile erhalten keine zusaetzlichen Schreibrechte.
Ohne Modul bleibt der bisherige Ausfuehrungspfad erhalten. Es werden weder
Profile noch globale CLI-Einstellungen veraendert. Der Phasenprompt benennt
den nativen Ergebnisdateipfad beziehungsweise delegiert das Schreiben an den
konfigurierten JSON-Ergebnisadapter. Aufgabenautoritaet und Sandbox-Grenzen
gelten weiterhin. Source-Aenderung ist keine Installation oder Rollout.

EN: The normal phase runner can load the execution policy from
`model-routing-governance/scripts/execution-policy.psm1` beneath `RoutingRoot`.
It binds worktree and `PWD` to the same physical path, preserves prompts in
JSON transport and adds session permissions according to the existing role.
Preflight and read-only profiles receive no additional write permissions.
Without the module, legacy execution remains unchanged. Profiles and global
CLI settings are not modified. The phase prompt specifies the native result
path or delegates result writing to the configured JSON adapter. Task authority
and sandbox boundaries still apply. Source changes do not install or roll out.

Offline integration:

```powershell
pwsh -NoProfile -File tests/test-model-routing.ps1 -ModelRoutingSource /path/to/model-routing-governance
```

Reevaluate after changes to routing roles, CLI permissions or result transport.

DE: Nach Aenderungen am normalen Phasenrunner beide Live-Stufen gekoppelt
aus der Model-Routing-Quelle ausfuehren: zuerst Smoke, danach normale Integration.
Der kanonische Einstieg ist `tests/live/invoke-model-routing-validation.ps1`
mit `-ConfirmLiveRun -MaxRetries 3 -AutonomousRunnerSource <diese Quelle>`.
Regeln und Verbesserungsbacklog: `docs/validation-basis.md` im Routing-Preset.
Offline-Pruefungen bleiben CI-faehig; Providerlaeufe bleiben manuell.

DE: Native agy-Fast-Profile liefern ihre JSON-Ergebnisse auf stdout; der Host
persistiert das Ergebnis atomar. Das Modell erhaelt dafuer kein write_file-Recht.
Claude-Fast-Ergebnisse werden ueber native structured_output-Envelopes im
Model-Routing-Adapter transportiert. Details zur Read-only-Probe 2.1 stehen in
`docs/fast-read-only-compatibility.md` der Routing-Quelle.

EN: Native agy-fast profiles return JSON on stdout; the host persists results
atomically without granting model write_file access. Claude-fast results use
native structured_output envelopes through the routing adapter. Probe 2.1
details live in the routing source's compatibility document.

EN: After production-runner changes, run both live stages from routing source:
smoke first, then normal integration. The canonical entry is the validation
script above with explicit live confirmation, retries and this source path.
The routing preset owns `docs/validation-basis.md`, repeat rules and improvement
backlog. Offline tests remain CI-safe; provider runs remain manual.
