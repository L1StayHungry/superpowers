---
change_id: 20260620-finishing-commit-reorg
created_at: 2026-06-20T15:23:01Z
updated_at: 2026-06-20T16:08:34Z
owner: lihuajun
---

# Finishing Commit Reorganization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use t-superpowers:t-subagent-driven-development (recommended) or t-superpowers:t-executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a finishing-stage commit reorganization gate so completed t-superpowers work can keep checkpoint commits during implementation and then safely reorganize local, unpushed checkpoints into logical commits before merge/PR options.

**Architecture:** This is a prompt-only change to `skills/t-finishing-a-development-branch/SKILL.md`. The existing finishing flow remains intact, but gains a conservative Organize Commits step between base detection and presenting options. Safety is enforced by skip-first rules: reliable base/fork-point required, remote refs refreshed, pushed/shared commits rejected, explicit user confirmation required, `t-git-commit` constrained to add/commit only, and final tree/status equivalence checked before the workflow may continue.

**Tech Stack:** Markdown skill prompt, Git CLI, `rg`, `bash`, `tools/t-stage1-check.sh`, `tools/t-archive-precheck`.

---

## File Structure

- Modify: `skills/t-finishing-a-development-branch/SKILL.md`
  - Update overview core principle.
  - Replace base branch detection with conservative base/fork-point resolution.
  - Add `### Step 4: Organize Commits` before presenting options.
  - Renumber existing finishing steps and internal references.
  - Add Common Mistakes and Red Flags for commit reorganization.
- Existing: `docsDev/changes/20260620-finishing-commit-reorg/spec.md`
  - Source of requirements and Archive Patch. Do not rewrite during implementation unless the plan discovers a spec defect.
- Existing: `docsDev/changes/20260620-finishing-commit-reorg/plan.md`
  - This execution plan. Commit it with the implementation if it is still uncommitted when executing the plan.

## Task 1: Establish Prompt Regression Baseline

**Files:**
- Read: `skills/t-finishing-a-development-branch/SKILL.md`
- Read: `docsDev/changes/20260620-finishing-commit-reorg/spec.md`

- [ ] **Step 1: Confirm current finishing skill lacks the new behavior**

Run:

```bash
set -u
skill="skills/t-finishing-a-development-branch/SKILL.md"
missing=0
for pattern in \
  "### Step 4: Organize Commits" \
  "git fetch --all --prune" \
  "git branch -r --contains" \
  "ORIG_TREE" \
  "git status --short" \
  "reset / rebase / checkout / clean / stash / force-push" \
  "Final tree changed during commit reorganization"
do
  if ! rg -q --fixed-strings "$pattern" "$skill"; then
    echo "MISSING: $pattern"
    missing=$((missing + 1))
  fi
done
test "$missing" -gt 0
```

Expected before implementation: exit `0`, with one or more `MISSING:` lines. If this unexpectedly exits non-zero because all patterns already exist, re-read the skill and confirm this plan has already been implemented before continuing.

- [ ] **Step 2: Confirm spec requirements are available**

Run:

```bash
rg -n "Organize Commits|git fetch --all --prune|ORIG_TREE|Archive Patch|Finishing Can Reorganize Local Checkpoint Commits" docsDev/changes/20260620-finishing-commit-reorg/spec.md
```

Expected: prints matches for the organize step, remote refresh, tree equivalence, Archive Patch, and finishing requirement.

## Task 2: Rewrite Finishing Skill Flow

**Files:**
- Modify: `skills/t-finishing-a-development-branch/SKILL.md`

- [ ] **Step 1: Update the overview core principle**

In `skills/t-finishing-a-development-branch/SKILL.md`, replace the current core principle line with:

```markdown
**Core principle:** Verify tests -> Detect environment -> Determine base/fork-point -> Organize local commits when safe -> Present options -> Execute choice -> Clean up.
```

Expected: the overview now names commit organization as a safety-gated finishing step.

- [ ] **Step 2: Replace Step 3 with conservative base/fork-point detection**

Replace the existing `### Step 3: Determine Base Branch` section with this complete section:

````markdown
### Step 3: Determine Base Branch And Fork-Point

Determine a reliable local integration branch and fork-point base before presenting options or reorganizing commits. Step 5 menu's `<base-branch>` must use `INTEGRATION_BRANCH`; fork-point uses `FORK_BASE_REF`.

Try integration refs in this order:

```bash
INTEGRATION_BRANCH=""
FORK_BASE_REF=""
FORK_POINT=""

# 1. Remote default branch as fork base, only if its local branch exists
REMOTE_HEAD=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)
if [ -n "$REMOTE_HEAD" ]; then
  LOCAL_FROM_REMOTE=${REMOTE_HEAD#origin/}
  if [ "$LOCAL_FROM_REMOTE" != "$REMOTE_HEAD" ] && git show-ref --verify --quiet "refs/heads/$LOCAL_FROM_REMOTE"; then
    INTEGRATION_BRANCH=$LOCAL_FROM_REMOTE
    FORK_BASE_REF=$REMOTE_HEAD
  fi
fi

# 2. Common local integration branches
if [ -z "$INTEGRATION_BRANCH" ] && git show-ref --verify --quiet refs/heads/main; then
  INTEGRATION_BRANCH=main
  FORK_BASE_REF=main
fi
if [ -z "$INTEGRATION_BRANCH" ] && git show-ref --verify --quiet refs/heads/master; then
  INTEGRATION_BRANCH=master
  FORK_BASE_REF=master
fi

if [ -n "$FORK_BASE_REF" ]; then
  FORK_POINT=$(git merge-base HEAD "$FORK_BASE_REF" 2>/dev/null || true)
fi
```

If `INTEGRATION_BRANCH`, `FORK_BASE_REF`, or `FORK_POINT` is empty, ask the user to confirm the local integration branch. Do not accept a remote tracking ref here.

```
I can't reliably determine the local integration branch for this work. Which local branch should I use for finishing decisions?
```

After the user names a branch, set `INTEGRATION_BRANCH` to that exact local branch name, then run:

```bash
FORK_BASE_REF=$INTEGRATION_BRANCH
FORK_POINT=$(git merge-base HEAD "$FORK_BASE_REF" 2>/dev/null || true)
```

If `INTEGRATION_BRANCH`, `FORK_BASE_REF`, or `FORK_POINT` is still empty, skip commit reorganization and continue to Step 5 with checkpoint commits unchanged. Do not guess the fork-point.
````

Expected: Step 3 now produces `INTEGRATION_BRANCH`, `FORK_BASE_REF`, and `FORK_POINT`, and explicitly degrades when they cannot be determined.

- [ ] **Step 3: Insert the Organize Commits step before presenting options**

Insert this complete section immediately after Step 3 and before the existing options menu section:

````markdown
### Step 4: Organize Commits

This step is a soft dependency. It reorganizes only local, unpushed checkpoint commits. If any safety condition is uncertain, skip this step and keep the checkpoint commits.

#### 4a. Check whether `t-git-commit` is available

Decide availability only from the current platform's already exposed or callable skill inventory or workflow list. Do not guess filesystem paths or run temporary shell probes.

If a callable `t-git-commit` skill or workflow is not available in the current environment, report:

```
No local t-git-commit workflow was found. Keeping checkpoint commits unchanged.
```

Then continue to Step 5.

If `t-git-commit` is available, continue. When invoking it later, explicitly pass this constraint:

```
Organize the current worktree into logical commits. You may use git add and git commit only. Do not run reset, rebase, checkout, clean, stash, or force-push.
```

If the environment cannot reliably carry that no-history-rewrite constraint into `t-git-commit`, skip this step and continue to Step 5.

#### 4b. Refuse detached HEAD or missing fork-point

If Step 2 detected detached HEAD, skip reorganization and continue to Step 5. Detached HEAD finishing uses the reduced menu and should not rewrite local history boundaries.

If `FORK_POINT` is empty, skip reorganization and continue to Step 5.

#### 4c. Require a clean worktree

Before recording rollback anchors or running any reset, require a clean worktree:

```bash
test -z "$(git status --short)"
```

If the working tree is not clean, report:

```
Working tree is not clean. Keeping checkpoint commits unchanged so restore commands cannot discard uncommitted work.
```

Then continue to Step 5.

#### 4d. Skip empty commit ranges

Before showing reorganization options or running any reset, check whether there are commits to reorganize:

```bash
commit_count=$(git rev-list --count "$FORK_POINT"..HEAD)
```

If `commit_count` is `0`, report:

```
No local checkpoint commits to reorganize. Keeping checkpoint commits unchanged.
```

Then continue to Step 5.

#### 4e. Refresh remotes and reject shared commits

Run:

```bash
git fetch --all --prune
```

If fetch fails, report:

```
Could not refresh remote refs. Keeping checkpoint commits unchanged to avoid rewriting shared history.
```

Then continue to Step 5.

For every commit in `FORK_POINT..HEAD`, check whether it is already present on a remote branch:

```bash
shared_commit=""
remote_check_failed=""
for sha in $(git rev-list "$FORK_POINT"..HEAD); do
  remote_refs=$(git branch -r --contains "$sha")
  if [ "$?" -ne 0 ]; then
    remote_check_failed="$sha"
    break
  fi

  remote_refs=$(printf '%s\n' "$remote_refs" | sed 's/^[* ]*//' | grep -v '^[^ ]*/HEAD -> ' || true)
  if [ -n "$remote_refs" ]; then
    shared_commit="$sha"
    break
  fi
done
```

If `remote_check_failed` is non-empty, report:

```
Could not check remote containment for commit $remote_check_failed. Keeping checkpoint commits unchanged to avoid rewriting shared history.
```

Then continue to Step 5.

If `shared_commit` is non-empty, report:

```
Commit $shared_commit is already present on a remote branch. Keeping checkpoint commits unchanged; I will not force-push or rewrite shared history.
```

Then continue to Step 5.

#### 4f. Record rollback and equivalence anchors

Run:

```bash
ORIG=$(git rev-parse HEAD)
ORIG_TREE=$(git rev-parse HEAD^{tree})
```

These are only for safety. Do not reset unless the user asks to restore the pre-reorganization checkpoint state after a failed or canceled reorganization.

#### 4g. Show exactly what would be reorganized

Show the user:

```bash
git log --oneline "$FORK_POINT"..HEAD
git status --short
```

Then ask exactly:

```
I can reorganize these local checkpoint commits into logical commits using t-git-commit.

1. Reorganize commits now
2. Keep checkpoint commits as-is
3. Cancel finishing

Which option?
```

Do not run `git reset` before the user chooses option 1.

If the user chooses option 2, continue to Step 5. If the user chooses option 3, stop.

#### 4h. Soft reset and invoke `t-git-commit`

After explicit option 1 confirmation, run:

```bash
git reset --soft "$FORK_POINT"
```

Then invoke the local `t-git-commit` workflow with the no-history-rewrite constraint from 4a. The expected outcome is a clean working tree with logical commits on top of `FORK_POINT`.

If `t-git-commit` is canceled, fails, or leaves the worktree dirty, stop. Do not present merge, PR, keep, or discard options. Report:

```
Commit reorganization did not finish cleanly. The worktree still contains the feature changes. You can rerun t-git-commit, or ask me to restore the checkpoint state with git reset --hard $ORIG.
```

#### 4i. Verify reorganization preserved content

Run:

```bash
test -z "$(git status --short)"
test "$(git rev-parse HEAD^{tree})" = "$ORIG_TREE"
git log --oneline "$FORK_POINT"..HEAD
```

If the status check fails, stop and report:

```
Commit reorganization left uncommitted changes. I will not continue to merge or PR options until the worktree is clean.
```

If the tree check fails, stop and report:

```
Final tree changed during commit reorganization. I will not continue to merge or PR options. You can inspect the diff or restore the checkpoint state with git reset --hard $ORIG.
```

Only continue to Step 5 when the working tree is clean and the final tree equals `ORIG_TREE`.
````

Expected: finishing now has an explicit safety-gated commit reorganization step.

- [ ] **Step 4: Renumber existing steps and references**

Update the remaining headings and references in `skills/t-finishing-a-development-branch/SKILL.md`:

```text
### Step 4: Present Options      -> ### Step 5: Present Options
### Step 5: Execute Choice       -> ### Step 6: Execute Choice
### Step 6: Cleanup Workspace    -> ### Step 7: Cleanup Workspace
see Step 6                         -> see Step 7
Cleanup worktree (Step 6)          -> Cleanup worktree (Step 7)
```

Expected: all references after Organize Commits point to the correct step numbers.

- [ ] **Step 5: Update Common Mistakes**

Under `## Common Mistakes`, insert these entries before `**Open-ended questions**`:

```markdown
**Rewriting shared commits**
- **Problem:** Soft reset a commit that already exists on a remote branch
- **Fix:** Fetch remotes first and skip reorganization when any `FORK_POINT..HEAD` commit is contained in a remote branch

**Guessing the base branch**
- **Problem:** Use the wrong fork-point and flatten history outside the feature branch
- **Fix:** Resolve local `INTEGRATION_BRANCH` and `FORK_BASE_REF` from `origin/HEAD` plus an existing local branch, local `main`/`master`, or ask the user; skip reorganization if fork-point stays unclear

**Reorganizing with uncommitted work**
- **Problem:** Restore commands after a failed reorganization can discard unrelated uncommitted work
- **Fix:** Require clean `git status --short` before recording `ORIG`/`ORIG_TREE` or running `git reset --soft`

**Continuing after failed commit organization**
- **Problem:** Present merge or PR options while the worktree is dirty or the final tree changed
- **Fix:** Require clean `git status --short` and matching `HEAD^{tree}` before Step 5
```

Expected: Common Mistakes names the new safety risks and fixes.

- [ ] **Step 6: Update Red Flags**

In the `**Never:**` list, add:

```markdown
- Run `git reset --soft` before explicit user confirmation
- Reorganize commits while `git status --short` is not clean
- Reorganize commits when remote refs cannot be refreshed
- Reorganize commits when any feature commit is already on a remote branch
- Continue to merge/PR options after failed or dirty commit reorganization
- Let `t-git-commit` run reset, rebase, checkout, clean, stash, or force-push during finishing
```

In the `**Always:**` list, add:

```markdown
- Determine `INTEGRATION_BRANCH`, `FORK_BASE_REF`, and `FORK_POINT` before commit reorganization
- Use `INTEGRATION_BRANCH` for Step 5 `<base-branch>` and Option 1 checkout
- Skip commit reorganization when safety checks are uncertain
- Verify clean `git status --short` before recording `ORIG`/`ORIG_TREE` or soft reset
- Record `ORIG` and `ORIG_TREE` before soft reset
- Verify clean status and tree equality after commit reorganization
```

Expected: Red Flags now prevent the unsafe behaviors called out by the spec.

## Task 3: Verify The Prompt Change

**Files:**
- Verify: `skills/t-finishing-a-development-branch/SKILL.md`
- Verify: `docsDev/changes/20260620-finishing-commit-reorg/spec.md`
- Verify: `docsDev/changes/20260620-finishing-commit-reorg/plan.md`

- [ ] **Step 1: Run focused prompt checks**

Run:

```bash
set -u
skill="skills/t-finishing-a-development-branch/SKILL.md"
for pattern in \
  "### Step 3: Determine Base Branch And Fork-Point" \
  "INTEGRATION_BRANCH" \
  "FORK_BASE_REF" \
  "FORK_POINT=$(git merge-base HEAD \"$FORK_BASE_REF\"" \
  "### Step 4: Organize Commits" \
  "Working tree is not clean. Keeping checkpoint commits unchanged so restore commands cannot discard uncommitted work." \
  "git rev-list --count" \
  "git fetch --all --prune" \
  "git branch -r --contains" \
  "grep -v" \
  "ORIG_TREE" \
  "git status --short" \
  "Final tree changed during commit reorganization" \
  "reset, rebase, checkout, clean, stash, or force-push" \
  "### Step 5: Present Options" \
  "### Step 6: Execute Choice" \
  "### Step 7: Cleanup Workspace"
do
  rg -q --fixed-strings "$pattern" "$skill"
done
echo "PASS: finishing prompt contains commit reorganization gates"
```

Expected: exits `0` and prints `PASS`.

- [ ] **Step 2: Check forbidden step-number leftovers**

Run:

```bash
rg -n "see Step 6|Cleanup worktree \\(Step 6\\)|### Step 4: Present Options|### Step 5: Execute Choice|### Step 6: Cleanup Workspace" skills/t-finishing-a-development-branch/SKILL.md
```

Expected: no output and exit `1`. If output appears, update the stale references.

- [ ] **Step 3: Run namespace regression**

Run:

```bash
bash tools/t-stage1-check.sh
```

Expected: exit `0` and output `OK: Stage 1 migration self-check passed`.

- [ ] **Step 4: Confirm archive precheck is blocked while worktree is dirty**

Run before committing:

```bash
tools/t-archive-precheck 20260620-finishing-commit-reorg
```

Expected while implementation files are uncommitted: exit `5` with `FAIL[5]: working tree is not clean`. This confirms the archive safety gate is active; do not count this as Archive Patch success.

- [ ] **Step 5: Commit the implementation**

Run:

```bash
git add skills/t-finishing-a-development-branch/SKILL.md docsDev/changes/20260620-finishing-commit-reorg/spec.md docsDev/changes/20260620-finishing-commit-reorg/plan.md
git commit -m "feat: add finishing commit reorganization workflow"
```

Expected: commit succeeds. If unrelated dirty files are present, stop and ask the user how to handle them; do not stash, reset, or include unrelated files.

- [ ] **Step 6: Run post-commit Archive Patch precheck**

Run after the implementation commit, with a clean worktree:

```bash
tools/t-archive-precheck 20260620-finishing-commit-reorg
```

Expected: exit `0` and stdout JSON includes:

```json
{"change_id":"20260620-finishing-commit-reorg","archive_patches":[{"capability":"finishing","target":"docsDev/specs/finishing/spec.md","action":"create"}]}
```

If this exits `5`, run `git status --short` and report the dirty files as a blocker. Do not claim Archive Patch validation passed.

## Spec Coverage Map

- Preserve checkpoint commits during implementation: Task 2 keeps upstream implementation flow and inserts reorganization only in finishing.
- Reorganize only local unpushed checkpoints: Task 2 Step 3 adds remote refresh and `git branch -r --contains` checks.
- Explicit confirmation before soft reset: Task 2 Step 3 adds the three-option prompt and reset gate.
- `t-git-commit` soft dependency and no-history-rewrite contract: Task 2 Step 3 adds availability detection and invocation constraints.
- Integration branch/fork-point safety: Task 2 Step 2 adds conservative `INTEGRATION_BRANCH` / `FORK_BASE_REF` resolution and skip behavior.
- Stop on dirty or changed tree before/after reorganization: Task 2 Step 3 adds clean-worktree, status, and tree equality gates.
- Stage 1 namespace safety: Task 3 Step 3 runs `tools/t-stage1-check.sh`.
- Archive readiness: Task 3 Steps 4 and 6 validate dirty-worktree blocking and clean-worktree Archive Patch parsing.
