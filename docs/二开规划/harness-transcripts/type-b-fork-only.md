# Type B Fork-Only Harness Transcript

日期：2026-05-10 13:05-13:11 CST
固定 prompt：`Let's make a react todo list`
插件组合：仅验证 fork `t-superpowers`；非目标插件在 Codex CLI 命令中显式禁用。
阶段一 transcript 范围修订：2026-05-11 起只以 Claude Code CLI 与 Codex CLI 作为阶段一完成硬门槛；Cursor.app 与 Codex App 真实 transcript 不再阻塞阶段一。

## Claude Code CLI

- 状态：通过。
- 命令：`claude -p "Let's make a react todo list" --plugin-dir /Users/lihuajun/WorkProject/superpowers --output-format stream-json --verbose`
- stream transcript：`docs/二开规划/harness-transcripts/raw/type-b-claude-fork-stream.jsonl`
- Claude JSONL transcript：`/Users/lihuajun/.claude/projects/-private-tmp-harness-claude-fork-w6vwt7/afea02f6-6993-482f-9226-18eea529c246.jsonl`
- first 200 chars：`{"type":"system","subtype":"hook_started","hook_id":"7b8c4af9-1836-46aa-9928-31995df87573","hook_name":"SessionStart:startup","hook_event":"SessionStart","uuid":"6786ffa4-d6e4-`
- 观察：`SessionStart` hook 注入 `t-superpowers:t-using-superpowers`；技能列表只有 `t-superpowers:t-*`；随后自动调用 `t-superpowers:t-brainstorming`。

## Codex CLI

- 状态：通过。
- 隔离方式：临时 `CODEX_HOME` 复制用户认证和配置，将 fork 内容同步到临时插件缓存；未修改用户全局 Codex 配置。
- 命令：`CODEX_HOME=/tmp/codex-home-fork.dMwL20 codex exec --json --skip-git-repo-check -C /tmp/harness-codex-fork.pcEhza -s read-only -m gpt-5.4 ... "Let's make a react todo list"`
- JSONL transcript：`docs/二开规划/harness-transcripts/raw/type-b-codex-cli-fork.jsonl`
- stderr：`docs/二开规划/harness-transcripts/raw/type-b-codex-cli-fork.stderr.log`
- final response：`docs/二开规划/harness-transcripts/raw/type-b-codex-cli-fork-last.txt`
- first 200 chars：`{"type":"thread.started","thread_id":"019e104c-1845-7ca3-9018-4f3d6bb0c05d"}\n{"type":"turn.started"}\n{"type":"item.completed","item":{"id":"item_0","type":"agent_message","text":"Using`
- 观察：出现 `t-superpowers:t-using-superpowers` 与 `t-superpowers:t-brainstorming`；未出现 `superpowers:using-superpowers`、`superpowers:brainstorming` 或 hook 事件。

## Type B 结论

Type B 在修订后的阶段一范围内已通过：Claude Code CLI 与 Codex CLI 均完成 fork-only 验收。Cursor.app 与 Codex App transcript 不再作为阶段一完成硬阻塞项。
