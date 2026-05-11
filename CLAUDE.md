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

复杂需求的状态应由 `plan.md` frontmatter 或确定性状态工具维护。

状态推进必须可追踪。

推荐状态：

```text
draft
ready
running
implemented
blocked
verified
accepted
archived
```

原则：

* AI 可以根据实现和验证证据推进到 `verified`。
* AI 不得自行推进到 `accepted`。
* `accepted` 必须来自人类验收证据。
* `archived` 只能在归档事务完成后出现。
* 状态变化必须记录历史。
* 关键状态变化应通过确定性校验器或状态转移工具完成。

验收证据可以来自：

```text
conversation
pr
ticket
```

如果证据无法在线验证，只能记录为 pending，不能直接 accepted。

---

## 8. 归档原则

归档的目标不是简单移动文件，而是把已验收的复杂变更沉淀为长期团队规格。

归档前必须满足：

* 当前实现已有验证证据。
* 用户或人工系统已经明确验收。
* `spec.md` 中存在结构化 Archive Patch。
* Archive Patch 目标在 `docsDev/specs/` 内。
* 归档目标路径通过规范化检查。
* 归档目标不存在冲突或 `.tmp` 残留。
* 事务失败时不能声称 archived。

归档应避免依赖：

```text
git checkout
```

作为默认回滚方式。

归档应该尽量使用：

* backup
* checksum
* temporary file
* atomic rename
* idempotency check
* failure log

失败时：

* 原 change 状态保持 accepted。
* 记录 `archive_failure`。
* 不自动反复重试破坏性清理。
* 必要时请求人工介入。

---

## 9. 确定性工具原则

关键门禁不能只靠 prompt 自述。

涉及以下行为时，优先使用确定性脚本或工具：

* 状态转移
* acceptance evidence 校验
* Archive Patch 校验
* 路径 normalize
* archive precheck
* 幂等检查
* forbidden path 检查
* namespace 回归检查

现有或预期工具包括：

```text
tools/t-stage1-check.sh
tools/t-validate
tools/t-state
```

如果工具尚未实现：

* 不要假装已经有确定性保障。
* 应先规划工具接口和测试。
* 不要让 LLM 直接手写关键 frontmatter 作为长期默认路径。

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
一个 validator 能力
一个 archive 能力
一个 subagent 纪律增强
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
新产物进入 docsDev/
归档目标进入 docsDev/specs/
```

### 状态机

至少验证：

```text
非法转移被拒绝
blocked 缺 reason 被拒绝
accepted 缺验收证据被拒绝
verified 需要 verification log
```

### 归档

至少验证：

```text
缺验收不能归档
Target 越界不能归档
缺 Scenario 不能归档
重复归档被拒绝
.tmp 残留被拒绝
失败后原状态不变
成功后进入 docsDev/archive/
```

### subagent

至少验证：

```text
subagent 不写 docs/superpowers/
subagent 写入 verification log
subagent 继承 TDD / path / verification policy
```

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
- 手动绕过 validator 修改关键状态
- 没有验证证据就声称完成
- 没有人类验收就 accepted
- 归档事务未完成就 archived
- 用 git checkout 作为默认归档回滚
- 一次性修改多个无关 skill
- 让 subagent 脱离主流程约束
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
要把规则沉淀到 skill、hook、validator、fixture 或文档中。
