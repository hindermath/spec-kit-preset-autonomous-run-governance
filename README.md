# Autonomous Run Governance Preset

Version: `0.1.1`
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
specify preset add --from https://github.com/hindermath/spec-kit-preset-autonomous-run-governance/archive/refs/tags/v0.1.1.zip --priority 70
```

Validate with `specify preset list`, `specify preset info
autonomous-run-governance`, and `specify preset resolve` for the affected
templates. Installation does not itself execute a feature or grant remote
write, merge, bypass, or provider-administration rights.
