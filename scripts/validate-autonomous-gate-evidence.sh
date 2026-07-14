#!/usr/bin/env bash
# Validate autonomous-run acceptance gates without changing repository state.

set -euo pipefail

usage() {
  cat <<'EOF'
validate-autonomous-gate-evidence.sh - validate exact-head gate evidence

Usage:
  bash validate-autonomous-gate-evidence.sh --requirements FILE --evidence FILE --head SHA

Options:
  --requirements FILE   Accepted gate requirements declared before delivery.
  --evidence FILE       Provider-neutral exact-head execution evidence.
  --head SHA            Full reviewed Git object ID expected for every row.
  -h, --help            Show this help.

The command is read-only. A successful result does not grant commit, push,
pull-request, merge, bypass, or provider-administration authority.
EOF
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 2
}

requirements=""
evidence=""
expected_head=""

while [ $# -gt 0 ]; do
  case "$1" in
    --requirements)
      [ $# -ge 2 ] || die "--requirements needs a file"
      requirements="$2"
      shift 2
      ;;
    --evidence)
      [ $# -ge 2 ] || die "--evidence needs a file"
      evidence="$2"
      shift 2
      ;;
    --head)
      [ $# -ge 2 ] || die "--head needs a full Git object ID"
      expected_head="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
done

[ -n "$requirements" ] || die "--requirements is required"
[ -n "$evidence" ] || die "--evidence is required"
[ -n "$expected_head" ] || die "--head is required"
[ -f "$requirements" ] || die "requirements file not found: $requirements"
[ -f "$evidence" ] || die "evidence file not found: $evidence"

python_command=""
if command -v python3 >/dev/null 2>&1; then
  python_command="python3"
elif command -v python >/dev/null 2>&1; then
  python_command="python"
else
  die "python3 or python is required to validate JSON on macOS/Linux"
fi

"$python_command" - "$requirements" "$evidence" "$expected_head" <<'PY'
import hashlib
import json
import re
import sys
from pathlib import Path


requirements_path = Path(sys.argv[1])
evidence_path = Path(sys.argv[2])
expected_head = sys.argv[3]
errors = []


def load_json(path, label):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        errors.append(f"{label} is not valid UTF-8 JSON: {exc}")
        return None


def text(value):
    return value if isinstance(value, str) else ""


def non_empty(value):
    return bool(text(value).strip())


def validate_tokens(value, label):
    if not isinstance(value, list) or any(not non_empty(item) for item in value):
        errors.append(f"{label} must be an array of non-empty strings")
        return []
    return value


if not re.fullmatch(r"(?:[0-9a-fA-F]{40}|[0-9a-fA-F]{64})", expected_head):
    errors.append("--head must be a full 40- or 64-character hexadecimal Git object ID")

requirements = load_json(requirements_path, "requirements")
evidence = load_json(evidence_path, "evidence")

requirements_by_id = {}
if isinstance(requirements, dict):
    if requirements.get("schemaVersion") != "1.0":
        errors.append("requirements schemaVersion must be 1.0")
    gates = requirements.get("gates")
    if not isinstance(gates, list) or not gates:
        errors.append("requirements gates must be a non-empty array")
        gates = []
    for index, gate in enumerate(gates):
        label = f"requirements gate[{index}]"
        if not isinstance(gate, dict):
            errors.append(f"{label} must be an object")
            continue
        gate_id = text(gate.get("gateId")).strip()
        applicability = text(gate.get("applicability")).strip()
        scope = text(gate.get("requiredScope")).strip()
        if not gate_id:
            errors.append(f"{label}.gateId must be non-empty")
            continue
        if gate_id in requirements_by_id:
            errors.append(f"duplicate requirement gateId: {gate_id}")
            continue
        if applicability not in ("Applicable", "N/A"):
            errors.append(f"{label}.applicability must be Applicable or N/A")
        if not scope:
            errors.append(f"{label}.requiredScope must be non-empty")
        command_tokens = validate_tokens(
            gate.get("requiredCommandTokens"), f"{label}.requiredCommandTokens"
        )
        runner_tokens = validate_tokens(
            gate.get("requiredRunnerOrPlatformTokens"),
            f"{label}.requiredRunnerOrPlatformTokens",
        )
        rationale = text(gate.get("rationale")).strip()
        trigger = text(gate.get("reevaluationTrigger")).strip()
        if applicability == "Applicable" and not command_tokens:
            errors.append(f"{label} Applicable gates need at least one required command token")
        if applicability == "N/A":
            if command_tokens or runner_tokens:
                errors.append(f"{label} N/A gates cannot require command or runner tokens")
            if not rationale:
                errors.append(f"{label} N/A gates need a rationale")
            if not trigger:
                errors.append(f"{label} N/A gates need a reevaluation trigger")
        requirements_by_id[gate_id] = {
            "applicability": applicability,
            "requiredScope": scope,
            "requiredCommandTokens": command_tokens,
            "requiredRunnerOrPlatformTokens": runner_tokens,
            "rationale": rationale,
            "reevaluationTrigger": trigger,
        }
else:
    errors.append("requirements root must be an object")

entries_by_id = {}
if isinstance(evidence, dict):
    if evidence.get("schemaVersion") != "1.0":
        errors.append("evidence schemaVersion must be 1.0")
    expected_requirements_hash = hashlib.sha256(requirements_path.read_bytes()).hexdigest()
    if text(evidence.get("requirementsSha256")).lower() != expected_requirements_hash:
        errors.append("evidence requirementsSha256 does not match the requirements file")
    if text(evidence.get("reviewedHead")).lower() != expected_head.lower():
        errors.append("evidence reviewedHead does not match --head")
    entries = evidence.get("entries")
    if not isinstance(entries, list) or not entries:
        errors.append("evidence entries must be a non-empty array")
        entries = []
    for index, entry in enumerate(entries):
        label = f"evidence entry[{index}]"
        if not isinstance(entry, dict):
            errors.append(f"{label} must be an object")
            continue
        gate_id = text(entry.get("gateId")).strip()
        role = text(entry.get("evidenceRole")).strip()
        if not gate_id:
            errors.append(f"{label}.gateId must be non-empty")
            continue
        if gate_id not in requirements_by_id:
            errors.append(f"{label} references undeclared gateId: {gate_id}")
            continue
        if role not in ("Primary", "Supplemental"):
            errors.append(f"{label}.evidenceRole must be Primary or Supplemental")
        entries_by_id.setdefault(gate_id, []).append(entry)

        requirement = requirements_by_id[gate_id]
        applicability = text(entry.get("applicability")).strip()
        scope = text(entry.get("requiredScope")).strip()
        head = text(entry.get("headSha")).strip()
        result = text(entry.get("result")).strip()
        if applicability != requirement["applicability"]:
            errors.append(f"{label}.applicability does not match requirement {gate_id}")
        if scope != requirement["requiredScope"]:
            errors.append(f"{label}.requiredScope does not match requirement {gate_id}")
        if head.lower() != expected_head.lower():
            errors.append(f"{label}.headSha does not match --head")

        if applicability == "Applicable":
            for field in (
                "provider",
                "runId",
                "workflow",
                "job",
                "runnerOrPlatform",
                "executedCommand",
                "evidenceReference",
            ):
                if not non_empty(entry.get(field)):
                    errors.append(f"{label}.{field} must be non-empty for Applicable gates")
            if result != "Pass":
                errors.append(f"{label}.result must be Pass for Applicable gates")
            executed_command = text(entry.get("executedCommand"))
            runner = text(entry.get("runnerOrPlatform"))
            for token in requirement["requiredCommandTokens"]:
                if token not in executed_command:
                    errors.append(f"{label}.executedCommand is missing required token: {token}")
            for token in requirement["requiredRunnerOrPlatformTokens"]:
                if token not in runner:
                    errors.append(f"{label}.runnerOrPlatform is missing required token: {token}")
            if role == "Supplemental" and not non_empty(entry.get("supplementalFor")):
                errors.append(f"{label}.supplementalFor is required for Supplemental evidence")
        elif applicability == "N/A":
            if role != "Primary":
                errors.append(f"{label} N/A evidence must be Primary")
            if result != "N/A":
                errors.append(f"{label}.result must be N/A")
            if text(entry.get("rationale")).strip() != requirement["rationale"]:
                errors.append(f"{label}.rationale does not match requirement {gate_id}")
            if text(entry.get("reevaluationTrigger")).strip() != requirement["reevaluationTrigger"]:
                errors.append(f"{label}.reevaluationTrigger does not match requirement {gate_id}")
            if not non_empty(entry.get("evidenceReference")):
                errors.append(f"{label}.evidenceReference must identify the N/A decision")
else:
    errors.append("evidence root must be an object")

for gate_id in requirements_by_id:
    rows = entries_by_id.get(gate_id, [])
    primary = [row for row in rows if text(row.get("evidenceRole")).strip() == "Primary"]
    if len(primary) != 1:
        errors.append(f"gate {gate_id} needs exactly one Primary evidence entry; found {len(primary)}")
    if primary:
        primary_ref = text(primary[0].get("evidenceReference")).strip()
        for row in rows:
            if text(row.get("evidenceRole")).strip() == "Supplemental":
                if text(row.get("supplementalFor")).strip() != primary_ref:
                    errors.append(
                        f"gate {gate_id} Supplemental evidence must reference the Primary evidenceReference"
                    )

if errors:
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)
    sys.exit(1)

supplemental_count = sum(
    1
    for rows in entries_by_id.values()
    for row in rows
    if text(row.get("evidenceRole")).strip() == "Supplemental"
)
print(
    f"PASS: {len(requirements_by_id)} gate requirements, "
    f"{len(requirements_by_id)} primary entries, {supplemental_count} supplemental entries, "
    f"reviewed head {expected_head}"
)
PY
