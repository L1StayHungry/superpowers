---
change_id: 20260620-finishing-commit-reorg
created_at: 2026-06-20T11:52:47Z
updated_at: 2026-06-20T16:08:34Z
owner: lihuajun
---

# Spec: finishing 阶段自动重排 checkpoint 提交

## 背景

用户当前的实际工作流：让 t-superpowers 跑完完整开发流程（期间产生多个 checkpoint commit），
然后再手动"取消当前所有 commit + 使用本地 T Git Commit skill 重新组织提交"。最后这一步是额外负担。

希望把"整理成规范、可审查的逻辑提交"内置进 t-superpowers 开发流程，跑完即得到干净历史，
不必每次手动重排。

之前 GPT 给出的实现是"全程不提交、最后统一整理"，已被评审否决并丢弃，原因：

- 跨 8 个 skill 文件全局删掉提交，改动面过大。
- 丢掉了 superpowers 刻意保留的"频繁提交"安全纪律（长流程无中间还原点）。
- subagent-driven / inline 多任务流程下，逐任务 code review 失去隔离（`git diff` 把多个任务混在一起）。

## 目标

- 保留 upstream 的 checkpoint 提交纪律（频繁提交 = 安全点 + 逐任务 review 隔离）。
- 在 `t-finishing-a-development-branch` 增加一个"重排提交"步骤：把本地未 push 的 checkpoint
  commit 通过 `git reset --soft` 合回工作区，再调用用户本地的 `t-git-commit` skill 重新组织成
  逻辑提交。
- 重排是软依赖：检测不到 `t-git-commit` skill 时跳过该步骤，保留 checkpoint 原样。
- 破坏性操作（soft reset）限制在"未 push 的本地 commit + 显式确认"边界内。

## 非目标

- 不新增 bundled `skills/t-git-commit/`（直接复用用户本地的 `t-git-commit`，避免两份真理源）。
- 因此不改 `tools/t-stage1-check.sh`、不改 `docsDev/t-superpowers-installer.md`。
- 不改 `t-brainstorming` / `t-writing-plans` / `t-executing-plans` / `t-subagent-driven-development`
  / `t-using-git-worktrees` / `t-requesting-code-review`（保留 upstream 的提交与 SHA-range review 行为）。
- 不让 `t-git-commit` 自己改写历史；soft reset 由 finishing 拥有。
- 不做事务化备份 / sha256 / `.tmp` 回滚表（记录原始 HEAD + git soft reset 已足够）。
- 不自动处理"已 push 的 checkpoint"（检测到即拒绝重排，交给用户）。
- 不引入任何状态机 / frontmatter 状态字段。
- 不为 plan / executing-plans 增加"checkpoint 会被重排"的提示注释（按 YAGNI 砍掉；finishing 自文档化）。

## 设计

### 核心流程（保持不变 + 新增一步）

```text
实现期：每个任务照常 checkpoint 提交
        （安全点；逐任务 review 继续用 BASE_SHA..HEAD_SHA，隔离不丢）
                    ↓
finishing：验证测试 → 探测环境 → 确定 base 分支 → 【重排提交(新增)】→ 呈现选项 → 执行 → 清理
```

新步骤插在"确定 base 分支"之后、"呈现选项"之前——因为重排需要 fork-point，而 fork-point 依赖
已确定的 base 分支。（这也修正了被否决版本把该步骤放在 base 分支之前的顺序错误。）

### 新增步骤：Organize Commits（检测门控）

伪流程：

1. **检测 `t-git-commit` skill 是否可用**（环境中是否存在可调用、名为 `t-git-commit` 的 skill）。
   - 不可用 → 跳过整个重排，保留 checkpoint commits 原样；提示"未发现 t-git-commit skill，
     已保留逐任务提交，可手动整理"，进入"呈现选项"。
   - 可用 → 继续。
2. 解析本地集成分支与 fork-point 参考：
   - `INTEGRATION_BRANCH` 是最终 merge/PR 选项里的本地集成目标，用于 Step 5 的 `<base-branch>`。
   - `FORK_BASE_REF` 只用于 `git merge-base HEAD "$FORK_BASE_REF"`，可以是 `origin/main` 这类远端跟踪 ref。
   - 不得把当前 feature 分支 upstream 当成 integration branch。
3. **安全检查**（任一不满足 → 跳过重排、保留原样并报告原因）：
   - `git status --short` 必须为空；工作区不干净时跳过重排，避免后续
     `git reset --hard "$ORIG"` 丢弃未提交改动。
   - `<fork-point>..HEAD` 必须至少有 1 个本地 checkpoint commit；为空时跳过重排。
   - 先执行 `git fetch --all --prune` 刷新远端引用；fetch 失败时跳过重排，避免基于过期远端信息改写历史。
   - 对 `<fork-point>..HEAD` 内每个 commit 执行 `git branch -r --contains <sha>`；远端包含检查失败时
     保守跳过；除 `origin/HEAD` 这类符号引用外，只要命中任何远端分支，即视为已 push / 已共享 → 拒绝重排。
   - reset 目标必须等于 fork-point，不得越过它去碰 base 分支历史。
4. 记录原始 HEAD sha 与 tree sha（`ORIG=$(git rev-parse HEAD)`；
   `ORIG_TREE=$(git rev-parse HEAD^{tree})`），作为兜底和重排后等价性校验依据：重排中止可
   `git reset --hard "$ORIG"` 精确还原到重排前状态。
5. **展示**将被压平的 commit 列表（`git log --oneline <fork-point>..HEAD`）+ 当前未提交改动，
   要求**显式确认**，三选一：执行重排 / 保持原样 / 取消。停止等待，未确认不动手。
6. 确认"执行重排"后：`git reset --soft <fork-point>`
   （所有 feature 改动回到暂存区/工作区，内容不丢，仅丢弃 checkpoint 的提交边界）。
7. **调用本地 `t-git-commit` skill** 整理工作树：它分析工作树 → 提议提交计划 → 用户确认 → 提交，
   且 finishing 必须向它明确传递约束："只允许 `git add` / `git commit`，不得执行
   reset / rebase / checkout / clean / stash / force-push"。如果当前环境无法确认或传递该契约，
   finishing 跳过重排，保留 checkpoint 原样。
8. 校验重排结果：
   - `git status --short` 必须为空。
   - `git rev-parse HEAD^{tree}` 必须等于 `ORIG_TREE`，证明重排只改变提交边界、不改变最终文件内容。
   - `git log --oneline <fork-point>..HEAD` 必须显示新的逻辑提交，原 checkpoint 边界不再作为当前分支提交存在。
   任一校验失败时停止，不进入"呈现选项"；提示用户可重新触发 `t-git-commit` 或
   `git reset --hard "$ORIG"` 回到重排前 checkpoint 状态。

### 软依赖契约

- finishing 依赖本地 `t-git-commit` 的行为是"把当前工作树整理并提交"。
- finishing 拥有 soft reset；`t-git-commit` 不承担任何历史改写职责。
- finishing 调用 `t-git-commit` 时必须显式声明禁止 reset / rebase / checkout / clean / stash /
  force-push；该约束无法确认时，不做 soft reset。
- 检测不到该 skill 时，行为优雅降级为"保留 checkpoint"。

### integration branch 与 fork-point 解析

`INTEGRATION_BRANCH` 是最终 merge/PR 菜单里的本地集成分支，不能是 `origin/main` 这类远端跟踪
ref。`FORK_BASE_REF` 是计算 fork-point 的参考 ref，可以是远端默认分支。解析必须保守，按顺序尝试：

1. `origin/HEAD` 可解析时，取其本地分支名候选（例如 `origin/main` → `main`）；只有本地分支存在时，
   设置 `INTEGRATION_BRANCH=<local>`，`FORK_BASE_REF=<origin/local>`。
2. 否则尝试本地 `main` / `master`，同时设置 `INTEGRATION_BRANCH` 与 `FORK_BASE_REF` 为该本地分支。
3. 仍无法确定时询问用户确认本地 integration branch；不接受远端跟踪 ref 作为本地 merge 目标。

任一步如果无法计算 `git merge-base HEAD "$FORK_BASE_REF"`，或用户没有确认本地集成分支，跳过重排并
保留 checkpoint 原样。不得在 base 不明确时猜测 fork-point。

### code review 隔离（无需改动）

因为保留了 checkpoint 提交，`t-requesting-code-review` 继续用 `BASE_SHA..HEAD_SHA` 做逐任务
review，隔离性天然成立。这是相对被否决版本的关键修复点，且**不需要任何代码改动**。

## 边界与失败处理

- **已 push 的 commit**：`git fetch --all --prune` 失败时跳过重排；fetch 成功后用
  `git branch -r --contains <sha>` 检测 `<fork-point>..HEAD` 内每个 commit；检查失败时保守跳过，
  命中远端分支即拒绝，保留 checkpoint，报告原因。不尝试 force-push。
- **工作区不干净**：跳过重排，保留 checkpoint，不记录 `ORIG` / `ORIG_TREE`，避免恢复命令丢弃未提交改动。
- **无本地 checkpoint commit**：`git rev-list --count <fork-point>..HEAD` 为 0 时跳过重排。
- **detached HEAD / 外部托管 worktree**：沿用 finishing 现有的环境探测；无法可靠确定 base/fork-point
  时跳过重排。
- **base 分支不可解析**：跳过重排，保留原样并提示。
- **soft reset 后 `t-git-commit` 被取消或失败**：工作树改动仍在（soft reset 不丢内容），
  不进入 merge / PR / keep / discard 选项；提示用户可重新触发 `t-git-commit`，或用
  `git reset --hard "$ORIG"` 还原到重排前的 checkpoint 状态。
- **重排后内容不等价或工作区不干净**：停止 finishing，不呈现后续选项；按上一条失败路径处理。
- **用户选"保持原样"**：保留 checkpoint commits 不动，直接进入选项。

## 影响文件

| 文件 | 动作 |
|---|---|
| `skills/t-finishing-a-development-branch/SKILL.md` | 改写：新增 Organize Commits 步骤（检测门控 + 安全检查 + soft reset + 调用本地 t-git-commit），并相应调整后续步骤编号与 Common Mistakes / Never / Always 清单。 |

## 验收标准（可写成测试 / 手验项）

1. **降级**：环境无 `t-git-commit` skill 时，finishing 跳过重排，保留 checkpoint commits，明确提示未重排。
2. **正常重排**：feature 分支有多个未 push checkpoint，确认后执行 → `git reset --soft fork-point`
   → 调用 `t-git-commit` → 历史变为逻辑提交；`git status --short` 为空；
   `git rev-parse HEAD^{tree}` 与重排前 tree sha 相同；`git log` 中原 checkpoint 提交边界消失。
3. **拒绝已 push**：`<fork-point>..HEAD` 含已 push commit 时，finishing 拒绝重排、保留原样并说明原因，
   不产生 reset。
4. **确认门**：未得到"执行重排"的显式确认前，不执行任何 `git reset`。
5. **fetch 失败降级**：远端刷新失败时跳过重排，保留 checkpoint commits，不执行 `git reset`。
6. **base 不明确降级**：无法解析或确认 base/fork-point 时跳过重排，保留 checkpoint commits。
7. **本地集成分支门**：`origin/HEAD` 只能作为 `FORK_BASE_REF`；Step 5 的 `<base-branch>` 必须来自
   本地 `INTEGRATION_BRANCH`。
8. **`t-git-commit` 契约门**：无法检测或无法向 `t-git-commit` 传递"禁止历史改写"约束时跳过重排。
9. **dirty 降级**：`git status --short` 不为空时跳过重排，保留 checkpoint commits。
10. **空范围降级**：`git rev-list --count <fork-point>..HEAD` 为 0 时跳过重排。
11. **兜底还原**：记录了原始 HEAD；重排中止后可 `git reset --hard <orig>` 回到重排前状态。
12. **Archive Patch**：`tools/t-archive-precheck 20260620-finishing-commit-reorg` 在干净工作区中能识别
   `docsDev/specs/finishing/spec.md` 目标与 required scenario。
13. **回归**：`bash tools/t-stage1-check.sh` 仍通过（本次不新增 skill，不应触发命名空间回归变化）。

## 风险

- reorg 行为环境相关：未安装本地 `t-git-commit` 的同事 / CI 不会自动重排，会保留 checkpoint（已认可）。
- "检测 skill 是否可用"由 agent 判断，非确定性文件检查；需在 SKILL.md 中把判定与降级写清楚，避免误判。
- soft reset 仍是破坏性本地操作；安全边界（未 push + 显式确认 + 记录 orig HEAD）必须在 prompt 中明确，
  不能弱化。
- 远端共享状态依赖 `git fetch` 后的本地远端引用；fetch 失败必须降级为不重排，而不是继续猜测。
- 只有干净工作区才能重排；否则任何 restore 命令都可能误删用户未提交改动。

## Archive Patch

### finishing

Target: docsDev/specs/finishing/spec.md
Action: create

#### ADDED Requirements

##### Requirement: Finishing Can Reorganize Local Checkpoint Commits

The finishing workflow may reorganize local checkpoint commits into reviewable logical commits before presenting merge,
PR, keep, or discard options.

###### Scenario: Local unpushed checkpoints are reorganized after explicit confirmation

- Given implementation has completed with checkpoint commits on a feature branch
- And the checkpoint commits are not present on any remote branch
- And the working tree is clean
- And there is at least one local checkpoint commit after the fork-point
- And a callable `t-git-commit` workflow is available under a no-history-rewrite contract
- When finishing determines a reliable base branch and fork-point
- And the user explicitly confirms commit reorganization
- Then finishing may run `git reset --soft <fork-point>`
- And it must invoke `t-git-commit` to create logical commits
- And the final tree must equal the pre-reorganization tree
- And the working tree must be clean before finishing presents merge, PR, keep, or discard options

###### Scenario: Shared or uncertain history is not rewritten

- Given finishing cannot refresh remote refs
- Or any checkpoint commit is contained in a remote branch
- Or the base branch or fork-point cannot be reliably determined
- Or the no-history-rewrite contract for `t-git-commit` is unavailable
- When finishing reaches the organize-commits step
- Then it must skip reorganization
- And it must keep checkpoint commits unchanged
- And it must report the reason before continuing
