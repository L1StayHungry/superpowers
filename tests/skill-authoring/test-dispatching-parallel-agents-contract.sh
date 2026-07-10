#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SKILL_FILE="$ROOT_DIR/skills/t-dispatching-parallel-agents/SKILL.md"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

grep -Fq 'Issue all independent subagent dispatches in the same response' "$SKILL_FILE" ||
  fail "$SKILL_FILE is missing same-response parallel dispatch guidance"
grep -Fq 'Subagent (general-purpose):' "$SKILL_FILE" ||
  fail "$SKILL_FILE is missing harness-neutral subagent examples"
grep -Fq 'Multiple dispatch calls in one response = parallel execution' "$SKILL_FILE" ||
  fail "$SKILL_FILE does not distinguish parallel from sequential dispatch"

if grep -Eq 'Task\(|TodoWrite|Claude Code / AI environment' "$SKILL_FILE"; then
  fail "$SKILL_FILE still names a harness-specific dispatch or todo tool"
fi

grep -Fq 'No shared state between investigations' "$SKILL_FILE" ||
  fail "$SKILL_FILE lost the independence safety boundary"
grep -Fq 'Run full test suite' "$SKILL_FILE" ||
  fail "$SKILL_FILE lost integration verification"

printf 'PASS: dispatching-parallel-agents uses harness-neutral same-response subagent dispatch\n'
