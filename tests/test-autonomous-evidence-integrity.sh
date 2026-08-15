#!/usr/bin/env bash
# Run cross-shell autonomous evidence-integrity fixtures.
set -euo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
command -v pwsh >/dev/null 2>&1 || { printf 'ERROR: pwsh is required\n' >&2; exit 2; }
exec pwsh -NoProfile -File "$script_dir/test-autonomous-evidence-integrity.ps1"
