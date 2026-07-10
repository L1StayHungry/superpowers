---
change_id: 20260710-sdd-v6
created_at: 2026-07-10T00:00:00Z
updated_at: 2026-07-10T09:05:00Z
owner: lihuajun
---

# SDD v6 Selective Sync Specification

## Background

The internal `t-subagent-driven-development` workflow still used the v5 pair
of per-task reviewers and conversation-heavy handoffs. Upstream v6.1.1 adds a
combined task review, durable file handoffs, progress recovery, and a broad
final review, but its paths, namespaces, and unconditional model argument do
not match the internal fork.

## Goals

- Use one reviewer per task while preserving separate specification and code
  quality verdicts.
- Keep a high-capability final whole-branch review after all task gates pass.
- Make task briefs, implementer reports, RED/GREEN evidence, review packages,
  and recovery state durable without expanding controller context.
- Keep all runtime artifacts under the active
  `docsDev/changes/<change-id>/transcripts/sdd/` directory.
- Support Claude Code, Cursor, and Codex model-selection differences without
  weakening review quality or blocking harness-controlled surfaces.
- Preserve local `t-*` namespaces, complex-task trigger boundaries, and
  explicit human authority for plan conflicts.

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

## Requirements

### Combined task review

Each completed task gets exactly one reviewer dispatch. The reviewer reads the
task's complete multi-commit diff once and returns both a spec-compliance
verdict and a code-quality verdict. Review is read-only.

Critical and Important findings enter a fix-and-re-review loop. Minor findings
are retained in the progress ledger for final triage. A plan-mandated finding
is a human decision and may not be dismissed or auto-fixed against the plan.

### Final review

After every task is ledger-complete, a high-capability reviewer examines the
entire branch from its merge base. All findings from that review go to one fix
subagent as a single wave, followed by fresh verification and review.

### File handoffs and resume

The controller creates a task brief, report path, and review package for each
task. Implementers write full reports and RED/GREEN evidence to files and
return only status, commits, a one-line test result, and concerns. The ledger
records completed tasks and must prevent duplicate dispatch after compaction
or resume.

### Plan compatibility

Legacy internal plans without Global Constraints fall back to the same-change
spec. Missing Interfaces formatting triggers one pre-Task-1 question only
when a signature, type, data shape, or ownership boundary is genuinely
ambiguous.

### Harness capability

When the harness exposes a model field, dispatches specify an appropriate
model and final review uses the most capable available model. When it does not,
the ledger records `harness-controlled` and execution continues without an
unsupported parameter.

## Non-Goals

- Do not add new distribution channels, publish, bump versions, push, or
  archive this change.
- Do not add a state machine, unified validator, transactional archive layer,
  or automatic acceptance.
- Do not remove pressure fixtures that are intentionally non-blocking.

## Archive Patch

### sdd

Target: docsDev/specs/sdd/spec.md

Action: create

##### Requirement: Internal SDD uses one combined task review gate

The internal SDD workflow uses one combined read-only task reviewer, durable
docsDev file handoffs and ledger recovery, capability-aware model selection,
and a final whole-branch review.

###### Scenario: Resume a multi-task internal plan after context loss

Given a multi-task internal plan resumes after context loss, the controller
skips tasks already marked complete, reviews every remaining task with
separate specification and quality verdicts from one diff read, and finishes
with a whole-branch review.
