# T-Smoke Node Math Design

## Overview

Build a tiny Node project that proves the subagent-driven-development harness can create implementation files, add tests, commit work, and leave the main generated project in a reviewable state.

## Requirements

- Use only Node built-in modules.
- Create `src/math.js` exporting `add(a, b)`.
- Create `test/math.test.js` using `node:test` and `node:assert/strict`.
- `npm test` must run `node --test` and pass.
- Commit the completed implementation back to the main repository, not only to a `.claude/worktrees/` worktree.

## Acceptance Criteria

- `npm test` exits 0.
- `src/math.js` exists in the main generated project.
- `test/math.test.js` exists in the main generated project.
- The main generated project has a commit containing the implementation.
