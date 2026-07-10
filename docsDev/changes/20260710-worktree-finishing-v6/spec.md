---
change_id: 20260710-worktree-finishing-v6
created_at: 2026-07-10T00:00:00+08:00
updated_at: 2026-07-10T00:00:00+08:00
owner: lihuajun
---

# Spec: worktree 本地化与 forge 中立收尾

## 背景

官方 v6.1.1 将手工 git worktree 的默认位置收敛到项目目录，并将收尾阶段的 PR 创建从硬编码
GitHub CLI 中解耦。本 fork 需要吸收这两点，同时保留既有的 checkpoint commit 重组安全门禁。

## 目标

- 手工 worktree 仅使用用户显式偏好、已有项目目录或默认 `.worktrees/`。
- 项目内 worktree 在创建前必须通过 gitignore 安全校验。
- finishing 保留 fork-point、远端共享提交、显式 soft reset、`t-git-commit` 限权和 tree 等价门禁。
- push 只在用户选择对应收尾选项后执行；change request 由当前 harness 可用的 forge 工具创建。
- 清理仅认领项目内 `.worktrees/` 或 `worktrees/`，不认领旧全局目录或 harness 管理目录。

## 非目标

- 不修改 vendor 快照、版本号、`t-archive` 或 `t-verification-before-completion`。
- 不自动 push、创建 PR/MR、merge 或清理分支。
- 不删除 finishing 的本地 checkpoint commit 重组能力。
- 不新增特定代码托管平台依赖。

## 风险

- cleanup ownership 仍通过“路径位于当前仓库 `.worktrees/` 或 `worktrees/` 下”推断。这依赖
  manual fallback 遵守同一目录约定；本阶段不新增 ownership marker，也不扩大 cleanup 范围。

## 需求

### Requirement: 手工 worktree 位置本地化

目录选择顺序必须为：用户已声明的显式偏好、已有 `.worktrees/`、已有 `worktrees/`、默认
`.worktrees/`。任何项目内目录都必须先验证已被 gitignore；未忽略时先提交 `.gitignore` 规则。

### Requirement: finishing 的历史重组安全门禁保持不变

仅当 fork-point 可靠、工作树干净、远端引用刷新成功、feature commits 未被远端分支包含且用户明确
确认时，才允许 soft reset。`t-git-commit` 只可 add/commit，完成后 tree 必须与重组前一致。

### Requirement: change request 操作 forge 中立

用户选择 push/change-request 选项后，workflow 先做非 force push。push 成功后，仅通过当前 harness
已经提供的 forge 工具创建 pull request 或 merge request；没有可用工具时停止于已 push 状态并报告。

## Archive Patch

### worktree-finishing

Target: docsDev/specs/worktree-finishing/spec.md
Action: create

#### ADDED Requirements

##### Requirement: Project-local Worktrees And Forge-neutral Finishing

Manual worktrees use an explicit user preference or a project-local directory, while finishing preserves history
safety gates and delegates change-request creation to an available forge integration.

###### Scenario: Safe project-local worktree and provider-neutral finish

- Given no harness-native worktree tool is available
- When the user authorizes an isolated workspace without an explicit external location
- Then the workflow uses an ignored project-local worktree directory
- And finishing never rewrites shared commits without explicit confirmation
- And push and change-request creation only run after the user chooses that finishing option
- And change-request creation uses an available forge tool rather than a hardcoded provider CLI
