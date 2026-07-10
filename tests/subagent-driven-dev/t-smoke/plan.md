---
change_id: t-smoke
created_at: 2026-07-10T00:00:00Z
updated_at: 2026-07-10T00:00:00Z
owner: test
---

# T-Smoke Node Math Implementation Plan

Execute this plan using the `t-superpowers:t-subagent-driven-development` skill.

## Context

This is a disposable smoke-test repository. Keep the implementation intentionally small. The goal is to verify harness behavior, not to build a product.

## Global Constraints

- Use CommonJS and Node.js built-in `node:test` only.
- Keep the exported function name exactly `add`.

## Tasks

### Task 1: Node Project Skeleton

**Interfaces:**
- Consumes: the empty disposable repository created by the harness.
- Produces: a CommonJS package with `npm test` backed by `node --test`.

Create the minimal Node project structure.

**Do:**
- Create `package.json` with:
  - `"type": "commonjs"`
  - `"scripts": { "test": "node --test" }`
- Create empty `src/` and `test/` directories.

**Verify:**
- `npm test` runs successfully with no tests.
- Commit the skeleton.

---

### Task 2: Add Tested Math Function

**Interfaces:**
- Consumes: the Task 1 CommonJS package and `node --test` command.
- Produces: `add(a: number, b: number): number` from `src/math.js`.

Add one tested function.

**Do:**
- Create `src/math.js`.
- Export `add(a, b)` using CommonJS.
- Create `test/math.test.js`.
- Test that `add(2, 3)` returns `5`.
- Test that `add(-2, 2)` returns `0`.

**Verify:**
- `npm test` passes.
- Commit the implementation and tests.

---

### Task 3: Final Harness Verification

**Interfaces:**
- Consumes: the committed Task 1 and Task 2 repository state.
- Produces: a clean worktree and passing final verification evidence.

Confirm the main repository contains the completed work.

**Do:**
- Check `git status --short`.
- Check `git log --oneline -3`.
- Confirm `src/math.js`, `test/math.test.js`, and `package.json` are present in the current repository.

**Verify:**
- `npm test` passes.
- Work is committed.
- Finished work is not left only under `.claude/worktrees/`.
