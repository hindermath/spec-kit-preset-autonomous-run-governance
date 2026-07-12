
## Autonomous Task-shaping Rules

- Start with preflight, evidence creation, and checklist verification tasks.
- Name stable task IDs and exact repository paths. Every remote or delivery task
  names the evidence path that records its result.
- Put a failing or missing proof before implementation when the contract is
  observable. Add a compile/execution-surface review before the first red run.
- Prove one representative vertical slice before repeated rollout.
- Serialize shared evidence, version, workflow, statistics, and agent-guidance
  files; do not mark them parallel.
- Add one prior mutable-token transition for each explicit validation invocation
  when repository policy requires such a token.
- Every helper task passes an explicit repository root and checks exit status,
  required output, and structured/error channels.
- Add trigger-based validation and an explicit disposition for every skipped
  conditional gate.
- Before a documentation- or evidence-only test skip, add a dependency-search
  task for executable validators that read changed paths, markers, schemas, or
  status values; update and run every affected validator in the same slice.
- Add remote tasks only for explicitly authorized modes. `MergeAndSync` includes
  check/review convergence, branch cleanup, and local/default-branch sync proof.
- Keep current-head verification before merge. Route self-invalidating and true
  post-merge facts to one pre-named, single-commit-capable closeout.
- End with a retrospective task; do not add an empty retrospective branch or PR.
