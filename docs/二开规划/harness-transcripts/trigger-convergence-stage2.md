# Stage 2 Trigger Convergence Harness Transcript

Date: 2026-05-12

Change: `20260512-trigger-convergence`

## Summary

This harness record validates the first stage-2 trigger convergence change:

- Simple Claude bootstrap prompt did not enter `t-brainstorming`.
- Simple Codex README prompt did not implicitly select `t-brainstorming`.
- Complex Codex PDF export prompt, without mentioning `t-superpowers`, implicitly selected `t-brainstorming`.
- Explicit `t-superpowers` PDF export prompt entered the complex-work skill path.

Raw logs are kept under `docs/二开规划/harness-transcripts/raw/`.

## Checks

### Claude Simple Bootstrap Negative

Prompt:

```text
帮我把按钮文案从'确定'改成'OK'
```

Command:

```bash
claude -p "帮我把按钮文案从'确定'改成'OK'" --plugin-dir /Users/lihuajun/WorkProject/superpowers --output-format stream-json --verbose
```

Result: PASS

Evidence:

- Raw stream: `docs/二开规划/harness-transcripts/raw/trigger-convergence-claude-simple.jsonl`
- Stderr: `docs/二开规划/harness-transcripts/raw/trigger-convergence-claude-simple.stderr.log`
- The run attempted to load `t-superpowers:t-using-superpowers`, then proceeded directly to locate the requested copy.
- No `t-superpowers:t-brainstorming` invocation occurred.
- No new `docsDev/changes/<change-id>/` directory was created for this prompt.

Note: The local Claude run reported an `EPERM` error while trying to read `/Users/lihuajun/.claude.json` for the `t-using-superpowers` skill load. That did not affect the negative assertion being checked here: the simple request did not enter `t-brainstorming`.

### Codex Simple Description Negative

Prompt:

```text
帮我加一个 README 段落
```

Command:

```bash
CODEX_HOME=/tmp/codex-home-trigger codex exec --json --skip-git-repo-check -C /tmp/codex-harness-trigger -s read-only -m gpt-5.4 "帮我加一个 README 段落"
```

Result: PASS

Evidence:

- Raw stream: `docs/二开规划/harness-transcripts/raw/trigger-convergence-codex-readme.jsonl`
- Stderr: `docs/二开规划/harness-transcripts/raw/trigger-convergence-codex-readme.stderr.log`
- Codex injected `t-superpowers:t-using-superpowers`.
- Codex did not inject `t-superpowers:t-brainstorming`.

### Codex Complex Implicit Positive

Prompt:

```text
我要做一个支持多种格式的 PDF 导出功能，涉及前端按钮、后端 API 和模板生成
```

Command:

```bash
CODEX_HOME=/tmp/codex-home-trigger codex exec --json --skip-git-repo-check -C /tmp/codex-harness-trigger -s read-only -m gpt-5.4 "我要做一个支持多种格式的 PDF 导出功能，涉及前端按钮、后端 API 和模板生成"
```

Result: PASS

Evidence:

- Raw stream: `docs/二开规划/harness-transcripts/raw/trigger-convergence-codex-pdf-implicit.jsonl`
- Stderr: `docs/二开规划/harness-transcripts/raw/trigger-convergence-codex-pdf-implicit.stderr.log`
- The prompt did not mention `t-superpowers`.
- Codex injected `t-superpowers:t-brainstorming`.
- Codex also injected `t-superpowers:t-using-superpowers` and `t-superpowers:t-writing-plans`.

### Explicit Complex Trigger Positive

Prompt:

```text
用 t-superpowers，我要做一个 PDF 导出功能
```

Command:

```bash
CODEX_HOME=/tmp/codex-home-trigger codex exec --json --skip-git-repo-check -C /tmp/codex-harness-trigger -s read-only -m gpt-5.4 "用 t-superpowers，我要做一个 PDF 导出功能"
```

Result: PASS

Evidence:

- Raw stream: `docs/二开规划/harness-transcripts/raw/trigger-convergence-explicit.jsonl`
- Stderr: `docs/二开规划/harness-transcripts/raw/trigger-convergence-explicit.stderr.log`
- Codex injected `t-superpowers:t-brainstorming`.
- Codex also injected `t-superpowers:t-using-superpowers` and `t-superpowers:t-writing-plans`.
- The model response explicitly entered the `t-superpowers:t-brainstorming` path before asking requirements questions.

## Known Harness Limits

- These are manual LLM-runtime harness checks, not deterministic CI fixtures.
- Codex was run in a temporary `CODEX_HOME` with the local `t-superpowers` plugin copied into the `openai-curated` plugin cache path.
- Codex read-only sandbox warnings are not part of the trigger assertion.
- Telemetry warnings about `t-superpowers:<skill>` tag characters are not part of the trigger assertion.
