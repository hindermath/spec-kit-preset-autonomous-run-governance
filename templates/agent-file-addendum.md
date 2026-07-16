
## Autonomous Spec Kit Runs

- Use the installed `speckit.autonomous` command for a fully delegated feature.
- Use `speckit.autonomous-status` for read-only inspection,
  `speckit.autonomous-stop` for a graceful safe-boundary pause, and
  `speckit.autonomous-resume` for an explicitly paused run. Do not resume
  `PausedByUser` through the general command.
- Determine `LocalImplementation`, `PublishPR`, or `MergeAndSync` from explicit
  current authority. General autonomy grants no remote or bypass permission.
- Iterate optional stages to convergence, establish evidence before edits, prove
  a vertical slice, serialize shared writers, and protect accepted scope.
- Require exact evidence paths for remote tasks. Keep unavailable reviewers and
  non-triggered checks explicit rather than treating them as passes.
- One mutable validation-token transition covers one explicit invocation.
- Pass repository roots explicitly to helpers and require clean exit, output,
  and error channels.
- Do not infer that Markdown, status, or evidence changes are test-free. Search
  for executable validators that consume changed paths, markers, schemas, or
  state values before skipping tests.
- Validate the exact intended commit candidate. `git diff --check` does not
  inspect untracked files; stage only intended paths, run
  `git diff --cached --check`, reconcile staged paths with repository status,
  and preserve unrelated work. Restore the prior index in local-only mode.
- Treat a green check as evidence only for the commands it executed. Map each
  acceptance gate to its workflow, job, runner or platform, and command before
  merge. Missing technical scope blocks merge; bypass grants no proof.
- Declare acceptance gates in the reviewed requirements JSON before
  implementation. Before merge, derive commands and runners from workflow
  definitions or logs, create temporary exact-head evidence, and run the
  installed validator through `bash <validator.sh>` or
  `pwsh -NoProfile -File <validator.ps1>` because installers may not preserve
  executable mode bits. Missing or token-mismatched rows fail closed; validator
  success grants no remote authority.
- Keep the exact-head provider snapshot temporary. Committing it before merge
  creates a new head and self-invalidates the proof; use causal closeout for a
  durable post-delivery record.
- Use a causal closeout only for self-invalidating current-head or post-merge
  facts, and keep it single-commit-capable without recursive self-reference.
- Create no empty feature, retrospective, or closeout pull request.
- Run the retrospective command after delivery and promote only portable rules.
- Keep the feature-local run-state index validated at phase boundaries. Recheck
  current authority and uncertain operations after every interruption; recorded
  delivery mode is evidence, not permission.
- Treat a generated `Deliver` heading as an orchestration label only. Persist
  the canonical machine-state stage `Publish`, `Review`, or `MergeAndSync` for
  remote closeout and validate the transition; `Deliver` is not a state value.
- After preset or governance drift, compare current mandatory correctness,
  security, permission, and evidence-integrity rules with accepted Plan, Tasks,
  and checklists. Minimally add an applicable missing rule and rerun Analyze;
  preserve scope and do not rewrite accepted artifacts for efficiency-only
  guidance.
