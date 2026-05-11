#!/usr/bin/env bash
# Verify the t-smoke generated project and Claude log.
# Usage: ./verify.sh PROJECT_DIRECTORY CLAUDE_LOG_FILE

set -euo pipefail

PROJECT_DIR="${1:?Usage: $0 PROJECT_DIRECTORY CLAUDE_LOG_FILE}"
LOG_FILE="${2:?Usage: $0 PROJECT_DIRECTORY CLAUDE_LOG_FILE}"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

assert_clean_main_project() {
  dirty_non_worktree="$(
    git -C "$PROJECT_DIR" status --short -uall \
      | grep -Ev '^.. \.claude/worktrees/' \
      | grep -v '^$' || true
  )"
  if [ -n "$dirty_non_worktree" ]; then
    echo "$dirty_non_worktree" >&2
    fail "main project has dirty files outside .claude/worktrees"
  fi
}

test -d "$PROJECT_DIR" || fail "project directory missing: $PROJECT_DIR"
test -f "$LOG_FILE" || fail "Claude log missing: $LOG_FILE"

grep -q 't-superpowers:t-subagent-driven-development' "$LOG_FILE" \
  || fail "Claude log does not contain t-superpowers:t-subagent-driven-development"

if grep -q 'Invalid pages parameter' "$LOG_FILE"; then
  fail "Claude log contains Invalid pages parameter"
fi

if grep -Eq '"name"[[:space:]]*:[[:space:]]*"Read"' "$LOG_FILE"; then
  fail "Claude log contains a Read tool call"
fi

if grep -q 'Read(' "$LOG_FILE"; then
  fail "Claude log contains Read("
fi

test -f "$PROJECT_DIR/package.json" || fail "package.json missing from main project"
test -f "$PROJECT_DIR/src/math.js" || fail "src/math.js missing from main project"
test -f "$PROJECT_DIR/test/math.test.js" || fail "test/math.test.js missing from main project"

if ! grep -q 'node --test' "$PROJECT_DIR/package.json"; then
  fail "package.json does not define node --test"
fi

if ! grep -q 'function add' "$PROJECT_DIR/src/math.js" && ! grep -q 'add =' "$PROJECT_DIR/src/math.js"; then
  fail "src/math.js does not appear to define add"
fi

if ! grep -q 'add(2, 3)' "$PROJECT_DIR/test/math.test.js"; then
  fail "test/math.test.js does not verify add(2, 3)"
fi

commit_count="$(git -C "$PROJECT_DIR" rev-list --count HEAD)"
if [ "$commit_count" -lt 2 ]; then
  fail "expected at least 2 commits including scaffold, found $commit_count"
fi

assert_clean_main_project

(cd "$PROJECT_DIR" && npm test)

assert_clean_main_project

echo "OK: t-smoke verification passed"
