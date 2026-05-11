# Stage 1 Smoke Harness Design

## Context

Stage 1 migrated the fork into the `t-superpowers` namespace. The static migration gates now pass, but the original completion criteria still treat two long subagent fixtures, `svelte-todo` and `go-fractals`, as hard blockers. Both fixtures have recently timed out after 3600 seconds even though the current failures exercise long-running model orchestration more than the core Stage 1 requirement: proving that the renamed plugin loads, dispatches, avoids known tool-schema loops, and merges subagent work back to the main test project.

This design formally revises the Stage 1 validation shape. The long fixtures remain useful pressure tests and must keep their logs, exit codes, and risk notes, but Stage 1 completion should depend on a short deterministic smoke harness plus the existing static, targeted, and harness-acceptance evidence.

## Goals

- Replace the two long subagent fixtures as Stage 1 hard blockers with one focused subagent smoke fixture.
- Keep `svelte-todo` and `go-fractals` as non-blocking pressure fixtures with explicit risk records.
- Preserve the Stage 1 guarantee that `t-superpowers` is independently named, loadable, and behavior-equivalent at the bootstrap boundary.
- Keep Type A, Type B, and Type C harness transcripts as required Stage 1 evidence. Type A/B cover Claude Code CLI and Codex CLI; Type C's Stage 1 hard gate is Claude Code CLI co-installed, while Codex CLI co-installed is follow-up evidence.
- Keep Codex hook selection blocked until Type A official-only Codex evidence decides whether to retain `hooks/hooks-codex.json` or switch to `hooks: []`.

## Revised Completion Criteria

Stage 1 can be marked complete only when all of these are true:

1. `bash tools/t-stage1-check.sh` exits 0.
2. The six protected files have no diff:
   `package.json`, `gemini-extension.json`, `.opencode/plugins/superpowers.js`, `CLAUDE.md`, `AGENTS.md`, and `GEMINI.md`.
3. Existing deterministic tests pass: brainstorm server, Claude Code targeted/integration tests, and local regression tests for timeout, plugin-dir, prompt, and preflight behavior.
4. The new subagent smoke fixture exits 0.
5. Type A official-only, Type B fork-only, and Type C co-installed harness transcripts are recorded. Codex CLI co-installed is recorded as follow-up if the current installation model prevents a real co-install.
6. Codex hook configuration is finalized from Type A evidence.

`svelte-todo` and `go-fractals` no longer block Stage 1 completion. Their latest results remain recorded as pressure-test risk evidence.

## Smoke Fixture

Add a short fixture at `tests/subagent-driven-dev/t-smoke/`.

The fixture should be small enough to complete in 5 to 10 minutes and should exercise only the migration-critical behavior:

- The runner invokes `t-superpowers:t-subagent-driven-development`.
- The Claude run uses the existing `Read` restriction.
- Subagent work is committed and merged or cherry-picked back into the main generated project.
- The generated project has implementation files, tests, and at least one commit.
- The generated project test command exits 0.

The fixture should create a minimal Node project with a small tested function:

- `package.json` with a local `npm test` script.
- `src/math.js` exporting `add(a, b)`.
- `test/math.test.js` or equivalent, verifying `add`.
- A final state where the main project has the source file, test file, passing tests, and a committed change.

The expected command is:

```bash
tests/subagent-driven-dev/run-test.sh t-smoke --plugin-dir /Users/lihuajun/WorkProject/superpowers --timeout 900
```

The 900 second timeout is part of the smoke contract. A timeout is a failed smoke run, not a soft warning.

## Smoke Assertions

The smoke verification should record or assert:

- Log contains `t-superpowers:t-subagent-driven-development`.
- Log does not contain `Invalid pages parameter`, `"name":"Read"`, or `Read(`.
- Main generated project contains the implementation and test files, not only `.claude/worktrees/`.
- Main generated project has at least one commit after initial scaffold.
- Main generated project test command exits 0.
- Runner propagates failures and timeouts as real non-zero exit codes.

The smoke fixture should avoid broad product-building tasks. It is a migration and harness smoke test, not an application-quality benchmark.

## Pressure Fixtures

`tests/subagent-driven-dev/svelte-todo` and `tests/subagent-driven-dev/go-fractals` remain in the repository as pressure fixtures.

Their role is to detect long-run stability issues:

- subagent task volume and orchestration latency,
- final review runtime,
- worktree merge-back reliability under larger plans,
- recurring tool schema loops.

They should not be marked as passed unless they actually exit 0. Their latest timeout results must remain in the Stage 1 acceptance record until a later run supersedes them.

## Documentation Updates

Update `docs/二开规划/阶段一执行plan.md`:

- Move `svelte-todo` and `go-fractals` from hard Stage 1 targeted tests to pressure fixtures.
- Add `t-smoke` as the required subagent-driven-dev Stage 1 harness.
- State that `t-smoke` exit 0 is required before Stage 1 completion.

Update `docs/二开规划/二次开发规划.md`:

- Revise the Stage 1 hard metrics to include the smoke harness instead of requiring both long fixtures to complete.
- Preserve the Type A, Type B, and Type C transcript categories. Type A/B remain Claude Code CLI + Codex CLI; Type C requires Claude Code CLI co-installed and records Codex CLI co-installed as follow-up evidence.
- Preserve Codex hook decision language.

Update `docs/二开规划/阶段一验收记录.md`:

- Add a section titled "验收标准修订".
- Record that long fixtures are pressure tests because they validate long-running orchestration, not the core namespace migration.
- Move `svelte-todo` and `go-fractals` from hard blockers to non-blocking pressure results once `t-smoke` passes.
- Keep Stage 1 blocked until `t-smoke`, Type A, Type B, Type C, and Codex hook decision are complete within the revised scope. Codex CLI co-installed does not block Stage 1 after the 2026-05-11 revision.

## Non-Goals

- Do not claim `svelte-todo` or `go-fractals` passed unless their runner exits 0.
- Do not fabricate Claude Code CLI or Codex CLI transcripts.
- Do not start Stage 2 before the revised Stage 1 criteria pass.
- Do not open a PR as part of this change.

## Risks

The revised criteria reduce Stage 1 latency but narrow what the hard gate proves. This is acceptable because Stage 1 is about namespace migration and harness loading, not proving that long multi-agent app builds are stable. The risk is controlled by preserving the pressure fixtures and their recorded failures as explicit follow-up work.

The Codex hook decision remains independent of the smoke fixture. It still requires Type A official-only evidence because the fork must remain single-install behavior-equivalent with the official plugin.
