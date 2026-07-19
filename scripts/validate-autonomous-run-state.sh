#!/usr/bin/env bash
# Validate autonomous-run checkpoint state without changing repository state.

set -euo pipefail

usage() {
  cat <<'EOF'
validate-autonomous-run-state.sh - validate resumable autonomous-run state

Usage:
  bash validate-autonomous-run-state.sh --state FILE

Options:
  --state FILE   Feature-local autonomous-run-state.json.
  -h, --help     Show this help.

The command is read-only. A successful result does not start, stop, resume,
commit, push, merge, or grant remote authority to an autonomous run.
EOF
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 2
}

state=""
while [ $# -gt 0 ]; do
  case "$1" in
    --state)
      [ $# -ge 2 ] || die "--state needs a file"
      state="$2"
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

[ -n "$state" ] || die "--state is required"
[ -f "$state" ] || die "state file not found: $state"

python_command=""
if command -v python3 >/dev/null 2>&1; then
  python_command="python3"
elif command -v python >/dev/null 2>&1; then
  python_command="python"
else
  die "python3 or python is required to validate JSON on macOS/Linux"
fi

"$python_command" - "$state" <<'PY'
import json
import re
import sys
import uuid
from datetime import datetime
from pathlib import Path, PurePosixPath


path = Path(sys.argv[1])
errors = []


def text(value):
    return value if isinstance(value, str) else ""


def require_text(obj, name, label):
    value = text(obj.get(name)).strip() if isinstance(obj, dict) else ""
    if not value:
        errors.append(f"{label}.{name} must be a non-empty string")
    return value


def valid_timestamp(value):
    if not value.endswith("Z"):
        return False
    try:
        datetime.fromisoformat(value[:-1] + "+00:00")
        return True
    except ValueError:
        return False


def valid_relative_path(value):
    candidate = PurePosixPath(value)
    return not candidate.is_absolute() and ".." not in candidate.parts


try:
    data = json.loads(path.read_text(encoding="utf-8"))
except (OSError, UnicodeError, json.JSONDecodeError) as exc:
    print(f"ERROR: state is not valid UTF-8 JSON: {exc}", file=sys.stderr)
    raise SystemExit(2)

if not isinstance(data, dict):
    errors.append("state root must be an object")
    data = {}

schema_version = text(data.get("schemaVersion")).strip()
if schema_version not in ("1.0", "1.1"):
    errors.append("state schemaVersion must be 1.0 or 1.1")

run_id = require_text(data, "runId", "state")
try:
    parsed_run_id = uuid.UUID(run_id)
    if parsed_run_id.int == 0:
        errors.append("state.runId must not be the all-zero starter value")
except ValueError:
    errors.append("state.runId must be a UUID")

feature_path = require_text(data, "featurePath", "state")
if feature_path and (not feature_path.startswith("specs/") or not valid_relative_path(feature_path)):
    errors.append("state.featurePath must be a relative path below specs/")

require_text(data, "branch", "state")
delivery_mode = require_text(data, "deliveryMode", "state")
if delivery_mode not in ("LocalImplementation", "PublishPR", "MergeAndSync"):
    errors.append("state.deliveryMode must be LocalImplementation, PublishPR, or MergeAndSync")

authority = data.get("authorityRevalidationRequired")
if not isinstance(authority, bool):
    errors.append("state.authorityRevalidationRequired must be boolean")

stages = (
    "Preflight", "Specify", "Clarify", "Checklists", "Plan", "PlanReview",
    "Tasks", "Analyze", "Implement", "Validate", "Publish", "Review",
    "MergeAndSync", "Retrospective"
)
stage = require_text(data, "stage", "state")
if stage not in stages:
    errors.append("state.stage is not an allowed autonomous-run stage")

statuses = ("Active", "StopRequested", "PausedByUser", "Interrupted", "Blocked", "Completed")
status = require_text(data, "status", "state")
if status not in statuses:
    errors.append("state.status is not an allowed autonomous-run status")

checkpoint = require_text(data, "checkpointCommit", "state")
if checkpoint != "N/A" and not re.fullmatch(r"(?:[0-9a-fA-F]{40}|[0-9a-fA-F]{64})", checkpoint):
    errors.append("state.checkpointCommit must be N/A or a full Git object ID")

artifacts = data.get("acceptedArtifacts")
if not isinstance(artifacts, list):
    errors.append("state.acceptedArtifacts must be an array")
    artifacts = []
artifact_paths = set()
for index, artifact in enumerate(artifacts):
    label = f"state.acceptedArtifacts[{index}]"
    if not isinstance(artifact, dict):
        errors.append(f"{label} must be an object")
        continue
    artifact_path = require_text(artifact, "path", label)
    artifact_hash = require_text(artifact, "sha256", label)
    if artifact_path and not valid_relative_path(artifact_path):
        errors.append(f"{label}.path must be repository-relative without ..")
    if artifact_path in artifact_paths:
        errors.append(f"duplicate accepted artifact path: {artifact_path}")
    artifact_paths.add(artifact_path)
    if artifact_hash and not re.fullmatch(r"[0-9a-f]{64}", artifact_hash):
        errors.append(f"{label}.sha256 must be lowercase SHA-256")

tasks = data.get("tasks")
if not isinstance(tasks, dict):
    errors.append("state.tasks must be an object")
    tasks = {}
tasks_path = require_text(tasks, "path", "state.tasks")
tasks_hash = require_text(tasks, "sha256", "state.tasks")
completed = tasks.get("completed")
total = tasks.get("total")
if not isinstance(completed, int) or isinstance(completed, bool) or completed < 0:
    errors.append("state.tasks.completed must be a non-negative integer")
if not isinstance(total, int) or isinstance(total, bool) or total < 0:
    errors.append("state.tasks.total must be a non-negative integer")
if isinstance(completed, int) and isinstance(total, int) and completed > total:
    errors.append("state.tasks.completed cannot exceed state.tasks.total")
if tasks_path == "N/A":
    if tasks_hash != "N/A" or completed != 0 or total != 0:
        errors.append("state.tasks N/A path requires N/A hash and zero counts")
elif not valid_relative_path(tasks_path):
    errors.append("state.tasks.path must be repository-relative without ..")
elif not re.fullmatch(r"[0-9a-f]{64}", tasks_hash):
    errors.append("state.tasks.sha256 must be lowercase SHA-256")

require_text(data, "lastPassingGate", "state")
next_action = require_text(data, "nextExactAction", "state")

operation = data.get("lastOperation")
if not isinstance(operation, dict):
    errors.append("state.lastOperation must be an object")
    operation = {}
require_text(operation, "kind", "state.lastOperation")
operation_state = require_text(operation, "state", "state.lastOperation")
if operation_state not in ("N/A", "Completed", "Failed", "NeedsRevalidation"):
    errors.append("state.lastOperation.state is not allowed")
require_text(operation, "summary", "state.lastOperation")

stop = data.get("stop")
if not isinstance(stop, dict):
    errors.append("state.stop must be an object")
    stop = {}
stop_reason = require_text(stop, "reason", "state.stop")
requested_at = require_text(stop, "requestedAt", "state.stop")
safe_boundary = require_text(stop, "safeBoundary", "state.stop")

closeout = data.get("closeout")
optional_closeout_states = ("N/A", "Pending", "Completed", "Failed", "NeedsRevalidation")
required_closeout_states = ("Pending", "Completed", "Failed", "NeedsRevalidation")
closeout_values = {}
if schema_version == "1.1":
    if not isinstance(closeout, dict):
        errors.append("state.closeout must be an object for schema 1.1")
        closeout = {}
    for field in (
        "mergeOrPublication",
        "defaultBranchSync",
        "postMergeActions",
        "finalValidation",
    ):
        value = require_text(closeout, field, "state.closeout")
        closeout_values[field] = value
        allowed_states = (
            required_closeout_states
            if field == "finalValidation"
            else optional_closeout_states
        )
        if value not in allowed_states:
            errors.append(f"state.closeout.{field} is not allowed")

updated_at = require_text(data, "updatedAt", "state")
if updated_at and not valid_timestamp(updated_at):
    errors.append("state.updatedAt must be an ISO-8601 UTC timestamp ending in Z")

stopped = status in ("StopRequested", "PausedByUser", "Interrupted", "Blocked")
if stopped:
    if authority is not True:
        errors.append(f"state.authorityRevalidationRequired must be true for {status}")
    if stop_reason == "N/A" or safe_boundary == "N/A":
        errors.append(f"state.stop reason and safeBoundary must be recorded for {status}")
    if requested_at == "N/A" or not valid_timestamp(requested_at):
        errors.append(f"state.stop.requestedAt must be a UTC timestamp for {status}")
elif any(value != "N/A" for value in (stop_reason, requested_at, safe_boundary)):
    errors.append(f"state.stop fields must be N/A for {status}")

if status == "Interrupted" and operation_state not in ("Failed", "NeedsRevalidation", "N/A"):
    errors.append("Interrupted state cannot claim the last operation completed")
if status == "Completed" and next_action != "N/A":
    errors.append("Completed state requires nextExactAction N/A")
if schema_version == "1.1" and status == "Completed":
    if closeout_values.get("finalValidation") != "Completed":
        errors.append("Completed state requires closeout.finalValidation Completed")
    if delivery_mode == "MergeAndSync":
        if closeout_values.get("mergeOrPublication") != "Completed":
            errors.append("MergeAndSync completion requires mergeOrPublication Completed")
        if closeout_values.get("defaultBranchSync") != "Completed":
            errors.append("MergeAndSync completion requires defaultBranchSync Completed")
        if closeout_values.get("postMergeActions") not in ("N/A", "Completed"):
            errors.append("MergeAndSync completion requires postMergeActions N/A or Completed")
    elif delivery_mode == "PublishPR":
        if closeout_values.get("mergeOrPublication") != "Completed":
            errors.append("PublishPR completion requires mergeOrPublication Completed")
        if closeout_values.get("defaultBranchSync") != "N/A":
            errors.append("PublishPR completion requires defaultBranchSync N/A")
        if closeout_values.get("postMergeActions") != "N/A":
            errors.append("PublishPR completion requires postMergeActions N/A")
    elif delivery_mode == "LocalImplementation":
        for field in ("mergeOrPublication", "defaultBranchSync", "postMergeActions"):
            if closeout_values.get(field) != "N/A":
                errors.append(
                    f"LocalImplementation completion requires {field} N/A"
                )

if errors:
    for message in errors:
        print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(2)

print(
    f"PASS: run {run_id}, feature {feature_path}, stage {stage}, "
    f"status {status}, tasks {completed}/{total}"
)
PY
