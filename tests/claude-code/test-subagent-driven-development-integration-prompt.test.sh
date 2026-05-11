#!/usr/bin/env bash
# Static regression checks for the subagent-driven-development integration prompt.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_FILE="$SCRIPT_DIR/test-subagent-driven-development-integration.sh"

if ! grep -q "disposable test repository" "$TEST_FILE"; then
  echo "FAIL: integration prompt must say the repo is disposable"
  exit 1
fi

if ! grep -q "explicit permission to work directly on the current branch" "$TEST_FILE"; then
  echo "FAIL: integration prompt must explicitly permit current-branch work"
  exit 1
fi

if ! grep -q "merge or cherry-pick the subagent's committed changes back into the current repository" "$TEST_FILE"; then
  echo "FAIL: integration prompt must reconcile Agent worktree changes back to the test repo"
  exit 1
fi

if ! grep -q "Do not use the Read tool" "$TEST_FILE"; then
  echo "FAIL: integration prompt must tell Claude to avoid Read in this harness"
  exit 1
fi

if ! grep -q "run_with_timeout 1800 claude" "$TEST_FILE"; then
  echo "FAIL: integration script must use portable timeout helper around claude"
  exit 1
fi

if ! grep -q -- "--disallowed-tools Read" "$TEST_FILE"; then
  echo "FAIL: integration script must disable Read to avoid empty pages tool errors"
  exit 1
fi

echo "PASS: integration prompt pins disposable current-branch execution"
echo "PASS: integration script uses portable timeout helper"
