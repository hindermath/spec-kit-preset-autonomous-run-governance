#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v pwsh >/dev/null 2>&1; then
  printf 'ERROR: PowerShell 7 (pwsh) is required for the cross-platform routing test.\n' >&2
  exit 2
fi

exec pwsh -NoLogo -NoProfile -File "$script_dir/test-model-routing.ps1" "$@"
