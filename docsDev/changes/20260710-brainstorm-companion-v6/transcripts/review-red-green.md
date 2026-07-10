# Review RED/GREEN

- Review completed: `2026-07-10T05:46:25Z`
- Scope: pre-commit pressure review and independent code review of the Stage 2 diff

## Skill pressure review

The first pressure review found three prompt contradictions and one cache namespace issue:

- JIT visual opt-in appeared as checklist item 2 even though it might not occur until later.
- The complex-only frontmatter conflicted with old “Every project” wording.
- Planning references used unprefixed `writing-plans`.
- Runtime guidance still named `.superpowers/brainstorm/`.

Static contract assertions were added first. `node tests/brainstorm-server/skill-contract.test.js` exited `1` with 2 passed / 3 failed for ordering, trigger wording, and planning routing. After the first fixes it passed 5/5. The cache-path assertion then failed 5/6 until scripts and guidance adopted the reviewed temp/`.t-superpowers`/`docsDev` policy; final focused result was 6/6.

## Code-review RED

Focused commands and expected failures after independent review:

| Command | Exit | RED result |
|---|---:|---|
| `node tests/brainstorm-server/helper.test.js` | 1 | 15 passed, 1 failed: a brief reconnect did not reload, so an offline screen broadcast could be lost. |
| `node tests/brainstorm-server/browser-launcher.test.js` | 1 | 3 passed, 2 failed: no JSON-argv launcher existed and the operator override still used a shell. |
| `node tests/brainstorm-server/server.test.js` | 1 | 33 passed, 1 failed: raw traversal was normalized to a valid content filename. |
| `node tests/brainstorm-server/lifecycle.test.js` | 1 | 11 passed, 2 failed: the new `.t-superpowers` path and JSON-argv opener were not implemented yet. |
| `bash tests/brainstorm-server/start-server.test.sh` | 1 | 3 passed, 1 failed: state still used `.superpowers/brainstorm/`. |
| `bash tests/brainstorm-server/stop-server.test.sh` | 1 | 6 passed, 1 failed: macOS `$TMPDIR` sessions were not removed. |
| `node tests/brainstorm-server/skill-contract.test.js` | 1 | 5 passed, 1 failed: default temp/docsDev cache policy was absent. |

## Focused GREEN

- Helper: 16/16.
- Browser launcher: 5/5; hostile URL remains one `execFile` argv element.
- Server: 34/34; raw and encoded traversal both return 404.
- Lifecycle: 13/13.
- Start/stop shell tests: 4/4 and 7/7.
- Skill contract: 6/6.

The reviewer also questioned reusing a project-level token across every `start-server.sh` invocation. The approved behavior requires same-port/key restart so an open tab can reconnect. The guide now scopes that reuse to a stable per-brainstorming-session directory under `$TMPDIR` and instructs cleanup when the session ends; it does not persist a permanent repository-root project key. Explicit persistence is allowed only under the user-requested `docsDev/changes/<change-id>/transcripts/visual-companion` path.

`windows-lifecycle.test.sh` remains a separate discoverable `npm run test:windows-lifecycle` command because it intentionally contains two 75-second watchdog windows. The full simulated Windows run was executed once after the upstream lifecycle port and passed 13/13; later fixes were covered by the focused start/stop, launcher, lifecycle, and shell tests without repeating the long wait.

## Final safety quality review

The final independent quality review found exactly three Important issues:

1. Temporary cleanup trusted any pathname below `$TMPDIR` or `/tmp`. A caller could therefore cause an explicit `/tmp/repo/docsDev/...` project directory, or a `..` path escaping the intended session root, to be removed after stopping the server.
2. Screen selection and `/files/` validated a pathname and later reopened it for reading. A symlink swap or rename replacement between those operations could bypass the original `lstat`/`realpath` decision.
3. Input-state handling was incomplete: the four valued start options could loop when their value was missing, while the WebSocket decoder accepted fragmented or RSV-bearing frames outside the browser-helper subset.

### Final RED

| Command | Exit | RED result |
|---|---:|---|
| `bash tests/brainstorm-server/stop-server.test.sh` | 1 | 7 passed, 3 failed: unmarked temp, explicit `/tmp` project, and canonical `..` escape cases were deleted. |
| `node tests/brainstorm-server/safe-file-read.test.js` | 1 | 0 passed, 3 failed: the safe same-fd helper did not exist, including repeatable 25-iteration symlink-swap and rename-replacement cases. |
| `bash tests/brainstorm-server/start-server.test.sh` | 1 | 4 passed, 5 failed: four valued options did not exit quickly and the stable marked temp root was absent. |
| `node tests/brainstorm-server/ws-protocol.test.js` | 1 | 32 passed, 2 failed: FIN=0 and RSV-set client frames were accepted. |

### Final GREEN and re-review

- `stop-server.sh` now deletes only when an owner-only cleanup marker is present and the canonical session path is strictly beneath the canonical `$TMPDIR/t-superpowers-brainstorm/` root or the direct legacy `/tmp/brainstorm-*` layout. Explicit project paths and canonical escapes remain on disk.
- `server.cjs` opens content with `O_NOFOLLOW` where available, compares the opened descriptor with `lstat`/`realpath` identity (`dev`, `ino`, regular-file type, and `nlink`), reads from that same descriptor, and always closes it. Invalid root candidates are skipped and invalid `/files/` requests return 404 without crashing.
- `start-server.sh` rejects missing values for all four valued options, and `decodeFrame` rejects non-final or RSV-bearing client frames.
- Fresh `npm --prefix tests/brainstorm-server test` result: 154 passed, 0 failed. The safety fix is commit `205a913e7ae800702a12456a83ce9e51f58b4d59`.
- Independent re-review: **PASS**. No Critical, Important, or Minor findings remain.
