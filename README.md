# Autonomous Run Governance Preset

Version: `0.1.4`
Requires: `spec-kit >= 0.8.3`
Recommended priority: `70`

This optional preset governs complete, delegated Spec Kit runs without making
remote authority implicit. It composes with security, architecture, iSAQB,
accessibility, cross-platform, and agent-parity presets.

It provides:

- `speckit.autonomous` for end-to-end, convergence-based feature delivery
- `speckit.autonomous-retrospective` for classified workflow learning
- Constitution, Spec, Plan, Tasks, and Agent addenda
- runbook, evidence, retrospective, and readiness-checklist templates
- machine-readable gate-requirements and exact-head evidence templates
- read-only Bash and PowerShell gate-evidence validators
- field-validation evidence from six product runs plus audit and closure runs

`LocalImplementation` is the safe default. `PublishPR` and `MergeAndSync`
require explicit current authorization. Provider bypass is never inferred from
autonomy, repository access, or an earlier run.

The preset does not prescribe a programming language, test framework, CI
provider, branch version scheme, agent vendor, or merge policy. Project rules
remain authoritative and supply the concrete commands and evidence paths.

Development install:

```bash
specify preset add --dev /path/to/autonomous-run-governance --priority 70
```

Published install:

```bash
specify preset add --from https://github.com/hindermath/spec-kit-preset-autonomous-run-governance/archive/refs/tags/v0.1.4.zip --priority 70
```

Version 0.1.4 retains the machine-checkable gate contract introduced in v0.1.3
and makes its invocation stable after ZIP installation. Declare every acceptance
gate before implementation with
`autonomous-run-gate-requirements-template`, then collect exact-head execution
evidence with `autonomous-run-gate-evidence-template`. The requirements define
command and optional runner/platform tokens, so a green tooling-only job cannot
satisfy a runtime gate merely because its name contains a platform.

Validate the final reviewed head on macOS/Linux:

```bash
bash .specify/presets/autonomous-run-governance/scripts/validate-autonomous-gate-evidence.sh \
  --requirements specs/NNN-feature/autonomous-gate-requirements.json \
  --evidence /temporary/provider-gate-evidence.json \
  --head "$(git rev-parse HEAD)"
```

The Bash validator requires `python3` or `python` for strict JSON parsing. On
Windows use PowerShell 7:

```powershell
pwsh -NoProfile -File .specify/presets/autonomous-run-governance/scripts/validate-autonomous-gate-evidence.ps1 `
  -Requirements specs/NNN-feature/autonomous-gate-requirements.json `
  -Evidence $env:TEMP/provider-gate-evidence.json `
  -Head (git rev-parse HEAD)
```

Dot-source the PowerShell script to use the equivalent Advanced Function
`Test-AutonomousGateEvidence` in an existing session.

Always invoke the installed scripts through `bash` or `pwsh -File`. Git records
the Bash source as executable, but a preset installer or ZIP extraction may copy
it without that mode bit. Direct path execution is therefore not a portable
contract.

The accepted requirements file is a reviewed feature artifact. The provider
evidence file SHOULD be generated in a temporary directory after checks finish,
because committing exact-head evidence before merge would create a new head and
self-invalidate the proof. A causal closeout may record the immutable run and
validator result after delivery without claiming that the closeout proves its
own new revision.

Validate with `specify preset list`, `specify preset info
autonomous-run-governance`, and `specify preset resolve` for the affected
templates. Installation does not itself execute a feature or grant remote
write, merge, bypass, or provider-administration rights.
