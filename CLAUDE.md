# t-superpowers 二次开发指导

## 0. 仓库定位

本仓库是基于 `obra/superpowers` fork 的内部二次开发仓库。

本仓库的默认目标不是给官方 Superpowers 提 PR，而是维护一个适合团队使用的内部发行版：

```text
t-superpowers
```

`t-superpowers` 的目标是保留 Superpowers 的底层工程纪律，同时改造它不适合团队落地的部分。

默认工作模式：

```text
internal fork development
```

只有用户明确要求以下意图时，才进入 upstream PR mode：

```text
prepare upstream PR
contribute back to upstream
open PR to obra/superpowers
给官方提 PR
贡献回官方
```

进入 upstream PR mode 时，必须先读取：

```text
docs/upstream-contrib.md
.github/PULL_REQUEST_TEMPLATE.md
```

普通内部二次开发不得默认套用 upstream PR 规则。

---

## 1. 二次开发初衷

我们认可 Superpowers 的底层工程纪律，包括：

* 需求澄清与方案比较
* 计划先行
* 测试驱动开发
* 系统化调试
* 完成前验证
* subagent 分工执行
* worktree 隔离
* code review
* skill 本身按工程方式迭代

但原版 Superpowers 的默认行为并不完全适合我们的团队：

* 触发过于频繁，简单需求也容易进入完整流程。
* 默认产物路径是 `docs/superpowers/`，不符合团队沉淀方式。
* 缺少稳定的长期规格库归档机制。
* 部分门禁依赖 prompt 自觉，不够确定。
* 团队需要同时兼顾 Codex、Cursor、Claude Code。
* 我们希望复杂需求高质量推进，简单需求仍能保持轻量。

因此，本 fork 的核心目标不是削弱 Superpowers，而是把它改造成更适合团队使用的工程化版本。

---

## 2. 最终期望状态

最终希望 `t-superpowers` 达到以下状态：

```text
简单需求：
  使用 Agent 普通模式或 Plan Mode
  不强制进入 t-superpowers

复杂需求：
  使用 t-superpowers
  进入 t-* skill 链路
  产生可追踪的 spec / plan / verification / acceptance / archive 记录
```

长期目标：

* `t-superpowers` 与官方 `superpowers` 命名空间独立。
* 可与官方版并存，但团队实际使用时应二选一启用。
* 简单任务不过度流程化。
* 复杂任务能稳定继承 Superpowers 的工程纪律。
* 运行时产物统一进入 `docsDev/`。
* 长期规格沉淀进入 `docsDev/specs/`。
* 归档行为有确定性校验和事务保护。
* 验收状态不能由 AI 自行声称。
* subagent 必须继承路径、TDD、验证和归档纪律。
* Codex / Cursor / Claude Code 的行为边界尽量一致。

---

## 3. 当前状态

阶段一命名空间迁移已经完成。

阶段一目标是让 fork 成为独立的 `t-superpowers` 命名空间，并在单装时尽量保持与官方版行为等价。

阶段一完成后，预期状态包括：

```text
skills/<name>/          -> skills/t-<name>/
superpowers:<skill>     -> t-superpowers:t-<skill>
plugin name             -> t-superpowers
upstream reference       -> vendor/superpowers/
```

阶段一验收记录见：

```text
docs/二开规划/阶段一验收记录.md
```

后续能力拓展规划见：

```text
docs/二开规划/二次开发规划.md
```

根级 `AGENTS.md` 只记录长期原则，不展开具体阶段施工清单。

---

## 4. 长期产物路径原则

`t-superpowers` 的新运行时产物应统一使用：

```text
docsDev/
```

复杂需求变更工件：

```text
docsDev/changes/<change-id>/spec.md
docsDev/changes/<change-id>/plan.md
docsDev/changes/<change-id>/transcripts/
```

长期共享规格库：

```text
docsDev/specs/<capability>/spec.md
```

归档快照：

```text
docsDev/archive/<change-id>/
```

skill 测试、回归、压力用例：

```text
docsDev/skill-tests/
```

禁止作为新产物路径：

```text
docs/superpowers/
openspec/
t-dev/
```

说明：

* `docs/superpowers/` 只允许作为 upstream 历史、vendor 参考或迁移说明出现。
* `openspec/` 不再作为 `t-superpowers` 的运行时或规格库路径。
* 旧的 `t-dev` 原型不再作为当前 fork 的目标架构。

---

## 5. 触发边界原则

`t-superpowers` 应用于复杂开发工作，而不是所有工作。

应该进入 `t-superpowers` 的情况：

* 多文件改动
* 新功能
* 用户可见行为变化
* 复杂 bugfix
* 根因不明的问题
* 涉及接口、权限、数据、并发、迁移、支付、认证等高风险区域
* 用户明确要求使用 `t-superpowers` 或某个 `t-*` skill

不应该强制进入 `t-superpowers` 的情况：

* 小文案修改
* 小样式修改
* 小配置修改
* 单文件机械改动
* 纯问答
* 纯代码阅读
* 普通 Agent Plan Mode
* 用户明确要求直接实现

模糊情况：

* 不要自动进入完整流程。
* 先判断是否真的复杂。
* 必要时询问用户是否希望走 `t-superpowers`。
* 不要为了使用 skill 而使用 skill。

Codex 注意事项：

* Codex 可能根据 skill frontmatter `description` 隐式触发 skill。
* 调整触发边界时，不能只改 bootstrap 文本，也要检查关键 `SKILL.md` 的 `description`。
* 不要简单依赖 `allow_implicit_invocation: false` 解决所有问题，除非明确决定复杂需求也必须显式触发。

---

## 6. 保留的 Superpowers 工程纪律

二次开发不得把 Superpowers 改成“只有路径不同的普通 prompt”。

应继续保留并强化这些纪律：

### 需求澄清

复杂需求实现前，应明确：

* 背景
* 目标
* 非目标
* 边界
* 成功标准
* 方案取舍
* 风险点

### 计划先行

复杂需求实现前，应有可执行计划：

* 涉及文件
* 任务拆分
* 验证方式
* 风险与回滚
* 是否需要 subagent / worktree / review

### 测试驱动

对行为变更和 bugfix，应优先采用：

```text
先复现或失败测试
再最小实现
再验证通过
```

如果无法写自动化测试，必须说明原因，并提供可复现的替代验证方式。

### 系统化调试

复杂 bug 不应靠猜：

* 先复现
* 收集证据
* 定位根因
* 验证假设
* 再修复

### 完成前验证

不得在没有新鲜验证证据的情况下声称：

```text
完成
已修复
测试通过
可以归档
```

验证记录应包含：

* 时间
* 命令
* 退出码
* 关键输出
* 结论
* 覆盖的任务或变更点

### subagent 纪律

subagent 必须继承主流程约束：

* 路径约束
* TDD 约束
* verification 约束
* 不写 `docs/superpowers/`
* 不自行声称验收通过
* 不跳过计划或验证

---

## 7. 状态与验收原则

复杂需求**不引入状态机**。`plan.md` frontmatter 只保留最小元数据：

```text
change_id
created_at
updated_at
owner
```

原则：

* 实现是否完成，靠 `t-verification-before-completion` skill 的新鲜证据判断，不靠 frontmatter 状态字段。
* 归档由人工启动；agent 不得自行判定"看起来用户同意了"就触发归档。
* 不引入 `status` / `status_history` / `blocked_reason` / `unblocked_reason` / `acceptance_evidence` / `pending_acceptance_evidence` / `archive_failure` 等字段。
* 不引入 `verified → accepted → archived` 等状态转移规则。
* 不做 conversation 类验收的 sha256 / transcript 核验；不做 PR 状态在线核验。

为什么不做：

* 10 人内部团队，PR review + 显式人工指令足以扛住"是否真的可以归档"。
* 状态机和严格 acceptance 校验的复杂度，远高于它们在过去 changes 里实际帮我们挡掉的问题数量。
* `git log` 和 PR 历史已经是状态变化的可追踪记录，不需要在 frontmatter 里另起一份。

---

## 8. 归档原则

归档的目标是把已验收的复杂变更沉淀为长期团队规格（`docsDev/specs/<capability>/spec.md`）。

归档由 `t-archive` skill 包装，**必须由用户显式触发**（"归档 <change-id>" / "走 t-archive" / "把这个 change 沉淀到 specs"）。skill 内部按下面五步执行，全部落到一个 git commit 内：

```text
1. tools/t-archive-precheck <change-id>
2. 解析 docsDev/changes/<change-id>/spec.md 末尾的 Archive Patch 块
3. 合并到 docsDev/specs/<capability>/spec.md（Action=create / update；
   并在 long-term spec 的 Change History 顶部 append 一条）
4. git mv docsDev/changes/<change-id> docsDev/archive/<change-id>
5. git add docsDev/specs docsDev/archive
   git commit -m "archive <change-id>: <summary>"
```

`tools/t-archive-precheck` 只做下列检查：

* `docsDev/changes/<change-id>/` 与 `spec.md` 存在。
* `spec.md` 末尾含 `## Archive Patch` 块且字段齐全（Target / Action / Requirement / Scenario）。
* Archive Patch 的 Target 经过路径规范化后严格位于 `docsDev/specs/` 之内（解析 symlink；禁止 `..` / 绝对路径；禁止 target 等于 specs 根）。
* `docsDev/archive/<change-id>/` 不存在（幂等）。
* `git status --porcelain` 为空（工作区干净，确保 `git reset` 可作为安全兜底）。

触发边界（写入 t-archive SKILL frontmatter description）：

* 只在用户**显式**说"归档"且带 change-id 时触发。
* **不允许**在 `t-verification-before-completion` 通过后自动接管。
* **不允许**根据"看起来 ok 了" / "可以了" 等模糊语义推断归档意图。
* **不允许**把 t-archive 串到 t-using-superpowers 的"复杂需求自动链路"里。

失败兜底：

* 第 1 步 precheck 退出非零：skill 报告退出码语义（越界 / 幂等 / 工作区脏 / 字段缺失），不动任何文件。
* 第 2-5 步任一失败：`git reset --hard HEAD && git clean -fd`（精确回到归档前的 HEAD，因 precheck 已确认起点干净）。
* commit 之后才发现错：用户决定 `git revert <archive-commit>` 或新 commit 修正；skill **不自动重试**。

明确**不做**：

* 事务化备份（`.tmp/` 目录 + checksum + atomic rename + 按步骤分类回滚表）。
* `archive_failure` frontmatter 块、状态保持 accepted 等复杂回滚语义。
* 失败后自动重试、自动破坏性清理。
* 并发 sha256 校验（precheck 工作区干净 + git mv 在单 commit 内已经足够）。

为什么这么做：

* skill 包装解决了"用户记不住一串命令、不想手动 merge markdown"的真实体验问题。
* skill 内部仍然轻量：调一个 ≤ 100 行 precheck + 几个 git 命令 + Markdown merge，没有事务化复杂度。
* git 已经天然提供原子提交、完整历史、`reset --hard` 回滚兜底；再加一层事务化备份只是在用户和 git 之间塞了一层间接。

---

## 9. 确定性工具原则

确定性工具只用在**真正不能靠 prompt 自述**的位置，且每个工具职责单一、实现轻量。

当前在用 / 计划中的工具：

```text
tools/t-stage1-check.sh    # 阶段一命名空间回归（已实现）
tools/t-archive-precheck   # 阶段二归档前检查（计划中，≤ 100 行）
```

`tools/t-archive-precheck` 的职责见 §8。除此之外**不再引入**：

* `tools/t-validate` 统一校验器（state-transition API、退出码语义、proposed-frontmatter 注入等）。
* `tools/t-state` 状态机工具。
* conversation 类 acceptance 的 transcript + sha256 核验工具。
* PR 在线状态核验工具。

原则：

* 关键命名空间约束（阶段一）继续靠 `tools/t-stage1-check.sh` + CI。
* 路径泄漏 / `superpowers:<x>` 残留这类回归，靠 CI 的 `rg` grep 检查即可，不需要单独 CLI。
* 触发收敛、verification、subagent 纪律继续靠 skill prompt 本身，**不**为它们另起确定性校验器。
* 如果有人想新加一个工具，先回答："它解决的具体问题在过去 3 个月内的 changes 里出现过几次？"答案是零就不加。

---

## 10. upstream 参考与同步原则

`vendor/superpowers/` 是 upstream 参考快照。

原则：

* 不直接修改 `vendor/superpowers/`。
* 刷新 upstream 时更新 `vendor/superpowers/UPSTREAM_COMMIT`。
* upstream 内容用于对照、diff、rebase 和移植。
* 不把 fork-specific 规则提交给官方。
* 不把 `t-superpowers` 重命名、`docsDev/`、团队路径、归档机制等内部内容 upstream。

同步 upstream 时：

```text
1. 刷新 vendor/superpowers/
2. 记录 UPSTREAM_COMMIT
3. 对比 upstream skill 变化
4. 判断是否移植到 t-* skill
5. 移植后运行相关回归
```

---

## 11. upstream PR Mode

默认不要进入 upstream PR mode。

只有用户明确要求时才进入，例如：

```text
prepare upstream PR
contribute this back
给官方提 PR
```

进入后必须：

* 读取 `docs/upstream-contrib.md`
* 读取 `.github/PULL_REQUEST_TEMPLATE.md`
* 搜索已有 PR / issue
* 确认问题真实存在
* 确认改动适合 upstream core
* 排除 fork-specific 内容
* 展示完整 diff
* 等待用户明确批准

如果当前改动属于内部 fork 需求，不要尝试 upstream。

---

## 12. 迭代原则

每次迭代应小而可审。

优先拆成：

```text
一个路径迁移
一个触发收敛
一个轻量工具（如 tools/t-archive-precheck）
一个归档约定调整
一个 harness metadata 调整
一个测试或 fixture
```

不要把多个无关目标塞进一次修改。

修改前：

* 读取相关源码。
* 读取 `docs/二开规划/二次开发规划.md` 中相关章节。
* 如果触碰阶段一假设，读取 `docs/二开规划/阶段一验收记录.md`。
* 明确本轮目标和非目标。

修改中：

* 不要修改无关文件。
* 不要把规划文档当成代码随意重写。
* 不要改 `vendor/superpowers/`。
* 不要引入与团队目标无关的 upstream PR 规则。
* 不要保留旧路径和新路径双事实源。

修改后：

* 说明改了哪些文件。
* 说明属于哪个目标。
* 说明运行了哪些验证。
* 说明没有运行哪些验证以及原因。
* 说明剩余风险。

---

## 13. 测试与验收原则

不要把“提示词看起来清楚”当成完成。

根据修改范围选择验证：

### 命名空间、manifest、hook、skill path

运行：

```bash
bash tools/t-stage1-check.sh
```

### 触发边界

至少验证：

```text
简单请求不进入 t-superpowers
复杂请求能进入 t-superpowers
Codex description 不误触发重 skill
```

### 路径迁移

至少验证：

```text
不再写 docs/superpowers/
新产物进入 docsDev/changes/<change-id>/
归档目标进入 docsDev/archive/<change-id>/
长期规格写入 docsDev/specs/<capability>/spec.md
```

### 归档

归档全部通过 `t-archive` skill 触发，验证项：

```text
t-archive 自动触发拦截：verification 通过 / "看起来 ok 了" 等模糊语义
                       不得自动调用 t-archive；无 archive commit 产生
t-archive 显式触发 + Archive Patch Target 越界（含 ".." / symlink /
                       target 等于 specs 根）：skill 报告 precheck
                       退出码 3；无文件被修改
t-archive 显式触发 + 缺 Scenario / Action / Requirement：skill 报告 precheck
                       退出码 2；无文件被修改
t-archive 显式触发 + docsDev/archive/<change-id>/ 已存在：skill 报告
                       precheck 退出码 4；无文件被修改
t-archive 显式触发 + 工作区不干净：skill 报告 precheck 退出码 5；
                       不动任何文件，不自动 stash
t-archive 合法归档：长期 spec 含 ADDED/MODIFIED 内容；
                   docsDev/changes/<change-id>/ 消失；
                   docsDev/archive/<change-id>/ 出现；
                   git log 有一条 archive commit
```

> 归档相关的"事务化失败回滚"、"原状态保持 accepted"、"`.tmp` 残留" 等场景对应的设计已经被砍掉，**不再作为验证项**。

### subagent

subagent 必须继承主流程的路径、TDD、verification 纪律，但**不引入**强制 dispatch prompt 模板。验证靠对应 skill 自身的 prompt + PR review，不为它单独建测试套件。

---

## 14. 禁止事项

除非用户明确要求，否则不要：

```text
- 把普通内部二次开发当成 upstream PR
- 修改 vendor/superpowers/
- 写入 docs/superpowers/ 作为新产物
- 写入 openspec/
- 恢复旧 t-dev v1 工作流
- 创建 t-dev/
- 把阶段计划全文塞进 AGENTS.md
- 没有验证证据就声称完成
- 让 agent 自行判定"看起来用户同意了"就触发 t-archive
- 在 t-verification-before-completion 通过后自动接管 t-archive
- 把 t-archive 串到 t-using-superpowers 的"复杂需求自动链路"里
- 在 plan.md frontmatter 上偷偷加回 status / status_history /
  acceptance_evidence 等已被显式砍掉的字段
- 重新引入 tools/t-validate / tools/t-state 等大型校验器
- 给 t-archive skill 内部塞回事务化（backup + sha256 + atomic rename +
  按步骤回滚表 + archive_failure 块）
- 重新引入 conversation sha256 / PR 在线核验
- 在 working tree 不干净时执行 t-archive
- t-archive 失败后自动重试或破坏性清理
- 一次性修改多个无关 skill
- 让 subagent 脱离主流程的路径 / TDD / verification 纪律
```

---

## 15. 工作汇报格式

完成修改后按以下格式汇报：

```text
Summary:
- ...

Files changed:
- ...

Validation:
- ...

Risks / follow-up:
- ...
```

如果被阻塞：

```text
Blocked because:
- ...

What I verified:
- ...

Need from human:
- ...
```

如果是计划：

```text
Scope:
- ...

Non-goals:
- ...

Implementation steps:
- ...

Validation:
- ...

Risks:
- ...
```

---

## 16. Definition of Done

一次内部二次开发迭代完成，应满足：

```text
1. 目标单一、范围清楚。
2. 不破坏 t-superpowers 命名空间。
3. 不写 forbidden paths。
4. 不污染 vendor/upstream reference。
5. 有必要的确定性校验或测试证据。
6. 有 before/after 行为说明。
7. 有风险说明。
8. 用户或 reviewer 能从 diff 看懂为什么改。
```

不要把“模型这次答对了”当成长期质量保证。
要把规则沉淀到 skill、hook、轻量工具、CI 检查、fixture 或文档中。
