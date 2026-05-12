---
change_id: 20260512-archive-precheck
created_at: 2026-05-12T11:32:28Z
updated_at: 2026-05-12T11:32:28Z
owner: lihuajun
---

# Archive Precheck Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use t-superpowers:t-subagent-driven-development (recommended) or t-superpowers:t-executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a deterministic `tools/t-archive-precheck` command that validates archive readiness before any future archive workflow mutates repository files.

**Architecture:** Implement one Python executable under `tools/` that locates the repository root from its own path, validates the requested change directory and Archive Patch shape, resolves Archive Patch targets against `docsDev/specs/`, checks archive idempotency, and finally verifies a clean worktree. Validation uses temporary git repositories under `/tmp` so dirty-worktree and valid-pass scenarios do not pollute the main repository.

**Tech Stack:** Python 3 standard library (`pathlib`, `re`, `subprocess`, `sys`), Git CLI, Bash fixture commands, existing `tools/t-stage1-check.sh`.

---

## File Structure

- `tools/t-archive-precheck`: new executable Python script. It owns argument parsing, Archive Patch shape checks, target path safety checks, archive destination check, and working-tree cleanliness check.
- `docsDev/changes/20260512-archive-precheck/spec.md`: existing spec; read for requirements and included in final diff checks.
- `docsDev/changes/20260512-archive-precheck/plan.md`: this plan; append verification notes only if execution discoveries need to be retained.

No repository test framework is added in this change. The spec allows fixture-based validation when no existing tool-test harness fits; this plan uses temporary repositories in `/tmp`.

## Preconditions

- Do not modify `vendor/superpowers/`.
- Do not add `skills/t-archive/`.
- Do not implement Archive Patch merge, `git mv`, or archive commits.
- Do not add status fields, acceptance evidence, transcript hashing, transaction backup directories, `tools/t-validate`, or `tools/t-state`.
- Keep the main repository worktree clean except for the files owned by this change.

### Task 1: Implement The Read-Only Precheck Command

**Files:**
- Create: `tools/t-archive-precheck`

- [ ] **Step 1: Create the executable script with the full implementation**

Use `apply_patch` to create `tools/t-archive-precheck` with this content:

```python
#!/usr/bin/env python3
from pathlib import Path
import re
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[1]
SPECS_ROOT = (ROOT / "docsDev/specs").resolve(strict=False)


def die(code, message):
    print(f"FAIL[{code}]: {message}", file=sys.stderr)
    return code


def archive_patch_sections(text):
    match = re.search(r"(?m)^## Archive Patch\s*$", text)
    if not match:
        raise ValueError("Archive Patch block is missing")
    block = text[match.end():]
    sections = [part.strip() for part in re.split(r"(?m)^###\s+", block)[1:]]
    sections = [section for section in sections if section]
    if not sections:
        raise ValueError("Archive Patch has no capability sections")
    return sections


def field(pattern, body):
    match = re.search(pattern, body, re.MULTILINE)
    return match.group(1).strip() if match else None


def section_target(section):
    title = section.splitlines()[0].strip()
    target = field(r"^Target:\s*(.+?)\s*$", section)
    action = field(r"^Action:\s*(\S+)\s*$", section)
    if not target:
        raise ValueError(f"{title}: missing Target")
    if action not in {"create", "update"}:
        raise ValueError(f"{title}: Action must be create or update")
    if not re.search(r"(?m)\bRequirement:\s+\S", section):
        raise ValueError(f"{title}: missing Requirement")
    if not re.search(r"(?m)\bScenario:\s+\S", section):
        raise ValueError(f"{title}: missing Scenario")
    return target


def check_target(raw_target):
    resolved = (ROOT / raw_target).resolve(strict=False)
    if resolved == SPECS_ROOT:
        return die(3, f"Archive Patch Target must not equal specs root: {raw_target}")
    try:
        resolved.relative_to(SPECS_ROOT)
    except ValueError:
        return die(3, f"Archive Patch Target escapes docsDev/specs: {raw_target}")
    return 0


def main():
    if len(sys.argv) != 2:
        return die(1, "usage: tools/t-archive-precheck <change-id>")

    change_id = sys.argv[1]
    change_dir = ROOT / "docsDev/changes" / change_id
    spec_path = change_dir / "spec.md"
    if not change_dir.is_dir():
        return die(1, f"missing change directory: {change_dir}")
    if not spec_path.is_file():
        return die(1, f"missing spec.md: {spec_path}")

    try:
        sections = archive_patch_sections(spec_path.read_text(encoding="utf-8"))
        targets = [section_target(section) for section in sections]
    except ValueError as exc:
        return die(2, str(exc))

    for target in targets:
        code = check_target(target)
        if code:
            return code

    archive_dir = ROOT / "docsDev/archive" / change_id
    if archive_dir.exists():
        return die(4, f"archive destination already exists: {archive_dir}")

    status = subprocess.run(
        ["git", "status", "--porcelain"],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    if status.returncode != 0:
        return die(5, status.stderr.strip() or "git status failed")
    if status.stdout.strip():
        return die(5, "working tree is not clean")

    print(f"OK: archive precheck passed for {change_id}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 2: Make the script executable**

Run:

```bash
chmod +x tools/t-archive-precheck
```

- [ ] **Step 3: Check the line budget**

Run:

```bash
wc -l tools/t-archive-precheck
```

Expected: the line count is at or below `100`.

- [ ] **Step 4: Verify no mutation commands exist in the tool**

Run:

```bash
rg -n "git (add|commit|mv|reset|clean|stash)|shutil|os\\.remove|unlink\\(|rmdir\\(" tools/t-archive-precheck
```

Expected: no output and exit code `1`.

### Task 2: Validate Argument And Archive Patch Shape Failures

**Files:**
- Read: `tools/t-archive-precheck`
- Create only under `/tmp`: temporary fixture repositories

- [ ] **Step 1: Create a clean temporary fixture repository**

Run:

```bash
tmp=$(mktemp -d /tmp/t-archive-precheck-shape.XXXXXX)
repo="$tmp/repo"
mkdir -p "$repo/tools" "$repo/docsDev/changes/missing-patch" "$repo/docsDev/changes/missing-target" "$repo/docsDev/changes/missing-action" "$repo/docsDev/changes/bad-action" "$repo/docsDev/changes/missing-requirement" "$repo/docsDev/changes/missing-scenario"
cp tools/t-archive-precheck "$repo/tools/t-archive-precheck"
chmod +x "$repo/tools/t-archive-precheck"
git -C "$repo" init
git -C "$repo" config user.email "test@example.com"
git -C "$repo" config user.name "Test User"
```

- [ ] **Step 2: Add malformed spec fixtures**

Run:

```bash
cat > "$repo/docsDev/changes/missing-patch/spec.md" <<'EOF'
# Missing Patch
EOF
cat > "$repo/docsDev/changes/missing-target/spec.md" <<'EOF'
# Missing Target

## Archive Patch

### archive
Action: create

##### Requirement: Shape
###### Scenario: Has scenario
- Given input
- When checked
- Then fail
EOF
cat > "$repo/docsDev/changes/missing-action/spec.md" <<'EOF'
# Missing Action

## Archive Patch

### archive
Target: docsDev/specs/archive/spec.md

##### Requirement: Shape
###### Scenario: Has scenario
- Given input
- When checked
- Then fail
EOF
cat > "$repo/docsDev/changes/bad-action/spec.md" <<'EOF'
# Bad Action

## Archive Patch

### archive
Target: docsDev/specs/archive/spec.md
Action: delete

##### Requirement: Shape
###### Scenario: Has scenario
- Given input
- When checked
- Then fail
EOF
cat > "$repo/docsDev/changes/missing-requirement/spec.md" <<'EOF'
# Missing Requirement

## Archive Patch

### archive
Target: docsDev/specs/archive/spec.md
Action: create

###### Scenario: Has scenario
- Given input
- When checked
- Then fail
EOF
cat > "$repo/docsDev/changes/missing-scenario/spec.md" <<'EOF'
# Missing Scenario

## Archive Patch

### archive
Target: docsDev/specs/archive/spec.md
Action: create

##### Requirement: Shape
System must fail.
EOF
git -C "$repo" add .
git -C "$repo" commit -m "baseline malformed fixtures"
```

- [ ] **Step 3: Verify exit code `1` for no argument**

Run:

```bash
"$repo/tools/t-archive-precheck" >/tmp/t-precheck-noarg.out 2>&1
code=$?
test "$code" -eq 1
rg -n "FAIL\\[1\\].*usage" /tmp/t-precheck-noarg.out
```

Expected: `test` exits `0`, and `rg` finds the usage failure.

- [ ] **Step 4: Verify exit code `1` for a missing change**

Run:

```bash
"$repo/tools/t-archive-precheck" does-not-exist >/tmp/t-precheck-missing-change.out 2>&1
code=$?
test "$code" -eq 1
rg -n "FAIL\\[1\\].*missing change directory" /tmp/t-precheck-missing-change.out
```

Expected: `test` exits `0`, and `rg` finds the missing directory failure.

- [ ] **Step 5: Verify exit code `2` for malformed Archive Patch cases**

Run:

```bash
for id in missing-patch missing-target missing-action bad-action missing-requirement missing-scenario; do
  "$repo/tools/t-archive-precheck" "$id" >"/tmp/t-precheck-$id.out" 2>&1
  code=$?
  test "$code" -eq 2
  rg -n "FAIL\\[2\\]" "/tmp/t-precheck-$id.out"
done
```

Expected: every fixture exits `2`, and every output contains `FAIL[2]`.

### Task 3: Validate Target Path Safety Failures

**Files:**
- Read: `tools/t-archive-precheck`
- Create only under `/tmp`: temporary fixture repositories and symlink fixture

- [ ] **Step 1: Create a clean temporary fixture repository**

Run:

```bash
tmp=$(mktemp -d /tmp/t-archive-precheck-path.XXXXXX)
repo="$tmp/repo"
mkdir -p "$repo/tools" "$repo/docsDev/changes/dotdot" "$repo/docsDev/changes/outside" "$repo/docsDev/changes/specs-root" "$repo/docsDev/changes/symlink-escape" "$tmp/outside-target"
cp tools/t-archive-precheck "$repo/tools/t-archive-precheck"
chmod +x "$repo/tools/t-archive-precheck"
git -C "$repo" init
git -C "$repo" config user.email "test@example.com"
git -C "$repo" config user.name "Test User"
mkdir -p "$repo/docsDev/specs"
ln -s "$tmp/outside-target" "$repo/docsDev/specs/escape"
```

- [ ] **Step 2: Add path-safety spec fixtures**

Run:

```bash
for pair in \
  "dotdot|docsDev/specs/../outside/spec.md" \
  "outside|docs/superpowers/foo/spec.md" \
  "specs-root|docsDev/specs/" \
  "symlink-escape|docsDev/specs/escape/spec.md"; do
  id=${pair%%|*}
  target=${pair#*|}
  cat > "$repo/docsDev/changes/$id/spec.md" <<EOF
# $id

## Archive Patch

### archive
Target: $target
Action: create

##### Requirement: Path Safety
System must reject unsafe targets.
###### Scenario: Unsafe target
- Given an unsafe target
- When checked
- Then fail
EOF
done
git -C "$repo" add .
git -C "$repo" commit -m "baseline path fixtures"
```

- [ ] **Step 3: Verify exit code `3` for every unsafe target**

Run:

```bash
for id in dotdot outside specs-root symlink-escape; do
  "$repo/tools/t-archive-precheck" "$id" >"/tmp/t-precheck-$id.out" 2>&1
  code=$?
  test "$code" -eq 3
  rg -n "FAIL\\[3\\]" "/tmp/t-precheck-$id.out"
done
```

Expected: every fixture exits `3`, and every output contains `FAIL[3]`.

### Task 4: Validate Idempotency, Dirty Worktree, And Valid Pass

**Files:**
- Read: `tools/t-archive-precheck`
- Create only under `/tmp`: temporary fixture repositories

- [ ] **Step 1: Create a clean temporary fixture repository**

Run:

```bash
tmp=$(mktemp -d /tmp/t-archive-precheck-state.XXXXXX)
repo="$tmp/repo"
mkdir -p "$repo/tools" "$repo/docsDev/changes/good" "$repo/docsDev/changes/already-archived" "$repo/docsDev/archive/already-archived"
cp tools/t-archive-precheck "$repo/tools/t-archive-precheck"
chmod +x "$repo/tools/t-archive-precheck"
git -C "$repo" init
git -C "$repo" config user.email "test@example.com"
git -C "$repo" config user.name "Test User"
for id in good already-archived; do
  cat > "$repo/docsDev/changes/$id/spec.md" <<EOF
# $id

## Archive Patch

### archive
Target: docsDev/specs/archive/spec.md
Action: create

##### Requirement: Valid Input
System must accept valid input.
###### Scenario: Valid precheck
- Given valid input
- When checked
- Then pass
EOF
done
touch "$repo/docsDev/archive/already-archived/.keep"
git -C "$repo" add .
git -C "$repo" commit -m "baseline state fixtures"
```

- [ ] **Step 2: Verify exit code `4` for an existing archive destination**

Run:

```bash
"$repo/tools/t-archive-precheck" already-archived >/tmp/t-precheck-already-archived.out 2>&1
code=$?
test "$code" -eq 4
rg -n "FAIL\\[4\\].*archive destination already exists" /tmp/t-precheck-already-archived.out
```

Expected: `test` exits `0`, and `rg` finds the archive destination conflict.

- [ ] **Step 3: Verify exit code `0` for valid input**

Run:

```bash
"$repo/tools/t-archive-precheck" good >/tmp/t-precheck-good.out 2>&1
code=$?
test "$code" -eq 0
rg -n "OK: archive precheck passed for good" /tmp/t-precheck-good.out
```

Expected: `test` exits `0`, and `rg` finds the pass message.

- [ ] **Step 4: Verify exit code `5` for a dirty working tree**

Run:

```bash
printf 'dirty\n' > "$repo/untracked-file.txt"
"$repo/tools/t-archive-precheck" good >/tmp/t-precheck-dirty.out 2>&1
code=$?
test "$code" -eq 5
rg -n "FAIL\\[5\\].*working tree is not clean" /tmp/t-precheck-dirty.out
```

Expected: `test` exits `0`, and `rg` finds the dirty worktree failure. The dirty fixture is in `/tmp`, not in the main repository.

### Task 5: Final Repository Validation And Commit

**Files:**
- Read: `tools/t-archive-precheck`
- Read: `docsDev/changes/20260512-archive-precheck/spec.md`
- Modify: `docsDev/changes/20260512-archive-precheck/plan.md` only if appending verification notes is needed

- [ ] **Step 1: Run the exact diff check from the spec**

Run:

```bash
git diff --check -- tools/t-archive-precheck docsDev/changes/20260512-archive-precheck/spec.md docsDev/changes/20260512-archive-precheck/plan.md
```

Expected: no output and exit code `0`.

- [ ] **Step 2: Run the stage 1 namespace regression check**

Run:

```bash
bash tools/t-stage1-check.sh
```

Expected: `OK: Stage 1 migration self-check passed`.

- [ ] **Step 3: Confirm final changed files**

Run:

```bash
git diff --stat
git diff --name-only
git status --short
```

Expected changed files:

```text
tools/t-archive-precheck
docsDev/changes/20260512-archive-precheck/plan.md
```

`docsDev/changes/20260512-archive-precheck/spec.md` may appear only if execution discoveries were appended to the spec, which this plan does not require.

- [ ] **Step 4: Stage only this change's files**

Run:

```bash
git add tools/t-archive-precheck
git add docsDev/changes/20260512-archive-precheck/plan.md
```

If execution appended verification notes to the spec, also stage:

```bash
git add docsDev/changes/20260512-archive-precheck/spec.md
```

- [ ] **Step 5: Confirm staged files**

Run:

```bash
git diff --cached --name-only
git diff --cached --check
```

Expected staged files are limited to this change's tool and plan files, plus the spec only if notes were appended. `git diff --cached --check` exits `0`.

- [ ] **Step 6: Commit the implementation**

Run:

```bash
git commit -m "feat: add archive precheck tool"
```

Expected: commit succeeds on branch `t-dev`.

## Self-Review Checklist

- Spec coverage: Tasks 1-4 cover argument errors, malformed Archive Patch, target escape, specs-root target, symlink escape, existing archive destination, dirty working tree, and valid pass.
- Scope control: The plan creates only `tools/t-archive-precheck` and this plan file; it does not add `t-archive`, merge specs, move change directories, or commit archives.
- Safety: Dirty-worktree and valid-pass checks run against temporary git repositories under `/tmp`, not against the main repository while implementation files are dirty.
- Tool constraints: The planned implementation is single-file, standard-library only, no network, no LLM calls, no cleanup or mutation commands.
- Exit-code consistency: Failure branches map to the spec's stable `0-5` exit codes.

## Plan Revision: Success JSON Metadata

Date: 2026-05-12T12:17:59Z

This revision supersedes the original Task 1 success output and the original Task 4 valid-pass assertion. Keep the original task structure, but implement and validate the following changes.

### Revised Task 1 Notes

- Import `json`.
- Parse each Archive Patch section into metadata with these fields:
  - `capability`: the `### <capability>` section title.
  - `target`: the raw `Target:` value from the spec.
  - `action`: the raw `Action:` value, limited to `create` or `update`.
- Keep Requirement and Scenario checks as shape validation only.
- Do not parse or emit Requirement bodies in this change.
- On success, print only this JSON object to stdout:

```json
{
  "change_id": "<change-id>",
  "archive_patches": [
    {
      "capability": "<capability>",
      "target": "docsDev/specs/<capability>/spec.md",
      "action": "create"
    }
  ]
}
```

- On failure, continue printing `FAIL[<code>]: ...` to stderr and return the stable exit code. Do not print JSON on failure.
- `wc -l tools/t-archive-precheck` must still be at or below `100`.

### Revised Task 4 Valid-Pass Assertion

Replace the original `rg -n "OK: archive precheck passed for good"` assertion with a JSON parse assertion:

```bash
"$repo/tools/t-archive-precheck" good >/tmp/t-precheck-good.json 2>/tmp/t-precheck-good.err
code=$?
test "$code" -eq 0
test ! -s /tmp/t-precheck-good.err
python3 - <<'PY' /tmp/t-precheck-good.json
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)

assert data["change_id"] == "good"
assert data["archive_patches"] == [
    {
        "capability": "archive",
        "target": "docsDev/specs/archive/spec.md",
        "action": "create",
    }
]
PY
```

Expected: `test` exits `0`, stderr is empty, and Python exits `0`.

### Additional Real Repository Smoke Test

After the main implementation files are committed or temporarily stashed in a controlled way, run this read-only check from the real repository root:

```bash
tools/t-archive-precheck 20260512-trigger-convergence >/tmp/t-precheck-real.json 2>/tmp/t-precheck-real.err
code=$?
test "$code" -eq 0
test ! -s /tmp/t-precheck-real.err
python3 - <<'PY' /tmp/t-precheck-real.json
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)

assert data["change_id"] == "20260512-trigger-convergence"
assert data["archive_patches"][0]["capability"] == "triggering"
assert data["archive_patches"][0]["target"] == "docsDev/specs/triggering/spec.md"
assert data["archive_patches"][0]["action"] == "create"
PY
```

Expected: exit code `0`, no stderr, and JSON metadata for the real `20260512-trigger-convergence` Archive Patch.

Do not run this smoke test while the main repository has uncommitted changes; the tool is required to reject dirty worktrees with exit `5`. If running before the implementation commit, document it as postponed and run it immediately after commit.

## Verification Log
