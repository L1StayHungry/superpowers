---
change_id: 20260710-v6-adoption-followup
created_at: 2026-07-10T18:38:00+08:00
updated_at: 2026-07-10T18:38:00+08:00
owner: lihuajun
---

# v6.1.1 Adoption Follow-up Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use t-superpowers:t-subagent-driven-development (recommended) or t-superpowers:t-executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close three residual consistency gaps left after the v6.1.1 adoption: restore the SDD controller anti-pre-judge guard, neutralize the persuasion supporting file, and move the document-review test onto the `docsDev/` artifact path.

**Architecture:** Three independent, small edits to fork-owned files. Each is its own reviewable delivery with its own deterministic check (grep or shell syntax). No shared state, no code interfaces between them.

**Tech Stack:** Markdown skills, Bash integration test, deterministic `rg`/`bash -n` checks, Git.

## Global Constraints

- The change identifier is `20260710-v6-adoption-followup`.
- The plan artifact path is `docsDev/changes/20260710-v6-adoption-followup/plan.md`.
- Skill references use the `t-superpowers:t-*` namespace.
- The repository and Codex plugin versions remain `5.1.1`.
- Do not modify `vendor/superpowers/`, `skills/t-verification-before-completion/`, or `skills/t-archive/`.
- The stage regression commands are `bash tools/t-stage1-check.sh`, `npm run test:npm-installer`, and `git diff --check`.
- The deterministic skill-test command is `bash tests/claude-code/run-skill-tests.sh`.

---

### Task 1: Restore the SDD controller anti-pre-judge guard

**Consumes:** N/A — the guard is prose added to an existing skill and reads no new symbol, type, or data contract.
**Produces:** N/A — the guard shapes controller behavior and exposes no callable or data interface to other tasks.

**Files:**
- Modify: `skills/t-subagent-driven-development/SKILL.md`

**Steps:**
- [ ] After `### 2. Dispatch one combined task review`, add a short paragraph forbidding pre-judging: the controller must not write `do not flag`, `don't treat X as a defect`, `at most Minor`, or `the plan chose` into a reviewer dispatch, and must let the reviewer raise the finding for review-loop adjudication.
- [ ] Add one entry to `## Red Flags` such as `pre-judge findings in a reviewer dispatch`.
- [ ] RED: `rg -n "pre-judge|do not flag" skills/t-subagent-driven-development/SKILL.md` returns nothing before the edit.
- [ ] GREEN: the same `rg` returns the new guard lines after the edit.

**Checkpoint:** commit `feat: 恢复 SDD reviewer dispatch 反预判纪律`.

---

### Task 2: Neutralize the persuasion supporting file

**Consumes:** N/A — a wording change with no consumed interface.
**Produces:** N/A — supporting documentation with no callable or data interface.

**Files:**
- Modify: `skills/t-writing-skills/persuasion-principles.md`

**Steps:**
- [ ] Replace `Use tracking: TodoWrite for checklists` with `Use tracking: todos for checklists` (line ~36).
- [ ] Replace `Checklists without TodoWrite tracking` with `Checklists without todo tracking` (line ~83).
- [ ] Replace `Some people find TodoWrite helpful for checklists.` with `Some people find todo tracking helpful for checklists.` (line ~84).
- [ ] RED: `rg -n "TodoWrite" skills/t-writing-skills/persuasion-principles.md` returns matches before the edit.
- [ ] GREEN: the same `rg` returns nothing after the edit.

**Checkpoint:** commit `chore: 中立化 persuasion-principles 待办用语`.

---

### Task 3: Move the document-review test onto docsDev

**Consumes:** N/A — a test path change with no consumed code interface.
**Produces:** N/A — a standalone integration test not wired into `run-skill-tests.sh`.

**Files:**
- Modify: `tests/claude-code/test-document-review-system.sh`

**Steps:**
- [ ] Replace the `mkdir -p docs/superpowers/specs` and the two `docs/superpowers/specs/test-feature-design.md` references with a `docsDev/`-based fixture path (e.g. `docsDev/changes/20260710-v6-adoption-followup-fixture/spec.md` or a generic `docsDev/specs-fixture/` path used only inside the disposable test project).
- [ ] Keep the L81 prompt reference pointing at `skills/t-brainstorming/spec-document-reviewer-prompt.md`; only the reviewed spec path changes.
- [ ] RED: `rg -n "docs/superpowers" tests/claude-code/test-document-review-system.sh` returns matches before the edit.
- [ ] GREEN: the same `rg` returns nothing, and `bash -n tests/claude-code/test-document-review-system.sh` exits 0 after the edit.

**Checkpoint:** commit `test: 将 document-review 测试迁到 docsDev 路径`.

---

### Task 4: Record the follow-up in the changelog

**Consumes:** N/A — documentation edit.
**Produces:** N/A — release note only.

**Files:**
- Modify: `CHANGELOG.md`

**Steps:**
- [ ] Append one bullet under `[Unreleased]` describing the three follow-up fixes; do not change the version number.
- [ ] GREEN: `rg -n "anti-pre-judge|pre-judge|收口|follow-up" CHANGELOG.md` returns the new note.

**Checkpoint:** commit `docs: 记录 v6.1.1 吸收收口补丁`.

---

## Validation

- `bash tools/t-stage1-check.sh`
- `npm run test:npm-installer`
- `bash tests/claude-code/run-skill-tests.sh`
- `bash -n tests/claude-code/test-document-review-system.sh`
- `git diff --check`
- Scoped `rg` confirmations described per task.
