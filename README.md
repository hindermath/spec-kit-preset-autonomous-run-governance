# Autonomous Run Governance Preset

Version: `0.2.1`
Requires: `spec-kit >= 0.8.3`
Recommended priority: `70`

This optional preset governs complete, delegated Spec Kit runs without making
remote authority implicit. It composes with security, architecture, iSAQB,
accessibility, cross-platform, and agent-parity presets.

It provides:

- `speckit.autonomous` for end-to-end, convergence-based feature delivery
- `speckit.autonomous-retrospective` for classified workflow learning
- `speckit.autonomous-status` for read-only run inspection
- `speckit.autonomous-stop` for a graceful pause at a safe boundary
- `speckit.autonomous-resume` for explicit recovery after pause or interruption
- Constitution, Spec, Plan, Tasks, and Agent addenda
- runbook, evidence, retrospective, and readiness-checklist templates
- machine-readable gate-requirements and exact-head evidence templates
- a machine-readable feature-local run-state template
- read-only Bash and PowerShell gate-evidence and run-state validators
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
specify preset add --from https://github.com/hindermath/spec-kit-preset-autonomous-run-governance/archive/refs/tags/v0.2.1.zip --priority 70
```

Version 0.2.1 retains the machine-checkable gate and lifecycle contracts from
v0.2.0 and adds a mandatory-rule delta audit for resume after preset or
governance drift. Current correctness, security, permission, and
evidence-integrity rules are compared with accepted Plan, Tasks, and checklists.
An applicable missing rule is added only to the affected entries before
readiness and Analyze rerun; accepted scope remains stable and efficiency-only
guidance does not cause retroactive task churn.

Version 0.2.0 added validated, feature-local lifecycle checkpoints. A deliberate
pause is `PausedByUser` and requires `speckit.autonomous-resume`; an unexpected
interruption requires drift, operation, governance, and authority revalidation.
The general command never overwrites an active run or silently resumes a
deliberate pause.

Create `specs/<feature>/autonomous-run-state.json` from
`autonomous-run-state-template` and validate it on macOS/Linux:

```bash
bash .specify/presets/autonomous-run-governance/scripts/validate-autonomous-run-state.sh \
  --state specs/NNN-feature/autonomous-run-state.json
```

On Windows:

```powershell
pwsh -NoProfile -File .specify/presets/autonomous-run-governance/scripts/validate-autonomous-run-state.ps1 `
  -State specs/NNN-feature/autonomous-run-state.json
```

The stop command is cooperative. It checkpoints at the next safe agent or
command boundary and does not claim to atomically terminate an arbitrary
external process. An operation without a trustworthy result becomes
`NeedsRevalidation`.

Declare every acceptance gate before implementation with
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

Always invoke installed scripts through `bash` or `pwsh -File`. Git records
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
