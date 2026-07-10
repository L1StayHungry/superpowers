#!/usr/bin/env bash
# Integration Test: subagent-driven-development workflow
# Actually executes a plan and verifies the new workflow behaviors
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "========================================"
echo " Integration Test: subagent-driven-development"
echo "========================================"
echo ""
echo "This test executes a real plan using the skill and verifies:"
echo "  1. Internal docsDev plan is preflighted once"
echo "  2. Task briefs and reports are file handoffs"
echo "  3. Subagents record self-review and RED/GREEN evidence"
echo "  4. One task reviewer returns spec and quality verdicts"
echo "  5. Progress ledger supports resume"
echo "  6. Final whole-branch review still runs"
echo ""
echo "WARNING: This test may take 10-30 minutes to complete."
echo ""

run_with_timeout() {
    local seconds="$1"
    shift

    if command -v timeout >/dev/null 2>&1; then
        timeout "$seconds" "$@"
        return $?
    fi

    python3 -c 'import subprocess, sys
seconds = int(sys.argv[1])
cmd = sys.argv[2:]
try:
    result = subprocess.run(cmd, timeout=seconds, stdin=subprocess.DEVNULL)
    sys.exit(result.returncode)
except subprocess.TimeoutExpired:
    sys.exit(124)
' "$seconds" "$@"
}

# Create test project
TEST_PROJECT=$(create_test_project)
echo "Test project: $TEST_PROJECT"

# Trap to cleanup
trap "cleanup_test_project $TEST_PROJECT" EXIT

# Set up minimal Node.js project
cd "$TEST_PROJECT"

cat > package.json <<'EOF'
{
  "name": "test-project",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "test": "node --test"
  }
}
EOF

mkdir -p src test docsDev/changes/sdd-integration

cat > CLAUDE.md <<'EOF'
# Test Harness Notes

Do not use the Read tool in this harness. Use shell read-only commands such as `sed -n`, `grep`, or `python3 -c` to inspect files.

If the Read tool is available despite this instruction, omit the `pages` parameter entirely on ordinary text files. Only use `pages` for paginated documents, and never pass an empty `pages` value.
EOF

# Create a simple implementation plan
cat > docsDev/changes/sdd-integration/plan.md <<'EOF'
---
change_id: sdd-integration
created_at: 2026-07-10T00:00:00Z
updated_at: 2026-07-10T00:00:00Z
owner: test
---

# Test Implementation Plan

This is a minimal plan to test the subagent-driven-development workflow.

## Global Constraints

- Use Node.js built-in test runner only.
- Keep the public module path exactly `src/math.js`.

## Task 1: Create Add Function

**Interfaces:**
- Consumes: `add(a: number, b: number): number` parameters.
- Produces: exported `add(a: number, b: number): number`.

Create a function that adds two numbers.

**File:** `src/math.js`

**Requirements:**
- Function named `add`
- Takes two parameters: `a` and `b`
- Returns the sum of `a` and `b`
- Export the function

**Implementation:**
```javascript
export function add(a, b) {
  return a + b;
}
```

**Tests:** Create `test/math.test.js` that verifies:
- `add(2, 3)` returns `5`
- `add(0, 0)` returns `0`
- `add(-1, 1)` returns `0`

**Verification:** `npm test`

## Task 2: Create Multiply Function

**Interfaces:**
- Consumes: `multiply(a: number, b: number): number` parameters and Task 1 module.
- Produces: exported `multiply(a: number, b: number): number`.

Create a function that multiplies two numbers.

**File:** `src/math.js` (add to existing file)

**Requirements:**
- Function named `multiply`
- Takes two parameters: `a` and `b`
- Returns the product of `a` and `b`
- Export the function
- DO NOT add any extra features (like power, divide, etc.)

**Implementation:**
```javascript
export function multiply(a, b) {
  return a * b;
}
```

**Tests:** Add to `test/math.test.js`:
- `multiply(2, 3)` returns `6`
- `multiply(0, 5)` returns `0`
- `multiply(-2, 3)` returns `-6`

**Verification:** `npm test`
EOF

# Initialize git repo
git init --quiet
git config user.email "test@test.com"
git config user.name "Test User"
git add .
git commit -m "Initial commit" --quiet

PLUGIN_DIR=$(cd "$SCRIPT_DIR/../.." && pwd)
EXPECTED_TASKS="1,2"
REPORT_TASK=1
RESUME_LEDGER_ARGS=()

if [[ "${SDD_RESUME_FROM_TASK1:-0}" == 1 ]]; then
    cat > src/math.js <<'EOF'
export function add(a, b) {
  return a + b;
}
EOF
    cat > test/math.test.js <<'EOF'
import test from 'node:test';
import assert from 'node:assert/strict';
import { add } from '../src/math.js';

test('add', () => {
  assert.equal(add(2, 3), 5);
  assert.equal(add(0, 0), 0);
  assert.equal(add(-1, 1), 0);
});
EOF
    git add src/math.js test/math.test.js
    git commit -m "Complete Task 1 before resume" --quiet

    SDD_DIR=$("$PLUGIN_DIR/skills/t-subagent-driven-development/scripts/sdd-workspace" \
        docsDev/changes/sdd-integration/plan.md)
    cat > "$SDD_DIR/task-1-report.md" <<'EOF'
# Task 1 report

- Status: complete
- RED: add tests failed before implementation
- GREEN: npm test passed after implementation
- Review: clean
EOF
    printf 'Task 1: complete | commits preloaded | tests 3/3 passing | review clean\n' \
        > "$SDD_DIR/progress.md"
    cp "$SDD_DIR/progress.md" "$SDD_DIR/resume-ledger-before-run.md"
    EXPECTED_TASKS="2"
    REPORT_TASK=2
    RESUME_LEDGER_ARGS=(--resume-ledger "$SDD_DIR/resume-ledger-before-run.md")
fi

echo ""
echo "Project setup complete. Starting execution..."
echo ""

# Run Claude with subagent-driven-development
# Capture full output to analyze
OUTPUT_FILE="$TEST_PROJECT/claude-output.txt"

# Create prompt file
cat > "$TEST_PROJECT/prompt.txt" <<'EOF'
I want you to execute the implementation plan at docsDev/changes/sdd-integration/plan.md using the exact t-superpowers:t-subagent-driven-development skill.

IMPORTANT: Follow the skill exactly. I will be verifying that you:
1. Read the plan once at the beginning
2. Use task briefs and report files instead of pasting full task history
3. Ensure subagents record self-review and RED/GREEN evidence
4. Use one combined task reviewer with separate spec and quality verdicts
5. Maintain the progress ledger and run a final whole-branch review

Begin now. Execute the plan.
EOF

# Note: We use a longer timeout since this is integration testing
# Use --allowed-tools to enable tool usage in headless mode
PROMPT="Execute the implementation plan at docsDev/changes/sdd-integration/plan.md using the exact t-superpowers:t-subagent-driven-development skill. Invoke that exact skill before doing any implementation work.

This is a disposable test repository created only for this integration test. You have explicit permission to work directly on the current branch. Claude Code may isolate Agent tool work in separate git worktrees; if that happens, merge or cherry-pick the subagent's committed changes back into the current repository before starting the next task or any review. All final implementation files and commits must be present in the current repository directory so the test harness can verify them.

Tool compatibility: Do not use the Read tool in this harness. Use Bash with read-only shell commands such as sed, grep, or python3 to inspect files.

The bundled SDD scripts are at $PLUGIN_DIR/skills/t-subagent-driven-development/scripts/. Invoke those exact scripts; do not invent alternate progress or task-brief directories. The repository may already contain a durable SDD progress ledger; follow the skill's resume contract instead of restarting completed work.

IMPORTANT: Follow the skill exactly. I will be verifying that you:
1. Read the plan once at the beginning
2. Use task briefs and report files instead of pasting full task history
3. Ensure subagents record self-review and RED/GREEN evidence
4. Use one combined task reviewer with separate spec and quality verdicts
5. Maintain the progress ledger and run a final whole-branch review

Begin now. Execute the plan."

# Run claude from inside the test project so its session JSONL lands in a
# project-specific directory under ~/.claude/projects/, isolated from any
# other concurrent claude sessions.
echo "Running Claude (plugin-dir: $PLUGIN_DIR, cwd: $TEST_PROJECT)..."
echo "================================================================================"
set +e
cd "$TEST_PROJECT" && run_with_timeout 1800 claude -p "$PROMPT" --plugin-dir "$PLUGIN_DIR" --allowed-tools=all --disallowed-tools Read --permission-mode bypassPermissions 2>&1 | tee "$OUTPUT_FILE"
CLAUDE_STATUS=${PIPESTATUS[0]}
set -e
if [ "$CLAUDE_STATUS" -ne 0 ]; then
    echo ""
    echo "================================================================================"
    echo "EXECUTION FAILED (exit code: $CLAUDE_STATUS)"
    exit 1
fi
echo "================================================================================"

echo ""
echo "Execution complete. Analyzing results..."
echo ""

# Find the session transcript. Because we ran claude from $TEST_PROJECT (a
# unique tmp dir), its sessions live in their own ~/.claude/projects/ folder
# and we can pick the most-recent one without racing other concurrent sessions.
# Resolve the real path because macOS mktemp returns /var/... but claude
# normalizes it to /private/var/... when naming the project dir.
TEST_PROJECT_REAL=$(cd "$TEST_PROJECT" && pwd -P)
# Claude normalizes the cwd to a directory name by replacing every non-alphanumeric
# character with `-` (so `_`, `.`, `/` all become `-`).
SESSION_DIR="$HOME/.claude/projects/$(echo "$TEST_PROJECT_REAL" | sed 's|[^a-zA-Z0-9]|-|g')"
# `|| true` prevents pipefail killing the script if ls gets SIGPIPE'd by head.
SESSION_FILE=$(ls -t "$SESSION_DIR"/*.jsonl 2>/dev/null | head -1 || true)

if [ -z "$SESSION_FILE" ]; then
    echo "ERROR: Could not find session transcript file"
    echo "Looked in: $SESSION_DIR"
    exit 1
fi

echo "Analyzing session transcript: $(basename "$SESSION_FILE")"
echo ""

# Verification tests
FAILED=0

echo "=== Verification Tests ==="
echo ""

# Test 1: Skill was invoked
echo "Test 1: Skill tool invoked..."
if grep -q '"name":"Skill".*"skill":"t-superpowers:t-subagent-driven-development"' "$SESSION_FILE"; then
    echo "  [PASS] subagent-driven-development skill was invoked"
else
    echo "  [FAIL] Skill was not invoked"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 2: Subagents were used (Agent / Task tool — name varies by harness version)
echo "Test 2: Subagents dispatched..."
task_count=$(grep -cE '"name":"(Agent|Task)"' "$SESSION_FILE" || true)
if [ "$task_count" -ge 2 ]; then
    echo "  [PASS] $task_count subagents dispatched"
else
    echo "  [FAIL] Only $task_count subagent(s) dispatched (expected >= 2)"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 3: Harness todo tracking or the durable ledger was used
echo "Test 3: Task tracking..."
todo_count=$(grep -c '"name":"TodoWrite"' "$SESSION_FILE" || true)
if [ "$todo_count" -ge 1 ]; then
    echo "  [PASS] TodoWrite used $todo_count time(s) for task tracking"
elif [ -f "$TEST_PROJECT/docsDev/changes/sdd-integration/transcripts/sdd/progress.md" ]; then
    echo "  [PASS] harness has no TodoWrite calls; durable SDD progress ledger used"
else
    echo "  [FAIL] neither harness todo tracking nor the durable ledger was used"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 4: Durable file handoffs and ledger were created under docsDev
echo "Test 4: SDD file handoffs..."
SDD_DIR="$TEST_PROJECT/docsDev/changes/sdd-integration/transcripts/sdd"
if [ -f "$SDD_DIR/.gitignore" ] \
   && [ -f "$SDD_DIR/progress.md" ] \
   && [ -f "$SDD_DIR/task-$REPORT_TASK-brief.md" ] \
   && [ -f "$SDD_DIR/task-$REPORT_TASK-report.md" ] \
   && find "$SDD_DIR" -maxdepth 1 -name 'review-*.diff' -type f | grep -q .; then
    echo "  [PASS] briefs, reports, review package, and ledger exist under docsDev"
else
    echo "  [FAIL] expected SDD handoff artifacts are incomplete under $SDD_DIR"
    find "$SDD_DIR" -maxdepth 1 -type f -print 2>/dev/null || true
    FAILED=$((FAILED + 1))
fi
if grep -Eq 'RED|Red' "$SDD_DIR/task-$REPORT_TASK-report.md" 2>/dev/null \
   && grep -Eq 'GREEN|Green' "$SDD_DIR/task-$REPORT_TASK-report.md" 2>/dev/null; then
    echo "  [PASS] implementer report contains RED/GREEN evidence"
else
    echo "  [FAIL] implementer report is missing RED/GREEN evidence"
    FAILED=$((FAILED + 1))
fi
if git -C "$TEST_PROJECT" ls-files docsDev/changes/sdd-integration/transcripts/sdd | grep -q .; then
    echo "  [FAIL] SDD scratch files were committed"
    git -C "$TEST_PROJECT" ls-files docsDev/changes/sdd-integration/transcripts/sdd
    FAILED=$((FAILED + 1))
else
    echo "  [PASS] SDD scratch files remain untracked across isolated worktrees"
fi
echo ""

# Test 5: Combined task review and final whole-branch review were dispatched
echo "Test 5: Review topology..."
if python3 "$SCRIPT_DIR/analyze-sdd-session.py" "$SESSION_FILE" \
    --tasks "$EXPECTED_TASKS" "${RESUME_LEDGER_ARGS[@]}"; then
    echo "  [PASS] Agent/Task tool calls prove one combined reviewer per task and one final review"
else
    echo "  [FAIL] Agent/Task tool-call topology did not match the SDD contract"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 6: Implementation actually works
echo "Test 6: Implementation verification..."
if [ -f "$TEST_PROJECT/src/math.js" ]; then
    echo "  [PASS] src/math.js created"

    if grep -q "export function add" "$TEST_PROJECT/src/math.js"; then
        echo "  [PASS] add function exists"
    else
        echo "  [FAIL] add function missing"
        FAILED=$((FAILED + 1))
    fi

    if grep -q "export function multiply" "$TEST_PROJECT/src/math.js"; then
        echo "  [PASS] multiply function exists"
    else
        echo "  [FAIL] multiply function missing"
        FAILED=$((FAILED + 1))
    fi
else
    echo "  [FAIL] src/math.js not created"
    FAILED=$((FAILED + 1))
fi

if [ -f "$TEST_PROJECT/test/math.test.js" ]; then
    echo "  [PASS] test/math.test.js created"
else
    echo "  [FAIL] test/math.test.js not created"
    FAILED=$((FAILED + 1))
fi

# Try running tests
if cd "$TEST_PROJECT" && npm test > test-output.txt 2>&1; then
    echo "  [PASS] Tests pass"
else
    echo "  [FAIL] Tests failed"
    cat test-output.txt
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 7: Git commits show proper workflow
echo "Test 7: Git commit history..."
commit_count=$(git -C "$TEST_PROJECT" log --oneline | wc -l)
if [ "$commit_count" -gt 2 ]; then  # Initial + at least 2 task commits
    echo "  [PASS] Multiple commits created ($commit_count total)"
else
    echo "  [FAIL] Too few commits ($commit_count, expected >2)"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 8: Check for extra features (spec compliance should catch)
echo "Test 8: No extra features added (spec compliance)..."
if grep -q "export function divide\|export function power\|export function subtract" "$TEST_PROJECT/src/math.js" 2>/dev/null; then
    echo "  [WARN] Extra features found (spec review should have caught this)"
    # Not failing on this as it tests reviewer effectiveness
else
    echo "  [PASS] No extra features added"
fi
echo ""

# Token Usage Analysis
echo "========================================="
echo " Token Usage Analysis"
echo "========================================="
echo ""
python3 "$SCRIPT_DIR/analyze-token-usage.py" "$SESSION_FILE"
echo ""

# Summary
echo "========================================"
echo " Test Summary"
echo "========================================"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "STATUS: PASSED"
    echo "All verification tests passed!"
    echo ""
    echo "The subagent-driven-development skill correctly:"
    echo "  ✓ Reads plan once at start"
    echo "  ✓ Uses file-based task briefs and reports"
    echo "  ✓ Enforces self-review"
    echo "  ✓ Uses one combined task reviewer with two verdicts"
    echo "  ✓ Runs a final whole-branch review"
    echo "  ✓ Produces working implementation"
    exit 0
else
    echo "STATUS: FAILED"
    echo "Failed $FAILED verification tests"
    echo ""
    echo "Output saved to: $OUTPUT_FILE"
    echo ""
    echo "Review the output to see what went wrong."
    exit 1
fi
