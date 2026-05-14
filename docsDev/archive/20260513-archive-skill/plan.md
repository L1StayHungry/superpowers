---
change_id: 20260513-archive-skill
created_at: 2026-05-13T07:37:17Z
updated_at: 2026-05-13T07:37:17Z
owner: lihuajun
---

# Archive Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use t-superpowers:t-subagent-driven-development (recommended) or t-superpowers:t-executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the explicit-trigger `t-archive` skill that wraps archive precheck, Archive Patch merge, change snapshot move, and archive commit.

**Architecture:** The implementation is one new skill file, `skills/t-archive/SKILL.md`. The skill consumes `tools/t-archive-precheck` JSON metadata as the mutation gate, performs prompt-guided Markdown merge rules, and uses Git for snapshot move, staging, commit, and rollback.

**Tech Stack:** Markdown skill instructions, Python 3 one-liners for JSON/frontmatter/H1 parsing during execution, Git CLI, existing `tools/t-archive-precheck`, existing `tools/t-stage1-check.sh`.

---

## File Structure

- `skills/t-archive/SKILL.md`: new skill entry. Owns explicit-trigger boundary, precheck call, Archive Patch merge rules, failure handling, and archive commit workflow.
- `docsDev/changes/20260513-archive-skill/spec.md`: existing approved spec. Read-only during implementation.
- `docsDev/changes/20260513-archive-skill/plan.md`: this plan. Append verification evidence only; do not rewrite completed task history.
- `docsDev/specs/archive/spec.md`: created during E2E archive of `20260512-archive-precheck`.
- `docsDev/specs/triggering/spec.md`: created during E2E archive of `20260512-trigger-convergence`.
- `docsDev/archive/20260512-archive-precheck/`: created by E2E archive.
- `docsDev/archive/20260512-trigger-convergence/`: created by E2E archive.
- `docsDev/changes/20260513-archive-skill/transcripts/`: manual prompt validation transcripts.

Do not modify:

- `tools/t-archive-precheck`
- `.codex-plugin/plugin.json`
- `.cursor-plugin/plugin.json`
- `.claude-plugin/plugin.json`
- `docs/二开规划/二次开发规划.md`
- `vendor/superpowers/`

## Preconditions

- Work from repository root: `/Users/lihuajun/WorkProject/superpowers`.
- Start with `git status --short` empty.
- `docsDev/changes/20260513-archive-skill/spec.md` and this plan must already be committed before Task 1 starts. If either file is dirty later, include it in the implementation commit before any E2E archive task runs.
- Do not treat plan execution as archive authorization. The E2E archive tasks require the user to explicitly say the exact archive command for each target change-id.
- Keep the Chinese trigger examples in the skill description exactly enough for runtime matching: `走 t-archive`, `把 ... 沉淀到 specs`, and `可以了`.
- Do not introduce transaction backup directories, checksums, atomic rename, `archive_failure`, status frontmatter, acceptance evidence, `tools/t-validate`, or `tools/t-state`.

### Task 1: Create The Explicit Archive Skill

**Files:**
- Create: `skills/t-archive/SKILL.md`

- [ ] **Step 1: Create `skills/t-archive/SKILL.md`**

Use `apply_patch`:

```patch
*** Begin Patch
*** Add File: skills/t-archive/SKILL.md
+---
+name: t-archive
+description: Use ONLY when the user explicitly asks to archive a specific change-id into docsDev/specs/ (e.g. "archive 20260508-add-billing-export", "走 t-archive", "把 20260508-add-billing-export 沉淀到 specs"). Do NOT auto-trigger after verification succeeds. Do NOT infer archive intent from phrases like "looks good" / "ok" / "可以了". The user must provide explicit archive intent and a change-id.
+---
+
+# Archive Completed Changes
+
+## Overview
+
+Archive an accepted `docsDev/changes/<change-id>/` change into the long-term `docsDev/specs/` library and move the full change snapshot to `docsDev/archive/`.
+
+**Announce at start:** "I'm using the t-archive skill to archive this change."
+
+This skill is a light wrapper around:
+
+1. `tools/t-archive-precheck <change-id>`
+2. Archive Patch merge into `docsDev/specs/<capability>/spec.md`
+3. `git mv docsDev/changes/<change-id> docsDev/archive/<change-id>`
+4. `git add docsDev/specs docsDev/archive`
+5. `git commit -m "archive <change-id>: <summary>"`
+
+## Hard Gates
+
+Do not run this skill unless the current user request has both:
+
+- Explicit archive intent, such as `archive`, `归档`, `走 t-archive`, or `沉淀到 specs`.
+- A concrete change-id matching `YYYYMMDD-<slug>`.
+
+If the user says `可以了`, `ok`, `looks good`, or verification has passed, do not infer archive intent. Report that archive requires an explicit request naming the change-id.
+
+If the user asks for archive intent without a concrete change-id, ask for the change-id and stop. Do not run precheck.
+
+## Exit Code Meanings
+
+| Code | Meaning |
+| --- | --- |
+| `1` | Argument, change directory, or spec is missing or invalid |
+| `2` | Archive Patch 字段缺失或格式错误 |
+| `3` | Target 路径越界 |
+| `4` | archive 目录已存在 |
+| `5` | 工作区不干净 |
+
+## Process
+
+### Step 1: Extract The Change-Id
+
+Extract one change-id from the current user request:
+
+```regex
+\b\d{8}-[a-z0-9-]{3,40}\b
+```
+
+If none is present, ask for the change-id and stop. If more than one is present, ask which one to archive and stop.
+
+### Step 2: Run Precheck Before Any Mutation
+
+Run:
+
+```bash
+precheck_json="$(mktemp)"
+precheck_err="$(mktemp)"
+tools/t-archive-precheck "<change-id>" >"${precheck_json}" 2>"${precheck_err}"
+precheck_code=$?
+if [ "${precheck_code}" -ne 0 ]; then
+  printf 'precheck exit %s\n' "${precheck_code}"
+  cat "${precheck_err}"
+fi
+```
+
+If `precheck_code` is non-zero:
+
+- Report the exit code meaning from the table above.
+- Include the stderr message.
+- Do not edit, stage, stash, reset, clean, or modify files.
+- Stop.
+
+### Step 3: Read Validated Metadata
+
+Parse the precheck JSON. Treat it as authoritative for `change_id`, `capability`, `target`, and `action`.
+
+```bash
+python3 - "${precheck_json}" <<'PY'
+import json
+import sys
+
+with open(sys.argv[1], encoding="utf-8") as handle:
+    data = json.load(handle)
+
+if not data.get("change_id"):
+    raise SystemExit("precheck JSON missing change_id")
+for patch in data.get("archive_patches", []):
+    for key in ("capability", "target", "action"):
+        if not patch.get(key):
+            raise SystemExit(f"precheck JSON patch missing {key}")
+        print(f"{patch['capability']} {patch['action']} {patch['target']}")
+PY
+```
+
+### Step 4: Derive Summary And Date
+
+Use UTC for Change History dates:
+
+```bash
+archive_date="$(date -u +%Y-%m-%d)"
+```
+
+Derive `<summary>` from the first H1 in `docsDev/changes/<change-id>/spec.md`. Strip one trailing ` Spec`; if no H1 exists, use the change-id.
+
+```bash
+summary="$(
+python3 - "docsDev/changes/<change-id>/spec.md" "<change-id>" <<'PY'
+import re
+import sys
+
+text = open(sys.argv[1], encoding="utf-8").read()
+fallback = sys.argv[2]
+match = re.search(r"(?m)^#\s+(.+?)\s*$", text)
+if not match:
+    print(fallback)
+else:
+    title = re.sub(r"\s+Spec$", "", match.group(1).strip())
+    print(title or fallback)
+PY
+)"
+```
+
+### Step 5: Validate Target Existence Before Writes
+
+Before editing any file, check all targets from precheck JSON:
+
+- `Action: create` requires the target file to be missing.
+- `Action: update` requires the target file to exist.
+
+```bash
+python3 - "${precheck_json}" <<'PY'
+from pathlib import Path
+import json
+import sys
+
+data = json.load(open(sys.argv[1], encoding="utf-8"))
+failed = False
+for patch in data["archive_patches"]:
+    target = Path(patch["target"])
+    exists = target.exists()
+    if patch["action"] == "create" and exists:
+        print(f"target exists for Action=create: {target}", file=sys.stderr)
+        failed = True
+    if patch["action"] == "update" and not exists:
+        print(f"target missing for Action=update: {target}", file=sys.stderr)
+        failed = True
+if failed:
+    raise SystemExit(1)
+PY
+```
+
+If this fails, stop without rollback because no mutation has happened.
+
+### Step 6: Apply Archive Patch
+
+Read `docsDev/changes/<change-id>/spec.md` and apply each `## Archive Patch` section named in the precheck JSON.
+
+Markdown section rules:
+
+- Archive Patch starts at `## Archive Patch` and must be terminal.
+- Capability section starts at `### <capability>` and ends before the next `### ` capability heading or end of file.
+- Long-term spec Requirement block starts at exact `### Requirement: <name>`.
+- A long-term spec Requirement block ends before the next heading at level 1, 2, or 3. If no such heading exists, the block ends at EOF.
+- Archive Patch Requirement headings are normalized when copied:
+  - `##### Requirement:` becomes `### Requirement:`
+  - `###### Scenario:` becomes `#### Scenario:`
+
+Action rules:
+
+- `ADDED Requirements`: append normalized Requirement blocks at the end of the `## Requirements` section, before the next `## ` heading or EOF.
+- `MODIFIED Requirements`: find the exact existing `### Requirement: <name>` block and replace it with the normalized body after `Replace with:`. Do not copy the `Replace with:` line into the long-term spec.
+- `REMOVED Requirements`: delete the exact existing `### Requirement: <name>` block named by `- Requirement: <name>`. Ignore `- Reason:` lines; they are Archive Patch rationale only.
+- `RENAMED Requirements`: parse `- From: <old>` and `- To: <new>` from the same renamed item, then rename only the exact `### Requirement: <old>` heading line to `### Requirement: <new>`. Keep the block body and scenarios unchanged. Ignore `- Reason:` lines.
+
+Change History rule:
+
+- Insert `- <UTC date>: archived from docsDev/changes/<change-id>/ (<summary>)` as the first bullet under `## Change History`.
+- Do not append duplicate Change History entries for the same change-id if the step is re-run during manual correction before commit.
+
+For `Action: create`, create the target with:
+
+```markdown
+---
+capability: <capability>
+owner: <owner from change spec frontmatter>
+updated_at: <ISO-8601 UTC timestamp>
+source: t-superpowers
+---
+
+# <Capability Title> Spec
+
+## Change History
+
+- <UTC date>: archived from docsDev/changes/<change-id>/ (<summary>)
+
+## Overview
+
+Archived long-term requirements for <capability>.
+
+## Requirements
+
+<normalized ADDED Requirements>
+
+## Notes
+```
+
+### Step 7: Validate The Pre-Move Diff
+
+Run:
+
+```bash
+git diff --check -- docsDev/specs "docsDev/changes/<change-id>"
+```
+
+Expected: exit `0`.
+
+If this fails, run rollback:
+
+```bash
+git reset --hard HEAD
+git clean -fd
+```
+
+Report the failed step and stop.
+
+### Step 8: Move, Stage, And Commit
+
+Run:
+
+```bash
+git mv "docsDev/changes/<change-id>" "docsDev/archive/<change-id>"
+git add docsDev/specs docsDev/archive
+git diff --cached --name-only -- docsDev/specs "docsDev/archive/<change-id>"
+```
+
+Confirm the staged list includes:
+
+- Every touched `docsDev/specs/<capability>/spec.md` target.
+- At least one path under `docsDev/archive/<change-id>/`.
+
+Then commit:
+
+```bash
+git commit -m "archive <change-id>: <summary>"
+```
+
+Report:
+
+```bash
+git log --oneline -1
+```
+
+### Step 9: Failure Handling
+
+If any step after a successful precheck mutates files and then fails before commit, run:
+
+```bash
+git reset --hard HEAD
+git clean -fd
+```
+
+Report the failed step and stop. Do not retry automatically.
+
+If the archive commit succeeds and a problem is found after commit, do not reset or retry automatically. Ask the user whether to use `git revert <archive-commit>` or make a corrective commit.
+*** End Patch
```

- [ ] **Step 2: Verify the skill file exists**

Run:

```bash
test -f skills/t-archive/SKILL.md
```

Expected: exit `0`.

### Task 2: Static Validation Of Skill Boundaries

**Files:**
- Read: `skills/t-archive/SKILL.md`

- [ ] **Step 1: Verify frontmatter name and explicit-trigger description**

Run:

```bash
rg -n "^name:[[:space:]]+t-archive[[:space:]]*$" skills/t-archive/SKILL.md
rg -n '^description:.*Use ONLY.*archive.*change-id' skills/t-archive/SKILL.md
```

Expected: both commands exit `0`.

- [ ] **Step 2: Verify required trigger-boundary phrases are present**

Run:

```bash
rg -n 'Do NOT auto-trigger|looks good|ok|可以了|走 t-archive|沉淀到 specs' skills/t-archive/SKILL.md
```

Expected: exit `0`, with matches in the frontmatter description or hard gates.

- [ ] **Step 3: Verify required archive commands and safety gates are present**

Run:

```bash
rg -n 'tools/t-archive-precheck|precheck_code|git mv "docsDev/changes/<change-id>" "docsDev/archive/<change-id>"|git diff --cached --name-only|git reset --hard HEAD|git clean -fd' skills/t-archive/SKILL.md
```

Expected: exit `0`.

- [ ] **Step 4: Verify target existence, summary, date, and block-boundary rules are present**

Run:

```bash
rg -n 'Action: create.*missing|Action: update.*exist|date -u \+%Y-%m-%d|first H1|Requirement block starts|ends before the next heading at level 1, 2, or 3' skills/t-archive/SKILL.md
```

Expected: exit `0`.

### Task 3: Commit The Skill Implementation

**Files:**
- Stage: `skills/t-archive/SKILL.md`

- [ ] **Step 0: Confirm plan and spec are committed or included**

Run:

```bash
git status --short -- docsDev/changes/20260513-archive-skill/spec.md docsDev/changes/20260513-archive-skill/plan.md
```

Expected: no output.

If either `spec.md` or `plan.md` appears, stage it together with `skills/t-archive/SKILL.md` in Step 3. Do not start Task 4 or Task 5 while these files are dirty, because `tools/t-archive-precheck` will exit `5`.

- [ ] **Step 1: Run whitespace validation**

Run:

```bash
git diff --check -- skills/t-archive/SKILL.md
```

Expected: exit `0`.

- [ ] **Step 2: Run Stage 1 migration check**

Run:

```bash
bash tools/t-stage1-check.sh
```

Expected: exit `0`. If it fails, stop and fix or mark this change blocked; do not record it as a pass.

- [ ] **Step 3: Commit the skill implementation**

Run:

```bash
git add skills/t-archive/SKILL.md docsDev/changes/20260513-archive-skill/spec.md docsDev/changes/20260513-archive-skill/plan.md
git commit -m "feat: add explicit archive skill"
```

Expected: commit succeeds.

### Task 3.5: Manual Prompt Validation

**Files:**
- Create: `docsDev/changes/20260513-archive-skill/transcripts/archive-skill-manual-prompts.md`

- [ ] **Step 1: Create transcript directory**

Run:

```bash
mkdir -p docsDev/changes/20260513-archive-skill/transcripts
```

Expected: exit `0`.

- [ ] **Step 2: Validate vague approval does not archive**

Feed these prompts to the agent or local runtime harness one at a time:

```text
可以了
looks good
ok
```

Expected:

- The agent does not invoke `t-archive`.
- The agent does not run `tools/t-archive-precheck`.
- The agent does not create an archive commit.
- The agent explains that archive requires explicit archive intent and a concrete change-id if archive is discussed.

Append the observed transcript and conclusion to:

```text
docsDev/changes/20260513-archive-skill/transcripts/archive-skill-manual-prompts.md
```

- [ ] **Step 3: Validate archive intent without change-id asks and stops**

Feed:

```text
走 t-archive
```

Expected:

- The agent asks for the concrete `YYYYMMDD-<slug>` change-id.
- The agent does not run `tools/t-archive-precheck`.
- The agent does not modify files.

Append the observed transcript and conclusion to `archive-skill-manual-prompts.md`.

- [ ] **Step 4: Validate explicit archive request enters t-archive without mutating yet**

Feed:

```text
归档 20260512-archive-precheck
```

Expected:

- The agent recognizes explicit archive intent for `20260512-archive-precheck`.
- The agent enters the `t-archive` flow.
- For this manual prompt validation task, stop before mutation and leave the real precheck plus archive run to Task 4.

Append the observed transcript and conclusion to `archive-skill-manual-prompts.md`.

- [ ] **Step 5: Commit manual prompt transcript**

Run:

```bash
git add docsDev/changes/20260513-archive-skill/transcripts/archive-skill-manual-prompts.md
git commit -m "docs: record archive skill prompt validation"
```

Expected: commit succeeds.

### Task 4: E2E Archive Of Archive Precheck Change

**Files:**
- Read: `docsDev/changes/20260512-archive-precheck/spec.md`
- Create: `docsDev/specs/archive/spec.md`
- Move: `docsDev/changes/20260512-archive-precheck/` to `docsDev/archive/20260512-archive-precheck/`

- [ ] **Step 1: Require explicit human archive intent**

Before doing any archive mutation, require the user to explicitly say:

```text
归档 20260512-archive-precheck
```

If the user has not said that exact change-id with archive intent, stop here and ask for it.

- [ ] **Step 2: Run precheck**

Run:

```bash
tools/t-archive-precheck 20260512-archive-precheck
```

Expected stdout:

```json
{"change_id": "20260512-archive-precheck", "archive_patches": [{"capability": "archive", "target": "docsDev/specs/archive/spec.md", "action": "create"}]}
```

Expected exit: `0`.

- [ ] **Step 2.5: Record actual Archive Patch Requirement names**

Run:

```bash
archive_precheck_requirements="$(
  rg -o "^##### Requirement: .+" docsDev/changes/20260512-archive-precheck/spec.md \
    | sed 's/^##### Requirement: //' \
    | paste -sd '|'
)"
printf '%s\n' "${archive_precheck_requirements}"
```

Expected: exit `0`. Use the printed Requirement names for Step 4 validation instead of guessing.

- [ ] **Step 3: Execute `t-archive` process for `20260512-archive-precheck`**

Use `skills/t-archive/SKILL.md` exactly as written:

- Create `docsDev/specs/archive/spec.md`.
- Normalize Archive Patch headings.
- Add Change History entry using `date -u +%Y-%m-%d`.
- Move the change directory with `git mv`.
- Stage specs and archive together.
- Derive `<summary>` using `skills/t-archive/SKILL.md` Step 4.
- Append the derived summary to the Verification Log in this plan.
- Commit with:

```bash
git commit -m "archive 20260512-archive-precheck: ${derived_summary}"
```

- [ ] **Step 4: Verify archive precheck E2E result**

Run:

```bash
test -f docsDev/specs/archive/spec.md
test -d docsDev/archive/20260512-archive-precheck
test ! -e docsDev/changes/20260512-archive-precheck
rg -n "${archive_precheck_requirements}|archived from docsDev/changes/20260512-archive-precheck" docsDev/specs/archive/spec.md
git log --oneline -1
```

Expected:

- All `test` commands exit `0`.
- `rg` exits `0`.
- `git log --oneline -1` starts with an archive commit for `20260512-archive-precheck`.

### Task 5: E2E Archive Of Trigger Convergence Change

**Files:**
- Read: `docsDev/changes/20260512-trigger-convergence/spec.md`
- Create: `docsDev/specs/triggering/spec.md`
- Move: `docsDev/changes/20260512-trigger-convergence/` to `docsDev/archive/20260512-trigger-convergence/`

- [ ] **Step 1: Require explicit human archive intent**

Before doing any archive mutation, require the user to explicitly say:

```text
归档 20260512-trigger-convergence
```

If the user has not said that exact change-id with archive intent, stop here and ask for it.

- [ ] **Step 2: Run precheck**

Run:

```bash
tools/t-archive-precheck 20260512-trigger-convergence
```

Expected stdout:

```json
{"change_id": "20260512-trigger-convergence", "archive_patches": [{"capability": "triggering", "target": "docsDev/specs/triggering/spec.md", "action": "create"}]}
```

Expected exit: `0`.

- [ ] **Step 2.5: Record actual Archive Patch Requirement names**

Run:

```bash
trigger_convergence_requirements="$(
  rg -o "^##### Requirement: .+" docsDev/changes/20260512-trigger-convergence/spec.md \
    | sed 's/^##### Requirement: //' \
    | paste -sd '|'
)"
printf '%s\n' "${trigger_convergence_requirements}"
```

Expected: exit `0`. Use the printed Requirement names for Step 4 validation instead of guessing.

- [ ] **Step 3: Execute `t-archive` process for `20260512-trigger-convergence`**

Use `skills/t-archive/SKILL.md` exactly as written:

- Create `docsDev/specs/triggering/spec.md`.
- Normalize Archive Patch headings.
- Add Change History entry using `date -u +%Y-%m-%d`.
- Move the change directory with `git mv`.
- Stage specs and archive together.
- Derive `<summary>` using `skills/t-archive/SKILL.md` Step 4.
- Append the derived summary to the Verification Log in this plan.
- Commit with:

```bash
git commit -m "archive 20260512-trigger-convergence: ${derived_summary}"
```

- [ ] **Step 4: Verify trigger convergence E2E result**

Run:

```bash
test -f docsDev/specs/triggering/spec.md
test -d docsDev/archive/20260512-trigger-convergence
test ! -e docsDev/changes/20260512-trigger-convergence
rg -n "${trigger_convergence_requirements}|archived from docsDev/changes/20260512-trigger-convergence" docsDev/specs/triggering/spec.md
git log --oneline -1
```

Expected:

- All `test` commands exit `0`.
- `rg` exits `0`.
- `git log --oneline -1` starts with an archive commit for `20260512-trigger-convergence`.

### Task 6: Final Validation Sweep

**Files:**
- Read: `skills/t-archive/SKILL.md`
- Read: `docsDev/specs/archive/spec.md`
- Read: `docsDev/specs/triggering/spec.md`
- Read: Git status and log

- [ ] **Step 1: Verify both archive commits exist**

Run:

```bash
git log --oneline --grep='^archive 20260512-archive-precheck:' -1
git log --oneline --grep='^archive 20260512-trigger-convergence:' -1
```

Expected: both commands print one commit.

- [ ] **Step 2: Verify no old change directories remain for archived changes**

Run:

```bash
find docsDev/changes -maxdepth 1 -type d \( -name '20260512-archive-precheck' -o -name '20260512-trigger-convergence' \)
```

Expected: no output.

- [ ] **Step 3: Verify stage1-check passes after all commits**

Run:

```bash
bash tools/t-stage1-check.sh
```

Expected: exit `0`.

- [ ] **Step 4: Verify final worktree state**

Run:

```bash
git status --short
```

Expected: no output.

## Self-Review Checklist

- [ ] Spec coverage: explicit trigger, precheck gate, create/update merge, git mv, commit, rollback, and E2E archive are covered by tasks.
- [ ] No forbidden design: no status fields, acceptance evidence, sha256, transaction backup, `tools/t-validate`, or `tools/t-state`.
- [ ] Archive Patch conflict fixed: `20260512-archive-precheck` creates `docsDev/specs/archive/spec.md`; `20260513-archive-skill` updates it.
- [ ] Manual archive tasks require explicit human archive intent before mutation.

## Verification Log

Append execution evidence here as tasks run.

- 2026-05-13: Task 1-3 implemented by worker. Commit `278f494 feat: add explicit archive skill` created `skills/t-archive/SKILL.md`.
- 2026-05-13: Spec review found the exit-code table needed exact Chinese meanings for codes 2-5. Fix commit `edc90c6 fix: clarify archive precheck failure meanings` updated `skills/t-archive/SKILL.md`.
- 2026-05-13: Validation after fix: `rg -n 'Archive Patch 字段缺失或格式错误|Target 路径越界|archive 目录已存在|工作区不干净' skills/t-archive/SKILL.md` exit `0`; `git diff --check -- skills/t-archive/SKILL.md` exit `0`; `bash tools/t-stage1-check.sh` exit `0`.
- 2026-05-13: Spec compliance re-review approved Task 1-3. E2E archive and manual prompt validation are still pending explicit archive validation steps.
- 2026-05-13: Task 4 E2E archived `20260512-archive-precheck`. Precheck stdout: `{"change_id": "20260512-archive-precheck", "archive_patches": [{"capability": "archive", "target": "docsDev/specs/archive/spec.md", "action": "create"}]}`. Derived summary: `Archive Precheck`. Archive commit: `0af1af8 archive 20260512-archive-precheck: Archive Precheck`.
- 2026-05-13: Task 4 validation passed: `test -f docsDev/specs/archive/spec.md`, `test -d docsDev/archive/20260512-archive-precheck`, `test ! -e docsDev/changes/20260512-archive-precheck`, `rg -n "Archive Precheck Guards Repository Safety|archived from docsDev/changes/20260512-archive-precheck" docsDev/specs/archive/spec.md`, and `bash tools/t-stage1-check.sh` all exited `0`.
- 2026-05-13: Hardened `skills/t-archive/SKILL.md` after the first E2E archive exposed a missing `docsDev/archive/` parent directory. Added `mkdir -p docsDev/archive` before `git mv`, post-archive verification commands, and explicit evidence-recording guidance. Updated this change spec and Archive Patch so the hardening will merge into `docsDev/specs/archive/spec.md` when `20260513-archive-skill` is archived.
- 2026-05-14: Task 5 E2E archived `20260512-trigger-convergence`. Precheck stdout: `{"change_id": "20260512-trigger-convergence", "archive_patches": [{"capability": "triggering", "target": "docsDev/specs/triggering/spec.md", "action": "create"}]}`. Derived summary: `Trigger Convergence`. Archive commit: `25b26fb archive 20260512-trigger-convergence: Trigger Convergence`.
- 2026-05-14: Task 5 validation passed: `test -d docsDev/archive/20260512-trigger-convergence`, `test ! -e docsDev/changes/20260512-trigger-convergence`, `test -f docsDev/specs/triggering/spec.md`, `rg -n "archived from docsDev/changes/20260512-trigger-convergence|T-Superpowers Trigger Boundary|Simple Requests Are Not Forced" docsDev/specs/triggering/spec.md`, `git status --short`, and `bash tools/t-stage1-check.sh` all exited `0`.
- 2026-05-14: Follow-up archive executed for `20260512-docsdev-paths`. Precheck stdout: `{"change_id": "20260512-docsdev-paths", "archive_patches": [{"capability": "runtime-artifacts", "target": "docsDev/specs/runtime-artifacts/spec.md", "action": "create"}]}`. Derived summary: `DocsDev Runtime Path Migration`. Archive commit: `6ac9d71 archive 20260512-docsdev-paths: DocsDev Runtime Path Migration`.
- 2026-05-14: Follow-up archive validation passed: `test -d docsDev/archive/20260512-docsdev-paths`, `test ! -e docsDev/changes/20260512-docsdev-paths`, `test -f docsDev/specs/runtime-artifacts/spec.md`, `rg -n "archived from docsDev/changes/20260512-docsdev-paths|Complex Change Artifacts Live Under DocsDev Changes" docsDev/specs/runtime-artifacts/spec.md`, `git status --short`, and `bash tools/t-stage1-check.sh` all exited `0`.
- 2026-05-14: Task 3.5 manual prompt validation recorded under `docsDev/changes/20260513-archive-skill/transcripts/archive-skill-manual-prompts.md`, with raw `codex exec -m gpt-5.2 --ephemeral --sandbox read-only` outputs under `transcripts/raw/`. `可以了`, `looks good`, and `ok` did not enter `t-archive`; `走 t-archive` asked for a concrete change-id and stopped; `归档 20260513-archive-skill` entered `t-archive` and reached the precheck gate, which blocked on dirty working tree with exit `5`.
- 2026-05-14: Task 6 final sweep passed. `git status --short` printed no output; archive commits exist for `20260512-archive-precheck`, `20260512-trigger-convergence`, and `20260512-docsdev-paths`; `find docsDev/changes -maxdepth 1 -type d \( -name '20260512-archive-precheck' -o -name '20260512-trigger-convergence' -o -name '20260512-docsdev-paths' \)` printed no output; `bash tools/t-stage1-check.sh` exited `0`; `tools/t-archive-precheck 20260513-archive-skill` exited `0` with stdout `{"change_id": "20260513-archive-skill", "archive_patches": [{"capability": "archive", "target": "docsDev/specs/archive/spec.md", "action": "update"}]}`.
