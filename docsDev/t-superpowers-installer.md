# T-Superpowers 安装与维护

`t-superpowers` 通过 4399 内部 npm 包分发，面向三个同等重要的目标载体：

```text
Claude Code
Codex
Cursor
```

三类载体共用同一个安装器入口，但落盘位置、宿主集成方式、更新方式和卸载语义不同。

## 0. npm 源配置

首次使用前，先配置 4399 内部 npm registry：

```bash
npm config set @4399:registry https://registry-npm.gz4399.com/
```

后续命令都通过最新版本执行：

```bash
npx @4399/tdata-t-superpowers@latest <command> <target>
```

可用命令：

```text
install    安装
update     更新
doctor     检查安装状态
uninstall  卸载
```

可用目标：

```text
claude
codex
cursor
all
```

`all` 表示批量执行三个目标，不代表任何一个目标更重要。当前执行顺序为：

```text
cursor -> claude -> codex
```

## 1. 快速安装全部目标

如果同一台机器同时使用 Claude Code、Codex 和 Cursor，可以一次安装并检查全部目标：

```bash
npx @4399/tdata-t-superpowers@latest install all
npx @4399/tdata-t-superpowers@latest doctor all
```

更新全部目标：

```bash
npx @4399/tdata-t-superpowers@latest update all
npx @4399/tdata-t-superpowers@latest doctor all
```

卸载全部目标：

```bash
npx @4399/tdata-t-superpowers@latest uninstall all
```

如果只使用其中一个宿主，建议只安装对应目标。

## 2. Claude Code

### 2.1 安装

Claude Code 目标通过 Claude Code 原生 plugin 命令安装。安装器会先生成本地 marketplace，再委托 `claude plugin` 完成安装：

```bash
npx @4399/tdata-t-superpowers@latest install claude
npx @4399/tdata-t-superpowers@latest doctor claude
```

默认安装 scope 是 `user`。如需项目级安装，显式传入 `--scope project`：

```bash
npx @4399/tdata-t-superpowers@latest install claude --scope project
npx @4399/tdata-t-superpowers@latest doctor claude --scope project
```

安装器生成的本地 marketplace 位置：

```text
~/.t-superpowers/claude-marketplace
```

marketplace 名称：

```text
t-superpowers-internal
```

Claude Code 中安装的 plugin 引用：

```text
t-superpowers@t-superpowers-internal
```

安装器实际委托的原生命令等价于：

```bash
claude plugin marketplace add ~/.t-superpowers/claude-marketplace --scope user
claude plugin install t-superpowers@t-superpowers-internal --scope user
```

安装后，重启 Claude Code 或开启一个新的 Claude Code 会话。

### 2.2 更新

```bash
npx @4399/tdata-t-superpowers@latest update claude
npx @4399/tdata-t-superpowers@latest doctor claude
```

Claude Code 更新会委托原生 marketplace / plugin 更新命令：

```bash
claude plugin marketplace update t-superpowers-internal
claude plugin update t-superpowers@t-superpowers-internal --scope user
```

如果安装时使用了项目级 scope，更新时也传入相同 scope：

```bash
npx @4399/tdata-t-superpowers@latest update claude --scope project
npx @4399/tdata-t-superpowers@latest doctor claude --scope project
```

### 2.3 卸载

```bash
npx @4399/tdata-t-superpowers@latest uninstall claude
```

卸载会委托 Claude Code 原生 plugin 命令：

```bash
claude plugin uninstall t-superpowers@t-superpowers-internal --scope user
```

如果安装时使用了项目级 scope，卸载时也传入相同 scope：

```bash
npx @4399/tdata-t-superpowers@latest uninstall claude --scope project
```

### 2.4 检查结果含义

| 状态 | 含义 | 建议处理 |
| --- | --- | --- |
| `PASS` | Claude Code 能看到 `t-superpowers-internal` marketplace，且已安装 plugin 版本与当前包内容一致。 | 重新打开 Claude Code 会话后使用。 |
| `UNKNOWN` | Claude Code 能看到 marketplace 和 plugin，但 JSON 输出缺少 marketplace 归属或版本信息，安装器无法完全证明关联关系。 | 重新打开 Claude Code 后显式请求一次 `t-superpowers`；必要时等待 Claude CLI 输出补齐后再运行 `doctor claude`。 |
| `FAIL` | 找不到 marketplace/plugin、plugin 来源不符合预期、版本不一致，或本机没有可用的 `claude` 命令。 | 确认 `claude` 在 `PATH` 中，然后重新执行 `install claude` 或 `update claude`。 |

## 3. Codex

### 3.1 安装

Codex 目标把 `t-*` skills 复制到 Codex skills 目录：

```bash
npx @4399/tdata-t-superpowers@latest install codex
npx @4399/tdata-t-superpowers@latest doctor codex
```

默认目录：

```text
~/.codex/skills/
```

如果设置了 `CODEX_HOME`，则使用：

```text
${CODEX_HOME}/skills/
```

安装器会写入管理凭据文件：

```text
.t-superpowers-install.json
```

如果目标目录中已存在非安装器管理的同名 `t-*` skill，安装会要求显式传入 `--adopt`，避免误覆盖用户已有内容。

### 3.2 更新

```bash
npx @4399/tdata-t-superpowers@latest update codex
npx @4399/tdata-t-superpowers@latest doctor codex
```

如果当前 Codex skills 已由安装器管理，更新会先备份旧版本，再替换为当前 npm 包中的 skills。若版本已经一致，默认不会重复写入；需要强制更新时使用：

```bash
npx @4399/tdata-t-superpowers@latest update codex --force
```

### 3.3 卸载

```bash
npx @4399/tdata-t-superpowers@latest uninstall codex
```

卸载只移除安装器凭据中记录的托管 `t-*` skill 目录，并删除 `.t-superpowers-install.json`。

如果 Codex skills 根目录不是安装器管理的目录，卸载会要求显式传入 `--adopt`，避免误删用户手工维护的 skills：

```bash
npx @4399/tdata-t-superpowers@latest uninstall codex --adopt
```

### 3.4 检查结果含义

`doctor codex` 会检查安装凭据、版本、关键 skill 文件和每个 `SKILL.md` 的 frontmatter。

当前 Codex skills adapter 不安装 session-start hook，因此检查成功时会返回 `WARN`：

```text
Codex skills adapter is valid; session-start hook injection is not installed by the skills adapter
```

这个 `WARN` 表示 skills adapter 本身有效，但 Codex 不具备与 Cursor/Claude Code 完全相同的 session-start 注入方式。

## 4. Cursor

### 4.1 安装

Cursor 目标会把完整 plugin payload 复制为一个物理目录：

```bash
npx @4399/tdata-t-superpowers@latest install cursor
npx @4399/tdata-t-superpowers@latest doctor cursor
```

目标目录：

```text
~/.cursor/plugins/local/t-superpowers
```

不要把 Cursor 目标安装成 symlink。实际 smoke 结果显示，Cursor 能稳定识别物理目录，但不稳定激活 `/add-plugin` 创建的 symlink。

如果目标目录已存在且不是安装器管理的目录，安装会要求显式传入 `--adopt`，避免误覆盖用户已有 plugin：

```bash
npx @4399/tdata-t-superpowers@latest install cursor --adopt
```

安装后，重启 Cursor 并开启新的 Agent 会话。

### 4.2 更新

```bash
npx @4399/tdata-t-superpowers@latest update cursor
npx @4399/tdata-t-superpowers@latest doctor cursor
```

如果当前 Cursor plugin 已由安装器管理，更新会先备份旧目录，再替换为当前 npm 包内容。若版本已经一致，默认不会重复写入；需要强制更新时使用：

```bash
npx @4399/tdata-t-superpowers@latest update cursor --force
```

如果目标目录不存在或是 symlink，`update cursor` 会退化为一次安装流程。

### 4.3 卸载

```bash
npx @4399/tdata-t-superpowers@latest uninstall cursor
```

卸载会移除整个 Cursor plugin 目标目录：

```text
~/.cursor/plugins/local/t-superpowers
```

如果目标目录不是安装器管理的目录，卸载会要求显式传入 `--adopt`，避免误删用户手工维护的 plugin：

```bash
npx @4399/tdata-t-superpowers@latest uninstall cursor --adopt
```

### 4.4 检查结果含义

`doctor cursor` 会检查：

```text
.cursor-plugin/plugin.json
skills/t-brainstorming/SKILL.md
skills/t-using-superpowers/SKILL.md
hooks/hooks-cursor.json
hooks/session-start
.t-superpowers-install.json
```

检查通过后，仍需要重启 Cursor 并开启新的 Agent 会话才能确认宿主已加载最新 plugin。

## 5. 通用选项

### 5.1 dry-run

所有目标都支持 `--dry-run`，用于预览将要执行的操作，不修改本机配置：

```bash
npx @4399/tdata-t-superpowers@latest install claude --dry-run
npx @4399/tdata-t-superpowers@latest update codex --dry-run
npx @4399/tdata-t-superpowers@latest uninstall cursor --dry-run
```

### 5.2 json 输出

需要脚本消费检查结果时，可以使用 `--json`：

```bash
npx @4399/tdata-t-superpowers@latest doctor all --json
```

### 5.3 adopt

`--adopt` 表示用户明确允许安装器接管已有目标。只在确认已有目录确实属于 `t-superpowers` 时使用。

适用场景包括：

```text
Cursor 目标目录已存在但缺少安装器凭据
Codex skills 目录已有同名 t-* skill
卸载一个没有安装器凭据但确认属于 t-superpowers 的目标
```

### 5.4 force

`--force` 用于在版本已经一致时仍重新执行更新：

```bash
npx @4399/tdata-t-superpowers@latest update cursor --force
npx @4399/tdata-t-superpowers@latest update codex --force
```

## 6. 使用边界

安装完成后，简单任务不需要进入 `t-superpowers` 流程。

适合直接处理的任务：

```text
小文案修改
小样式修改
小配置修改
单文件机械改动
纯问答
纯代码阅读
```

适合显式使用 `t-superpowers` 或某个 `t-*` skill 的任务：

```text
多文件功能
复杂 bugfix
用户可见行为变化
需要计划和验证记录的工作
需要归档到 docsDev/specs/ 的复杂变更
```

示例：

```text
用 t-superpowers 帮我规划首页 PDF 导出功能，先不要实现。
```

归档必须由用户显式提出，并带上具体 change-id，例如：

```text
归档 20260515-npm-installer-distribution
```

## 7. Skill 一览

| Skill | 基本功能 | 适合场景 | 不适合场景 |
| --- | --- | --- | --- |
| `t-using-superpowers` | 说明触发边界，并引导访问其它 `t-*` skills。 | 会话启动、显式 `t-superpowers` 请求、判断是否需要复杂流程。 | 可以直接完成的简单编辑。 |
| `t-brainstorming` | 澄清意图、比较方案，并把复杂需求整理成约定规格。 | 多文件功能、行为变化、需求不清的问题。 | 文案、样式、配置、问答、纯代码阅读。 |
| `t-writing-plans` | 把已确认的规格转成可执行计划。 | 已有规格，需要拆分步骤、验证和交接。 | 可以直接实现的小改动。 |
| `t-executing-plans` | 按计划顺序执行，并在检查点验证。 | 已有可执行计划，需要逐项落地。 | 需求仍不清或需要重新设计的工作。 |
| `t-subagent-driven-development` | 使用并行 agents 执行可安全拆分的计划。 | 多个相互独立的子任务。 | 强耦合或必须串行推进的任务。 |
| `t-test-driven-development` | 针对行为变化或 bugfix 执行 red-green-refactor。 | 可以用失败测试证明修复的复杂变更。 | 纯文档、文案、样式或机械改动。 |
| `t-systematic-debugging` | 复现症状、收集证据、定位根因后再修复。 | 复杂 bug、失败测试、异常行为、根因不明问题。 | 已明确的小改动或只读调查。 |
| `t-verification-before-completion` | 在声称完成前要求新鲜验证证据。 | 最终确认修复、通过或可交付之前。 | 尚未实现的早期讨论。 |
| `t-requesting-code-review` | 请求聚焦的代码审查。 | 重要功能、高风险变更、合并前检查。 | 极小且低风险的改动。 |
| `t-receiving-code-review` | 严谨评估 review 意见后再决定是否修改。 | review 意见不清、存在风险或需要技术判断。 | 明显拼写错误等无需争议的修改。 |
| `t-dispatching-parallel-agents` | 把独立任务拆给多个并行 agents。 | 两个以上可独立研究或实现的任务。 | 共享状态多或依赖顺序明确的任务。 |
| `t-using-git-worktrees` | 确保较大开发工作在隔离 workspace 中推进。 | 较大功能或计划执行，不应干扰当前工作区。 | 当前 workspace 已合适的小改动。 |
| `t-finishing-a-development-branch` | 在实现和验证后指导最终集成选择。 | 工作已实现并验证，准备合并、PR 或清理。 | 尚未完成或验证失败的工作。 |
| `t-writing-skills` | 按 skill 开发纪律创建、修改和验证 skills。 | 新增或修改 `t-*` skills。 | 与 skills 无关的普通代码修改。 |
| `t-archive` | 把已验收变更归档到长期 `docsDev/specs/` 记录。 | 用户显式要求归档某个 change-id。 | verification 后自动清理，或“看起来可以了”等模糊同意。 |
