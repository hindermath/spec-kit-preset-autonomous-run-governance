#!/usr/bin/env bash
# Validate a worktree delivery set or exact staged candidate without modification.
set -euo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
python_command="$(command -v python3 || command -v python || true)"
[ -n "$python_command" ] || { printf 'ERROR AEI001: python3 or python is required\n' >&2; exit 2; }
arguments=(delivery)
while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo|--intended|--allow-historical-whitespace) [ "$#" -ge 2 ] || exit 2; arguments+=("$1" "$2"); shift 2 ;;
    --staged) arguments+=("$1"); shift ;;
    -h|--help) printf '%s\n' 'Usage: validate-autonomous-delivery-set.sh --repo PATH [--staged] [--intended PATH ...] [--allow-historical-whitespace PATH=RAW_SHA256 ...]'; exit 0 ;;
    *) printf 'ERROR AEI001: unknown option: %s\n' "$1" >&2; exit 2 ;;
  esac
done
exec "$python_command" "$script_dir/autonomous-evidence-core.py" "${arguments[@]}"
