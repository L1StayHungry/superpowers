---
change_id: 20260512-docsdev-paths
created_at: 2026-05-12T03:51:05Z
updated_at: 2026-05-12T03:51:05Z
owner: lihuajun
---

# DocsDev Runtime Path Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use t-superpowers:t-subagent-driven-development (recommended) or t-superpowers:t-executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move live t-superpowers runtime artifact instructions from `docs/superpowers/{specs,plans}/` to `docsDev/changes/<change-id>/`.

**Architecture:** This is a prompt and documentation-path migration, not a new tool. `t-brainstorming` owns creating `docsDev/changes/<change-id>/spec.md`; `t-writing-plans` reuses that change directory for `plan.md`; live dispatch and handoff examples use the same path family.

**Tech Stack:** Markdown skill files, YAML frontmatter examples, Bash/rg/git validation, optional Claude/Codex CLI harness transcripts under `docsDev/changes/20260512-docsdev-paths/transcripts/`.

---

## File Structure

- `skills/t-brainstorming/SKILL.md`: replace live spec output instructions, add change-id rules, collision handling, explicit spec iteration rules, and docsDev review wording.
- `skills/t-writing-plans/SKILL.md`: replace live plan output instructions and handoff wording; add rules for colocating `plan.md` beside an approved `spec.md`.
- `skills/t-brainstorming/spec-document-reviewer-prompt.md`: update the reviewer dispatch path reference to `docsDev/changes/<change-id>/spec.md`.
- `skills/t-subagent-driven-development/SKILL.md`: update the example plan path used in the execution handoff example.
- `skills/t-requesting-code-review/SKILL.md`: update the `PLAN_OR_REQUIREMENTS` example path.
- `docsDev/changes/20260512-docsdev-paths/transcripts/`: create only if harness checks are run.

## Preconditions

- Do not modify `vendor/superpowers/`.
- Do not migrate historical `docs/superpowers/` files.
- Do not modify `RELEASE-NOTES.md`, old planning docs, or legacy test fixtures only because they mention upstream paths.
- Do not change stage 2 trigger-boundary behavior.
- If unrelated entry/instruction files are dirty, keep them unstaged and document any `tools/t-stage1-check.sh` blocker.

### Task 1: Baseline The Live Path Leak

**Files:**
- Read: `skills/t-brainstorming/SKILL.md`
- Read: `skills/t-writing-plans/SKILL.md`
- Read: `skills/t-brainstorming/spec-document-reviewer-prompt.md`
- Read: `skills/t-subagent-driven-development/SKILL.md`
- Read: `skills/t-requesting-code-review/SKILL.md`

- [ ] **Step 1: Confirm working tree scope**

Run:

```bash
git status --short
```

Expected before implementation: no staged files. If unrelated files are dirty, leave them unstaged.

- [ ] **Step 2: Capture current scoped old-path hits**

Run:

```bash
rg -n "docs/superpowers/(specs|plans)" skills/t-brainstorming skills/t-writing-plans skills/t-subagent-driven-development skills/t-requesting-code-review --glob "!vendor/**"
```

Expected before implementation:

```text
skills/t-brainstorming/spec-document-reviewer-prompt.md:7:**Dispatch after:** Spec document is written to docs/superpowers/specs/
skills/t-writing-plans/SKILL.md:18:**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
skills/t-writing-plans/SKILL.md:138:**"Plan complete and saved to `docs/superpowers/plans/<filename>.md`. Two execution options:**
skills/t-subagent-driven-development/SKILL.md:133:[Read plan file once: docs/superpowers/plans/feature-plan.md]
skills/t-brainstorming/SKILL.md:29:6. **Write design doc** — save to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and commit
skills/t-brainstorming/SKILL.md:111:- Write the validated design (spec) to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
skills/t-requesting-code-review/SKILL.md:60:  PLAN_OR_REQUIREMENTS: Task 2 from docs/superpowers/plans/deployment-plan.md
```

Do not treat `RELEASE-NOTES.md`, `docs/superpowers/` history, or tests as failures for this scoped live-path check.

### Task 2: Update t-brainstorming Runtime Spec Path

**Files:**
- Modify: `skills/t-brainstorming/SKILL.md`

- [ ] **Step 1: Replace checklist item 6**

Replace:

```markdown
6. **Write design doc** — save to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and commit
```

With:

```markdown
6. **Write design doc** — save to `docsDev/changes/<change-id>/spec.md` and commit
```

- [ ] **Step 2: Replace the Documentation section**

Replace the `## After the Design` subsection beginning at `**Documentation:**` and ending immediately before `**Spec Self-Review:**` with:

````markdown
**Documentation:**

- Write the validated design spec to `docsDev/changes/<change-id>/spec.md`.
- Use one change directory per brainstorming round. If the user raises an unrelated complex need while another change is active, create a new `change-id` instead of folding it into the existing spec.
- For a new change, build `change-id` as `YYYYMMDD-<slug>`:
  - Get the date with `date -u +%Y%m%d`.
  - Use a slug made of lowercase `a-z`, digits, and hyphen, length 3-40.
  - If `docsDev/changes/<change-id>/` already exists, stop and ask for a different slug or change-id.
- Use this frontmatter:

```yaml
---
change_id: <change-id>
created_at: <ISO-8601 UTC timestamp>
updated_at: <ISO-8601 UTC timestamp>
owner: <owner>
---
```

- When explicitly revising an existing spec, edit `docsDev/changes/<change-id>/spec.md` in place and append a `Change History` entry explaining the revision. Do not silently replace earlier rationale without history.
- Use elements-of-style:writing-clearly-and-concisely skill if available.
- Commit the design document to git.
````

- [ ] **Step 3: Update the user review gate wording**

In the quote under `**User Review Gate:**`, keep the generic `<path>` but ensure no sentence nearby references `docs/superpowers/`. The desired quote remains:

```markdown
> "Spec written and committed to `<path>`. Please review it and let me know if you want to make any changes before we start writing out the implementation plan."
```

- [ ] **Step 4: Verify t-brainstorming old path is gone**

Run:

```bash
rg -n "docs/superpowers/(specs|plans)" skills/t-brainstorming --glob "!vendor/**"
```

Expected after this task: no output and exit code 1.

### Task 3: Update t-writing-plans Runtime Plan Path

**Files:**
- Modify: `skills/t-writing-plans/SKILL.md`

- [ ] **Step 1: Replace the Save plans section**

Replace:

```markdown
**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
- (User preferences for plan location override this default)
```

With:

```markdown
**Save plans to:** `docsDev/changes/<change-id>/plan.md`
- If the approved spec is `docsDev/changes/<change-id>/spec.md`, save the plan beside it as `docsDev/changes/<change-id>/plan.md`.
- If the approved spec is outside `docsDev/changes/<change-id>/spec.md`, ask for the target `change-id` or docsDev change directory before writing.
- (User preferences for plan location override this default.)
```

- [ ] **Step 2: Add plan frontmatter guidance after the Plan Document Header example**

After the plan header example code block, add:

````markdown
When writing the plan file, include this frontmatter before the plan title:

```yaml
---
change_id: <change-id>
created_at: <ISO-8601 UTC timestamp>
updated_at: <ISO-8601 UTC timestamp>
owner: <owner>
---
```
````

- [ ] **Step 3: Replace the Execution Handoff saved path**

Replace:

```markdown
**"Plan complete and saved to `docs/superpowers/plans/<filename>.md`. Two execution options:**
```

With:

```markdown
**"Plan complete and saved to `docsDev/changes/<change-id>/plan.md`. Two execution options:**
```

- [ ] **Step 4: Verify t-writing-plans old path is gone**

Run:

```bash
rg -n "docs/superpowers/(specs|plans)" skills/t-writing-plans --glob "!vendor/**"
```

Expected after this task: no output and exit code 1.

### Task 4: Update Live Supporting Prompt Examples

**Files:**
- Modify: `skills/t-brainstorming/spec-document-reviewer-prompt.md`
- Modify: `skills/t-subagent-driven-development/SKILL.md`
- Modify: `skills/t-requesting-code-review/SKILL.md`

- [ ] **Step 1: Update the spec reviewer dispatch path**

In `skills/t-brainstorming/spec-document-reviewer-prompt.md`, replace:

```markdown
**Dispatch after:** Spec document is written to docs/superpowers/specs/
```

With:

```markdown
**Dispatch after:** Spec document is written to `docsDev/changes/<change-id>/spec.md`
```

- [ ] **Step 2: Update the subagent-driven development example plan path**

In `skills/t-subagent-driven-development/SKILL.md`, replace:

```markdown
[Read plan file once: docs/superpowers/plans/feature-plan.md]
```

With:

```markdown
[Read plan file once: docsDev/changes/<change-id>/plan.md]
```

- [ ] **Step 3: Update the requesting-code-review PLAN_OR_REQUIREMENTS example**

In `skills/t-requesting-code-review/SKILL.md`, replace:

```markdown
  PLAN_OR_REQUIREMENTS: Task 2 from docs/superpowers/plans/deployment-plan.md
```

With:

```markdown
  PLAN_OR_REQUIREMENTS: Task 2 from docsDev/changes/20260512-deployment-plan/plan.md
```

- [ ] **Step 4: Verify all scoped live old paths are gone**

Run:

```bash
rg -n "docs/superpowers/(specs|plans)" skills/t-brainstorming skills/t-writing-plans skills/t-subagent-driven-development skills/t-requesting-code-review --glob "!vendor/**"
```

Expected after implementation: no output and exit code 1.

### Task 5: Static Validation And Diff Review

**Files:**
- Read: modified live instruction files
- Read: `docsDev/changes/20260512-docsdev-paths/spec.md`
- Modify: `docsDev/changes/20260512-docsdev-paths/plan.md` only if execution discoveries need to be appended later

- [ ] **Step 1: Run whitespace and Markdown diff check**

Run:

```bash
git diff --check -- skills/t-brainstorming/SKILL.md skills/t-writing-plans/SKILL.md skills/t-brainstorming/spec-document-reviewer-prompt.md skills/t-subagent-driven-development/SKILL.md skills/t-requesting-code-review/SKILL.md docsDev/changes/20260512-docsdev-paths/spec.md docsDev/changes/20260512-docsdev-paths/plan.md
```

Expected: no output and exit code 0.

- [ ] **Step 2: Run scoped old-path regression scan**

Run:

```bash
rg -n "docs/superpowers/(specs|plans)" skills/t-brainstorming skills/t-writing-plans skills/t-subagent-driven-development skills/t-requesting-code-review --glob "!vendor/**"
```

Expected: no output and exit code 1.

- [ ] **Step 3: Run new-path presence scan**

Run:

```bash
rg -n "docsDev/changes/<change-id>/spec.md|docsDev/changes/<change-id>/plan.md|docsDev/changes/20260512-deployment-plan/plan.md" skills/t-brainstorming skills/t-writing-plans skills/t-subagent-driven-development skills/t-requesting-code-review --glob "!vendor/**"
```

Expected includes:

```text
skills/t-brainstorming/SKILL.md
skills/t-brainstorming/spec-document-reviewer-prompt.md
skills/t-writing-plans/SKILL.md
skills/t-subagent-driven-development/SKILL.md
skills/t-requesting-code-review/SKILL.md
```

- [ ] **Step 4: Confirm historical references remain scoped out**

Run:

```bash
rg -n "docs/superpowers/(specs|plans)" RELEASE-NOTES.md docs/superpowers tests --glob "!**/node_modules/**"
```

Expected: matches may remain. These are historical or legacy fixture references and are not failures for this change.

- [ ] **Step 5: Run stage 1 check and record blocker if present**

Run:

```bash
bash tools/t-stage1-check.sh
```

Expected if the working tree is otherwise clean: exit code 0. If it fails with `FAIL: excluded entry/instruction files have uncommitted changes`, document the dirty files and do not count it as passed.

### Task 6: Optional Runtime Harness Transcript

**Files:**
- Create: `docsDev/changes/20260512-docsdev-paths/transcripts/raw/docsdev-paths-brainstorming.jsonl`
- Create: `docsDev/changes/20260512-docsdev-paths/transcripts/raw/docsdev-paths-brainstorming.stderr.log`
- Create: `docsDev/changes/20260512-docsdev-paths/transcripts/raw/docsdev-paths-writing-plans.jsonl`
- Create: `docsDev/changes/20260512-docsdev-paths/transcripts/raw/docsdev-paths-writing-plans.stderr.log`
- Create: `docsDev/changes/20260512-docsdev-paths/transcripts/docsdev-paths-stage2.md`

This task is recommended when a Claude/Codex CLI harness is available. If runtime interaction blocks file creation at the user approval gate, save the transcript and record the blocker instead of claiming the harness passed.

- [ ] **Step 1: Create transcript directory**

Run:

```bash
mkdir -p docsDev/changes/20260512-docsdev-paths/transcripts/raw
```

- [ ] **Step 2: Create an isolated harness project**

Run:

```bash
rm -rf /tmp/t-docsdev-paths-harness
mkdir -p /tmp/t-docsdev-paths-harness
git -C /tmp/t-docsdev-paths-harness init
```

Expected: `/tmp/t-docsdev-paths-harness/.git/` exists.

- [ ] **Step 3: Run a brainstorming path harness**

Run from `/tmp/t-docsdev-paths-harness`, with transcript output written back to the main repository:

```bash
cd /tmp/t-docsdev-paths-harness
claude -p "用 t-superpowers:t-brainstorming。我要做一个 PDF 导出功能。为了验证 docsDev 路径迁移，请使用 slug pdf-export-path-harness；如果需要设计确认，使用最小设计：前端按钮触发后端 API，后端返回 PDF 文件。请把最终 spec 写入当前项目的 docsDev/changes/<change-id>/spec.md，不要写 docs/superpowers/specs/。" --plugin-dir /Users/lihuajun/WorkProject/superpowers --output-format stream-json --verbose > /Users/lihuajun/WorkProject/superpowers/docsDev/changes/20260512-docsdev-paths/transcripts/raw/docsdev-paths-brainstorming.jsonl 2> /Users/lihuajun/WorkProject/superpowers/docsDev/changes/20260512-docsdev-paths/transcripts/raw/docsdev-paths-brainstorming.stderr.log
```

Expected pass condition:

```text
/tmp/t-docsdev-paths-harness/docsDev/changes/<change-id>/spec.md exists
/tmp/t-docsdev-paths-harness/docs/superpowers/specs/ does not contain a new file from this run
```

If the command runs in the repository instead of `/tmp/t-docsdev-paths-harness`, stop and discard the harness output before committing. The harness must not create test specs in the main repo.

- [ ] **Step 4: Run a writing-plans path harness**

If Step 3 produced a temp spec, run from `/tmp/t-docsdev-paths-harness`:

```bash
claude -p "用 t-superpowers:t-writing-plans。已有 spec 在 docsDev/changes/<change-id>/spec.md。请为它创建 implementation plan，并按当前 skill 指令保存到同一个 change 目录的 plan.md，不要写 docs/superpowers/plans/。" --plugin-dir /Users/lihuajun/WorkProject/superpowers --output-format stream-json --verbose > /Users/lihuajun/WorkProject/superpowers/docsDev/changes/20260512-docsdev-paths/transcripts/raw/docsdev-paths-writing-plans.jsonl 2> /Users/lihuajun/WorkProject/superpowers/docsDev/changes/20260512-docsdev-paths/transcripts/raw/docsdev-paths-writing-plans.stderr.log
```

Before running, replace `<change-id>` in the prompt with the actual change-id created in `/tmp/t-docsdev-paths-harness/docsDev/changes/`.

Expected pass condition:

```text
/tmp/t-docsdev-paths-harness/docsDev/changes/<change-id>/plan.md exists
/tmp/t-docsdev-paths-harness/docs/superpowers/plans/ does not contain a new file from this run
```

- [ ] **Step 5: Write harness summary if runtime checks ran**

Create `docsDev/changes/20260512-docsdev-paths/transcripts/docsdev-paths-stage2.md` with:

```markdown
# DocsDev Path Migration Harness Transcript

Date: 2026-05-12

Change: `20260512-docsdev-paths`

## Summary

- Brainstorming path harness: PASS or BLOCKED with reason.
- Writing-plans path harness: PASS or BLOCKED with reason.

## Evidence

- Brainstorming raw stream: `docsDev/changes/20260512-docsdev-paths/transcripts/raw/docsdev-paths-brainstorming.jsonl`
- Brainstorming stderr: `docsDev/changes/20260512-docsdev-paths/transcripts/raw/docsdev-paths-brainstorming.stderr.log`
- Writing-plans raw stream: `docsDev/changes/20260512-docsdev-paths/transcripts/raw/docsdev-paths-writing-plans.jsonl`
- Writing-plans stderr: `docsDev/changes/20260512-docsdev-paths/transcripts/raw/docsdev-paths-writing-plans.stderr.log`

## File State

- Spec path checked: `/tmp/t-docsdev-paths-harness/docsDev/changes/<change-id>/spec.md`
- Plan path checked: `/tmp/t-docsdev-paths-harness/docsDev/changes/<change-id>/plan.md`
- Old path check: `/tmp/t-docsdev-paths-harness/docs/superpowers/`
```

- [ ] **Step 6: Verify transcript placement**

Run:

```bash
find docs/二开规划/harness-transcripts -maxdepth 2 -type f -name 'docsdev-paths-*' | sort
find docsDev/changes/20260512-docsdev-paths/transcripts -type f | sort
```

Expected:

```text
first command: no output
second command: only docsdev-paths transcript files for this change
```

### Task 7: Commit The Path Migration

**Files:**
- Modify: `skills/t-brainstorming/SKILL.md`
- Modify: `skills/t-writing-plans/SKILL.md`
- Modify: `skills/t-brainstorming/spec-document-reviewer-prompt.md`
- Modify: `skills/t-subagent-driven-development/SKILL.md`
- Modify: `skills/t-requesting-code-review/SKILL.md`
- Modify: `docsDev/changes/20260512-docsdev-paths/plan.md` only if execution logs are appended
- Create: `docsDev/changes/20260512-docsdev-paths/transcripts/` only if harness checks run

- [ ] **Step 1: Review final diff scope**

Run:

```bash
git diff --stat
git diff --name-only
```

Expected implementation files are limited to the files listed in this task. Do not stage unrelated dirty files.

- [ ] **Step 2: Stage only this change's files**

Run:

```bash
git add skills/t-brainstorming/SKILL.md
git add skills/t-writing-plans/SKILL.md
git add skills/t-brainstorming/spec-document-reviewer-prompt.md
git add skills/t-subagent-driven-development/SKILL.md
git add skills/t-requesting-code-review/SKILL.md
git add docsDev/changes/20260512-docsdev-paths/plan.md
git add docsDev/changes/20260512-docsdev-paths/transcripts
```

If no harness transcripts were created, the final `git add` may report that the path does not exist; that is acceptable.

- [ ] **Step 3: Confirm staged files exclude unrelated docs**

Run:

```bash
git diff --cached --name-only
```

Expected staged files:

```text
skills/t-brainstorming/SKILL.md
skills/t-brainstorming/spec-document-reviewer-prompt.md
skills/t-requesting-code-review/SKILL.md
skills/t-subagent-driven-development/SKILL.md
skills/t-writing-plans/SKILL.md
docsDev/changes/20260512-docsdev-paths/plan.md
```

If harness transcripts were created, `docsDev/changes/20260512-docsdev-paths/transcripts/...` may also appear.

- [ ] **Step 4: Commit after validation passes or blockers are documented**

Run:

```bash
git commit -m "feat: migrate t-superpowers artifacts to docsDev changes"
```

Expected: commit succeeds on branch `t-dev`.

## Self-Review Checklist

- Spec coverage: Tasks 2-4 cover all live instruction files named in the spec, including `t-requesting-code-review`.
- Runtime path coverage: Task 5 checks old-path removal and new-path presence in the scoped live files.
- Change-id coverage: Task 2 adds new-change, collision, unrelated-change, and explicit-revision rules to `t-brainstorming`.
- Transcript placement: Task 6 writes any harness artifacts under `docsDev/changes/20260512-docsdev-paths/transcripts/`.
- Scope check: The plan does not implement `t-archive`, `tools/t-archive-precheck`, historical docs migration, or trigger-boundary changes.
