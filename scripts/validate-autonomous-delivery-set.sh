#!/usr/bin/env bash
# Validate an explicit autonomous delivery set without staging or modification.
set -euo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
python_command="$(command -v python3 || command -v python || true)"
[ -n "$python_command" ] || { printf 'ERROR AEI001: python3 or python is required\n' >&2; exit 2; }
arguments=(delivery)
while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo|--intended) [ "$#" -ge 2 ] || exit 2; arguments+=("$1" "$2"); shift 2 ;;
    -h|--help) printf '%s\n' 'Usage: validate-autonomous-delivery-set.sh --repo PATH [--intended PATH ...]'; exit 0 ;;
    *) printf 'ERROR AEI001: unknown option: %s\n' "$1" >&2; exit 2 ;;
  esac
done
exec "$python_command" "$script_dir/autonomous-evidence-core.py" "${arguments[@]}"
