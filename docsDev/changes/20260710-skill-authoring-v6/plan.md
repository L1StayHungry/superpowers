---
change_id: 20260710-skill-authoring-v6
created_at: 2026-07-10T08:25:00Z
updated_at: 2026-07-10T08:50:00Z
owner: lihuajun
---

# Skill Authoring v6 Implementation Plan

**Goal:** Adopt upstream v6.1.1 authoring and harness-neutrality improvements one skill at a time without widening internal triggers or changing protected workflows.

**Architecture:** Give each skill its own deterministic contract, observe the pre-change failure, make the smallest prompt edit, run all accumulated contracts plus the stage-one gate, and commit before touching the next skill. Keep live wording evidence under the archive-stable `docsDev/skill-tests/` path.

## Global Constraints

- The change identifier is `20260710-skill-authoring-v6`.
- The repository and plugin versions remain `5.1.1`.
- Supported harnesses are Claude Code, Cursor, and Codex.
- Do not modify `vendor/superpowers/`, `skills/t-verification-before-completion/`, or `skills/t-archive/`.
- Do not remove Cursor `agents/` or `commands/` placeholder directories.
- Reusable tests and behavior evidence must not depend on `docsDev/changes/20260710-skill-authoring-v6/`.
- Every skill completes RED, GREEN, regression, and commit before the next skill is edited.

### Task 1: Strengthen `t-writing-skills`

**Interfaces:**
- Consumes: pre-change `skills/t-writing-skills/SKILL.md`; upstream v6.1.1 authoring guidance; pressure scenario in `docsDev/skill-tests/20260710-writing-skills-form-microtest/prompt.md`.
- Produces: focused command `bash tests/skill-authoring/test-writing-skills-contract.sh`; stable control/guided raw evidence and rubric; commit `6f400d7`.

- [x] Observe the contract fail on missing SDO.
- [x] Add failure-form matching, controlled micro-test requirements, portable links, and generic discovery/todo/instruction wording.
- [x] Run five final control calls and two five-call guided variants in fresh contexts; preserve pilots and failed v1 output separately.
- [x] Require five final guided v2 runs to score 4/4 before commit.

### Task 2: Neutralize parallel dispatch

**Interfaces:**
- Consumes: current `t-dispatching-parallel-agents` same-state and independence boundaries.
- Produces: same-response generic subagent dispatch contract and commit `7d1ea3d`.

- [x] Replace `Task(...)` examples with generic subagent dispatches issued together.
- [x] Preserve independence checks and full-suite integration verification.

### Task 3: Neutralize plan execution

**Interfaces:**
- Consumes: current plan review, task tracking, verification, and finishing handoff.
- Produces: capability-based subagent selection, generic todo-list tracking, and commit `7c1719e`.

- [x] Avoid naming one harness or an unavailable dispatch/todo tool.
- [x] Preserve branch safety and internal finishing references.

### Task 4: Neutralize review reception

**Interfaces:**
- Consumes: review findings and current forge capabilities.
- Produces: generic instruction-file wording, direct pushback, forge-neutral thread replies, and commit `7e1b4af`.

- [x] Remove the harness-specific instruction filename and coded pushback signal.
- [x] Preserve technical verification, per-finding tests, and thread-local replies.

### Task 5: Correct debugging and TDD references

**Interfaces:**
- Consumes: narrow local trigger descriptions and existing engineering discipline.
- Produces: delimiter-safe `Ultra-think`, portable TDD reference, commits `4769e55` and `cdc686a`.

- [x] Fix the systematic-debugging signal without adopting the broad upstream description.
- [x] Replace force-loading syntax with a portable relative Markdown link without adopting the broad upstream TDD description.

### Task 6: Update onboarding and run final regression

**Interfaces:**
- Consumes: completed selective-sync behavior, supported internal installer commands, all focused contract entrypoints.
- Produces: corrected onboarding/installer/Unreleased documentation; full verification transcript; final documentation commit.

- [x] Document selected v6.1.1 behavior and supported Claude Code/Cursor/Codex installation paths.
- [x] Run all focused tests, stage-one, installer, build, pack, shell syntax, protected-path, and whitespace checks.
- [x] Record fresh output and commit documentation.
