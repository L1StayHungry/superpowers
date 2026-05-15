---
change_id: 20260515-harness-smoke
created_at: 2026-05-15T01:02:15Z
updated_at: 2026-05-15T01:02:15Z
owner: lihuajun
---

# Harness Smoke Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use t-superpowers:t-executing-plans for sequential execution. Do not use subagents for the app smoke steps because they require user-operated desktop apps.

**Goal:** Verify that `t-superpowers` behaves correctly in real CLI and App harnesses after landing hardening.

**Architecture:** Run CLI smoke in scratch directories and capture raw logs under this change. Ask the user to perform Cursor.app and Codex App smoke from a fixed checklist, then record the observations in `transcripts/app-smoke.md`. Treat install/load problems as `BLOCKED`, not as prompt failures.

**Tech Stack:** Claude Code CLI, Codex CLI where locally available, Cursor.app, Codex App, Markdown transcripts, `rg`, `bash`, `git`.

---

## File Structure

- `docsDev/changes/20260515-harness-smoke/spec.md`: smoke requirements.
- `docsDev/changes/20260515-harness-smoke/plan.md`: this operation plan.
- `docsDev/changes/20260515-harness-smoke/transcripts/app-smoke.md`: manual App checklist and results.
- `docsDev/changes/20260515-harness-smoke/transcripts/raw/`: CLI raw logs and stderr files.

## Task 1: Prepare Smoke Workspace

**Files:**
- Create runtime directory only: `docsDev/changes/20260515-harness-smoke/transcripts/raw/`

- [x] **Step 1: Create transcript directories**

Run:

```bash
mkdir -p docsDev/changes/20260515-harness-smoke/transcripts/raw
```

Expected: exit `0`.

- [x] **Step 2: Create scratch project**

Run:

```bash
SMOKE_TMP="/tmp/t-superpowers-harness-smoke"
rm -rf "${SMOKE_TMP}"
mkdir -p "${SMOKE_TMP}/src"
cat > "${SMOKE_TMP}/README.md" <<'EOF'
# Harness Smoke Scratch
EOF
cat > "${SMOKE_TMP}/src/Button.tsx" <<'EOF'
export function Button() {
  return <button>确定</button>;
}
EOF
```

Expected: exit `0`. The scratch project exists outside this repository.

- [x] **Step 3: Record baseline repository state**

Run:

```bash
git status --short
find docsDev/changes -maxdepth 1 -type d | sort
```

Expected: only `docsDev/changes/20260515-harness-smoke` is active for this smoke change.

## Task 2: Run Claude Code CLI Smoke

**Files:**
- Create: `docsDev/changes/20260515-harness-smoke/transcripts/raw/claude-simple.jsonl`
- Create: `docsDev/changes/20260515-harness-smoke/transcripts/raw/claude-simple.stderr.log`
- Create: `docsDev/changes/20260515-harness-smoke/transcripts/raw/claude-explicit.jsonl`
- Create: `docsDev/changes/20260515-harness-smoke/transcripts/raw/claude-explicit.stderr.log`
- Create: `docsDev/changes/20260515-harness-smoke/transcripts/cli-smoke.md`

- [x] **Step 1: Run simple Claude prompt**

Run:

```bash
REPO="/Users/lihuajun/WorkProject/superpowers"
SMOKE_TMP="/tmp/t-superpowers-harness-smoke"
cd "${SMOKE_TMP}"
claude -p "帮我把按钮文案从'确定'改成'OK'" \
  --plugin-dir "${REPO}" \
  --output-format stream-json \
  --verbose \
  > "${REPO}/docsDev/changes/20260515-harness-smoke/transcripts/raw/claude-simple.jsonl" \
  2> "${REPO}/docsDev/changes/20260515-harness-smoke/transcripts/raw/claude-simple.stderr.log"
```

Expected: command exits `0` or records a clear harness error in stderr. Do not treat a harness error as a prompt failure; classify it as `BLOCKED`.

- [x] **Step 2: Classify simple Claude prompt**

Run:

```bash
REPO="/Users/lihuajun/WorkProject/superpowers"
if rg -n "t-superpowers:t-brainstorming|t-brainstorming" "${REPO}/docsDev/changes/20260515-harness-smoke/transcripts/raw/claude-simple.jsonl"; then
  echo "FAIL: Claude simple prompt entered t-brainstorming"
else
  echo "PASS: Claude simple prompt did not enter t-brainstorming"
fi
```

Expected: prints `PASS`.

- [x] **Step 3: Run explicit complex Claude prompt**

Run:

```bash
REPO="/Users/lihuajun/WorkProject/superpowers"
SMOKE_TMP="/tmp/t-superpowers-harness-smoke"
cd "${SMOKE_TMP}"
claude -p "用 t-superpowers，我要做一个 PDF 导出功能" \
  --plugin-dir "${REPO}" \
  --output-format stream-json \
  --verbose \
  > "${REPO}/docsDev/changes/20260515-harness-smoke/transcripts/raw/claude-explicit.jsonl" \
  2> "${REPO}/docsDev/changes/20260515-harness-smoke/transcripts/raw/claude-explicit.stderr.log"
```

Expected: command exits `0` or records a clear harness error in stderr. Do not continue to classify as prompt failure if the CLI itself is blocked.

- [x] **Step 4: Classify explicit complex Claude prompt**

Run:

```bash
REPO="/Users/lihuajun/WorkProject/superpowers"
if rg -n "t-superpowers|t-brainstorming" "${REPO}/docsDev/changes/20260515-harness-smoke/transcripts/raw/claude-explicit.jsonl"; then
  echo "PASS: Claude explicit prompt entered t-superpowers"
else
  echo "FAIL: Claude explicit prompt did not enter t-superpowers"
fi
```

Expected: prints `PASS`.

- [x] **Step 5: Create CLI smoke summary**

Create `docsDev/changes/20260515-harness-smoke/transcripts/cli-smoke.md` with:

```bash
RUN_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
cat > /Users/lihuajun/WorkProject/superpowers/docsDev/changes/20260515-harness-smoke/transcripts/cli-smoke.md <<EOF
# CLI Smoke Results

Date: ${RUN_DATE}

## Claude Code CLI

### Simple Prompt

- Prompt: `帮我把按钮文案从'确定'改成'OK'`
- Result: NOT VERIFIED
- Raw stream: `transcripts/raw/claude-simple.jsonl`
- Stderr: `transcripts/raw/claude-simple.stderr.log`
- Observation: classification pending

### Explicit Complex Prompt

- Prompt: `用 t-superpowers，我要做一个 PDF 导出功能`
- Result: NOT VERIFIED
- Raw stream: `transcripts/raw/claude-explicit.jsonl`
- Stderr: `transcripts/raw/claude-explicit.stderr.log`
- Observation: classification pending
EOF
```

Then replace each `NOT VERIFIED` result and `classification pending` observation with the actual classification from Steps 2 and 4.

## Task 3: Run Codex CLI Smoke If Local Plugin Loading Is Available

**Files:**
- Create if run: `docsDev/changes/20260515-harness-smoke/transcripts/raw/codex-simple.jsonl`
- Create if run: `docsDev/changes/20260515-harness-smoke/transcripts/raw/codex-simple.stderr.log`
- Create if run: `docsDev/changes/20260515-harness-smoke/transcripts/raw/codex-explicit.jsonl`
- Create if run: `docsDev/changes/20260515-harness-smoke/transcripts/raw/codex-explicit.stderr.log`
- Modify: `docsDev/changes/20260515-harness-smoke/transcripts/cli-smoke.md`

- [x] **Step 1: Check Codex CLI availability**

Run:

```bash
command -v codex
```

Expected: if missing, append `Codex CLI: BLOCKED - codex command unavailable` to `cli-smoke.md` and skip this task.

- [x] **Step 2: Check local t-superpowers loading path**

Use the same isolated `CODEX_HOME` approach previously recorded for trigger convergence. Do not modify the user's global Codex configuration. If the local plugin cache path cannot be set up safely, append:

```markdown
## Codex CLI

- Result: BLOCKED
- Reason: local t-superpowers plugin loading path unavailable in this environment
```

Expected: blocked status is acceptable when plugin loading is unavailable.

- [x] **Step 3: Skip Codex simple prompt because local setup is blocked**

Run from a scratch project with isolated `CODEX_HOME`. The variable must point to a temporary Codex home that already has local `t-superpowers` available:

```bash
CODEX_SMOKE_HOME="/tmp/codex-home-harness-smoke"
test -d "${CODEX_SMOKE_HOME}" || {
  echo "BLOCKED: ${CODEX_SMOKE_HOME} does not exist or is not configured for local t-superpowers"
  exit 1
}
CODEX_HOME="${CODEX_SMOKE_HOME}" codex exec --json --skip-git-repo-check \
  -C /tmp/t-superpowers-harness-smoke \
  -s read-only \
  -m gpt-5.4 \
  "帮我加一个 README 段落" \
  > /Users/lihuajun/WorkProject/superpowers/docsDev/changes/20260515-harness-smoke/transcripts/raw/codex-simple.jsonl \
  2> /Users/lihuajun/WorkProject/superpowers/docsDev/changes/20260515-harness-smoke/transcripts/raw/codex-simple.stderr.log
```

Expected: transcript does not contain `t-superpowers:t-brainstorming`.

- [x] **Step 4: Skip Codex explicit complex prompt because local setup is blocked**

Run:

```bash
CODEX_SMOKE_HOME="/tmp/codex-home-harness-smoke"
test -d "${CODEX_SMOKE_HOME}" || {
  echo "BLOCKED: ${CODEX_SMOKE_HOME} does not exist or is not configured for local t-superpowers"
  exit 1
}
CODEX_HOME="${CODEX_SMOKE_HOME}" codex exec --json --skip-git-repo-check \
  -C /tmp/t-superpowers-harness-smoke \
  -s read-only \
  -m gpt-5.4 \
  "用 t-superpowers，我要做一个 PDF 导出功能" \
  > /Users/lihuajun/WorkProject/superpowers/docsDev/changes/20260515-harness-smoke/transcripts/raw/codex-explicit.jsonl \
  2> /Users/lihuajun/WorkProject/superpowers/docsDev/changes/20260515-harness-smoke/transcripts/raw/codex-explicit.stderr.log
```

Expected: transcript contains `t-superpowers` or `t-brainstorming`.

- [x] **Step 5: Append Codex CLI summary**

Append Codex CLI result sections to `cli-smoke.md` with result `PASS`, `FAIL`, or `BLOCKED`, raw log paths, and observations.

## Task 4: User Runs Cursor.app Smoke

**Files:**
- Modify: `docsDev/changes/20260515-harness-smoke/transcripts/app-smoke.md`

- [ ] **Step 1: Prepare Cursor.app**

Ask the user to open Cursor.app, open a scratch project, and enable the local plugin if supported:

```text
/add-plugin /Users/lihuajun/WorkProject/superpowers
```

Expected: user sees `T-Superpowers` or confirms the local plugin cannot be loaded.

- [ ] **Step 2: Run Cursor simple prompt**

User prompt:

```text
帮我把按钮文案从“确定”改成“OK”
```

Expected: Cursor does not enter `t-brainstorming`.

- [ ] **Step 3: Run Cursor explicit complex prompt**

User prompt:

```text
用 t-superpowers，我要做一个 PDF 导出功能
```

Expected: Cursor enters `t-superpowers` or `t-brainstorming`, and asks clarifying questions or starts planning.

- [ ] **Step 4: Record Cursor result**

Record the user observation in `transcripts/app-smoke.md` under the Cursor.app section.

## Task 5: User Runs Codex App Smoke

**Files:**
- Modify: `docsDev/changes/20260515-harness-smoke/transcripts/app-smoke.md`

- [ ] **Step 1: Prepare Codex App**

Ask the user to open Codex App and check whether internal `t-superpowers` is available as a plugin. If unavailable, record `BLOCKED: install path unclear`.

- [ ] **Step 2: Run Codex App simple prompt**

User prompt:

```text
帮我加一个 README 段落
```

Expected: Codex App does not enter `t-brainstorming`.

- [ ] **Step 3: Run Codex App explicit complex prompt**

User prompt:

```text
用 t-superpowers，我要做一个 PDF 导出功能
```

Expected: Codex App enters `t-superpowers` or `t-brainstorming`, and asks clarifying questions or starts planning.

- [ ] **Step 4: Record Codex App result**

Record the user observation in `transcripts/app-smoke.md` under the Codex App section.

## Task 6: Final Verification And Evidence Commit

**Files:**
- Modify: `docsDev/changes/20260515-harness-smoke/transcripts/cli-smoke.md`
- Modify: `docsDev/changes/20260515-harness-smoke/transcripts/app-smoke.md`
- Modify: `docsDev/changes/20260515-harness-smoke/plan.md`

- [x] **Step 1: Verify stage and formatting**

Run:

```bash
git diff --check -- docsDev/changes/20260515-harness-smoke
bash tools/t-stage1-check.sh
rg -n "Result: (PASS|FAIL|BLOCKED|NOT VERIFIED)" docsDev/changes/20260515-harness-smoke/transcripts
if find docs/superpowers -newer docsDev/changes/20260515-harness-smoke/spec.md -type f 2>/dev/null | rg .; then
  echo "FAIL: new docs/superpowers artifact detected"
  exit 1
fi
```

Expected: all commands exit `0`.

- [x] **Step 2: Append verification log**

Append a `## Verification Log` section to this plan with UTC timestamp, commands, exit codes, and final classification for each harness.

- [ ] **Step 3: Commit smoke evidence**

Run:

```bash
git add docsDev/changes/20260515-harness-smoke
git commit -m "docs: record harness smoke results"
```

Expected: commit succeeds.

## Manual App Checklist For User

Run these in Cursor.app and Codex App after I ask for app smoke:

### Cursor.app

1. Open a scratch project, not this repository.
2. Enable local plugin if supported: `/add-plugin /Users/lihuajun/WorkProject/superpowers`.
3. Confirm displayed plugin name is `T-Superpowers`, or report that local plugin loading is unavailable.
4. Prompt: `帮我把按钮文案从“确定”改成“OK”`.
5. Report whether it entered `t-brainstorming`.
6. Prompt: `用 t-superpowers，我要做一个 PDF 导出功能`.
7. Report whether it entered `t-superpowers` or `t-brainstorming`.

### Codex App

1. Open Codex App and check whether internal `t-superpowers` is available.
2. If unavailable, report `BLOCKED: install path unclear`.
3. Prompt: `帮我加一个 README 段落`.
4. Report whether it entered `t-brainstorming`.
5. Prompt: `用 t-superpowers，我要做一个 PDF 导出功能`.
6. Report whether it entered `t-superpowers` or `t-brainstorming`.

## Self-Review

- Spec coverage: CLI smoke, app smoke, classifications, transcript storage, and no runtime changes are covered.
- Scope control: this plan verifies harness behavior only and does not change skills, hooks, manifests, archive tooling, or vendor.
- Path consistency: all new evidence paths are under `docsDev/changes/20260515-harness-smoke/`.
- App limitations: Cursor.app and Codex App install/load issues are explicitly classified as `BLOCKED`, not hidden.

## Verification Log

### 2026-05-15 CLI Smoke Verification

Timestamp: `2026-05-15T01:23:44Z`

CLI classifications:

- PASS: Claude Code CLI simple prompt did not make a `Skill` tool call and stayed in direct edit flow.
- PASS: Claude Code CLI explicit complex prompt made a `Skill` tool call for `t-superpowers:t-brainstorming` and produced clarifying-question behavior.
- BLOCKED: Codex CLI is installed as `codex-cli 0.123.0`, but local `t-superpowers` plugin loading was not available in an isolated, non-global setup.
- NOT VERIFIED: Cursor.app smoke requires user-operated desktop validation.
- NOT VERIFIED: Codex App smoke requires user-operated desktop validation.

Execution evidence:

- `claude -p "帮我把按钮文案从'确定'改成'OK'" --plugin-dir /Users/lihuajun/WorkProject/superpowers --output-format stream-json --verbose`: exit `0`; raw stream stored at `transcripts/raw/claude-simple.jsonl`; stderr is empty.
- `python3` JSONL classification for `claude-simple.jsonl`: exit `0`; `Skill` tool calls: none.
- `claude -p "用 t-superpowers，我要做一个 PDF 导出功能" --plugin-dir /Users/lihuajun/WorkProject/superpowers --output-format stream-json --verbose`: exit `0`; raw stream stored at `transcripts/raw/claude-explicit.jsonl`; stderr is empty.
- `python3` JSONL classification for `claude-explicit.jsonl`: exit `0`; `Skill` tool call found for `t-superpowers:t-brainstorming`.
- `command -v codex && codex --version`: exit `0`; output includes `codex-cli 0.123.0`.
- `CODEX_HOME=/tmp/codex-home-harness-smoke codex exec ...`: exit `1`; blocked by missing authentication in isolated `CODEX_HOME`.
- `CODEX_HOME=/tmp/codex-home-harness-smoke-* codex debug prompt-input ...`: exit `0`; prompt input did not expose local `t-superpowers` skills after temporary marketplace/cache setup.

Deterministic checks:

- `git diff --check -- docsDev/changes/20260515-harness-smoke`: exit `0`.
- `bash tools/t-stage1-check.sh`: exit `0`; output `OK: Stage 1 migration self-check passed`.
- `rg -n "Result: (PASS|FAIL|BLOCKED|NOT VERIFIED)" docsDev/changes/20260515-harness-smoke/transcripts`: exit `0`; found CLI and App result classifications.
- `find docs/superpowers -newer docsDev/changes/20260515-harness-smoke/spec.md -type f 2>/dev/null | rg .`: exit `1` inside the `if` check, interpreted as pass because no new `docs/superpowers` artifact was found.

Notes:

- The plan's initial raw `rg "t-brainstorming"` classification was too broad for Claude Code CLI because startup metadata lists available slash commands. Final classification uses actual assistant `tool_use` events.
- Claude simple prompt hit write approval denial after avoiding `t-brainstorming`; this is a CLI permission behavior, not a trigger regression.
- Claude explicit prompt hit non-interactive permission denials for `Skill` and `AskUserQuestion`, but the raw stream still shows the intended `t-superpowers:t-brainstorming` entry and clarifying-question behavior.
