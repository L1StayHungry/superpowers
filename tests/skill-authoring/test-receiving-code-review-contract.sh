#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SKILL_FILE="$ROOT_DIR/skills/t-receiving-code-review/SKILL.md"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

grep -Fq 'explicit instruction-file violation' "$SKILL_FILE" ||
  fail "$SKILL_FILE still names one harness-specific instruction file"
grep -Fq 'Name that tension, then tell your partner about the issue' "$SKILL_FILE" ||
  fail "$SKILL_FILE is missing a direct, non-coded pushback path"
grep -Fq "current forge's thread-reply mechanism" "$SKILL_FILE" ||
  fail "$SKILL_FILE is missing forge-neutral inline reply guidance"

if grep -Eq 'CLAUDE\.md|Circle K|gh api|GitHub Thread Replies' "$SKILL_FILE"; then
  fail "$SKILL_FILE still contains a harness-specific file, coded signal, or hard-coded forge command"
fi

grep -Fq 'Verify before implementing' "$SKILL_FILE" ||
  fail "$SKILL_FILE lost its technical verification principle"
grep -Fq 'Test each fix individually' "$SKILL_FILE" ||
  fail "$SKILL_FILE lost per-finding verification"

printf 'PASS: receiving-code-review is instruction-file and forge neutral without weakening review rigor\n'
