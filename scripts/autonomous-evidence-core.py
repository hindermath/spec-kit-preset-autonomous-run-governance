#!/usr/bin/env python3
"""Read-only evidence validators for autonomous Spec Kit delivery."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path, PurePosixPath


class EvidenceError(Exception):
    def __init__(self, code: str, message: str, exit_code: int = 2) -> None:
        super().__init__(message)
        self.code = code
        self.exit_code = exit_code


def fail(code: str, message: str, exit_code: int = 2) -> None:
    raise EvidenceError(code, message, exit_code)


def normalized_bytes(path: Path) -> bytes:
    raw = path.read_bytes()
    if raw.startswith(b"\xef\xbb\xbf"):
        raw = raw[3:]
    text = raw.decode("utf-8", errors="strict")
    if "\x00" in text:
        fail("AEI002", f"binary NUL is not supported: {path}")
    return text.replace("\r\n", "\n").replace("\r", "\n").encode("utf-8")


def normalized_hash(path: Path) -> str:
    return hashlib.sha256(normalized_bytes(path)).hexdigest()


def load_json(path: Path, label: str) -> dict:
    try:
        data = json.loads(normalized_bytes(path).decode("utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        fail("AEI002", f"{label} is not strict UTF-8 JSON: {exc}")
    if not isinstance(data, dict):
        fail("AEI002", f"{label} root must be an object")
    return data


def require_text(data: dict, key: str, label: str) -> str:
    value = data.get(key)
    if not isinstance(value, str) or not value.strip():
        fail("AEI003", f"{label}.{key} must be a non-empty string")
    return value.strip()


def run_git(repo: Path, *arguments: str) -> str:
    result = subprocess.run(
        ["git", "-C", str(repo), *arguments],
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if result.returncode != 0:
        fail("AEI004", f"git {' '.join(arguments)} failed: {result.stderr.strip()}")
    return result.stdout


def relative_path(repo: Path, value: str) -> tuple[str, Path]:
    candidate = PurePosixPath(value.replace("\\", "/"))
    if candidate.is_absolute() or not candidate.parts or ".." in candidate.parts:
        fail("AEI005", f"path must be repository-relative without traversal: {value}")
    normalized = candidate.as_posix()
    if normalized in (".", ""):
        fail("AEI005", f"path must name a file: {value}")
    path = repo.joinpath(*candidate.parts)
    resolved_repo = repo.resolve()
    resolved_path = path.resolve(strict=False)
    if resolved_path != resolved_repo and resolved_repo not in resolved_path.parents:
        fail("AEI005", f"path escapes repository: {value}")
    return normalized, path


def git_state(repo: Path) -> tuple[str, str]:
    tree = run_git(repo, "write-tree").strip()
    status = run_git(repo, "status", "--porcelain=v1", "--untracked-files=all", "--ignored")
    return tree, hashlib.sha256(status.encode("utf-8")).hexdigest()


def validate_text_whitespace(path: Path, label: str) -> None:
    raw = path.read_bytes()
    if b"\x00" in raw:
        return
    try:
        text = raw.decode("utf-8-sig", errors="strict")
    except UnicodeDecodeError as exc:
        fail("AEI006", f"{label} is neither UTF-8 text nor detected binary: {exc}")
    for number, line in enumerate(text.replace("\r\n", "\n").replace("\r", "\n").split("\n"), 1):
        if line.endswith((" ", "\t")):
            fail("AEI007", f"trailing whitespace: {label}:{number}")


def delivery_command(args: argparse.Namespace) -> str:
    repo = Path(args.repo).resolve()
    if not (repo / ".git").exists() and not run_git(repo, "rev-parse", "--git-dir").strip():
        fail("AEI004", "repository root is not a Git worktree")
    before = git_state(repo)
    intended: list[str] = []
    intended_paths: dict[str, Path] = {}
    for value in args.intended:
        normalized, path = relative_path(repo, value)
        if normalized in intended_paths:
            fail("AEI005", f"duplicate intended path: {normalized}")
        if path.is_symlink():
            fail("AEI005", f"intended path must not be a symbolic link: {normalized}")
        if not path.exists() or not path.is_file():
            fail("AEI005", f"intended path is not an existing file: {normalized}")
        ignored = subprocess.run(
            ["git", "-C", str(repo), "check-ignore", "--quiet", "--", normalized],
            check=False,
        ).returncode == 0
        if ignored:
            fail("AEI005", f"intended path is ignored: {normalized}")
        intended.append(normalized)
        intended_paths[normalized] = path

    tracked = [
        line for line in run_git(repo, "diff", "--name-only", "HEAD", "--").splitlines() if line
    ]
    untracked = [
        line
        for line in run_git(repo, "ls-files", "--others", "--exclude-standard").splitlines()
        if line
    ]
    for path_text in intended:
        if path_text not in untracked and path_text not in tracked:
            fail("AEI005", f"intended path is neither changed nor untracked: {path_text}")

    checked = sorted(set(tracked + intended))
    for path_text in checked:
        _, path = relative_path(repo, path_text)
        if path.exists() and path.is_file():
            validate_text_whitespace(path, path_text)

    after = git_state(repo)
    if before != after:
        fail("AEI008", "delivery validation changed index or worktree state")
    unrelated = sorted(set(untracked) - set(intended))
    return json.dumps(
        {
            "schemaVersion": "1.0",
            "result": "Pass",
            "trackedPaths": sorted(tracked),
            "intendedUntrackedPaths": sorted(set(intended) & set(untracked)),
            "unrelatedUntrackedPaths": unrelated,
            "checkedPaths": checked,
            "indexTree": before[0],
            "worktreeStatusSha256": before[1],
        },
        indent=2,
    )


def phase_command(args: argparse.Namespace) -> str:
    if args.exit_code != 0:
        fail("AEI101", f"phase process exited {args.exit_code}", 3)
    result_path = Path(args.result)
    result = load_json(result_path, "phase result")
    if result.get("schemaVersion") != "1.0":
        fail("AEI102", "phase result schemaVersion must be 1.0", 3)
    if require_text(result, "phaseId", "phase result") != args.phase_id:
        fail("AEI103", "phase result does not match the requested phase", 3)
    require_text(result, "attemptId", "phase result")
    outcome = require_text(result, "outcome", "phase result")
    if outcome == "Blocked":
        require_text(result, "blockedReason", "phase result")
        fail("AEI104", "phase result is Blocked", 3)
    if outcome != "Completed":
        fail("AEI104", f"phase outcome is not Completed: {outcome}", 3)
    expected = result.get("expectedTasks")
    completed = result.get("completedTasks")
    if not isinstance(expected, int) or isinstance(expected, bool) or expected < 0:
        fail("AEI105", "expectedTasks must be a non-negative integer", 3)
    if not isinstance(completed, int) or isinstance(completed, bool) or completed != expected:
        fail("AEI105", "completedTasks must equal expectedTasks", 3)
    if result.get("gatesSatisfied") is not True:
        fail("AEI106", "gatesSatisfied must be true", 3)
    payload_text = require_text(result, "payloadPath", "phase result")
    payload_hash = require_text(result, "payloadSha256", "phase result").lower()
    repo = Path(args.repo).resolve()
    _, payload_path = relative_path(repo, payload_text)
    if not payload_path.is_file():
        fail("AEI107", f"phase payload is missing: {payload_text}", 3)
    if normalized_hash(payload_path) != payload_hash:
        fail("AEI107", "phase payload hash does not match", 3)
    return json.dumps(
        {
            "schemaVersion": "1.0",
            "result": "Completed",
            "phaseId": args.phase_id,
            "normalizedSha256": normalized_hash(result_path),
            "payloadSha256": payload_hash,
        },
        indent=2,
    )


def validate_requirements(path: Path) -> tuple[dict, str]:
    data = load_json(path, "requirements")
    if data.get("schemaVersion") != "1.0":
        fail("AEI201", "requirements schemaVersion must be 1.0")
    gates = data.get("gates")
    if not isinstance(gates, list) or not gates:
        fail("AEI201", "requirements gates must be a non-empty array")
    by_id: dict[str, dict] = {}
    for gate in gates:
        if not isinstance(gate, dict):
            fail("AEI201", "each requirements gate must be an object")
        gate_id = require_text(gate, "gateId", "requirements gate")
        if gate_id in by_id:
            fail("AEI201", f"duplicate gateId: {gate_id}")
        applicability = require_text(gate, "applicability", gate_id)
        if applicability not in ("Applicable", "N/A"):
            fail("AEI201", f"invalid applicability for {gate_id}")
        by_id[gate_id] = gate
    return by_id, normalized_hash(path)


def validate_gate_entries(evidence: dict, requirements: dict, expected_head: str) -> None:
    entries = evidence.get("entries")
    if not isinstance(entries, list) or not entries:
        fail("AEI202", "evidence entries must be a non-empty array")
    grouped: dict[str, list[dict]] = {}
    for entry in entries:
        if not isinstance(entry, dict):
            fail("AEI202", "each evidence entry must be an object")
        gate_id = require_text(entry, "gateId", "evidence entry")
        if gate_id not in requirements:
            fail("AEI202", f"undeclared gateId: {gate_id}")
        grouped.setdefault(gate_id, []).append(entry)
        requirement = requirements[gate_id]
        if entry.get("applicability") != requirement.get("applicability"):
            fail("AEI202", f"applicability mismatch: {gate_id}")
        if entry.get("requiredScope") != requirement.get("requiredScope"):
            fail("AEI202", f"scope mismatch: {gate_id}")
        if str(entry.get("headSha", "")).lower() != expected_head.lower():
            fail("AEI202", f"head mismatch: {gate_id}")
        if requirement.get("applicability") == "Applicable":
            for field in ("provider", "runId", "workflow", "job", "runnerOrPlatform", "executedCommand", "evidenceReference"):
                require_text(entry, field, gate_id)
            if entry.get("result") != "Pass":
                fail("AEI202", f"Applicable gate is not Pass: {gate_id}")
            for token in requirement.get("requiredCommandTokens", []):
                if token not in str(entry.get("executedCommand", "")):
                    fail("AEI202", f"missing command token for {gate_id}: {token}")
            for token in requirement.get("requiredRunnerOrPlatformTokens", []):
                if token not in str(entry.get("runnerOrPlatform", "")):
                    fail("AEI202", f"missing runner token for {gate_id}: {token}")
        else:
            if entry.get("result") != "N/A":
                fail("AEI202", f"N/A gate result must be N/A: {gate_id}")
            require_text(entry, "rationale", gate_id)
            require_text(entry, "reevaluationTrigger", gate_id)
    if set(grouped) != set(requirements):
        fail("AEI202", "evidence must cover every declared gate exactly")
    for gate_id, rows in grouped.items():
        primary = [row for row in rows if row.get("evidenceRole") == "Primary"]
        if len(primary) != 1:
            fail("AEI202", f"gate needs exactly one Primary row: {gate_id}")


def historical_gate(evidence: dict, requirements: dict, requirements_hashes: set[str], head: str) -> str:
    if evidence.get("schemaVersion") != "1.0":
        fail("AEI203", "historical evidence schemaVersion must be 1.0")
    if str(evidence.get("requirementsSha256", "")).lower() not in requirements_hashes:
        fail("AEI203", "historical requirementsSha256 mismatch")
    if str(evidence.get("reviewedHead", "")).lower() != head.lower():
        fail("AEI203", "historical evidence reviewedHead mismatch")
    validate_gate_entries(evidence, requirements, head)
    return json.dumps({"schemaVersion": "1.0", "result": "HistoricalOnly", "mergeAuthorized": False}, indent=2)


def gate_command(args: argparse.Namespace) -> str:
    if not re.fullmatch(r"(?:[0-9a-fA-F]{40}|[0-9a-fA-F]{64})", args.head):
        fail("AEI201", "head must be a full 40- or 64-character Git object ID")
    requirements_path = Path(args.requirements)
    evidence_path = Path(args.evidence)
    requirements, requirements_hash = validate_requirements(requirements_path)
    evidence = load_json(evidence_path, "gate evidence")
    if args.historical:
        raw_requirements_hash = hashlib.sha256(requirements_path.read_bytes()).hexdigest()
        return historical_gate(
            evidence,
            requirements,
            {requirements_hash, raw_requirements_hash},
            args.head,
        )
    if evidence.get("schemaVersion") != "2.0":
        fail("AEI203", "new delivery requires Gate Evidence schemaVersion 2.0")
    snapshot_type = require_text(evidence, "snapshotType", "gate evidence")
    if snapshot_type not in ("PreMerge", "PostMerge"):
        fail("AEI203", "snapshotType must be PreMerge or PostMerge")
    require_text(evidence, "snapshotId", "gate evidence")
    captured = require_text(evidence, "capturedAt", "gate evidence")
    if not captured.endswith("Z"):
        fail("AEI203", "capturedAt must be UTC")
    if str(evidence.get("requirementsSha256", "")).lower() != requirements_hash:
        fail("AEI203", "requirementsSha256 does not match normalized requirements")
    if str(evidence.get("reviewedHead", "")).lower() != args.head.lower():
        fail("AEI203", "reviewedHead does not match --head")
    validate_gate_entries(evidence, requirements, args.head)
    merge_commit = str(evidence.get("mergeCommit", "")).strip()
    pre_hash = str(evidence.get("acceptedPreMergeSha256", "")).strip().lower()
    changed_paths = evidence.get("changedPaths", [])
    if snapshot_type == "PreMerge":
        if merge_commit or pre_hash:
            fail("AEI204", "PreMerge evidence cannot claim merge facts")
    else:
        if not re.fullmatch(r"(?:[0-9a-fA-F]{40}|[0-9a-fA-F]{64})", merge_commit):
            fail("AEI205", "PostMerge mergeCommit must be a full Git object ID")
        if args.merge_commit and merge_commit.lower() != args.merge_commit.lower():
            fail("AEI205", "PostMerge mergeCommit does not match expected merge")
        if not isinstance(changed_paths, list) or changed_paths:
            fail("AEI205", "PostMerge changedPaths must be empty")
        pre_path_text = require_text(evidence, "acceptedPreMergePath", "gate evidence")
        pre_path = Path(pre_path_text)
        if not pre_path.is_file():
            fail("AEI205", "accepted PreMerge evidence is missing")
        if normalized_hash(pre_path) != pre_hash:
            fail("AEI205", "accepted PreMerge hash mismatch")
        pre = load_json(pre_path, "accepted PreMerge evidence")
        if pre.get("schemaVersion") != "2.0" or pre.get("snapshotType") != "PreMerge":
            fail("AEI205", "accepted evidence is not a schema-2.0 PreMerge snapshot")
        if str(pre.get("reviewedHead", "")).lower() != args.head.lower():
            fail("AEI205", "accepted PreMerge reviewedHead mismatch")
    return json.dumps(
        {
            "schemaVersion": "2.0",
            "result": "Pass",
            "snapshotType": snapshot_type,
            "normalizedSha256": normalized_hash(evidence_path),
            "mergeAuthorized": snapshot_type == "PostMerge",
        },
        indent=2,
    )


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser()
    commands = root.add_subparsers(dest="command", required=True)
    delivery = commands.add_parser("delivery")
    delivery.add_argument("--repo", required=True)
    delivery.add_argument("--intended", action="append", default=[])
    phase = commands.add_parser("phase")
    phase.add_argument("--repo", required=True)
    phase.add_argument("--result", required=True)
    phase.add_argument("--phase-id", required=True)
    phase.add_argument("--exit-code", required=True, type=int)
    gate = commands.add_parser("gate")
    gate.add_argument("--requirements", required=True)
    gate.add_argument("--evidence", required=True)
    gate.add_argument("--head", required=True)
    gate.add_argument("--merge-commit", default="")
    gate.add_argument("--historical", action="store_true")
    return root


def main() -> int:
    args = parser().parse_args()
    try:
        if args.command == "delivery":
            output = delivery_command(args)
        elif args.command == "phase":
            output = phase_command(args)
        else:
            output = gate_command(args)
        print(output)
        return 0
    except EvidenceError as exc:
        print(f"ERROR {exc.code}: {exc}", file=sys.stderr)
        return exc.exit_code
    except (OSError, UnicodeError) as exc:
        print(f"ERROR AEI001: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
