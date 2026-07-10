---
change_id: 20260710-worktree-finishing-v6
created_at: 2026-07-10T00:00:00+08:00
updated_at: 2026-07-10T00:00:00+08:00
owner: lihuajun
---

# Worktree And Finishing v6 Implementation Plan

## Global Constraints

- 保留 `t-*` 命名空间与复杂需求触发边界。
- 不修改 `vendor/superpowers/`、版本号、`t-archive`、`t-verification-before-completion`。
- 不自动 push、创建 change request、merge、discard 或 cleanup。
- 不削弱 5314938 引入的 checkpoint commit 重组安全门禁。

## Task 1: 建立旧行为基线

**Files:**
- Create: `tests/claude-code/test-worktree-finishing-contract.sh`
- Create: `docsDev/changes/20260710-worktree-finishing-v6/transcripts/red.txt`

**Interfaces:**
- Consumes: 两个 skill 的 Markdown 契约。
- Produces: 可独立运行且可接入现有 runner 的 contract test。

- [x] 写入目录选择、gitignore、重组安全门、forge 中立契约。
- [x] 在当前旧 skill 上运行并记录 RED；确认失败来自待同步行为而不是测试错误。

## Task 2: 本地化 worktree 选择

**Files:**
- Modify: `skills/t-using-git-worktrees/SKILL.md`

**Interfaces:**
- Consumes: 用户 worktree 偏好、项目目录状态、harness native worktree capability。
- Produces: 已忽略的项目内手工 worktree，或由用户显式选择的位置。

- [x] 移除旧全局 fallback。
- [x] 保留 native tool 优先、隔离检测、gitignore 校验和 baseline test。

## Task 3: Forge 中立 finishing

**Files:**
- Modify: `skills/t-finishing-a-development-branch/SKILL.md`

**Interfaces:**
- Consumes: 用户收尾选择、branch/fork-point/remote refs、当前 harness forge capability。
- Produces: 安全 push 结果，以及可用时由 forge 工具创建的 change request。

- [x] 保留 fork-point、shared commit、soft-reset、`t-git-commit` 和 tree 门禁。
- [x] 移除旧全局目录清理所有权与 `gh pr create`。
- [x] 仅在用户选择后 push，再使用可用 forge 工具；不可用时报告并停止。

## Task 4: 回归与提交

**Files:**
- Modify: `tests/claude-code/run-skill-tests.sh`
- Create: `docsDev/changes/20260710-worktree-finishing-v6/transcripts/green.txt`

**Interfaces:**
- Consumes: focused contract、阶段一检查、安装器、构建与打包命令。
- Produces: fresh verification evidence 和单一 focused commit。

- [x] focused GREEN 与 runner 回归。
- [x] stage1、installer、build、pack、bash syntax、diff check。
- [x] 提交 `feat: localize worktree and finishing workflows`。
