---
name: t-release
description: 用于准备、校验并发布当前项目的内部 npm 包 @4399/tdata-t-superpowers。仅在用户明确要求发布、发版、升级版本、cut release 或 publish 时使用；写版本号、提交 release commit、真实 npm publish 前都必须取得用户明确确认。
---

# T Release

## 目的

这个 skill 专门用于当前仓库的 `@4399/tdata-t-superpowers` 发版。它把后续反复要做的发布动作固定下来：同步版本号、构建 npm 包、跑安装器测试、做本地 tarball smoke、做内部 registry dry-run、等待用户明确说“发布”、真实 `npm publish`，最后再从 registry 安装验证。

不要把它用于普通开发、文档修改、skill 内容迭代或 npm 包安装排障。那些工作完成并验证后，才进入这个发布流程。

## 硬性规则

- 用户没有明确说要发版、发布、升级版本或 publish 时，不要主动进入本 skill。
- 用户没有明确确认目标版本号前，不要写任何 version 字段。
- 用户没有明确说“发布”或等价的发布确认前，不要执行真实 `npm publish`。
- 不要覆盖已存在的 npm 版本；npm 版本是不可变的。
- 根 `package.json` 只能改 `version` 字段，必须保留 `name: "superpowers"` 和 `main: ".opencode/plugins/superpowers.js"`。
- 不要修改 `vendor/superpowers/`。
- npm 包里不能带 `.claude-plugin/marketplace.json`，只能带 `.claude-plugin/plugin.json`。
- Codex doctor 返回 session-start hook adapter 的 `WARN` 是预期结果；其他 WARN/FAIL 要先解释清楚。

## Step 1：发布前摸底

先收集当前仓库和 registry 状态，不要改文件：

```bash
git status --short
node tools/sync-versions.mjs --check
node -p "require('./package.json').version"
npm whoami --registry https://registry-npm.gz4399.com/
npm dist-tag ls @4399/tdata-t-superpowers --registry https://registry-npm.gz4399.com/
```

处理规则：

- 如果工作区有未提交变更，先判断它们是否属于本次发版准备。普通功能、文档、skill 改动应先单独提交，再开始 release commit。
- 如果版本号不同步，先停下来说明 drift，不能继续发布。
- 如果用户没有给目标版本号，查看最近 commit 和本次实际 diff，建议一个 semver 版本，并说明理由。
- 如果 `npm whoami` 失败，让用户先配置内部 npm 登录，不要继续 publish 流程。

版本建议原则：

- 破坏安装、命令、manifest 或兼容性的变更：major。
- 新增用户可见能力、skill、安装目标或 CLI 行为：minor。
- 修 bug、补文档、强化校验且不改变使用方式：patch。

## Step 2：确认并同步版本号

向用户展示目标版本，等用户确认后再执行：

```bash
node tools/sync-versions.mjs --set <version>
node tools/sync-versions.mjs --check
```

随后检查 diff：

```bash
git diff -- package.json .cursor-plugin/plugin.json .claude-plugin/plugin.json .codex-plugin/plugin.json .claude-plugin/marketplace.json
```

确认只更新了这些位置的 `version` 字段：

- `package.json`
- `.cursor-plugin/plugin.json`
- `.claude-plugin/plugin.json`
- `.codex-plugin/plugin.json`
- `.claude-plugin/marketplace.json`

如果出现 `name`、`main`、plugin source、registry、description 等额外变化，停止并修正。

## Step 3：本地发布门禁

按顺序运行：

```bash
npm run test:npm-installer -- --test-reporter=spec
npm run build
npm run pack:dry-run
git diff --check
bash tools/t-stage1-check.sh
```

`pack:dry-run` 输出必须满足：

- 包名是 `@4399/tdata-t-superpowers`
- 版本是用户确认的 `<version>`
- 包含 `.claude-plugin/plugin.json`
- 不包含 `.claude-plugin/marketplace.json`
- 包含 `skills/`、`cli/`、`lib/`、三个 harness manifest、hooks、assets、`README.md`、`CHANGELOG.md`、`LICENSE`
- 不包含 `.agents/skills/` 下的项目内发布 skill

任一命令失败都停止，不要继续到 dry-run publish。

## Step 4：本地 tarball 安装 smoke

生成真实 tarball，并在临时 npm 项目里安装：

```bash
npm pack ./dist/npm-package
tmp=$(mktemp -d /tmp/tdata-tsp-release.XXXXXX)
repo=/Users/lihuajun/WorkProject/superpowers
cd "$tmp"
npm init -y >/dev/null
npm install "$repo/4399-tdata-t-superpowers-<version>.tgz"
```

从临时项目执行：

```bash
HOME="$tmp/home" node_modules/.bin/tdata-t-superpowers install cursor --json
HOME="$tmp/home" node_modules/.bin/tdata-t-superpowers doctor cursor --json
CODEX_HOME="$tmp/codex" node_modules/.bin/tdata-t-superpowers install codex --json
CODEX_HOME="$tmp/codex" node_modules/.bin/tdata-t-superpowers doctor codex --json
HOME="$tmp/home" node_modules/.bin/tdata-t-superpowers install claude --dry-run --json
```

验收标准：

- Cursor doctor 是 `PASS`，安装目标是物理目录，不是 symlink，并能看到所有 `t-*` skills。
- Codex doctor 是预期 `WARN`，并能看到所有 managed `t-*` skills。
- Claude dry-run 是 `PASS`，只报告将生成 marketplace，不写真实用户配置。

记录证据后删除仓库根目录生成的 `.tgz`，除非用户明确要求保留。

## Step 5：内部 registry 发布预检

只做 dry-run，不发布：

```bash
npm publish ./dist/npm-package --registry https://registry-npm.gz4399.com/ --dry-run
npm view @4399/tdata-t-superpowers@<version> version --registry https://registry-npm.gz4399.com/
```

预期：

- `npm publish --dry-run` 退出码为 `0`，输出类似 `+ @4399/tdata-t-superpowers@<version>`。
- `npm view ...@<version>` 返回 `E404`，表示该版本当前未发布。

如果 `npm view` 返回版本号，说明版本已存在，必须停止并选择新版本。

## Step 6：记录证据并提交 release commit

有活跃 change 时，把证据写入：

```text
docsDev/changes/<change-id>/transcripts/npm-smoke.md
```

没有活跃 change 时，新建：

```text
docsDev/changes/<YYYYMMDD-release-<version>>/transcripts/npm-smoke.md
```

证据至少包含：

- 日期和版本号
- 测试、build、pack、stage1 的结果
- 本地 tarball install smoke 结果
- publish dry-run 结果
- `npm view` 对目标版本的结果
- 预期 WARN，尤其是 Codex hook WARN

提交 release commit：

```bash
git add package.json .cursor-plugin/plugin.json .claude-plugin/plugin.json .codex-plugin/plugin.json .claude-plugin/marketplace.json
git add CHANGELOG.md README.md
git add <本次实际修改的 release 证据文件>
git commit -m "chore(release): v<version>"
```

只 add 实际变更文件。不要用 `git add docsDev` 把无关 change、archive 或 smoke 草稿一起提交。

## Step 7：发布前最后确认

提交后，向用户展示这份摘要，并等待明确发布指令：

```text
发布摘要：
- 版本：<version>
- npm 包：@4399/tdata-t-superpowers@<version>
- registry：https://registry-npm.gz4399.com/
- latest 当前指向：<dist-tag output>
- release commit：<commit hash>
- 本地测试：<pass/fail 摘要>
- tarball smoke：<pass/fail 摘要>
- publish dry-run：<pass/fail 摘要>

请明确回复“发布”，我再执行真实 npm publish。
```

不要把“可以了”“看起来没问题”“ok”等模糊回复当成发布授权。

## Step 8：真实发布并验证

用户明确说“发布”后执行：

```bash
npm publish ./dist/npm-package --registry https://registry-npm.gz4399.com/
npm view @4399/tdata-t-superpowers@<version> version --registry https://registry-npm.gz4399.com/
npm dist-tag ls @4399/tdata-t-superpowers --registry https://registry-npm.gz4399.com/
```

然后从 registry 安装到临时 npm 项目，再跑一遍 smoke：

```bash
tmp=$(mktemp -d /tmp/tdata-tsp-registry.XXXXXX)
cd "$tmp"
npm init -y >/dev/null
npm install @4399/tdata-t-superpowers@<version> --registry https://registry-npm.gz4399.com/

HOME="$tmp/home" node_modules/.bin/tdata-t-superpowers install cursor --json
HOME="$tmp/home" node_modules/.bin/tdata-t-superpowers doctor cursor --json
CODEX_HOME="$tmp/codex" node_modules/.bin/tdata-t-superpowers install codex --json
CODEX_HOME="$tmp/codex" node_modules/.bin/tdata-t-superpowers doctor codex --json
HOME="$tmp/home" node_modules/.bin/tdata-t-superpowers install claude --dry-run --json
```

把真实发布结果、`npm view`、dist-tag 和 registry install smoke 追加到同一份 evidence 文件，并提交一条证据提交：

```bash
git add <release evidence file>
git commit -m "docs: record internal npm publish"
```

## 完成汇报

最终回复必须包含：

- 已发布的包名和版本
- release commit hash
- 发布证据 commit hash
- `npm view` 返回值
- `npm dist-tag ls` 返回值
- Cursor、Codex、Claude 的 registry install smoke 结论
- 团队成员更新命令：

```bash
npm config set @4399:registry https://registry-npm.gz4399.com/
npx @4399/tdata-t-superpowers@latest update all
npx @4399/tdata-t-superpowers@latest doctor all
```
