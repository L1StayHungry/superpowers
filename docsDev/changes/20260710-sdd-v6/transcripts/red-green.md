# SDD v6 RED/GREEN Evidence

## RED

- Time: 2026-07-10 Asia/Shanghai
- Command: `bash tests/claude-code/test-sdd-workspace.sh`
- Exit code: `1`
- Expected failure: `missing executable script:
  skills/t-subagent-driven-development/scripts/sdd-workspace`
- Conclusion: the old implementation lacked the required exact CLI and could
  not satisfy the docsDev handoff contract.

## Scripts GREEN

- Command: `SDD_SCRIPTS_ONLY=1 bash tests/claude-code/test-sdd-workspace.sh`
- Exit code: `0`
- Key output: `PASS: SDD artifacts use docsDev, exact CLIs fail closed, legacy
  constraints fall back, and multi-commit review packages remain complete`

## Full Focused GREEN

- Command: `bash tests/claude-code/test-sdd-workspace.sh`
- Exit code: `0`
- Key output: same PASS line, with the combined reviewer, read-only review,
  model capability, ledger, and final-review static contracts also enabled.

## Pending Integration Evidence

## Symlink Safety RED/GREEN

- RED command: `bash tests/claude-code/test-sdd-workspace.sh`
- RED exit: `1`
- RED output: `FAIL: sdd-workspace followed a transcripts symlink`
- GREEN command: the same focused test after rejecting symlinked
  `transcripts`, `sdd`, and `.gitignore` components and verifying the canonical
  workspace remains exactly inside the change.
- GREEN exit: `0`.

## Global Constraints Boundary RED/GREEN

- RED command: `bash tests/claude-code/test-sdd-workspace.sh`
- RED exit: `1`
- RED output: `FAIL: Global Constraints extraction swallowed the following task`
- Root cause: the first extractor stopped only at another level-2 heading, but
  valid generated plans use level-3 Task headings.
- GREEN: extraction now stops at the first subsequent Markdown heading, while
  plan and same-spec fallback cases both retain exact constraint values.

## Claude Targeted and Integration

- Targeted Q&A initially exposed two stale harness assertions and a runner
  configured with a 120-second whole-test timeout for ten model calls. The
  prompts now explicitly invoke `t-superpowers:t-subagent-driven-development`,
  assertions match the combined-review/file-handoff contract, and direct
  execution with per-query `CLAUDE_TEST_TIMEOUT=120` completed normally.
- Integration run 1 was stopped after proving its ambiguous skill name routed
  to a non-local workflow and wrote root-level artifacts. The prompt now names
  the exact internal skill and bundled scripts.
- Integration run 3 completed the workflow: exact skill invocation, five
  subagents, two task commits, one combined reviewer for each task, task
  briefs/reports/review packages/ledger under docsDev, RED/GREEN evidence,
  6/6 passing tests, and a clean final whole-branch review.
- Run 3's process exit was `1` only because the old analyzer required a
  harness-specific `TodoWrite` call. The corrected rule accepts either native
  todo tracking or the durable SDD ledger. Offline re-analysis command checked
  all original PASS lines plus the ledger evidence and exited `0`:

```text
PASS: corrected task-tracking rule accepts the durable ledger
PASS: integration-3 offline re-analysis satisfies every corrected functional assertion
```

- A full rerun with the corrected analyzer loaded the exact t skill and
  completed Task 1, then remained idle after recording Task 2 in-progress for
  roughly four minutes. It was manually stopped as a repeated model-service
  stall; no functional failure or false XFAIL classification was recorded.

## Deterministic Regression GREEN

All of the following exited `0` after the final implementation changes:

- `bash tests/claude-code/test-sdd-workspace.sh`
- `bash tests/claude-code/test-subagent-driven-development-integration-prompt.test.sh`
- `bash tests/claude-code/test-writing-plans-contract.sh`
- `bash tests/claude-code/run-skill-tests-timeout.test.sh`
- `bash tests/subagent-driven-dev/run-test-preflight.test.sh` — 12 passed
- `bash tools/t-stage1-check.sh`
- `npm run test:npm-installer` — 67 passed
- `npm run build`
- `npm run pack:dry-run` — 72 packaged files, version remains `5.1.1`
- `bash -n` for all modified/new SDD and harness shell scripts
- `git diff --check`

## Independent Review RED/GREEN

The combined read-only review found four implementation gaps plus pending
`t-smoke`:

- `.gitignore` replacement was not atomic;
- reviewer prompts still allowed worktree creation;
- legacy `spec.md` symlinks could inject external constraints;
- live topology checks could match user prompt prose and did not exercise a
  resume ledger.

Fixes and fresh evidence:

- `.gitignore` now stages with same-directory `mktemp` and atomically replaces
  the destination. A chmod-500 fixture proves a staging failure preserves the
  existing file.
- Both reviewer prompts prohibit creating/removing worktrees and require a
  `Cannot verify` result when read-only material is missing.
- `task-brief` rejects symlinked legacy specs before reading constraints.
- `analyze-sdd-session.py` reads only `Agent`/`Task` tool-use blocks. Synthetic
  fixtures test the analyzer itself. A separate live resume integration mode
  preloads a committed Task 1 plus its durable ledger entry, invokes the exact
  SDD skill, and analyzes the resulting tool calls with `--resume-ledger` so a
  Task 1 re-dispatch fails the run. The original real integration-3 session
  reports:

```text
PASS: implementers={1: 1, 2: 1} combined_reviewers={1: 1, 2: 1} final_reviewers=1
```

### Live resume RED/GREEN

The first real resume run correctly skipped ledger-complete Task 1, but exposed
an isolation bug: the nested untracked `.gitignore` was absent from the
implementer's linked worktree, so `task-2-report.md` entered its commit. The
controller then needed a report-note commit and a second final review. This was
RED evidence, not a passing resume run.

`sdd-workspace` now atomically adds
`/docsDev/changes/*/transcripts/sdd/` to the shared Git `info/exclude`, while
retaining the workspace-local ignore. A deterministic linked-worktree fixture
proves the report is ignored outside the controller worktree.

Fresh live command:

```text
bash tests/claude-code/test-subagent-driven-development-resume-integration.sh
```

Session `883ee642-ead8-4903-820b-0e373eb2d85f` exited `0` with:

```text
PASS: SDD scratch files remain untracked across isolated worktrees
PASS: implementers={2: 1} combined_reviewers={2: 1} final_reviewers=1
2 tests passing, 0 failures
STATUS: PASSED
```

The session read the preloaded Task 1 ledger entry, never dispatched Task 1,
created only the Task 2 brief/report/review package, and completed with one
final whole-branch review.

## Post-Commit Integrity Review

A root-level combined review of commit `e4da93f` found three additional
Important gaps:

- a caller in repository A could pass repository B's plan and write B;
- a final Task could absorb following plan-level Validation/Risks sections;
- happy-path topology analysis counted roles but did not enforce dispatch
  order, and final-role recognition was too broad.

RED fixtures now cover two repositories, a level-3 final Task followed by a
level-2 Validation section, and the reversed order final → reviewer →
implementer. GREEN behavior requires canonical caller/plan root equality,
heading-level task boundaries, Task implementer before its reviewer, every
task reviewer before one strictly described `Final whole-branch review`.

A final root review found that per-task ordering alone still allowed Task 2
implementation before Task 1 review. The new interleaved fixture first failed
with:

```text
FAIL: session analyzer accepted Task 2 implementation before Task 1 review gate
```

The GREEN analyzer checks sorted task order as
`implement(N) < review(N) < implement(N+1)`, so the next task cannot start
until the previous task's combined review gate has passed. The focused SDD
contract and `git diff --check` both exit `0` afterward.

## Committed t-smoke Attempt

- Command: `tests/subagent-driven-dev/run-test.sh t-smoke --plugin-dir
  /Users/lihuajun/WorkProject/superpowers --timeout 900`
- Plugin commit: `e4da93f`
- Result: stopped after more than four minutes without a first assistant turn.
- Stream evidence: SessionStart and init succeeded, followed by
  `api_retry attempt=1 error_status=502 server_error`; the disposable project
  remained at its scaffold commit with no SDD workspace.
- Classification: model-service infrastructure failure. This is not counted
  as a functional pass or XFAIL. The earlier full Claude integration run
  remains the live end-to-end functional evidence.
