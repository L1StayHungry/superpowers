---
name: t-finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work - guides completion of development work by presenting structured options for merge, PR, or cleanup
---

# Finishing a Development Branch

## Overview

Guide completion of development work by presenting clear options and handling chosen workflow.

**Core principle:** Verify tests -> Detect environment -> Determine base/fork-point -> Organize local commits when safe -> Present options -> Execute choice -> Clean up.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## The Process

### Step 1: Verify Tests

**Before presenting options, verify tests pass:**

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

**If tests fail:**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

Stop. Don't proceed to Step 2.

**If tests pass:** Continue to Step 2.

### Step 2: Detect Environment

**Determine workspace state before presenting options:**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
```

This determines which menu to show and how cleanup works:

| State | Menu | Cleanup |
|-------|------|---------|
| `GIT_DIR == GIT_COMMON` (normal repo) | Standard 4 options | No worktree to clean up |
| `GIT_DIR != GIT_COMMON`, named branch | Standard 4 options | Provenance-based (see Step 7) |
| `GIT_DIR != GIT_COMMON`, detached HEAD | Reduced 3 options (no merge) | No cleanup (externally managed) |

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

If `INTEGRATION_BRANCH`, `FORK_BASE_REF`, or `FORK_POINT` is empty, skip reorganization and continue to Step 5.

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

### Step 5: Present Options

Use `INTEGRATION_BRANCH` for `<base-branch>` in the menu and local merge commands. Do not use `FORK_BASE_REF` there if it is a remote tracking ref such as `origin/main`.

**Normal repo and named-branch worktree — present exactly these 4 options:**

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

**Detached HEAD — present exactly these 3 options:**

```
Implementation complete. You're on a detached HEAD (externally managed workspace).

1. Push as new branch and create a Pull Request
2. Keep as-is (I'll handle it later)
3. Discard this work

Which option?
```

**Don't add explanation** - keep options concise.

### Step 6: Execute Choice

#### Option 1: Merge Locally

```bash
# Get main repo root for CWD safety
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"

# Merge first — verify success before removing anything
git checkout <base-branch>
git pull
git merge <feature-branch>

# Verify tests on merged result
<test command>

# Only after merge succeeds: cleanup worktree (Step 7), then delete branch
```

Then: Cleanup worktree (Step 7), then delete branch:

```bash
git branch -d <feature-branch>
```

#### Option 2: Push and Create PR

```bash
# Push branch
git push -u origin <feature-branch>

# Create PR
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
<2-3 bullets of what changed>

## Test Plan
- [ ] <verification steps>
EOF
)"
```

**Do NOT clean up worktree** — user needs it alive to iterate on PR feedback.

#### Option 3: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

**Don't cleanup worktree.**

#### Option 4: Discard

**Confirm first:**
```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

Wait for exact confirmation.

If confirmed:
```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
```

Then: Cleanup worktree (Step 7), then force-delete branch:
```bash
git branch -D <feature-branch>
```

### Step 7: Cleanup Workspace

**Only runs for Options 1 and 4.** Options 2 and 3 always preserve the worktree.

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
WORKTREE_PATH=$(git rev-parse --show-toplevel)
```

**If `GIT_DIR == GIT_COMMON`:** Normal repo, no worktree to clean up. Done.

**If worktree path is under `.worktrees/`, `worktrees/`, or `~/.config/superpowers/worktrees/`:** Superpowers created this worktree — we own cleanup.

```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
git worktree remove "$WORKTREE_PATH"
git worktree prune  # Self-healing: clean up any stale registrations
```

**Otherwise:** The host environment (harness) owns this workspace. Do NOT remove it. If your platform provides a workspace-exit tool, use it. Otherwise, leave the workspace in place.

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally | yes | - | - | yes |
| 2. Create PR | - | yes | yes | - |
| 3. Keep as-is | - | - | yes | - |
| 4. Discard | - | - | - | yes (force) |

## Common Mistakes

**Skipping test verification**
- **Problem:** Merge broken code, create failing PR
- **Fix:** Always verify tests before offering options

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

**Open-ended questions**
- **Problem:** "What should I do next?" is ambiguous
- **Fix:** Present exactly 4 structured options (or 3 for detached HEAD)

**Cleaning up worktree for Option 2**
- **Problem:** Remove worktree user needs for PR iteration
- **Fix:** Only cleanup for Options 1 and 4

**Deleting branch before removing worktree**
- **Problem:** `git branch -d` fails because worktree still references the branch
- **Fix:** Merge first, remove worktree, then delete branch

**Running git worktree remove from inside the worktree**
- **Problem:** Command fails silently when CWD is inside the worktree being removed
- **Fix:** Always `cd` to main repo root before `git worktree remove`

**Cleaning up harness-owned worktrees**
- **Problem:** Removing a worktree the harness created causes phantom state
- **Fix:** Only clean up worktrees under `.worktrees/`, `worktrees/`, or `~/.config/superpowers/worktrees/`

**No confirmation for discard**
- **Problem:** Accidentally delete work
- **Fix:** Require typed "discard" confirmation

## Red Flags

**Never:**
- Proceed with failing tests
- Merge without verifying tests on result
- Delete work without confirmation
- Force-push without explicit request
- Use a remote tracking ref such as `origin/main` as the Step 5 `<base-branch>` or local merge checkout target
- Run `git reset --soft` before explicit user confirmation
- Reorganize commits while `git status --short` is not clean
- Reorganize commits when remote refs cannot be refreshed
- Reorganize commits when any feature commit is already on a remote branch
- Continue to merge/PR options after failed or dirty commit reorganization
- Let `t-git-commit` run reset, rebase, checkout, clean, stash, or force-push during finishing
- Remove a worktree before confirming merge success
- Clean up worktrees you didn't create (provenance check)
- Run `git worktree remove` from inside the worktree

**Always:**
- Verify tests before offering options
- Detect environment before presenting menu
- Determine `INTEGRATION_BRANCH`, `FORK_BASE_REF`, and `FORK_POINT` before commit reorganization
- Use `INTEGRATION_BRANCH` for Step 5 `<base-branch>` and Option 1 checkout
- Skip commit reorganization when safety checks are uncertain
- Verify clean `git status --short` before recording `ORIG`/`ORIG_TREE` or soft reset
- Record `ORIG` and `ORIG_TREE` before soft reset
- Verify clean status and tree equality after commit reorganization
- Present exactly 4 options (or 3 for detached HEAD)
- Get typed confirmation for Option 4
- Clean up worktree for Options 1 & 4 only
- `cd` to main repo root before worktree removal
- Run `git worktree prune` after removal
