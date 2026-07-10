#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SKILL_FILE="$ROOT_DIR/skills/t-test-driven-development/SKILL.md"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

grep -Fq 'description: "Use ONLY when implementing complex behavior changes or bugfixes that need test-first work. Do NOT use for copy/style/config tweaks, Q&A, or pure code reading."' "$SKILL_FILE" ||
  fail "$SKILL_FILE widened the internal complex-only trigger"
grep -Fq '[testing-anti-patterns.md](testing-anti-patterns.md)' "$SKILL_FILE" ||
  fail "$SKILL_FILE is missing the portable relative Markdown link"

if grep -Fq '@testing-anti-patterns.md' "$SKILL_FILE"; then
  fail "$SKILL_FILE retains the harness-specific force-load syntax"
fi

grep -Fq 'NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST' "$SKILL_FILE" ||
  fail "$SKILL_FILE lost the TDD iron law"
grep -Fq 'Verify RED - Watch It Fail' "$SKILL_FILE" ||
  fail "$SKILL_FILE lost observed RED evidence"

printf 'PASS: test-driven-development uses a portable reference without widening local triggers\n'
