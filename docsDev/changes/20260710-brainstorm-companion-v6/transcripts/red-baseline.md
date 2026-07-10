# RED Baseline

- Time: `2026-07-10T05:25:39Z`
- Runtime under test: pre-port `skills/t-brainstorming` based on upstream v5.1.0
- Test dependency: `ws ^8.21.0`

## Full package entrypoint

Command:

```bash
npm --prefix tests/brainstorm-server test
```

Exit: `1`

Key output:

```text
--- Frame Size Boundaries ---
PASS 31
FAIL 1: rejects oversized 64-bit frames before payload allocation
Cannot convert undefined to a BigInt
```

The package entrypoint stops at the first failing suite by design, so the focused cases below were also run independently to prove each missing behavior.

## Focused security and lifecycle RED

| Command | Exit | Key expected failure |
|---|---:|---|
| `node tests/brainstorm-server/helper.test.js` | 1 | Browser helper accesses `window` during pure-helper loading; reconnect helpers and state machine are absent. |
| `node tests/brainstorm-server/browser-launcher.test.js` | 1 | `browserLauncherForPlatform is not a function` for Windows, WSL, and headless Linux. |
| `node tests/brainstorm-server/auth.test.js` | 1 | 4 passed, 16 failed: startup URL lacks key; unauthenticated HTTP returns 200; wrong-key/file routes and cross-origin cookie WebSocket are not rejected. |
| `node tests/brainstorm-server/branding.test.js` | 1 | 1 passed, 3 failed: repository, waiting, and Codex-only pages do not show `T-Superpowers Brainstorming` with the resolved version. |
| `node tests/brainstorm-server/skill-contract.test.js` | 1 | 1 passed, 3 failed: offer happens by anticipation instead of at the first visual question; no `--open`; no authenticated guide contract. |
| `node tests/brainstorm-server/server.test.js` | 1 | New dotfile/path tests fail and `/files/` crashes the old server with a socket hangup, proving the confinement regression before later cases can run. |
| `node tests/brainstorm-server/lifecycle.test.js` | 1 | 3 passed, 10 failed: no 4-hour/configurable idle timeout, key/port persistence, safe fallback, IPv6 URL bracket, or one-time open behavior. |
| `bash tests/brainstorm-server/start-server.test.sh` | 1 | 1 passed, 3 failed: Windows-like shell keeps owner PID and no safe server instance ID is persisted/passed. |
| `bash tests/brainstorm-server/stop-server.test.sh` | 1 | 2 passed, 5 failed: unrelated or mismatched processes are signalled and persistent stopped metadata is absent. |

## RED validity

- The initially selected upstream fixed port `3334` was already occupied by an unrelated local process, so the server test was changed back to the fork's randomized high-port convention and rerun.
- The rerun reached the server and failed on missing path confinement, not on setup, import, dependency, or port errors.
- No upstream production script was copied before these failures were observed.
