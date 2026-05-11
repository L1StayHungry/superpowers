# Type A Official-Only Harness Transcript

日期：2026-05-10 13:05-13:08 CST
固定 prompt：`Let's make a react todo list`
插件组合：仅验证 upstream/official `superpowers`；非目标插件在 Codex CLI 命令中显式禁用。
阶段一 transcript 范围修订：2026-05-11 起只以 Claude Code CLI 与 Codex CLI 作为阶段一完成硬门槛；Cursor.app 与 Codex App 真实 transcript 不再阻塞阶段一。

## Claude Code CLI

- 状态：通过。
- 命令：`claude -p "Let's make a react todo list" --plugin-dir /Users/lihuajun/.claude/plugins/cache/claude-plugins-official/superpowers/5.1.0 --output-format stream-json --verbose`
- stream transcript：`docs/二开规划/harness-transcripts/raw/type-a-claude-official-stream.jsonl`
- Claude JSONL transcript：`/Users/lihuajun/.claude/projects/-private-tmp-harness-claude-official-dNzj52/448f3350-7407-4cd4-9384-23c2a22d653a.jsonl`
- first 200 chars：`{"type":"system","subtype":"hook_started","hook_id":"0f403c62-27df-4c28-855a-843945650271","hook_name":"SessionStart:startup","hook_event":"SessionStart","uuid":"1a53856e-f98c-4a60-`
- 观察：`SessionStart` hook 注入 `superpowers:using-superpowers`；随后自动调用 `superpowers:brainstorming`。

## Codex CLI

- 状态：通过。
- 命令：`codex exec --json --skip-git-repo-check -C /tmp/harness-codex-official.2dMhcO -s read-only -m gpt-5.4 ... "Let's make a react todo list"`
- JSONL transcript：`docs/二开规划/harness-transcripts/raw/type-a-codex-cli-official.jsonl`
- stderr：`docs/二开规划/harness-transcripts/raw/type-a-codex-cli-official.stderr.log`
- final response：`docs/二开规划/harness-transcripts/raw/type-a-codex-cli-official-last.txt`
- first 200 chars：`{"type":"thread.started","thread_id":"019e1049-086d-7600-b4c5-81229fab1488"}\n{"type":"turn.started"}\n{"type":"item.completed","item":{"id":"item_0","type":"agent_message","text":"Using`
- 观察：自动声明并读取 `superpowers:using-superpowers` 与 `superpowers:brainstorming`；未出现 Codex hook/session-start 事件。
- Codex hook 结论：官方 Codex baseline 没有 hook 注入；当前 `codex features list` 中 `codex_hooks` 为 `false`。因此 fork 按决策矩阵切到选项 B：`.codex-plugin/plugin.json` 使用 `"hooks": []`。

## Type A 结论

Type A 在修订后的阶段一范围内已通过：Claude Code CLI 与 Codex CLI 均完成 official-only baseline。Codex hook 决策已可关闭为选项 B。Cursor.app 与 Codex App transcript 不再作为阶段一完成硬阻塞项。
