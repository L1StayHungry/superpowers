# App Smoke Results

Date: 2026-05-15
Change: `20260515-harness-smoke`

## Result Legend

- `PASS`: observed behavior matches expected behavior.
- `FAIL`: harness ran, but behavior contradicted expected behavior.
- `BLOCKED`: harness could not be tested because install, plugin loading, login, UI access, or export path is unavailable.
- `NOT VERIFIED`: test has not been run yet.

## Cursor.app

### Setup

- Plugin source: `/Users/lihuajun/WorkProject/superpowers`
- Expected plugin display name: `T-Superpowers`
- Setup result: BLOCKED
- Setup notes:
  - Cursor `/add-plugin /Users/lihuajun/WorkProject/superpowers` reported that it symlinked the repo to `~/.cursor/plugins/local/t-superpowers`.
  - The same Cursor response said the manifest was verified as `T-Superpowers` and that `skills`, `agents`, `commands`, and `hooks` were present.
  - After a full Cursor quit/reopen, the user reported the plugin was still not recognized. The Cursor Plugins UI showed `No Plugins`.
  - On disk before physical-directory reproduction, `~/.cursor/plugins/local/t-superpowers` was a symlink to `/Users/lihuajun/WorkProject/superpowers`.

### Simple Prompt

- Prompt: `帮我把按钮文案从“确定”改成“OK”`
- Expected: does not enter `t-brainstorming`
- Result: PASS
- Evidence: user-provided Cursor screenshot in chat.
- Observation: Cursor did not enter `t-brainstorming`; it treated the request as a simple copy edit and changed `src/locale/lang/jp.json`. This proves the simple prompt stayed direct, but it does not prove the plugin was enabled because setup was blocked.

### Explicit Complex Prompt

- Prompt: `用 t-superpowers，我要做一个 PDF 导出功能`
- Expected: enters `t-superpowers` or `t-brainstorming`
- Result: BLOCKED
- Evidence: user-provided Cursor screenshot in chat.
- Observation: Cursor responded that it did not find a skill for `t-superpowers` or PDF export, then proceeded to inspect project files. This is classified as plugin-loading blocked, not as a `t-superpowers` trigger-rule failure.

### Physical Directory Reproduction

- Purpose: distinguish Cursor symlink handling from Cursor plugin runtime recognition.
- Source: `/Users/lihuajun/WorkProject/superpowers`
- Target: `~/.cursor/plugins/local/t-superpowers`
- Disk setup result: PASS
- Runtime result: NOT VERIFIED
- Setup notes:
  - Removed symlink `~/.cursor/plugins/local/t-superpowers -> /Users/lihuajun/WorkProject/superpowers`.
  - Copied physical plugin payload into `~/.cursor/plugins/local/t-superpowers`.
  - Verified target is not a symlink.
  - Verified `.cursor-plugin/plugin.json` has `name: "t-superpowers"` and `displayName: "T-Superpowers"`.
  - Verified 15 `t-*` skill directories exist under `skills/`.
  - Verified `skills/t-brainstorming/SKILL.md` exists.
  - Verified `hooks/hooks-cursor.json` exists.
  - Verified `hooks/session-start` is executable.
- Expected manual check after preparation:
  1. Fully quit Cursor.
  2. Reopen Cursor and start a new Agent session.
  3. Ask: `请列出当前可用 skills 中名称包含 t- 或 t-superpowers 的条目。只列名称，不要做项目分析。`
  4. Ask: `用 t-superpowers:t-brainstorming，帮我规划首页 PDF 导出功能；先不要实现。`

## Codex App

### Setup

- Expected plugin: internal `t-superpowers`
- Setup result: NOT VERIFIED
- Setup notes:

### Simple Prompt

- Prompt: `帮我加一个 README 段落`
- Expected: does not enter `t-brainstorming`
- Result: NOT VERIFIED
- Evidence:
- Observation:

### Explicit Complex Prompt

- Prompt: `用 t-superpowers，我要做一个 PDF 导出功能`
- Expected: enters `t-superpowers` or `t-brainstorming`
- Result: NOT VERIFIED
- Evidence:
- Observation:
