---
change_id: 20260710-brainstorm-companion-v6
created_at: 2026-07-10T05:21:03Z
updated_at: 2026-07-10T05:47:35Z
owner: lihuajun
---

# Brainstorming Visual Companion v6 Implementation Plan

## Change History

- 2026-07-10: Initial implementation plan for the approved v6 companion sync.
- 2026-07-10: Added pre-commit review fixes for JIT ordering, temp/docsDev runtime paths, no-shell browser opening, short-outage recovery, traversal rejection, and platform-temp cleanup.

## Goal

Selectively port upstream v6.1.1 visual-companion security and lifecycle improvements into `skills/t-brainstorming` while retaining local triggering, paths, version, and text-only branding.

## Interfaces

- `server.cjs`: keeps the zero-dependency HTTP/WebSocket server and exported protocol helpers; adds session auth, safe browser launcher selection, bounded frame decoding, persisted port/token reuse, and lifecycle controls.
- `start-server.sh --project-dir DIR [--open] [--host HOST] [--foreground]`: keeps the local t-path invocation, creates project-scoped state, passes a shell-safe server instance ID, and opens the authenticated URL only when requested.
- `stop-server.sh SESSION_DIR`: reports structured stop status and signals a PID only when command line and instance ID match persisted state.
- `helper.js`: derives its WebSocket key from sessionStorage, reconnects with 500ms-to-30s backoff, and exposes connected/reconnecting/disconnected UI states.
- `t-brainstorming/SKILL.md`: keeps the complex-only trigger and `docsDev/changes/<change-id>/spec.md` output; adds one-time JIT visual opt-in and `--open` behavior.

## Implementation Steps

1. Add this approved spec/plan and an evidence directory without state-machine metadata.
2. Copy and adapt the upstream v6.1.1 brainstorm tests to the `t-brainstorming` path, retain existing team cases, replace Prime Radiant branding assertions with local text/no-network assertions, and update test dependencies.
3. Run the full test suite against the v5 runtime and record the expected RED failures with timestamp, command, exit code, and key output.
4. Port the upstream v6.1.1 scripts into `skills/t-brainstorming`, preserving executable modes and adapting only namespace, artifact paths, root/Codex version lookup, and local text-only branding.
5. Update `SKILL.md` and companion guidance for a one-time JIT visual question, automatic `--open` after acceptance, and no repeat after refusal.
6. Run focused GREEN, simulated Windows lifecycle cases, shell syntax checks, stage-one regression, installer tests, build, pack dry-run, and whitespace validation; record fresh evidence.
7. Review the scoped diff, commit only this stage as `feat: harden brainstorming companion for v6`, and do not push, publish, archive, or bump versions.

## TDD Evidence

- Initial RED: protocol 31 passed / 1 failed; auth 4/20 passed; branding 1/4 passed; skill contract 1/4 passed; lifecycle 3/13 passed; start 1/4 passed; stop 2/7 passed. See `transcripts/red-baseline.md`.
- Review RED: helper short reconnect 15/16, browser launcher 3/5, server 33/34, lifecycle 11/13, start 3/4, stop 6/7, and skill contract 5/6. See `transcripts/review-red-green.md`.
- Final standard GREEN: 141 passed, 0 failed through the package test entrypoint.
- Full Windows/MSYS lifecycle simulation: 13 passed, 0 failed, 0 skipped, including both 75-second watchdog windows.

## Non-Goals

- Do not change other skills, vendor source, distribution versions, archive behavior, or upstream contribution files.
- Do not add remote images, Prime Radiant branding, telemetry, or network pixels.
- Migrate script-managed cache directories to `.t-superpowers/brainstorm/`, but keep the guide's default `--project-dir` beneath `$TMPDIR/t-superpowers-brainstorm/<stable-project-id>` so repository roots stay clean. Only explicit persistent visual artifacts use `docsDev/changes/<change-id>/transcripts/visual-companion`.

## Validation

- `npm --prefix tests/brainstorm-server test`
- Windows lifecycle simulation and targeted shell tests included by the test package
- `bash -n skills/t-brainstorming/scripts/*.sh`
- `bash tools/t-stage1-check.sh`
- `npm run test:npm-installer`
- `npm run build`
- `npm run pack:dry-run`
- `git diff --check`

## Risks

- A full Windows host is not available locally, so simulated shell branches complement but do not replace real Windows validation.
- Port reuse and persistent cookie behavior depend on filesystem permissions and concurrent local processes; tests must exercise fallback and collision behavior.
- Upstream branding code must be removed without weakening adjacent security headers or lifecycle logic.
