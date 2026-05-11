# Type C Co-Installed Harness Transcript

日期：2026-05-10 13:06-13:12 CST
固定 prompt：`Let's make a react todo list`
目标：验证 official `superpowers` 与 fork `t-superpowers` 共存、namespace 分离、分别禁用互不污染。
阶段一 transcript 范围修订：2026-05-11 起只以 Claude Code CLI 与 Codex CLI 作为阶段一完成硬门槛；Cursor.app 与 Codex App 真实 transcript 不再阻塞阶段一。Codex CLI co-installed 因当前安装模型限制降级为后续验证项，阶段一 Type C 硬门槛由 Claude Code CLI co-installed transcript 满足。

## Claude Code CLI

- 状态：通过。
- 命令：`claude -p "Let's make a react todo list" --plugin-dir /Users/lihuajun/.claude/plugins/cache/claude-plugins-official/superpowers/5.1.0 --plugin-dir /Users/lihuajun/WorkProject/superpowers --output-format stream-json --verbose`
- stream transcript：`docs/二开规划/harness-transcripts/raw/type-c-claude-coinstalled-stream.jsonl`
- Claude JSONL transcript：`/Users/lihuajun/.claude/projects/-private-tmp-harness-claude-coinstalled-2voPy2/e534bb3d-677a-4c8c-b650-79f0e32769bf.jsonl`
- first 200 chars：`{"type":"system","subtype":"hook_started","hook_id":"0e68b22c-4194-42ff-88d9-523d3cd94d64","hook_name":"SessionStart:startup","hook_event":"SessionStart","uuid":"bc98fd8f-de88-`
- 观察：两个插件同时可见；`superpowers:using-superpowers` 与 `t-superpowers:t-using-superpowers` 均注入；两个 namespace 未覆盖。双 bootstrap 作为 co-installed 事实记录，不作为单装等价证据。
- 单独禁用依据：Type A Claude Code 证明只加载 official 可用；Type B Claude Code 证明只加载 fork 可用。

## Codex CLI

- 状态：后续验证项，不阻塞阶段一。
- 尝试方式：临时 `CODEX_HOME` 同时放置 official 缓存与 fork 缓存，并启用 `superpowers@openai-curated` 与 `t-superpowers@openai-curated`。
- JSONL transcript：`docs/二开规划/harness-transcripts/raw/type-c-codex-cli-coinstalled.jsonl`
- stderr：`docs/二开规划/harness-transcripts/raw/type-c-codex-cli-coinstalled.stderr.log`
- final response：`docs/二开规划/harness-transcripts/raw/type-c-codex-cli-coinstalled-last.txt`
- first 200 chars：`{"type":"thread.started","thread_id":"019e104c-e426-7941-916e-45e635b711fb"}\n{"type":"turn.started"}\n{"type":"item.completed","item":{"id":"item_0","type":"agent_message","text":"Using`
- 观察：Codex CLI 只加载 official namespace；`t-superpowers:t-*` 计数为 0。额外塞入的 `t-superpowers` 缓存未被识别为已安装插件。
- 单独禁用依据：Type A Codex CLI 证明 official 可用；Type B Codex CLI 证明 fork 可用。但同装共存仍未验证通过，作为后续验证项保留。

## Type C 结论

Type C 在修订后的阶段一范围内已通过：Claude Code CLI co-installed 已证明两个 namespace 同时可见且互不覆盖。Codex CLI 同装尝试未能加载 fork，作为后续验证项保留；Cursor.app 与 Codex App transcript 不再作为阶段一完成硬阻塞项。
