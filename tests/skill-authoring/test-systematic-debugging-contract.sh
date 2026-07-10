#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SKILL_FILE="$ROOT_DIR/skills/t-systematic-debugging/SKILL.md"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

grep -Fq 'description: "Use ONLY for complex bugs, failing tests, or unexpected behavior where the root cause is unknown. Do NOT use for simple edits, Q&A, or pure code reading."' "$SKILL_FILE" ||
  fail "$SKILL_FILE widened the internal complex-only trigger"
grep -Fq '"Ultra-think this" - Question fundamentals, not just symptoms' "$SKILL_FILE" ||
  fail "$SKILL_FILE is missing the delimiter-safe Ultra-think signal"

if grep -Fq '"Ultrathink this"' "$SKILL_FILE"; then
  fail "$SKILL_FILE retains the concatenated Ultrathink false-trigger token"
fi

grep -Fq 't-superpowers:t-test-driven-development' "$SKILL_FILE" ||
  fail "$SKILL_FILE lost the internal TDD reference"
grep -Fq 't-superpowers:t-verification-before-completion' "$SKILL_FILE" ||
  fail "$SKILL_FILE lost the internal verification reference"

printf 'PASS: systematic-debugging fixes the Ultra-think token without widening local triggers\n'
