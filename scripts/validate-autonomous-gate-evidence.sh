#!/usr/bin/env bash
# Validate lifecycle-bound autonomous gate evidence without changing files.
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
python_command="$(command -v python3 || command -v python || true)"
if [ -z "$python_command" ]; then
  printf 'ERROR AEI001: python3 or python is required\n' >&2
  exit 2
fi

arguments=(gate)
while [ "$#" -gt 0 ]; do
  case "$1" in
    --requirements|--evidence|--head|--merge-commit)
      [ "$#" -ge 2 ] || { printf 'ERROR AEI001: %s needs a value\n' "$1" >&2; exit 2; }
      arguments+=("$1" "$2")
      shift 2
      ;;
    --historical)
      arguments+=("$1")
      shift
      ;;
    -h|--help)
      printf '%s\n' 'Usage: validate-autonomous-gate-evidence.sh --requirements FILE --evidence FILE --head SHA [--merge-commit SHA] [--historical]'
      exit 0
      ;;
    *) printf 'ERROR AEI001: unknown option: %s\n' "$1" >&2; exit 2 ;;
  esac
done
exec "$python_command" "$script_dir/autonomous-evidence-core.py" "${arguments[@]}"
