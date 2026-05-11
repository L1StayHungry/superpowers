# Stage 1 t-superpowers Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` or `superpowers:executing-plans` to implement this task-by-task. Steps use checkbox syntax for tracking.

**Goal:** migrate the fork from `superpowers` to independently installable `t-superpowers` for Claude/Cursor/Codex, without changing behavior-shaping content.

**Architecture:** freeze an upstream vendor baseline first, then migrate only machine-visible names and runtime references, then prove scope control with deterministic checks and harness transcripts. OpenCode/Gemini/npm remain byte-for-byte excluded.

**Tech Stack:** Bash, Git, JSON manifests, Markdown skill files, Claude/Cursor/Codex plugin metadata, existing shell/Node test suites.

---

## Task 1: Preflight And Guardrails

**Files:** none

- [ ] Run repository sanity checks.

```bash
cd /Users/lihuajun/WorkProject/superpowers
git status --short
git log --oneline -1 f2cbfbefebbfef77321e4c9abc9e949826bea9d7
git diff f2cbfbefebbfef77321e4c9abc9e949826bea9d7 -- \
  package.json gemini-extension.json .opencode/plugins/superpowers.js
git diff --exit-code -- \
  package.json gemini-extension.json .opencode/plugins/superpowers.js \
  CLAUDE.md AGENTS.md GEMINI.md
```

Expected:
- commit prints `f2cbfbe Release v5.1.0 (#1468)`
- both diff commands produce no output
- if any excluded entry has diff, stop and resolve the fork-localization decision first.

- [ ] Commit current plan docs if desired before migration, because the migration will be noisy.

```bash
git add docs/二开规划/PLAN1.md docs/二开规划/二次开发规划.md docs/二开规划/阶段一执行plan.md
git commit -m "docs: plan t-superpowers stage 1 migration"
```

## Task 2: Vendor Upstream Baseline

**Files:**
- Create: `/Users/lihuajun/WorkProject/superpowers/vendor/superpowers/**`
- Create: `/Users/lihuajun/WorkProject/superpowers/vendor/superpowers/UPSTREAM_COMMIT`
- Create: `/Users/lihuajun/WorkProject/superpowers/docs/upstream-contrib.md`

- [ ] Extract upstream files from the local upstream commit.

```bash
mkdir -p vendor/superpowers
git archive f2cbfbefebbfef77321e4c9abc9e949826bea9d7 -- \
  skills hooks CLAUDE.md AGENTS.md GEMINI.md \
  .claude-plugin/plugin.json .claude-plugin/marketplace.json \
  .cursor-plugin/plugin.json .codex-plugin/plugin.json \
  package.json gemini-extension.json .opencode/plugins/superpowers.js \
  | tar -xC vendor/superpowers/
```

- [ ] Add `vendor/superpowers/UPSTREAM_COMMIT`.

```bash
cat > vendor/superpowers/UPSTREAM_COMMIT <<EOF
upstream: https://github.com/obra/superpowers
branch: main
commit: f2cbfbefebbfef77321e4c9abc9e949826bea9d7
synced_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
notes: initial vendoring for t-superpowers fork
EOF
```

- [ ] Generate upstream contributor baseline.

```bash
cp vendor/superpowers/CLAUDE.md docs/upstream-contrib.md
diff -q vendor/superpowers/CLAUDE.md docs/upstream-contrib.md
```

Expected: `diff` exits 0.

- [ ] Commit.

```bash
git add vendor/superpowers docs/upstream-contrib.md
git commit -m "chore: vendor upstream superpowers baseline"
```

## Task 3: Add Stage 1 Self-Check First

**Files:**
- Create: `/Users/lihuajun/WorkProject/superpowers/tools/t-stage1-check.sh`

- [ ] Create `tools/t-stage1-check.sh` with assertions for:
  - no non-`t-*` skill directories under `skills/`
  - no `superpowers:(14 upstream skills|archive)` residuals in `skills hooks .claude-plugin .cursor-plugin .codex-plugin tests`, excluding `vendor/`, `package.json`, `gemini-extension.json`, `.opencode/**`
  - manifest names/display names/skills fields equal expected `t-superpowers` values
  - `hooks/session-start` no longer references `skills/using-superpowers/SKILL.md` or `superpowers:using-superpowers`
  - all 14 `skills/t-*/SKILL.md` files exist with `name: t-*`
  - vendor baseline files and `UPSTREAM_COMMIT` exist
  - `docs/upstream-contrib.md` equals `vendor/superpowers/CLAUDE.md`
  - Cursor `agents/` and `commands/` dirs exist
  - Codex `hooks` is either `[]` or `"./hooks/hooks-codex.json"`; option A file contains no `CLAUDE_PLUGIN_ROOT`
  - excluded JSON entries `package.json` and `gemini-extension.json` still have `"name": "superpowers"`
  - excluded OpenCode entry `.opencode/plugins/superpowers.js` remains outside the migration scope and is protected by the final 6-file `git diff --exit-code` guard
  - `AGENTS.md` is still a symlink to `CLAUDE.md`

- [ ] Make it executable and verify red state.

```bash
chmod +x tools/t-stage1-check.sh
bash tools/t-stage1-check.sh
```

Expected now: FAIL, starting with non-`t-*` skill directories or unmigrated manifest names.

- [ ] Commit.

```bash
git add tools/t-stage1-check.sh
git commit -m "test: add stage 1 migration self-check"
```

## Task 4: Rename Skills And Runtime References

**Files:**
- Move: the 14 directories listed in the rename loop from `/Users/lihuajun/WorkProject/superpowers/skills/` to matching `t-` prefixed directory names
- Modify: all moved `SKILL.md` frontmatter
- Modify: runtime references inside `/Users/lihuajun/WorkProject/superpowers/skills/` and `/Users/lihuajun/WorkProject/superpowers/hooks/`

- [ ] Rename the 14 skill directories.

```bash
for n in brainstorming dispatching-parallel-agents executing-plans finishing-a-development-branch receiving-code-review requesting-code-review subagent-driven-development systematic-debugging test-driven-development using-git-worktrees using-superpowers verification-before-completion writing-plans writing-skills; do
  git mv "skills/$n" "skills/t-$n"
done
```

- [ ] Update each frontmatter `name`.

```bash
for n in brainstorming dispatching-parallel-agents executing-plans finishing-a-development-branch receiving-code-review requesting-code-review subagent-driven-development systematic-debugging test-driven-development using-git-worktrees using-superpowers verification-before-completion writing-plans writing-skills; do
  perl -0pi -e "s/^name:\s+\Q$n\E\s*$/name: t-$n/m" "skills/t-$n/SKILL.md"
done
```

- [ ] Replace runtime skill IDs.

```bash
for n in brainstorming dispatching-parallel-agents executing-plans finishing-a-development-branch receiving-code-review requesting-code-review subagent-driven-development systematic-debugging test-driven-development using-git-worktrees using-superpowers verification-before-completion writing-plans writing-skills; do
  perl -0pi -e "s/superpowers:\Q$n\E/t-superpowers:t-$n/g" \
    $(rg -l "superpowers:$n" skills hooks .claude-plugin .cursor-plugin .codex-plugin || true)
done
```

- [ ] Update renamed internal file-path references.

```bash
perl -0pi -e 's#skills/brainstorming/#skills/t-brainstorming/#g; s#skills/using-superpowers/SKILL.md#skills/t-using-superpowers/SKILL.md#g' \
  $(rg -l 'skills/(brainstorming/|using-superpowers/SKILL.md)' skills hooks || true)
```

- [ ] Commit.

```bash
git add skills hooks
git commit -m "refactor: prefix superpowers skills with t"
```

## Task 5: Update Plugin Manifests And Hooks

**Files:**
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `.cursor-plugin/plugin.json`
- Modify: `.codex-plugin/plugin.json`
- Create: `hooks/hooks-codex.json`
- Create: `agents/.gitkeep`
- Create: `commands/.gitkeep`

- [ ] Update JSON fields with a structured JSON edit:
  - `.claude-plugin/plugin.json.name = "t-superpowers"`
  - `.cursor-plugin/plugin.json.name = "t-superpowers"`
  - `.cursor-plugin/plugin.json.displayName = "T-Superpowers"`
  - `.codex-plugin/plugin.json.name = "t-superpowers"`
  - `.codex-plugin/plugin.json.interface.displayName = "T-Superpowers"`
  - `.codex-plugin/plugin.json.hooks = "./hooks/hooks-codex.json"`
  - `.claude-plugin/marketplace.json.name = "t-superpowers-dev"`
  - `.claude-plugin/marketplace.json.plugins[0].name = "t-superpowers"`
  - keep all description/defaultPrompt/longDescription text unchanged.

- [ ] Add `hooks/hooks-codex.json`.

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      {
        "command": "./hooks/run-hook.cmd session-start"
      }
    ]
  }
}
```

- [ ] Add Cursor placeholder directories.

```bash
mkdir -p agents commands
touch agents/.gitkeep commands/.gitkeep
```

- [ ] Verify hook constraint.

```bash
! rg '\$\{?CLAUDE_PLUGIN_ROOT\}?' hooks/hooks-codex.json
```

Expected: command exits 0 because `rg` finds nothing.

- [ ] Commit.

```bash
git add .claude-plugin .cursor-plugin .codex-plugin hooks/hooks-codex.json agents commands
git commit -m "chore: rename plugin manifests to t-superpowers"
```

## Task 6: Update Targeted Tests

**Files:**
- Modify: `tests/subagent-driven-dev/run-test.sh`
- Modify: `tests/subagent-driven-dev/go-fractals/plan.md`
- Modify: `tests/subagent-driven-dev/go-fractals/scaffold.sh`
- Modify: `tests/subagent-driven-dev/svelte-todo/plan.md`
- Modify: `tests/subagent-driven-dev/svelte-todo/scaffold.sh`
- Modify: `tests/claude-code/test-subagent-driven-development-integration.sh`
- Modify: `tests/claude-code/test-requesting-code-review.sh`
- Modify: `tests/claude-code/test-document-review-system.sh`
- Modify: `tests/brainstorm-server/server.test.js`
- Modify: `tests/brainstorm-server/ws-protocol.test.js`
- Modify: `tests/brainstorm-server/windows-lifecycle.test.sh`

- [ ] Replace targeted runtime skill IDs.

```bash
perl -0pi -e 's/superpowers:subagent-driven-development/t-superpowers:t-subagent-driven-development/g' \
  tests/subagent-driven-dev/run-test.sh \
  tests/subagent-driven-dev/go-fractals/plan.md \
  tests/subagent-driven-dev/go-fractals/scaffold.sh \
  tests/subagent-driven-dev/svelte-todo/plan.md \
  tests/subagent-driven-dev/svelte-todo/scaffold.sh \
  tests/claude-code/test-subagent-driven-development-integration.sh

perl -0pi -e 's/superpowers:requesting-code-review/t-superpowers:t-requesting-code-review/g' \
  tests/claude-code/test-requesting-code-review.sh
```

- [ ] Replace targeted path references.

```bash
perl -0pi -e 's#skills/brainstorming/#skills/t-brainstorming/#g' \
  tests/claude-code/test-document-review-system.sh \
  tests/brainstorm-server/server.test.js \
  tests/brainstorm-server/ws-protocol.test.js \
  tests/brainstorm-server/windows-lifecycle.test.sh
```

- [ ] Do not edit `docs/superpowers/plans`, `docs/superpowers/specs`, `/tmp/superpowers-tests`, `--plugin-dir /path/to/superpowers`, or `github.com/superpowers-test/fractals`.

- [ ] Commit.

```bash
git add tests/subagent-driven-dev tests/claude-code tests/brainstorm-server
git commit -m "test: update targeted tests for t-superpowers"
```

## Task 7: Run Static Verification

**Files:** no expected edits unless checks fail

- [ ] Run the self-check.

```bash
bash tools/t-stage1-check.sh
```

Expected: `OK: Stage 1 migration self-check passed`.

- [ ] Confirm excluded files and root instructions were not touched.

```bash
git diff --exit-code -- \
  package.json gemini-extension.json .opencode/plugins/superpowers.js \
  CLAUDE.md AGENTS.md GEMINI.md
```

Expected: no output.

- [ ] Confirm no forbidden runtime references remain.

```bash
rg -n --glob '!vendor/**' --glob '!package.json' --glob '!gemini-extension.json' --glob '!.opencode/**' \
  'superpowers:(brainstorming|writing-plans|test-driven-development|systematic-debugging|verification-before-completion|subagent-driven-development|using-superpowers|using-git-worktrees|executing-plans|requesting-code-review|receiving-code-review|finishing-a-development-branch|dispatching-parallel-agents|writing-skills|archive)' \
  skills hooks .claude-plugin .cursor-plugin .codex-plugin tests
```

Expected: no matches.

- [ ] Commit any fixes from static verification.

```bash
git add .
git commit -m "fix: satisfy stage 1 migration checks"
```

Skip commit if no fixes.

## Task 8: Run Targeted Test Suites

**Files:** no expected edits unless tests fail

- [ ] Brainstorm server tests.

```bash
cd /Users/lihuajun/WorkProject/superpowers/tests/brainstorm-server
npm test
bash windows-lifecycle.test.sh
```

Expected: server/WebSocket tests pass and lifecycle script exits 0.

- [ ] Claude Code targeted tests, if `claude` CLI is available.

```bash
cd /Users/lihuajun/WorkProject/superpowers/tests/claude-code
./run-skill-tests.sh --test test-document-review-system.sh
./run-skill-tests.sh --test test-requesting-code-review.sh --integration
./run-skill-tests.sh --test test-subagent-driven-development-integration.sh --integration
```

Expected: each script exits 0. If `claude` is unavailable, record that as an environment blocker, not a code pass.

- [ ] Subagent driven dev targeted tests, if `claude` CLI is available.

```bash
cd /Users/lihuajun/WorkProject/superpowers/tests/subagent-driven-dev
./run-test.sh t-smoke --plugin-dir /Users/lihuajun/WorkProject/superpowers --timeout 900
```

Expected: t-smoke exits 0, runs its fixture verifier, and leaves reviewable logs under /tmp/superpowers-tests/.... svelte-todo and go-fractals remain pressure fixtures; record their latest exit codes and logs, but they are not Stage 1 hard blockers after this standard revision.

## Task 9: Harness Acceptance Evidence

**Files:**
- Create: `/Users/lihuajun/WorkProject/superpowers/docs/二开规划/阶段一验收记录.md`

2026-05-11 验收范围修订：阶段一真实 transcript 硬门槛只覆盖 Claude Code CLI 与 Codex CLI。Cursor.app 与 Codex App transcript 不再作为阶段一完成阻塞项；Cursor 侧保留 manifest 结构静态校验与占位目录要求。Codex CLI co-installed 因当前安装模型限制降级为后续验证项；Codex CLI 的 official-only 与 fork-only 单装行为仍是阶段一硬门槛。

- [ ] Record Type A official-only baseline:
  - upstream `superpowers` only
  - in-scope harnesses: Claude Code CLI and Codex CLI
  - prompt: `Let's make a react todo list`
  - archive transcript and record transcript path, first 200 chars, and any environment blocker.
  - explicitly record whether Codex injects bootstrap.

- [ ] Record Type B fork-only:
  - Claude Code CLI and Codex CLI separately
  - same prompt
  - verify bootstrap text is behavior-equivalent except `superpowers:using-superpowers` -> `t-superpowers:t-using-superpowers`.
  - archive transcript for each in-scope harness and record transcript path, first 200 chars, and any environment blocker.

- [ ] Record Type C co-installed:
  - Claude Code CLI: `superpowers` and `t-superpowers` both visible as separate plugins
  - Codex CLI co-installed: record latest attempt and limitation as follow-up evidence, not a Stage 1 blocker
  - `/skills` shows non-overwriting namespaces
  - disabling either plugin leaves the other usable
  - double bootstrap injection is allowed and documented as expected.
  - archive transcript for the hard-gate harness and record transcript path, first 200 chars, and any environment blocker.

- [ ] If Type A proves Codex does not inject bootstrap:
  - set `.codex-plugin/plugin.json.hooks` to `[]`
  - delete `hooks/hooks-codex.json`
  - rerun `bash tools/t-stage1-check.sh`
  - document transcript evidence.

## Task 10: Final Review

**Files:** all changed files

- [ ] Review behavior-safety diff.

```bash
git diff --stat
git diff -- skills/t-*/SKILL.md hooks/session-start .claude-plugin .cursor-plugin .codex-plugin
```

Expected:
- `SKILL.md` body changes are only `name: t-*`, runtime IDs matching the 14 upstream `superpowers:` skills, and broken path updates such as `skills/t-brainstorming/`
- no behavior-shaping description/defaultPrompt/longDescription rewrites
- excluded entry files have no diff.

- [ ] Run final gates.

```bash
bash tools/t-stage1-check.sh
set -o pipefail
tests/subagent-driven-dev/run-test.sh t-smoke --plugin-dir /Users/lihuajun/WorkProject/superpowers --timeout 900 | tee /tmp/t-smoke-run.out
git diff --exit-code -- \
  package.json gemini-extension.json .opencode/plugins/superpowers.js \
  CLAUDE.md AGENTS.md GEMINI.md
```

Expected: `bash tools/t-stage1-check.sh` and `tests/subagent-driven-dev/run-test.sh t-smoke --plugin-dir /Users/lihuajun/WorkProject/superpowers --timeout 900` both exit 0 before Stage 1 can complete; excluded-file git diff has no output.

- [ ] Final commit.

```bash
git add .
git commit -m "refactor: migrate fork to t-superpowers namespace"
```

- [ ] Do not open a PR until the complete diff has been reviewed by the human partner and the upstream PR-template requirements have been satisfied.
