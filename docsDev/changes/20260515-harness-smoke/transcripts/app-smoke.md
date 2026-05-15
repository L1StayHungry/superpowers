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
- Setup result: NOT VERIFIED
- Setup notes:

### Simple Prompt

- Prompt: `帮我把按钮文案从“确定”改成“OK”`
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
