#!/usr/bin/env bash
# Test: subagent-driven-development skill
# Verifies that the skill is loaded and follows correct workflow
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

CLAUDE_TEST_TIMEOUT="${CLAUDE_TEST_TIMEOUT:-90}"

echo "=== Test: subagent-driven-development skill ==="
echo ""

# Test 1: Verify skill can be loaded
echo "Test 1: Skill loading..."

output=$(run_claude "Use the t-superpowers:t-subagent-driven-development skill before answering. Answer in English. What are its key steps?" "$CLAUDE_TEST_TIMEOUT")

if assert_contains "$output" "subagent-driven-development\|Subagent-Driven Development\|Subagent Driven" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "plan\|pre.flight" "Mentions plan preflight"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Verify one combined task reviewer returns two verdicts
echo "Test 2: Combined task review..."

output=$(run_claude "Use the t-superpowers:t-subagent-driven-development skill before answering. Answer in English. How many reviewers are dispatched for each task, and which two separate verdicts must that reviewer return?" "$CLAUDE_TEST_TIMEOUT")

if assert_contains "$output" "one\|single\|1" "One task reviewer"; then
    : # pass
else
    exit 1
fi
if assert_contains "$output" "spec.*compliance" "Spec compliance verdict" \
   && assert_contains "$output" "code.*quality\|task.*quality" "Code quality verdict"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Verify self-review is mentioned
echo "Test 3: Self-review requirement..."

output=$(run_claude "Use the t-superpowers:t-subagent-driven-development skill before answering. Answer in English. Must implementers do self-review, and what should they check?" "$CLAUDE_TEST_TIMEOUT")

if assert_contains "$output" "self-review\|self review" "Mentions self-review"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "tests\|RED\|GREEN\|files changed\|commits" "Records implementation and test evidence"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 4: Verify plan is read once
echo "Test 4: Plan reading efficiency..."

output=$(run_claude "Use the t-superpowers:t-subagent-driven-development skill before answering. Answer in English. How many times should the controller scan the full plan, and when?" "$CLAUDE_TEST_TIMEOUT")

if assert_contains "$output" "once\|one time\|single" "Read plan once"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "Step 1\|beginning\|start\|before.*Task" "Read before Task 1"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 5: Verify combined reviewer is skeptical and diff-focused
echo "Test 5: Task reviewer mindset..."

output=$(run_claude "Use the t-superpowers:t-subagent-driven-development skill before answering. Answer in English. What is the task reviewer's attitude toward the implementer report, and what file does it inspect?" "$CLAUDE_TEST_TIMEOUT")

if assert_contains "$output" "not trust\|don't trust\|skeptical\|verify.*independently\|suspiciously" "Reviewer is skeptical"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "diff\|review package" "Reviewer reads the review package"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 6: Verify review loops
echo "Test 6: Review loop requirements..."

output=$(run_claude "Use the t-superpowers:t-subagent-driven-development skill before answering. Answer in English. What happens if a task reviewer finds issues: one-time review or loop?" "$CLAUDE_TEST_TIMEOUT")

if assert_contains "$output" "loop\|again\|repeat\|until.*approved\|until.*compliant" "Review loops mentioned"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "fixer\|fix subagent\|implementer.*fix\|fix.*issues" "A fix agent addresses blocking issues"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 7: Verify task information moves through a brief file
echo "Test 7: File-based task handoff..."

output=$(run_claude "Use the t-superpowers:t-subagent-driven-development skill before answering. Answer in English. How does the controller provide one task's requirements without pasting the whole plan?" "$CLAUDE_TEST_TIMEOUT")

if assert_contains "$output" "task.*brief\|brief.*file\|task-brief" "Provides a task brief file"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "not.*whole.*plan\|does not.*read.*plan\|don't.*paste.*plan\|never.*paste.*plan" "Doesn't hand over the whole plan"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 8: Verify worktree requirement
echo "Test 8: Worktree requirement..."

output=$(run_claude "Use the t-superpowers:t-subagent-driven-development skill before answering. Answer in English. What workflow skills are required before using it?" "$CLAUDE_TEST_TIMEOUT")

if assert_contains "$output" "using-git-worktrees\|worktree" "Mentions worktree requirement"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 9: Verify main branch warning
echo "Test 9: Main branch red flag..."

output=$(run_claude "Use the t-superpowers:t-subagent-driven-development skill before answering. Answer in English. Is it okay to start directly on main?" "$CLAUDE_TEST_TIMEOUT")

if assert_contains "$output" "worktree\|feature.*branch\|not.*main\|never.*main\|avoid.*main\|don't.*main\|consent\|permission" "Warns against main branch"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 10: Verify final whole-branch review remains mandatory
echo "Test 10: Final whole-branch review..."

output=$(run_claude "Use the t-superpowers:t-subagent-driven-development skill before answering. Answer in English. After every task passes its task review, what review still must run?" "$CLAUDE_TEST_TIMEOUT")

if assert_contains "$output" "final.*whole.branch\|whole.branch.*review\|broad.*final.*review" "Requires final whole-branch review"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All subagent-driven-development skill tests passed ==="
