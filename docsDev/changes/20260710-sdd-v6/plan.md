---
change_id: 20260710-sdd-v6
created_at: 2026-07-10T06:30:00Z
updated_at: 2026-07-10T08:15:00Z
owner: lihuajun
---

# SDD v6 Selective Sync Implementation Plan

## Global Constraints

- `sdd-workspace` MUST accept exactly `PLAN_FILE`.
- `task-brief` MUST accept exactly `PLAN_FILE TASK_NUMBER [OUTFILE]`.
- `review-package` MUST accept exactly `PLAN_FILE BASE HEAD [OUTFILE]`.
- `PLAN_FILE` MUST resolve to `docsDev/changes/<change-id>/plan.md` in the
  current worktree; an external plan must first be associated there.
- Default transient artifacts MUST resolve to
  `docsDev/changes/<change-id>/transcripts/sdd/` and be self-ignored.
- No command or skill may introduce an upstream SDD scratch directory.
- Root and plugin versions remain `5.1.1`.
- `t-verification-before-completion`, `t-archive`, vendor content, and archive
  state rules remain unchanged.

### Task 1: Add deterministic SDD handoff scripts

**Interfaces:**
- Consumes: an internal `docsDev/changes/<change-id>/plan.md`, a positive task
  number, and an ancestor commit range.
- Produces: the exact CLIs `sdd-workspace PLAN_FILE`, `task-brief PLAN_FILE
  TASK_NUMBER [OUTFILE]`, and `review-package PLAN_FILE BASE HEAD [OUTFILE]`.

- [x] Add a failing contract test covering paths, exact arity, invalid task and
  revision input, legacy constraint fallback, self-ignore, and multi-commit
  diffs.
- [x] Implement the three scripts with quoted paths, executable modes, atomic
  file replacement, and fail-closed validation.
- [x] Verify the focused scripts-only test passes.

### Task 2: Replace two task reviewers with one combined gate

**Interfaces:**
- Consumes: task brief, implementer report, BASE/HEAD, review package, and
  binding Global Constraints.
- Produces: separate Spec Compliance and Task Quality verdicts from one
  read-only reviewer dispatch.

- [x] Delete the old spec and quality prompt pair.
- [x] Add the combined task reviewer prompt and file-based implementer report
  contract with RED/GREEN evidence.
- [x] Update `t-requesting-code-review` to use harness-neutral reviewer wording
  and a read-only checkout.

### Task 3: Upgrade SDD orchestration and compatibility

**Interfaces:**
- Consumes: a preflighted internal plan, harness subagent capabilities, and the
  durable progress ledger.
- Produces: one implementer and one combined reviewer per unfinished task,
  recovery-safe bookkeeping, and one final whole-branch review/fix wave.

- [x] Add plan conflict preflight and human adjudication for plan-mandated
  findings.
- [x] Add capability-aware model selection with `harness-controlled` fallback.
- [x] Add legacy Global Constraints/Interfaces handling, Critical/Important
  repair loops, Minor ledger roll-up, and no-repeat resume behavior.

### Task 4: Update and run integration harnesses

**Interfaces:**
- Consumes: the installed plugin skills/scripts and disposable Claude Code
  repositories.
- Produces: deterministic targeted evidence plus Claude integration and
  `t-smoke` results without treating infrastructure failures as functional
  passes.

- [x] Update the Claude unit/integration prompts and `t-smoke` plan to internal
  docsDev paths and the combined-review topology.
- [x] Run targeted tests, Claude SDD integration, stage-one, installer, build,
  pack dry-run, shell syntax, and whitespace verification.
- [x] Run the committed `t-smoke` harness and append its infrastructure result;
  the model service returned 502 before the first assistant turn, so this run
  carries no functional pass/fail verdict.
- [x] Record exact deterministic and live integration evidence and create the
  focused implementation commit.

## TDD Evidence

- RED: `bash tests/claude-code/test-sdd-workspace.sh` exited 1 because
  `skills/t-subagent-driven-development/scripts/sdd-workspace` did not exist.
- Scripts GREEN: `SDD_SCRIPTS_ONLY=1 bash
  tests/claude-code/test-sdd-workspace.sh` passed.
- Full focused GREEN: `bash tests/claude-code/test-sdd-workspace.sh` passed.
- Symlink RED: the focused test exited 1 because the first implementation
  followed a pre-existing `transcripts` symlink.
- Symlink GREEN: `transcripts`, `sdd`, and `.gitignore` symlink cases are
  rejected before any external write and the full focused test passes.
- Review GREEN: `.gitignore` uses same-directory atomic replacement and
  preserves an existing file when staging fails; legacy spec symlinks are
  rejected; reviewers cannot create worktrees; tool-call analysis proves one
  implementer and combined reviewer per clean task plus one final reviewer.
- Claude integration run 3 completed both tasks, both combined reviews, and
  final whole-branch review with 6/6 tests. Its only failing assertion was the
  obsolete requirement for a `TodoWrite` call despite a valid durable ledger;
  corrected offline re-analysis passes every functional assertion.
- Claude integration run 4 loaded the exact t skill and completed Task 1, then
  was manually stopped after a repeated service-side stall before Task 2
  dispatch. It did not expose a functional regression.
- Post-commit integrity review added current-worktree/plan-root equality,
  heading-level task boundaries, and ordered tool-call topology. Focused RED
  fixtures cover a foreign repository plan, plan-level Validation after the
  last task, and final/reviewer/implementer reverse order.
- Final sequential-gate RED proved the analyzer accepted Implement Task 1 →
  Implement Task 2 → Review Task 1. GREEN now requires every Task N review
  gate to precede Task N+1 implementation.

## Non-Goals

- No version bump, publish, push, archive, upstream PR, vendor change, or
  unrelated skill rewrite.

## Validation

- `bash tests/claude-code/test-sdd-workspace.sh`
- `bash tests/claude-code/test-subagent-driven-development-integration-prompt.test.sh`
- Claude SDD targeted/integration tests
- `tests/subagent-driven-dev/run-test.sh t-smoke --plugin-dir /Users/lihuajun/WorkProject/superpowers --timeout 900`
- `bash tools/t-stage1-check.sh`
- `npm run test:npm-installer`
- `bash -n` for modified and added shell scripts
- `git diff --check`

## Risks

- Live Claude routing and tool names can vary by harness version; deterministic
  contract tests remain the source of functional truth and live failures must
  be classified with evidence.
- The ignored ledger can be removed by destructive clean operations; recovery
  then falls back conservatively to git history and report files.
- The committed `t-smoke` attempt reached SessionStart/init but received a 502
  API retry and never produced an assistant turn; it is recorded as an
  infrastructure failure, not a workflow pass.
