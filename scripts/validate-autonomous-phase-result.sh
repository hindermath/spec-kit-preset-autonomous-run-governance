#!/usr/bin/env bash
# Validate semantic completion evidence for one routed phase.
set -euo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
python_command="$(command -v python3 || command -v python || true)"
[ -n "$python_command" ] || { printf 'ERROR AEI001: python3 or python is required\n' >&2; exit 2; }
arguments=(phase)
while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo|--result|--phase-id|--attempt-id|--exit-code|--expected-tasks|--expected-payload|--gate-exit-code|--task-manifest|--task-inventory-sha) [ "$#" -ge 2 ] || exit 2; arguments+=("$1" "$2"); shift 2 ;;
    -h|--help) printf '%s\n' 'Usage: validate-autonomous-phase-result.sh --repo PATH --result FILE --phase-id ID [--attempt-id UUID] --exit-code N --expected-tasks N --expected-payload PATH --gate-exit-code N [--task-manifest PATH]'; exit 0 ;;
    *) printf 'ERROR AEI001: unknown option: %s\n' "$1" >&2; exit 2 ;;
  esac
done
exec "$python_command" "$script_dir/autonomous-evidence-core.py" "${arguments[@]}"
