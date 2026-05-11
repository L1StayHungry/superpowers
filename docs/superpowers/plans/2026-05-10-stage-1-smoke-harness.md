# Stage 1 Smoke Harness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a short subagent-driven smoke harness and revise Stage 1 acceptance so namespace migration can close without treating long pressure fixtures as hard blockers.

**Architecture:** Add a `t-smoke` fixture under the existing `tests/subagent-driven-dev/` runner, then let the runner execute an optional fixture verifier after successful Claude runs. Update the Stage 1 planning and acceptance docs so the smoke harness is the hard gate and `svelte-todo` / `go-fractals` remain recorded pressure fixtures.

**Tech Stack:** Bash, Node built-in test runner, Git, Markdown, existing Claude Code `run-test.sh` harness, existing `tools/t-stage1-check.sh`.

---

## File Structure

- Create `tests/subagent-driven-dev/t-smoke/design.md`: describes the tiny generated project for the smoke fixture.
- Create `tests/subagent-driven-dev/t-smoke/plan.md`: the plan Claude executes through `t-superpowers:t-subagent-driven-development`.
- Create `tests/subagent-driven-dev/t-smoke/scaffold.sh`: initializes the disposable smoke repository.
- Create `tests/subagent-driven-dev/t-smoke/verify.sh`: verifies log content, generated files, commits, clean main project state, and `npm test`.
- Modify `tests/subagent-driven-dev/run-test.sh`: run optional fixture verifier after Claude exits 0 and print smoke next steps.
- Modify `tests/subagent-driven-dev/run-test-preflight.test.sh`: add static regression coverage for the verifier hook and `t-smoke` scaffold guidance.
- Modify `docs/二开规划/阶段一执行plan.md`: make `t-smoke` the required subagent Stage 1 test and move the long fixtures to pressure-test status.
- Modify `docs/二开规划/二次开发规划.md`: revise Stage 1 hard metrics to match the smoke-harness standard.
- Modify `docs/二开规划/阶段一验收记录.md`: add the formal acceptance-standard revision and record smoke/pressure status.
- Optionally create `docs/二开规划/harness-transcripts/`: store Type A, Type B, and Type C transcript records once real sessions are captured.

## Task 1: Add The `t-smoke` Fixture

**Files:**
- Create: `tests/subagent-driven-dev/t-smoke/design.md`
- Create: `tests/subagent-driven-dev/t-smoke/plan.md`
- Create: `tests/subagent-driven-dev/t-smoke/scaffold.sh`
- Create: `tests/subagent-driven-dev/t-smoke/verify.sh`

- [ ] **Step 1: Create the fixture directory**

```bash
mkdir -p tests/subagent-driven-dev/t-smoke
```

Expected: directory exists.

- [ ] **Step 2: Add the smoke design**

Create `tests/subagent-driven-dev/t-smoke/design.md` with this exact content:

```markdown
# T-Smoke Node Math Design

## Overview

Build a tiny Node project that proves the subagent-driven-development harness can create implementation files, add tests, commit work, and leave the main generated project in a reviewable state.

## Requirements

- Use only Node built-in modules.
- Create `src/math.js` exporting `add(a, b)`.
- Create `test/math.test.js` using `node:test` and `node:assert/strict`.
- `npm test` must run `node --test` and pass.
- Commit the completed implementation back to the main repository, not only to a `.claude/worktrees/` worktree.

## Acceptance Criteria

- `npm test` exits 0.
- `src/math.js` exists in the main generated project.
- `test/math.test.js` exists in the main generated project.
- The main generated project has a commit containing the implementation.
```

- [ ] **Step 3: Add the executable smoke plan**

Create `tests/subagent-driven-dev/t-smoke/plan.md` with this exact content:

```markdown
# T-Smoke Node Math Implementation Plan

Execute this plan using the `t-superpowers:t-subagent-driven-development` skill.

## Context

This is a disposable smoke-test repository. Keep the implementation intentionally small. The goal is to verify harness behavior, not to build a product.

## Tasks

### Task 1: Node Project Skeleton

Create the minimal Node project structure.

**Do:**
- Create `package.json` with:
  - `"type": "commonjs"`
  - `"scripts": { "test": "node --test" }`
- Create empty `src/` and `test/` directories.

**Verify:**
- `npm test` runs successfully with no tests.
- Commit the skeleton.

---

### Task 2: Add Tested Math Function

Add one tested function.

**Do:**
- Create `src/math.js`.
- Export `add(a, b)` using CommonJS.
- Create `test/math.test.js`.
- Test that `add(2, 3)` returns `5`.
- Test that `add(-2, 2)` returns `0`.

**Verify:**
- `npm test` passes.
- Commit the implementation and tests.

---

### Task 3: Final Harness Verification

Confirm the main repository contains the completed work.

**Do:**
- Check `git status --short`.
- Check `git log --oneline -3`.
- Confirm `src/math.js`, `test/math.test.js`, and `package.json` are present in the current repository.

**Verify:**
- `npm test` passes.
- Work is committed.
- Finished work is not left only under `.claude/worktrees/`.
```

- [ ] **Step 4: Add the scaffold script**

Create `tests/subagent-driven-dev/t-smoke/scaffold.sh` with this exact content:

```bash
#!/usr/bin/env bash
# Scaffold the t-smoke subagent-driven-development test project
# Usage: ./scaffold.sh TARGET_DIRECTORY

set -e

TARGET_DIR="${1:?Usage: $0 TARGET_DIRECTORY}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

git init

cp "$SCRIPT_DIR/design.md" .
cp "$SCRIPT_DIR/plan.md" .

cat > CLAUDE.md << 'EOF'
# Test Harness Notes

Do not use the Read tool in this harness. Use shell read-only commands such as `sed -n`, `grep`, or `python3 -c` to inspect files.

If the Read tool is available despite this instruction, omit the `pages` parameter entirely on ordinary text files. Only use `pages` for paginated documents, and never pass an empty `pages` value.

This is a disposable smoke-test repository. Work may happen in Claude Code worktrees, but completed task work must be committed and merged or cherry-picked back into this repository before reporting DONE.

Keep the implementation small. The goal is to verify `t-superpowers:t-subagent-driven-development` harness behavior, not to build a product.
EOF

mkdir -p .claude
cat > .claude/settings.local.json << 'SETTINGS'
{
  "permissions": {
    "allow": [
      "Edit(**)",
      "Write(**)",
      "Bash(npm:*)",
      "Bash(node:*)",
      "Bash(mkdir:*)",
      "Bash(git:*)",
      "Bash(test:*)"
    ]
  }
}
SETTINGS

git add .
git commit -m "Initial t-smoke project setup"

echo "Scaffolded t-smoke project at: $TARGET_DIR"
echo ""
echo "To run the test:"
echo "  claude -p \"Execute this plan using t-superpowers:t-subagent-driven-development. Plan: $TARGET_DIR/plan.md\" --plugin-dir /path/to/superpowers"
```

- [ ] **Step 5: Add the fixture verifier**

Create `tests/subagent-driven-dev/t-smoke/verify.sh` with this exact content:

```bash
#!/usr/bin/env bash
# Verify the t-smoke generated project and Claude log.
# Usage: ./verify.sh PROJECT_DIRECTORY CLAUDE_LOG_FILE

set -euo pipefail

PROJECT_DIR="${1:?Usage: $0 PROJECT_DIRECTORY CLAUDE_LOG_FILE}"
LOG_FILE="${2:?Usage: $0 PROJECT_DIRECTORY CLAUDE_LOG_FILE}"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

test -d "$PROJECT_DIR" || fail "project directory missing: $PROJECT_DIR"
test -f "$LOG_FILE" || fail "Claude log missing: $LOG_FILE"

grep -q 't-superpowers:t-subagent-driven-development' "$LOG_FILE" \
  || fail "Claude log does not contain t-superpowers:t-subagent-driven-development"

if grep -q 'Invalid pages parameter' "$LOG_FILE"; then
  fail "Claude log contains Invalid pages parameter"
fi

if grep -q '"name":"Read"' "$LOG_FILE"; then
  fail "Claude log contains a Read tool call"
fi

if grep -q 'Read(' "$LOG_FILE"; then
  fail "Claude log contains Read("
fi

test -f "$PROJECT_DIR/package.json" || fail "package.json missing from main project"
test -f "$PROJECT_DIR/src/math.js" || fail "src/math.js missing from main project"
test -f "$PROJECT_DIR/test/math.test.js" || fail "test/math.test.js missing from main project"

if ! grep -q 'node --test' "$PROJECT_DIR/package.json"; then
  fail "package.json does not define node --test"
fi

if ! grep -q 'function add' "$PROJECT_DIR/src/math.js" && ! grep -q 'add =' "$PROJECT_DIR/src/math.js"; then
  fail "src/math.js does not appear to define add"
fi

if ! grep -q 'add(2, 3)' "$PROJECT_DIR/test/math.test.js"; then
  fail "test/math.test.js does not verify add(2, 3)"
fi

commit_count="$(git -C "$PROJECT_DIR" rev-list --count HEAD)"
if [ "$commit_count" -lt 2 ]; then
  fail "expected at least 2 commits including scaffold, found $commit_count"
fi

dirty_non_worktree="$(
  git -C "$PROJECT_DIR" status --short \
    | grep -v '^\?\? \.claude/worktrees/' \
    | grep -v '^$' || true
)"
if [ -n "$dirty_non_worktree" ]; then
  echo "$dirty_non_worktree" >&2
  fail "main project has dirty files outside .claude/worktrees"
fi

(cd "$PROJECT_DIR" && npm test)

echo "OK: t-smoke verification passed"
```

- [ ] **Step 6: Make scripts executable and run syntax checks**

```bash
chmod +x tests/subagent-driven-dev/t-smoke/scaffold.sh
chmod +x tests/subagent-driven-dev/t-smoke/verify.sh
bash -n tests/subagent-driven-dev/t-smoke/scaffold.sh
bash -n tests/subagent-driven-dev/t-smoke/verify.sh
```

Expected: no output and exit 0.

- [ ] **Step 7: Smoke-test scaffolding only**

```bash
tmpdir="$(mktemp -d)"
tests/subagent-driven-dev/t-smoke/scaffold.sh "$tmpdir/project"
test -f "$tmpdir/project/plan.md"
test -f "$tmpdir/project/design.md"
test -f "$tmpdir/project/CLAUDE.md"
git -C "$tmpdir/project" log --oneline -1
rm -rf "$tmpdir"
```

Expected: latest commit message is `Initial t-smoke project setup`.

- [ ] **Step 8: Commit the fixture**

```bash
git add tests/subagent-driven-dev/t-smoke
git commit -m "test: add subagent stage 1 smoke fixture"
```

## Task 2: Wire Fixture Verification Into The Runner

**Files:**
- Modify: `tests/subagent-driven-dev/run-test.sh`
- Modify: `tests/subagent-driven-dev/run-test-preflight.test.sh`

- [ ] **Step 1: Add a failing static regression for fixture verifier support**

Append this block to `tests/subagent-driven-dev/run-test-preflight.test.sh` before the final `echo "Results: ..."` block:

```bash
if grep -q 'run_fixture_verifier "$TEST_DIR" "$OUTPUT_DIR/project" "$LOG_FILE"' "$RUN_TEST"; then
  echo "PASS: run-test executes fixture verifier after successful Claude runs"
  pass=$((pass + 1))
else
  echo "FAIL: run-test executes fixture verifier after successful Claude runs"
  fail=$((fail + 1))
fi

if grep -q 't-smoke)' "$RUN_TEST" && grep -q 'npm test' "$RUN_TEST"; then
  echo "PASS: run-test prints t-smoke next steps"
  pass=$((pass + 1))
else
  echo "FAIL: run-test prints t-smoke next steps"
  fail=$((fail + 1))
fi
```

- [ ] **Step 2: Run the preflight test and confirm it fails**

```bash
bash tests/subagent-driven-dev/run-test-preflight.test.sh
```

Expected: output includes:

```text
FAIL: run-test executes fixture verifier after successful Claude runs
FAIL: run-test prints t-smoke next steps
```

- [ ] **Step 3: Add verifier support to `run-test.sh`**

Insert this function after `run_with_timeout()` in `tests/subagent-driven-dev/run-test.sh`:

```bash
run_fixture_verifier() {
  local test_dir="$1"
  local project_dir="$2"
  local log_file="$3"

  if [[ ! -x "$test_dir/verify.sh" ]]; then
    return 0
  fi

  echo ">>> Running fixture verifier..."
  "$test_dir/verify.sh" "$project_dir" "$log_file"
  echo ""
}
```

- [ ] **Step 4: Call the verifier only after Claude exits 0**

In `tests/subagent-driven-dev/run-test.sh`, immediately after the block that prints `>>> Test complete`, add:

```bash
if [[ "$CLAUDE_STATUS" -eq 0 ]]; then
  set +e
  run_fixture_verifier "$TEST_DIR" "$OUTPUT_DIR/project" "$LOG_FILE"
  VERIFY_STATUS=$?
  set -e

  if [[ "$VERIFY_STATUS" -ne 0 ]]; then
    CLAUDE_STATUS="$VERIFY_STATUS"
    echo ">>> Fixture verifier failed"
  fi
fi
```

Keep the final `exit "$CLAUDE_STATUS"` unchanged so verifier failures propagate.

- [ ] **Step 5: Add `t-smoke` next steps**

Replace the final next-steps conditional in `tests/subagent-driven-dev/run-test.sh` with:

```bash
if [[ "$TEST_NAME" == "go-fractals" ]]; then
  echo "   cd $OUTPUT_DIR/project && go test ./..."
elif [[ "$TEST_NAME" == "svelte-todo" ]]; then
  echo "   cd $OUTPUT_DIR/project && npm test && npx playwright test"
elif [[ "$TEST_NAME" == "t-smoke" ]]; then
  echo "   cd $OUTPUT_DIR/project && npm test"
fi
```

- [ ] **Step 6: Verify preflight now passes**

```bash
bash -n tests/subagent-driven-dev/run-test.sh tests/subagent-driven-dev/run-test-preflight.test.sh
bash tests/subagent-driven-dev/run-test-preflight.test.sh
```

Expected:

```text
Results: 11 passed, 0 failed
```

If the pass count differs because additional checks already exist, require `0 failed`.

- [ ] **Step 7: Commit runner verification support**

```bash
git add tests/subagent-driven-dev/run-test.sh tests/subagent-driven-dev/run-test-preflight.test.sh
git commit -m "test: verify subagent smoke fixture outputs"
```

## Task 3: Update Stage 1 Planning Documents

**Files:**
- Modify: `docs/二开规划/阶段一执行plan.md`
- Modify: `docs/二开规划/二次开发规划.md`
- Modify: `docs/二开规划/阶段一验收记录.md`

- [ ] **Step 1: Update `阶段一执行plan.md` Task 8**

In `docs/二开规划/阶段一执行plan.md`, replace the subagent-driven-dev targeted test block:

```bash
cd /Users/lihuajun/WorkProject/superpowers/tests/subagent-driven-dev
./run-test.sh svelte-todo --plugin-dir /Users/lihuajun/WorkProject/superpowers
./run-test.sh go-fractals --plugin-dir /Users/lihuajun/WorkProject/superpowers
```

with:

```bash
cd /Users/lihuajun/WorkProject/superpowers/tests/subagent-driven-dev
./run-test.sh t-smoke --plugin-dir /Users/lihuajun/WorkProject/superpowers --timeout 900
```

Replace the following expected-result sentence:

```text
Expected: each run completes and leaves reviewable logs under `/tmp/superpowers-tests/...`.
```

with:

```text
Expected: `t-smoke` exits 0, runs its fixture verifier, and leaves reviewable logs under `/tmp/superpowers-tests/...`. `svelte-todo` and `go-fractals` remain pressure fixtures; record their latest exit codes and logs, but they are not Stage 1 hard blockers after this standard revision.
```

- [ ] **Step 2: Update `阶段一执行plan.md` final gates**

In the final gates section, add this command after `bash tools/t-stage1-check.sh`:

```bash
set -o pipefail
tests/subagent-driven-dev/run-test.sh t-smoke --plugin-dir /Users/lihuajun/WorkProject/superpowers --timeout 900 | tee /tmp/t-smoke-run.out
```

Expected: the document states both commands must exit 0 before Stage 1 can complete.

- [ ] **Step 3: Update `二次开发规划.md` hard metrics**

In `docs/二开规划/二次开发规划.md`, replace this sentence:

```text
阶段一完成的硬指标：§5.4 自检脚本退出码 0 + 类型 A 基线已记录 + 类型 B（按 harness 分别）+ 类型 C 全部通过。
```

with:

```text
阶段一完成的硬指标：§5.4 自检脚本退出码 0 + 6 个排除文件无 diff + 确定性 targeted tests 通过 + `tests/subagent-driven-dev/run-test.sh t-smoke --plugin-dir /Users/lihuajun/WorkProject/superpowers --timeout 900` 退出码 0 + 类型 A 基线已记录 + 类型 B（按 harness 分别）+ 类型 C 全部通过。`svelte-todo` 与 `go-fractals` 保留为 pressure fixtures，只记录最新结果，不作为阶段一完成阻塞项。
```

- [ ] **Step 4: Add an acceptance-standard revision section**

In `docs/二开规划/阶段一验收记录.md`, add this section after `## 当前状态`:

```markdown
## 验收标准修订

阶段一硬指标正式修订：`svelte-todo` 与 `go-fractals` 不再作为阶段一完成的硬阻塞项，改为 pressure fixtures。原因是这两个长样例主要验证长时间多代理编排稳定性、最终 review 时长和复杂任务吞吐，不等同于阶段一命名迁移正确性。

阶段一新的 subagent 硬门槛是 `tests/subagent-driven-dev/run-test.sh t-smoke --plugin-dir /Users/lihuajun/WorkProject/superpowers --timeout 900` 退出码 0。该 smoke fixture 覆盖 `t-superpowers:t-subagent-driven-development` 触发、`Read` 工具禁用、worktree 合回、主项目提交、生成项目测试通过和真实退出码传播。

本修订不影响 Type A / Type B / Type C harness transcript 类别，也不影响 Codex hook 决策要求。2026-05-11 起，阶段一真实 transcript 硬门槛只覆盖 Claude Code CLI 与 Codex CLI；Cursor.app 与 Codex App transcript 不再阻塞阶段一。Codex CLI co-installed 降级为后续验证项，阶段一 Type C 硬门槛由 Claude Code CLI co-installed transcript 满足。
```

- [ ] **Step 5: Move long fixture status to pressure results**

In `docs/二开规划/阶段一验收记录.md`, keep the latest `svelte-todo` and `go-fractals` log paths and exit code 124, but place them under a heading named:

```markdown
## Pressure Fixtures / 非阻塞风险
```

The text must say both remain failed pressure runs until a later exit-0 run supersedes them.

- [ ] **Step 6: Add the `t-smoke` pending line**

In `docs/二开规划/阶段一验收记录.md`, under hard metrics, set the subagent smoke status to pending until Task 4 runs:

```markdown
| Subagent smoke harness `t-smoke` | 待执行 | 需运行 `tests/subagent-driven-dev/run-test.sh t-smoke --plugin-dir /Users/lihuajun/WorkProject/superpowers --timeout 900` |
```

- [ ] **Step 7: Validate doc wording**

```bash
rg -n 'svelte-todo|go-fractals|t-smoke|Pressure Fixtures|验收标准修订|阶段一完成的硬指标' \
  docs/二开规划/阶段一执行plan.md \
  docs/二开规划/二次开发规划.md \
  docs/二开规划/阶段一验收记录.md
```

Expected:
- `t-smoke` appears in the hard-gate text.
- `svelte-todo` and `go-fractals` appear as pressure fixtures or non-blocking risk, not as hard blockers.
- Type A, Type B, Type C and Codex hook decision language remain present.

- [ ] **Step 8: Commit planning-document revisions**

```bash
git add docs/二开规划/阶段一执行plan.md docs/二开规划/二次开发规划.md docs/二开规划/阶段一验收记录.md
git commit -m "docs: revise stage 1 acceptance around smoke harness"
```

## Task 4: Run And Record The Smoke Harness

**Files:**
- Modify: `docs/二开规划/阶段一验收记录.md`

- [ ] **Step 1: Run static checks before the live smoke**

```bash
bash tools/t-stage1-check.sh
git diff --exit-code -- package.json gemini-extension.json .opencode/plugins/superpowers.js CLAUDE.md AGENTS.md GEMINI.md
bash tests/subagent-driven-dev/run-test-preflight.test.sh
```

Expected:
- self-check prints `OK: Stage 1 migration self-check passed`.
- protected-file diff prints no output.
- preflight exits 0.

- [ ] **Step 2: Run the smoke harness**

```bash
tests/subagent-driven-dev/run-test.sh t-smoke --plugin-dir /Users/lihuajun/WorkProject/superpowers --timeout 900
```

Expected:
- command exits 0.
- output contains `>>> Running fixture verifier...`.
- output contains `OK: t-smoke verification passed`.
- output prints a project directory under `/tmp/superpowers-tests/.../subagent-driven-development/t-smoke/project`.
- output prints a Claude log path under `/tmp/superpowers-tests/.../subagent-driven-development/t-smoke/claude-output.json`.

- [ ] **Step 3: Independently verify the generated smoke project**

Use the project and log paths printed by Step 2:

```bash
project_dir="$(awk -F': ' '/Project directory:/ {print $2}' /tmp/t-smoke-run.out | tail -1)"
log_file="$(awk -F': ' '/Claude log:/ {print $2}' /tmp/t-smoke-run.out | tail -1)"
test -n "$project_dir"
test -n "$log_file"
cd "$project_dir"
npm test
git log --oneline -5
git status --short
rg -n 'Invalid pages parameter|"name":"Read"|Read\(' "$log_file"
```

Expected:
- `npm test` exits 0.
- `git log --oneline -5` shows at least the scaffold commit plus an implementation commit.
- `git status --short` has no business-file changes outside `.claude/worktrees/`.
- `rg` exits 1 with no matches.

- [ ] **Step 4: Update the acceptance record with concrete smoke evidence**

In `docs/二开规划/阶段一验收记录.md`, update the `t-smoke` row from pending to passed and include:

- exact command,
- exit code 0,
- project path,
- log path,
- generated project test command and result,
- latest generated project commit summary,
- no `Invalid pages parameter`, no `"name":"Read"`, no `Read(`.

Do not mark Stage 1 complete unless Type A, Type B, Type C, and Codex hook decision are also complete within the revised scope. Type C's Stage 1 hard gate is Claude Code CLI co-installed; Codex CLI co-installed remains follow-up evidence.

- [ ] **Step 5: Commit the smoke result record**

```bash
git add docs/二开规划/阶段一验收记录.md
git commit -m "docs: record stage 1 smoke harness result"
```

## Task 5: Complete Harness Acceptance Evidence

**Files:**
- Create: `docs/二开规划/harness-transcripts/type-a-official-only.md`
- Create: `docs/二开规划/harness-transcripts/type-b-fork-only.md`
- Create: `docs/二开规划/harness-transcripts/type-c-co-installed.md`
- Modify: `docs/二开规划/阶段一验收记录.md`
- Possibly modify: `.codex-plugin/plugin.json`
- Possibly delete: `hooks/hooks-codex.json`

- [ ] **Step 1: Create transcript directory**

```bash
mkdir -p docs/二开规划/harness-transcripts
```

- [ ] **Step 2: Record Type A official-only**

Run clean official-only sessions for Claude Code CLI and Codex CLI using this exact prompt:

```text
Let's make a react todo list
```

For each harness, record:
- date and local time,
- plugin combination: official `superpowers` only,
- first 200 characters of the transcript,
- whether bootstrap was injected,
- whether Codex injected bootstrap.

Save the concrete observations in `docs/二开规划/harness-transcripts/type-a-official-only.md`. The file must contain no empty sections.

- [ ] **Step 3: Record Type B fork-only**

Run clean fork-only sessions for Claude Code CLI and Codex CLI using this exact prompt:

```text
Let's make a react todo list
```

For each harness, record:
- date and local time,
- plugin combination: fork `t-superpowers` only,
- first 200 characters of the transcript,
- whether `t-superpowers:t-using-superpowers` bootstrap appears,
- whether the namespace is `t-superpowers:t-*`,
- any deviation from Type A beyond namespace replacement.

Save the concrete observations in `docs/二开规划/harness-transcripts/type-b-fork-only.md`.

- [ ] **Step 4: Record Type C co-installed**

Run a Claude Code CLI co-installed session where official `superpowers` and fork `t-superpowers` are both visible. Record:
- both plugin names are visible and distinct,
- skill namespaces do not overwrite each other,
- disabling official leaves fork usable,
- disabling fork leaves official usable,
- double bootstrap injection, if observed, is recorded as expected rather than treated as behavior-equivalence evidence.

Record the latest Codex CLI co-installed attempt as follow-up evidence. If Codex CLI cannot recognize a manually staged fork plugin as a second installed plugin, that limitation does not block Stage 1 after the 2026-05-11 revision.

Save the concrete observations in `docs/二开规划/harness-transcripts/type-c-co-installed.md`.

- [ ] **Step 5: Finalize Codex hook decision**

If Type A Codex evidence shows official `superpowers` injects bootstrap, keep:

```json
"hooks": "./hooks/hooks-codex.json"
```

and keep `hooks/hooks-codex.json`.

If Type A Codex evidence shows official `superpowers` does not inject bootstrap, edit `.codex-plugin/plugin.json` so the `hooks` field is:

```json
"hooks": []
```

and delete `hooks/hooks-codex.json`.

After either decision, run:

```bash
bash tools/t-stage1-check.sh
```

Expected: self-check exits 0.

- [ ] **Step 6: Update the acceptance record**

In `docs/二开规划/阶段一验收记录.md`, update Harness Acceptance:

- Type A status and path to `type-a-official-only.md`,
- Type B status and path to `type-b-fork-only.md`,
- Type C status and path to `type-c-co-installed.md`,
- Codex hook decision and evidence path.

Stage 1 may be marked complete only if every revised hard metric is passed.

- [ ] **Step 7: Commit transcript evidence and Codex decision**

If Codex hook files did not change:

```bash
git add docs/二开规划/harness-transcripts docs/二开规划/阶段一验收记录.md
git commit -m "docs: record stage 1 harness acceptance"
```

If Codex hook files changed:

```bash
git add docs/二开规划/harness-transcripts docs/二开规划/阶段一验收记录.md .codex-plugin/plugin.json hooks/hooks-codex.json
git commit -m "docs: record stage 1 harness acceptance"
```

## Task 6: Final Stage 1 Gate

**Files:**
- Modify: `docs/二开规划/阶段一验收记录.md`

- [ ] **Step 1: Run final deterministic gates**

```bash
bash tools/t-stage1-check.sh
git diff --exit-code -- package.json gemini-extension.json .opencode/plugins/superpowers.js CLAUDE.md AGENTS.md GEMINI.md
cd tests/brainstorm-server && npm test
cd tests/brainstorm-server && node ws-protocol.test.js
cd tests/brainstorm-server && bash windows-lifecycle.test.sh
cd tests/claude-code && ./run-skill-tests.sh --test test-document-review-system.sh
cd tests/claude-code && ./run-skill-tests.sh --test test-requesting-code-review.sh --integration
cd tests/claude-code && ./run-skill-tests.sh --test test-subagent-driven-development-integration.sh --integration
cd tests/subagent-driven-dev && ./run-test.sh t-smoke --plugin-dir /Users/lihuajun/WorkProject/superpowers --timeout 900
```

Expected: every command exits 0.

- [ ] **Step 2: Confirm pressure fixtures remain honestly recorded**

```bash
rg -n 'Pressure Fixtures|svelte-todo|go-fractals|exit.*124|退出码 124' docs/二开规划/阶段一验收记录.md
```

Expected: the latest `svelte-todo` and `go-fractals` pressure results remain present unless newer exit-0 runs have superseded them.

- [ ] **Step 3: Mark Stage 1 complete only if every revised gate passed**

If every revised gate passed, update `docs/二开规划/阶段一验收记录.md`:

```markdown
阶段一状态：`完成 / ready for stage 2`。
```

Add a dated summary of the final gate commands and results.

If any revised gate failed, leave:

```markdown
阶段一状态：`未完成 / validation blocked`。
```

and record the failed command, exit code, and log path.

- [ ] **Step 4: Commit final acceptance status**

```bash
git add docs/二开规划/阶段一验收记录.md
git commit -m "docs: finalize stage 1 acceptance status"
```

- [ ] **Step 5: Do not open a PR**

Before any PR, follow `/Users/lihuajun/WorkProject/superpowers/AGENTS.md`: read the full PR template, search open and closed PRs, show the complete diff to the human partner, and get explicit approval.

## Self-Review

- Spec coverage: Tasks 1 and 2 implement the `t-smoke` fixture and verifier. Task 3 revises the three planning and acceptance documents. Task 4 records the smoke run. Task 5 covers Type A, Type B, Type C, and Codex hook decision. Task 6 gates Stage 1 completion.
- Blocked-token scan: clear. The plan contains no empty file sections or unspecified code blocks.
- Type consistency: paths and command names match the design spec: `tests/subagent-driven-dev/t-smoke`, `run-test.sh t-smoke --plugin-dir /Users/lihuajun/WorkProject/superpowers --timeout 900`, and `t-superpowers:t-subagent-driven-development`.
