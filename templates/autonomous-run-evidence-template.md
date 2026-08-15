# Autonomous Run Evidence

## Identity and Authority

| Field | Value |
|---|---|
| Feature | `[feature]` |
| Accepted inputs | `[paths]` |
| Delivery mode | `[LocalImplementation/PublishPR/MergeAndSync]` |
| Authority source | `[current request or N/A]` |
| Evidence owner | `[owner]` |
| Run-state path | `specs/[feature]/autonomous-run-state.json` |
| Run-state status | `[Active/StopRequested/PausedByUser/Interrupted/Blocked/Completed]` |

## Model Routing

| Phase | Command | Role | Profile | Model | Effort | Preflight | Result SHA-256 |
|---|---|---|---|---|---|---|---|
| `[phase]` | `[command]` | `[stable role/script-only]` | `[local profile/N/A]` | `[resolved model/N/A]` | `[effort/N/A]` | `[Pass/Blocked/N/A]` | `[hash/N/A]` |

Model identifiers are execution evidence, not feature requirements. A model
change requires a completed process boundary and a validated handoff hash.

## Scope and Convergence

| Gate | State | Evidence or disposition |
|---|---|---|
| Preflight | Open | `[path/result]` |
| Clarify | Open | `[questions or no-material-ambiguity result]` |
| Checklists | Open | `[counts]` |
| Plan review | Open | `[result]` |
| Analyze | Open | `[severity counts and accepted findings]` |
| Implementation | Open | `[task counts]` |

## Validation

| Invocation | Trigger | Mutable token/value | Explicit root | Exit | Error channel | Result and proof boundary |
|---|---|---|---|---:|---|---|
| `[command]` | `[trigger]` | `[value/N/A]` | `[path]` | `[code]` | `[clean/failure]` | `[Pass/Fail/N/A and evidence]` |

One mutable-token transition covers one explicit invocation. A nominal zero
exit cannot override a fatal structured or error-channel signal.

## Delivery Candidate Integrity

- Delivery-set validator and exact intended untracked paths:
- Index/worktree before and after evidence:
- Unrelated or ignored paths and disposition:
- Structured phase-result paths and normalized hashes:

| Check | Result | Evidence |
|---|---|---|
| Intended paths | `[Pass/Open]` | `[path inventory]` |
| Tracked worktree diff | `[Pass/Open]` | `git diff --check` |
| Exact staged candidate | `[Pass/N/A/Open]` | `git diff --cached --check or local-only equivalent` |
| Status reconciliation | `[Pass/Open]` | `[staged/untracked/unstaged boundary]` |
| Index preservation | `[Pass/N/A/Open]` | `[restored prior state or authorized staged candidate]` |

## Acceptance Gate Contract

- Lifecycle snapshot type (`PreMerge` or `PostMerge`):
- Accepted PreMerge path and normalized hash, when PostMerge:
- Historical schema-1.0 evidence, if any, and audit-only rationale:

| Item | Value |
|---|---|
| Requirements artifact | `[reviewed feature path]` |
| Requirements SHA-256 | `[lowercase hash]` |
| Temporary evidence snapshot | `[local/provider-artifact path; do not commit before merge]` |
| Reviewed head | `[full 40- or 64-character Git object ID]` |
| Validator | `[installed Bash/PowerShell command]` |
| Validator result | `[Pass/Fail/Open plus exact output]` |

The requirements artifact is declared before implementation. Generate the
provider evidence after final checks, derive commands and runners from workflow
definitions or logs, and keep the exact-head snapshot temporary so recording it
does not create a new, unvalidated head.

## Remote Delivery

| Item | Result | Evidence |
|---|---|---|
| Push | `[Pass/N/A/Open]` | `[branch/path]` |
| Pull request | `[Pass/N/A/Open]` | `[URL or rationale]` |
| Required checks | `[Pass/N/A/Open]` | `[review-context gate]` |
| Acceptance execution map | `[Pass/N/A/Open]` | `[requirements hash + validated temporary exact-head evidence]` |
| Actionable threads | `[count/N/A/Open]` | `[provider evidence]` |
| Unavailable reviews | `[None/limitation]` | `[provider evidence]` |
| Merge | `[Pass/N/A/Open]` | `[authority and result]` |
| Default-branch sync | `[Pass/N/A/Open]` | `[local and remote revision]` |
| Causal closeout | `[Required/N/A/Open]` | `[pre-named path and reason]` |
| Duplicate events | `[Observed/N/A]` | `[classification; no implicit cancellation]` |

## Closeout State

| Step | State | Evidence |
|---|---|---|
| Merge or publication | `[N/A/Pending/Completed/Failed/NeedsRevalidation]` | `[proof]` |
| Default-branch synchronization | `[N/A/Pending/Completed/Failed/NeedsRevalidation]` | `[proof]` |
| Manifest-declared post-merge actions | `[N/A/Pending/Completed/Failed/NeedsRevalidation]` | `[proof]` |
| Final validation | `[Pending/Completed/Failed/NeedsRevalidation]` | `[proof]` |

## Resume and Follow-up

- Checkpoint commit: `[full object ID or N/A]`
- Last operation: `[kind and Completed/Failed/NeedsRevalidation/N/A]`
- Last passing gate: `[gate]`
- Next exact action: `[action]`
- Stop reason and safe boundary: `[reason/boundary or N/A]`
- Authority revalidation required: `[true/false]`
- Residual risk: `[risk]`
- Out-of-scope follow-up: `[owner/path/trigger]`
