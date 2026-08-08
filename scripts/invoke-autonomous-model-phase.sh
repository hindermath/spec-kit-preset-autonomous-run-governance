#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
preset_root="$(cd -- "$script_dir/.." && pwd)"

case "${1:-}" in
  -h|--help)
    cat <<'EOF'
invoke-autonomous-model-phase.sh

DE: Fuehrt genau eine fail-closed modellgeroutete Spec-Kit-Phase aus.
EN: Runs exactly one fail-closed model-routed Spec Kit phase.

Usage:
  invoke-autonomous-model-phase.sh -Action Validate|Run|Status -State PATH [OPTIONS]

Required for Validate and Run:
  -RunnerConfig PATH

Required for Run:
  -PhaseId ID

Documentation:
EOF
    printf '  %s/docs/man/invoke-autonomous-model-phase.1\n' "$preset_root"
    exit 0
    ;;
esac

if ! command -v pwsh >/dev/null 2>&1; then
  printf 'Fehler: PowerShell 7 (pwsh) ist fuer den strukturierten Phasen-Kern erforderlich.\n' >&2
  exit 2
fi

exec pwsh -NoLogo -NoProfile -File \
  "$script_dir/invoke-autonomous-model-phase.ps1" "$@"
