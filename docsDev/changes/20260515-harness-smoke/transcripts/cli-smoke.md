# CLI Smoke Results

Date: 2026-05-15T01:22:22Z
Change: `20260515-harness-smoke`

## Classification Method

Claude Code CLI stream-json output includes startup hook context and init metadata that list available skills and slash commands. Those lines mention `t-brainstorming` even when the prompt does not enter the workflow. Final classification therefore uses actual assistant `tool_use` events, especially `Skill` calls, rather than a raw substring grep over the whole JSONL file.

## Claude Code CLI

Command base:

```bash
claude -p <prompt> --plugin-dir /Users/lihuajun/WorkProject/superpowers --output-format stream-json --verbose
```

### Simple Prompt

- Prompt: `帮我把按钮文案从'确定'改成'OK'`
- Result: PASS
- Raw stream: `transcripts/raw/claude-simple.jsonl`
- Stderr: `transcripts/raw/claude-simple.stderr.log`
- Observation: No `Skill` tool call was made. The agent stayed in the direct edit path with `Grep`, `Read`, `Edit`, and `Bash` attempts.
- Execution note: The edit itself was blocked by Claude Code CLI write approval, but that is not a `t-brainstorming` trigger failure.

### Explicit Complex Prompt

- Prompt: `用 t-superpowers，我要做一个 PDF 导出功能`
- Result: PASS
- Raw stream: `transcripts/raw/claude-explicit.jsonl`
- Stderr: `transcripts/raw/claude-explicit.stderr.log`
- Observation: The transcript contains an actual `Skill` tool call for `t-superpowers:t-brainstorming`, followed by clarifying-question behavior for PDF export requirements.
- Execution note: The `Skill` and `AskUserQuestion` tools were permission-denied by the non-interactive CLI harness, but the trigger intent and brainstorming behavior are visible in the raw stream.

## Codex CLI

- Result: BLOCKED
- Command availability: `codex-cli 0.123.0` is installed.
- Reason: A temporary local marketplace and isolated `CODEX_HOME` could be created, but the isolated home had no authentication state for `codex exec`. Prompt-input checks with the temporary marketplace did not expose local `t-superpowers` skills in the model-visible skill list.
- Observation: This is a local plugin loading/distribution blocker, not evidence that the prompt boundary failed.
- Follow-up: Define a stable Codex CLI local install path for internal `t-superpowers`, or publish it to the team's Codex plugin source before treating Codex CLI smoke as required.
