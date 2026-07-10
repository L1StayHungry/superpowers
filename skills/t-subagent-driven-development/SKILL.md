---
name: t-subagent-driven-development
description: "Use ONLY when executing a written implementation plan with independent tasks that benefit from parallel agents. Do NOT use for simple edits, Q&A, or pure code reading."
---

# Subagent-Driven Development

Execute a written plan with a fresh implementer for each task, one task
reviewer that returns separate spec-compliance and code-quality verdicts, and
a high-capability final whole-branch review.

**Core principle:** file-based handoffs + one combined task gate + durable
progress + broad final review.

**Continuous execution:** do not ask whether to continue between tasks. Stop
only for a blocker, a real ambiguity, a plan conflict requiring human
judgment, or completion of the whole plan.

## Required Workflow Skills

- Use `t-superpowers:t-using-git-worktrees` before implementation unless the
  user explicitly chose the current worktree.
- The plan should come from `t-superpowers:t-writing-plans`.
- Implementers use `t-superpowers:t-test-driven-development` for behavior
  changes and bug fixes.
- The final reviewer uses `t-superpowers:t-requesting-code-review`.
- Finish with `t-superpowers:t-finishing-a-development-branch` when branch
  integration is in scope.

## Process Overview

1. Associate the plan with an internal change and run pre-flight review.
2. Resolve the SDD workspace and resume from its progress ledger.
3. For each unfinished task: make a brief, dispatch one implementer, build a
   review package, dispatch one task reviewer, and close the review loop.
4. Run one broad final whole-branch review.
5. Send all final-review findings through one fix subagent, verify once, and
   finish the branch.

Never dispatch multiple implementers concurrently in one working tree.

## Plan Association and Compatibility

The active source of truth must be:

```text
docsDev/changes/<change-id>/plan.md
```

An external plan must first be associated or copied there. Do not execute it
in place and do not create a parallel upstream-style documentation path. Preserve the
source plan's content and record where it came from in the internal plan or
spec before Task 1.

Resolve the ignored handoff directory:

```bash
scripts/sdd-workspace PLAN_FILE
```

Resolve `scripts/` relative to the directory containing this `SKILL.md`, not
the target repository's current directory. In a plugin harness, use its
bundled plugin-root variable or the installed skill path to form the absolute
script path. Do not copy the scripts into the target project.

The command accepts exactly one internal `PLAN_FILE` and returns:

```text
docsDev/changes/<change-id>/transcripts/sdd/
```

The directory self-ignores its briefs, reports, review packages, and ledger so
runtime transcripts cannot pollute a commit. `sdd-workspace` also atomically
ensures `/docsDev/changes/*/transcripts/sdd/` in the repository's shared Git
`info/exclude`. This Git-local side effect lets isolated linked worktrees
inherit the scratch exclusion; it does not edit a tracked `.gitignore` or a
different repository.

### Legacy `docsDev` plans

- If `## Global Constraints` is absent, `task-brief` copies that section from
  the same-directory `spec.md`. Treat those exact values as binding.
- If a task lacks `Interfaces`, inspect the task and surrounding plan before
  Task 1. Ask the human one batched question only when the missing contract
  creates real ambiguity about a signature, type, data shape, or ownership
  boundary. If the interface is already unambiguous, proceed and note the
  resolved contract in the ledger; missing formatting alone is not a blocker.
- Do not add status-machine fields to legacy plan frontmatter.

## Pre-Flight Plan Review

Before dispatching Task 1, scan the full plan once for:

- contradictions between tasks;
- conflicts with Global Constraints or the approved spec;
- a plan-mandated implementation that the review rubric would consider a
  defect, such as an assertion-free test or verbatim duplicated logic;
- unclear task ordering, interfaces, or ownership.

If clean, proceed silently. If conflicts exist, present all of them to the
human partner as one batched question, quoting both conflicting passages and
asking which governs. Do not let an implementer or reviewer silently choose.

## Model Capability Detection

Before the first dispatch, inspect the current harness's subagent interface:

- If it supports an explicit model field, every dispatch MUST specify a model.
  Use an economical capable model for mechanical implementation, a standard
  model for integration work, and a high-capability model for subtle review.
- If the harness does not expose model selection (for example a Codex surface
  where model choice is harness-controlled), omit the unsupported argument,
  record `reviewer_model=harness-controlled` in the ledger, and continue. Lack
  of a model parameter never blocks execution.
- The final whole-branch reviewer always gets the most capable available
  reviewer model when explicit selection exists.

Do not invent model names or pass unsupported fields.

## File Handoffs

Large requirements, reports, evidence, and diffs live in files instead of the
controller conversation.

### Task brief

Before dispatching Task N:

```bash
scripts/task-brief PLAN_FILE TASK_NUMBER [OUTFILE]
```

The default file is `task-N-brief.md` in the SDD workspace. It contains the
full task, its Interfaces marker, and Global Constraints from the plan or
legacy spec fallback. Give the implementer this file as its requirements
source; never paste the whole plan or accumulated task history.

### Implementer report and TDD evidence

Use `task-N-report.md` beside the brief. The implementer writes:

- implementation and files changed;
- commits created;
- exact test commands and results;
- RED command, expected failing output, and reason;
- GREEN command and passing output;
- self-review and concerns.

Fixers append their changes and focused test evidence to the same report.
The implementer returns only status, commits, a one-line test summary,
concerns, and the report path.

### Review package

Record BASE before dispatching the implementer. After all task commits exist:

```bash
scripts/review-package PLAN_FILE BASE HEAD [OUTFILE]
```

Never substitute `HEAD~1`: a task may contain multiple commits. The package
contains the complete commit list, diff stat, and net diff and fails closed
for invalid, empty, or reversed ranges.

### Controller context budget

For completed work retain only:

```text
Task status | commit range | one-line test result | review verdict
```

Paths point to the full brief, report, evidence, and review package. Do not
paste their bodies back into the conversation.

## Durable Progress Ledger

At start, read `progress.md` in the directory returned by `sdd-workspace`.
Trust the ledger and `git log` after compaction. Tasks marked complete are
complete: do not re-dispatch a completed task or repeat its review.

After a clean task review, append a durable line such as:

```text
Task 2: complete | commits abc1234..def5678 | tests 18/18 passing | review clean | reviewer_model=harness-controlled
```

Also record:

- in-progress/base information before a dispatch;
- resolved legacy Interfaces decisions;
- Minor findings for final-review triage;
- blocked state and the evidence needed to resume.

The ledger is ignored scratch, not acceptance evidence and not a plan status
machine. If destructive cleanup removes it, reconstruct conservatively from
git history and existing report files rather than re-running known work.

## Per-Task Dispatch

### 1. Dispatch the implementer

Use [implementer-prompt.md](implementer-prompt.md). Provide only:

- one sentence of scene-setting context;
- the task brief path;
- interfaces or decisions from earlier tasks that the brief cannot contain;
- the report path and worktree;
- the supported explicit model, or no model field on a harness-controlled
  surface.

The implementer follows TDD, commits, self-reviews, writes its report, and
returns the compact status contract. Resolve `NEEDS_CONTEXT`, `BLOCKED`, and
`DONE_WITH_CONCERNS` before review.

### 2. Dispatch one combined task review

Generate a fresh review package, then dispatch exactly one task reviewer from
[task-reviewer-prompt.md](task-reviewer-prompt.md). That reviewer reads the
diff once and independently returns spec compliance and code quality as two
separate verdicts:

- a specification-compliance verdict;
- a code-quality verdict with Critical, Important, and Minor findings.

The reviewer uses a read-only checkout and must not edit, commit, switch
branches, move HEAD, or mutate the index. A missing verdict means the gate did
not run and must be repeated.

### 3. Resolve findings

- Resolve every `Cannot verify from diff` item using controller-owned plan and
  cross-task context.
- A `plan-mandated` finding or any finding that conflicts with plan text
  requires human partner adjudication. Present finding and plan passage
  together; do not dismiss it or dispatch a contradictory fix autonomously.
- Dispatch a fixer for all open Critical and Important findings. Require the
  covering test file, command, output, and updated report. Generate a fresh
  package and repeat the combined review until both verdicts pass.
- Append Minor findings to the ledger. Do not silently discard them and do not
  block the next task unless they expose a material risk.

Only then mark the task complete and move to the next unfinished ledger item.

## Final Whole-Branch Review

After all tasks are ledger-complete:

1. Determine the branch merge base/fork point.
2. Run `scripts/review-package PLAN_FILE MERGE_BASE HEAD`.
3. Dispatch a high-capability reviewer with subagent description exactly `Final whole-branch review`, using
   `t-superpowers:t-requesting-code-review`, the full plan, final package, and
   accumulated Minor findings. This is broader than a task review and checks
   cross-task integration, architecture, security, and omitted behavior.
4. If findings remain, dispatch ONE fix subagent with the complete findings
   list. Do not create one fixer per finding. Require focused tests plus the
   full required verification once after the combined fix wave.
5. Generate one fresh package and have the final reviewer verify the complete
   fix wave. Do not claim completion while Critical or Important findings are
   open.

## Red Flags

Never:

- execute an unassociated external plan;
- write SDD artifacts outside the active `docsDev` change;
- skip pre-flight, a task verdict, or final whole-branch review;
- dispatch separate spec and quality reviewers for one task;
- let a reviewer mutate the checkout;
- use `HEAD~1` for a multi-commit task;
- ignore plan-mandated findings or choose for the human;
- proceed with Critical or Important findings open;
- lose Minor findings between tasks;
- re-dispatch ledger-complete work after resume;
- make an unavailable explicit model parameter a blocker;
- let implementer self-review replace independent review;
- start on main/master without explicit user consent.

## Alternative

Use `t-superpowers:t-executing-plans` when the written plan must be executed in
a separate session rather than coordinated here.
