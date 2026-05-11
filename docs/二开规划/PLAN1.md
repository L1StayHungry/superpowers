# 阶段一 t-superpowers 命名迁移实施计划

## Summary
阶段一只做机器可见命名与引用迁移，让当前 fork 从 upstream `superpowers` 独立成 `t-superpowers`，并保持单装行为等价。已确认 `/Users/lihuajun/WorkProject/superpowers` 当前在 `t-dev`，本地改动仅新增二开规划文档；upstream `obra/superpowers main` 当前为 `f2cbfbefebbfef77321e4c9abc9e949826bea9d7`。

已锁定两个默认：
- Codex hook 采用规划中的选项 A：新增兼容 hook，并显式写入 `.codex-plugin/plugin.json`。
- 同步调整仍服务于 Claude/Cursor/Codex/brainstorm-server 的活跃测试；OpenCode/Gemini/npm 排除入口相关测试不作为阶段一验收。

## Design Decisions
- 采用“vendor-first → t-* 命名迁移 → 受限运行时引用替换 → 自检与 harness 验收”的顺序。这样先固定 upstream 基线，再改发布面，最后用脚本证明迁移范围没有扩散。
- vendor 取数优先使用本地已有 upstream commit，而不是要求先配置 `upstream` remote。当前 fork 历史已经包含 `f2cbfbefebbfef77321e4c9abc9e949826bea9d7`，直接 `git archive` 可减少环境前置条件；仅当未来 fork main 落后时再临时 fetch upstream。
- Codex hook 默认选项 A，因为阶段一目标是 fork-only 单装行为等价；只有 official-only 实测证明 Codex 也不注入 bootstrap 时，才允许回退到选项 B（`hooks: []`）。
- 测试迁移只覆盖会验证 t-* 运行面或被目录重命名直接影响的套件。OpenCode、Gemini、npm、Codex marketplace sync 都是阶段一排除入口，不把它们纳入 fork-only 行为等价测试。

## Implementation Flow
- 先跑预检：确认目标 commit 可访问，3 处排除入口与根级指令文件当前无未提交改动，且当前 repo 的 3 处排除入口未偏离 upstream commit（`git diff f2cbfbefebbfef77321e4c9abc9e949826bea9d7 -- package.json gemini-extension.json .opencode/plugins/superpowers.js` 应无输出）。这个 upstream diff 是本计划针对当前仓库事实的启动假设，不是通用 CI invariant。
- 生成 `vendor/superpowers/` 基线和 `UPSTREAM_COMMIT`，再从 vendor 的 upstream `CLAUDE.md` 生成 `docs/upstream-contrib.md`。
- 迁移发布面：`skills/` 目录和 `SKILL.md` frontmatter、4 处 manifest、`hooks/session-start`、Codex hook、Cursor 占位目录。
- 迁移验证面：只更新 `tests/subagent-driven-dev/`、`tests/claude-code/`、`tests/brainstorm-server/` 中与 t-* 命名或重命名路径相关的断言与路径。
- 最后执行 `tools/t-stage1-check.sh`、实施期静态核对、三类 harness 验收，并把 transcript 存到阶段一验收记录。

## Failure Handling
- 如果排除入口预检出现 diff，立即停止阶段一实施；先和团队决定保留还是放弃历史本地化，不能在命名迁移里顺手处理。
- 如果目标 upstream commit 本地不存在，先 `git fetch origin`；仍不存在时再临时添加/fetch upstream，并在 `UPSTREAM_COMMIT` notes 中记录取数来源。
- 如果 `tools/t-stage1-check.sh` 报告非 t-* skill、残留 `superpowers:<x>`（`x` 为 14 个 upstream skill 名或阶段二预留的 `archive`）、manifest 字段错误、Codex hook 字段错误、Cursor 占位目录缺失或根指令 symlink 破坏，按报错修复后重跑，不允许用文档豁免跳过。
- 如果 official-only Codex 基线无 bootstrap 注入，按决策回退改为 `hooks: []` 并删除 `hooks/hooks-codex.json`；如果有注入，则必须保留选项 A。
- 如果 co-installed 验收出现双重 bootstrap 注入，这不是失败；只有插件命名冲突、`/skills` 覆盖或无法独立启停才算失败。

## Key Changes
- 建立 upstream vendor 基线：fork `main` 已包含 upstream commit `f2cbfbefebbfef77321e4c9abc9e949826bea9d7`（`git log --oneline -1 f2cbfbefebbfef77321e4c9abc9e949826bea9d7` 显示 `Release v5.1.0 (#1468)`），且当前仓库只有 fork `origin` remote，所以 vendor 同步不需要额外配置 upstream remote。用以下带 pathspec 的命令复制完整集合；后续 rebase 时若 fork main 落后于 upstream，再临时 `git remote add upstream https://github.com/obra/superpowers && git fetch upstream` 后取数。
  ```bash
  mkdir -p /Users/lihuajun/WorkProject/superpowers/vendor/superpowers
  git archive f2cbfbefebbfef77321e4c9abc9e949826bea9d7 -- \
    skills hooks CLAUDE.md AGENTS.md GEMINI.md \
    .claude-plugin/plugin.json .claude-plugin/marketplace.json \
    .cursor-plugin/plugin.json .codex-plugin/plugin.json \
    package.json gemini-extension.json .opencode/plugins/superpowers.js \
    | tar -xC /Users/lihuajun/WorkProject/superpowers/vendor/superpowers/
  ```
  也可用 `git show f2cbfbefebbfef77321e4c9abc9e949826bea9d7:<path>` 逐文件取出。
  - `skills/`（14 个 upstream skill 副本）
  - `hooks/`（含 `session-start` 原版正文）
  - 根级指令文件 `CLAUDE.md`（upstream 原文）/ `AGENTS.md`（若 upstream 不是 symlink，单独保存；若是 symlink，保留或记录其目标）/ `GEMINI.md`
  - 4 处必改 manifest：`.claude-plugin/plugin.json` / `.claude-plugin/marketplace.json` / `.cursor-plugin/plugin.json` / `.codex-plugin/plugin.json`
  - 3 处排除入口：`package.json` / `gemini-extension.json` / `.opencode/plugins/superpowers.js`
  并写入 `/Users/lihuajun/WorkProject/superpowers/vendor/superpowers/UPSTREAM_COMMIT`，包含 `upstream` / `branch` / `commit` / `synced_at` / `notes` 五个字段（`commit` 为 7-40 位十六进制）。
- 将 `/Users/lihuajun/WorkProject/superpowers/skills/<name>/` 全部 `git mv` 为 `/Users/lihuajun/WorkProject/superpowers/skills/t-<name>/`，仅把每个 `SKILL.md` frontmatter 的 `name:` 改为 `t-<name>`。
- 在 `/Users/lihuajun/WorkProject/superpowers/skills/`、`/Users/lihuajun/WorkProject/superpowers/hooks/`、4 个必改 manifest、以及 `tests/` 中以下三个套件内做批量替换：
  - `tests/subagent-driven-dev/`：把 `superpowers:subagent-driven-development` 改为 `t-superpowers:t-subagent-driven-development`（命中文件 `go-fractals/plan.md`、`go-fractals/scaffold.sh`、`svelte-todo/plan.md`、`svelte-todo/scaffold.sh`、`run-test.sh`）。
  - `tests/claude-code/`：替换 `superpowers:subagent-driven-development`、`superpowers:requesting-code-review`、`skills/brainstorming/` 三类硬编码（命中文件 `test-subagent-driven-development-integration.sh`、`test-requesting-code-review.sh`、`test-document-review-system.sh`）。
  - `tests/brainstorm-server/`：替换 `skills/brainstorming/` 路径为 `skills/t-brainstorming/`（命中文件 `server.test.js`、`ws-protocol.test.js`、`windows-lifecycle.test.sh`，共 7 处路径引用）。
- 不批量改 `/Users/lihuajun/WorkProject/superpowers/docs/`、`/Users/lihuajun/WorkProject/superpowers/vendor/`、`/Users/lihuajun/WorkProject/superpowers/package.json`、`/Users/lihuajun/WorkProject/superpowers/gemini-extension.json`、`/Users/lihuajun/WorkProject/superpowers/.opencode/plugins/superpowers.js`、`/Users/lihuajun/WorkProject/superpowers/scripts/sync-to-codex-plugin.sh`。
- 明确不替换的 `tests/` 范围：
  - `tests/explicit-skill-requests/` 与 `tests/skill-triggering/` 中的 `docs/superpowers/plans/...` 是 fixture，对应阶段二才迁移到 `docsDev/changes/<id>/plan.md` 的产物路径，阶段一保持不变（与二次开发规划 §5.2“不改默认产物路径”一致）。
  - `tests/opencode/` 与 `tests/codex-plugin-sync/` 实测无 `superpowers:<x>`（`x` 为 14 个 upstream skill 名或阶段二预留的 `archive`）残留，且核心被测对象（`.opencode/plugins/superpowers.js`、`scripts/sync-to-codex-plugin.sh`）阶段一字节不动；因此不纳入阶段一 fork-only 行为等价测试，自检脚本反向断言作兜底。
  - 全局禁止替换的测试 fixture 字面值：`docs/superpowers/plans/`、`docs/superpowers/specs/` 产物路径 fixture；`/tmp/superpowers-tests/` 临时输出目录；`--plugin-dir /path/to/superpowers` 命令行示例；`github.com/superpowers-test/fractals` Go module 名 fixture。
- 修改 4 个 manifest：Claude/Cursor/Codex plugin `name` 为 `t-superpowers`，Cursor `displayName` 和 Codex `interface.displayName` 为 `T-Superpowers`，Claude marketplace 顶层 name 为 `t-superpowers-dev`，嵌套 plugin name 为 `t-superpowers`。
- 更新 `/Users/lihuajun/WorkProject/superpowers/hooks/session-start` 读取 `/skills/t-using-superpowers/SKILL.md`，并把注入正文里的运行时 id 改为 `t-superpowers:t-using-superpowers`；不改 “You have superpowers.” 等行为塑造文本。
- 新增 `/Users/lihuajun/WorkProject/superpowers/hooks/hooks-codex.json`，command 使用相对路径 `./hooks/run-hook.cmd session-start`，文件内容不出现 `${CLAUDE_PLUGIN_ROOT}` / `$CLAUDE_PLUGIN_ROOT` 字面值（依赖 `run-hook.cmd` 自身用 `%~dp0` / `dirname` 自定位）；在 `.codex-plugin/plugin.json` 显式设置 `"hooks": "./hooks/hooks-codex.json"`。
- 创建 `/Users/lihuajun/WorkProject/superpowers/agents/.gitkeep` 和 `/Users/lihuajun/WorkProject/superpowers/commands/.gitkeep`，满足 Cursor manifest 已声明路径。
- 从 `/Users/lihuajun/WorkProject/superpowers/vendor/superpowers/CLAUDE.md` 字节级生成 `/Users/lihuajun/WorkProject/superpowers/docs/upstream-contrib.md`；不从当前中文 `CLAUDE.md` 复制。
- 新增 `/Users/lihuajun/WorkProject/superpowers/tools/t-stage1-check.sh`，以二开规划 §5.4 脚本为基准，并叠加：
  - 反向断言 `tests/` 中无 `superpowers:(brainstorming|writing-plans|test-driven-development|systematic-debugging|verification-before-completion|subagent-driven-development|using-superpowers|using-git-worktrees|executing-plans|requesting-code-review|receiving-code-review|finishing-a-development-branch|dispatching-parallel-agents|writing-skills|archive)` 残留（与二次开发规划 §5.4 第 2 条 alternation 同源；不命中 `plugins/superpowers`、`/tmp/superpowers-tests/` 等产品/输出路径 fixture）
  - `.cursor-plugin/plugin.json` 的 `displayName == "T-Superpowers"`
  - `.codex-plugin/plugin.json` 的 `interface.displayName == "T-Superpowers"`
  - 三个 plugin.json 的 `skills` 字段仍为 `"./skills/"`
  - `hooks/hooks-codex.json` 不包含 `${CLAUDE_PLUGIN_ROOT}` / `$CLAUDE_PLUGIN_ROOT`
  - 3 处排除入口的 `name` 字段仍为 `"superpowers"`（与二次开发规划 §5.4 第 10 条等价；不与 upstream 字节级比对，因为 fork 维护者可能存在合法本地化历史，阶段一只要求"不再动"而非"回退到 upstream 原件"）
  - 阶段一执行期间 3 处排除入口与根级指令文件无 git diff（由 Test Plan 中 `git diff --exit-code` 6 文件断言兜底，自检脚本不重复实现）
  - `AGENTS.md` 仍是指向 `CLAUDE.md` 的 symlink

## Public Interfaces
- 插件包名：`superpowers` → `t-superpowers`，仅限 Claude/Cursor/Codex 三个支持入口。
- Skill 命名空间：`superpowers:<name>` → `t-superpowers:t-<name>`。
- Skill 文件系统入口：`skills/<name>/` → `skills/t-<name>/`。
- Codex plugin 新增公开 manifest 字段：`"hooks": "./hooks/hooks-codex.json"`。
- 明确不变接口：
  - `/Users/lihuajun/WorkProject/superpowers/package.json`、`/Users/lihuajun/WorkProject/superpowers/gemini-extension.json`、`/Users/lihuajun/WorkProject/superpowers/.opencode/plugins/superpowers.js` 保持阶段一前字节不变。
  - 保留 `AGENTS.md -> CLAUDE.md` symlink 关系不变；根 `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` 字节级不动（不修改 fork 维护者已本地化的中文 `CLAUDE.md`）。

## Test Plan
- 先写并运行自检脚本，迁移前应失败，迁移完成后运行：
  `bash /Users/lihuajun/WorkProject/superpowers/tools/t-stage1-check.sh`
  期望输出 `OK: Stage 1 migration self-check passed`。
- 运行实施期静态核对（任一有 diff 即视为污染单装等价）：
  ```bash
  git diff --exit-code -- \
    package.json gemini-extension.json .opencode/plugins/superpowers.js \
    CLAUDE.md AGENTS.md GEMINI.md
  ```
  期望无 diff。
- 更新并运行活跃测试（仅限阶段一替换范围内的套件）：
  - `tests/brainstorm-server/`：server 启动 + WebSocket 协议 + Windows 生命周期测试，确认替换为 `skills/t-brainstorming/scripts/` 后仍能起服务并跑通协议握手。
  - `tests/claude-code/`：被点名的 3 个脚本（`test-subagent-driven-development-integration.sh`、`test-requesting-code-review.sh`、`test-document-review-system.sh`）期望使用 `t-*` skill 名称或 `t-superpowers:t-*` namespace。
  - `tests/subagent-driven-dev/`：`run-test.sh svelte-todo` 与 `run-test.sh go-fractals` 跑通（`plan.md` 中 dispatch prompt 已含 `t-superpowers:t-subagent-driven-development`）。
- 三类并存验收记录到 `/Users/lihuajun/WorkProject/superpowers/docs/二开规划/阶段一验收记录.md`（每类必须有 transcript 头部 200 字符存档）：
  - **类型 A（official-only 基线）**：只装 upstream `superpowers`，输入 `Let's make a react todo list`；特别记录 Codex 是否注入 bootstrap（决定 §3.3 决策矩阵走 A 还是 B）。
  - **类型 B（fork-only 行为等价）**：分别在 Claude Code CLI 与 Codex CLI 各跑一次同一输入；bootstrap 注入正文除 skill 标识从 `superpowers:using-superpowers` 替换为 `t-superpowers:t-using-superpowers` 外，与类型 A 等价。Cursor.app 与 Codex App 真实 transcript 不作为阶段一完成硬阻塞项。
  - **类型 C（official + fork co-installed）**：Claude Code CLI 的插件/技能清单同时显示两个独立条目，`/skills` 列表互不覆盖，单独禁用任一插件不影响另一插件功能（不验“行为等价”，双重 bootstrap 注入是预期行为）。Codex CLI co-installed 降级为后续验证项，记录限制即可。
- 决策回退：若类型 A 实测证明 Codex 不注入 bootstrap（必须有 transcript 证据），把 `.codex-plugin/plugin.json` 的 `hooks` 切回选项 B（`hooks: []`），删除 `hooks/hooks-codex.json`，并在验收记录里附 transcript。
- 最终人工 diff 复核重点：`SKILL.md` 除 frontmatter `name` 与运行时 skill id 外，不应出现行为塑造文本改写；manifest description/defaultPrompt 不应变化。
- 阶段一完成的硬指标（任一未通过即不进入阶段二）：
  - `tools/t-stage1-check.sh` 退出码 0
  - 上述 `git diff --exit-code` 6 个文件全部无 diff
  - 三个替换范围内测试套件全部通过
  - 三类并存验收（A 基线 / B fork-only 覆盖 Claude Code CLI + Codex CLI；C co-installed 覆盖 Claude Code CLI，Codex CLI co-installed 后续验证）transcript 均已存档

## Assumptions
- 阶段一不改 `description`、`defaultPrompt`、skill 规则文本、默认产物路径，也不新增 `t-archive`。
- `scripts/sync-to-codex-plugin.sh` 视为 upstream 发布辅助脚本，不纳入阶段一运行时命名迁移；若未来要发布到 Codex marketplace，单独规划 `plugins/t-superpowers` 同步链路。
- `tests/codex-plugin-sync/test-sync-to-codex-plugin.sh` 与 `scripts/sync-to-codex-plugin.sh` 联动；阶段一既然不动 `scripts/sync-to-codex-plugin.sh`，该测试套件本轮不在 fork-only 行为等价测试范围（自检脚本仍校验 `tests/` 内无 `superpowers:<x>` 残留，`x` 为 14 个 upstream skill 名或阶段二预留的 `archive`）。
- 不打开 PR；若后续要向上游提交或创建 PR，必须先执行仓库 `AGENTS.md` 要求的 PR 模板阅读、历史 PR 搜索、完整 diff 人审。
