#!/usr/bin/env bash
# Run a subagent-driven-development test
# Usage: ./run-test.sh <test-name> [--plugin-dir <path>] [--timeout <seconds>]
#
# Example:
#   ./run-test.sh go-fractals
#   ./run-test.sh svelte-todo --plugin-dir /path/to/superpowers

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_NAME="${1:?Usage: $0 <test-name> [--plugin-dir <path>]}"
shift

# Parse optional arguments
PLUGIN_DIR=""
TIMEOUT_SECONDS=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --plugin-dir)
      PLUGIN_DIR="$2"
      shift 2
      ;;
    --timeout)
      TIMEOUT_SECONDS="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Default plugin dir to parent of tests directory
if [[ -z "$PLUGIN_DIR" ]]; then
  PLUGIN_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi

# Verify test exists
TEST_DIR="$SCRIPT_DIR/$TEST_NAME"
if [[ ! -d "$TEST_DIR" ]]; then
  echo "Error: Test '$TEST_NAME' not found at $TEST_DIR"
  echo "Available tests:"
  ls -1 "$SCRIPT_DIR" | grep -v '\.sh$' | grep -v '\.md$'
  exit 1
fi

prereq_skip() {
  echo "SKIP: prerequisite missing or unsupported: $1"
  exit 78
}

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

run_fixture_verifier() {
  local test_dir="$1"
  local project_dir="$2"
  local log_file="$3"

  if [[ ! -x "$test_dir/verify.sh" ]]; then
    return 0
  fi

  echo ">>> Running fixture verifier..."
  "$test_dir/verify.sh" "$project_dir" "$log_file"
  local status=$?
  echo ""
  return "$status"
}

check_node_for_svelte() {
  if ! command -v node >/dev/null 2>&1; then
    prereq_skip "node >= 20.19.0 or >= 22.12.0 required"
  fi

  local version major minor patch
  version="$(node -p 'process.versions.node' 2>/dev/null || true)"
  if [[ -z "$version" ]]; then
    prereq_skip "node >= 20.19.0 or >= 22.12.0 required"
  fi

  IFS=. read -r major minor patch <<< "$version"
  major="${major#v}"
  minor="${minor:-0}"

  if [[ "$major" =~ ^[0-9]+$ && "$minor" =~ ^[0-9]+$ ]]; then
    if (( major == 20 && minor >= 19 )); then return 0; fi
    if (( major == 22 && minor >= 12 )); then return 0; fi
    if (( major > 22 )); then return 0; fi
  fi

  prereq_skip "node >= 20.19.0 or >= 22.12.0 required (found $version)"
}

case "$TEST_NAME" in
  go-fractals)
    command -v go >/dev/null 2>&1 || prereq_skip "go command not found"
    ;;
  svelte-todo)
    check_node_for_svelte
    ;;
esac

if [[ -z "$TIMEOUT_SECONDS" ]]; then
  TIMEOUT_SECONDS="${SUBAGENT_TEST_TIMEOUT:-3600}"
fi

if [[ ! "$TIMEOUT_SECONDS" =~ ^[0-9]+$ || "$TIMEOUT_SECONDS" -le 0 ]]; then
  echo "Error: --timeout must be a positive integer number of seconds"
  exit 1
fi

# Create timestamped output directory
TIMESTAMP=$(date +%s)
OUTPUT_BASE="/tmp/superpowers-tests/$TIMESTAMP/subagent-driven-development"
OUTPUT_DIR="$OUTPUT_BASE/$TEST_NAME"
mkdir -p "$OUTPUT_DIR"

echo "=== Subagent-Driven Development Test ==="
echo "Test: $TEST_NAME"
echo "Output: $OUTPUT_DIR"
echo "Plugin: $PLUGIN_DIR"
echo "Timeout: ${TIMEOUT_SECONDS}s"
echo ""

# Scaffold the project
echo ">>> Scaffolding project..."
"$TEST_DIR/scaffold.sh" "$OUTPUT_DIR/project"
echo ""

# Prepare the prompt
if [[ -f "$OUTPUT_DIR/project/docsDev/changes/$TEST_NAME/plan.md" ]]; then
  PLAN_PATH="$OUTPUT_DIR/project/docsDev/changes/$TEST_NAME/plan.md"
else
  PLAN_PATH="$OUTPUT_DIR/project/plan.md"
fi
PROMPT="Execute this plan using the exact t-superpowers:t-subagent-driven-development skill, and invoke that exact skill before implementation. The plan is at: $PLAN_PATH

This is a disposable test repository created only for this harness run. You have explicit permission to work directly on the current branch. Claude Code may isolate Agent tool work in .claude/worktrees; if that happens, merge or cherry-pick every subagent commit back into the current repository before starting the next task or any review. The final implementation files and commits must be present in $OUTPUT_DIR/project so the harness can verify them.

Every implementer subagent must commit its completed task before reporting DONE. If a task creates files in a worktree, those files must be committed there and merged or cherry-picked back to $OUTPUT_DIR/project. Do not leave finished work only inside .claude/worktrees.

For Svelte dev-server checks, use bounded checks only. Prefer npm run build plus static source/module verification. If you start npm run dev, use a short timeout, stop the server yourself, and do not loop indefinitely debugging browser fetches.

Tool compatibility: Do not use the Read tool in this harness. Use Bash with read-only shell commands such as sed, grep, or python3 to inspect files.

The bundled SDD scripts are at $PLUGIN_DIR/skills/t-subagent-driven-development/scripts/. Invoke those exact scripts; do not invent alternate progress or task-brief directories."

# Run Claude with JSON output for token tracking
LOG_FILE="$OUTPUT_DIR/claude-output.json"
echo ">>> Running Claude..."
echo "Prompt: $PROMPT"
echo "Log file: $LOG_FILE"
echo ""

# Run claude and capture output
# Using stream-json to get token usage stats
# --dangerously-skip-permissions for automated testing (subagents don't inherit parent settings)
cd "$OUTPUT_DIR/project"
set +e
run_with_timeout "$TIMEOUT_SECONDS" claude -p "$PROMPT" \
  --plugin-dir "$PLUGIN_DIR" \
  --disallowed-tools Read \
  --dangerously-skip-permissions \
  --output-format stream-json \
  --verbose \
  > "$LOG_FILE" 2>&1
CLAUDE_STATUS=$?
set -e

# Extract final stats
echo ""
echo ">>> Claude exit code: $CLAUDE_STATUS"
if [[ "$CLAUDE_STATUS" -eq 124 ]]; then
  echo ">>> Test timed out after ${TIMEOUT_SECONDS}s"
elif [[ "$CLAUDE_STATUS" -ne 0 ]]; then
  echo ">>> Test failed"
else
  echo ">>> Test complete"
fi
echo "Project directory: $OUTPUT_DIR/project"
echo "Claude log: $LOG_FILE"
echo ""

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

# Show token usage if available
if command -v jq &> /dev/null; then
  echo ">>> Token usage:"
  # Extract usage from the last message with usage info
  jq -s '[.[] | select(.type == "result")] | last | .usage' "$LOG_FILE" 2>/dev/null || echo "(could not parse usage)"
  echo ""
fi

echo ">>> Next steps:"
echo "1. Review the project: cd $OUTPUT_DIR/project"
echo "2. Review Claude's log: less $LOG_FILE"
echo "3. Check if tests pass:"
case "$TEST_NAME" in
  go-fractals)
    echo "   cd $OUTPUT_DIR/project && go test ./..."
    ;;
  svelte-todo)
    echo "   cd $OUTPUT_DIR/project && npm test && npx playwright test"
    ;;
  t-smoke)
    echo "   cd $OUTPUT_DIR/project && npm test"
    ;;
esac

exit "$CLAUDE_STATUS"
