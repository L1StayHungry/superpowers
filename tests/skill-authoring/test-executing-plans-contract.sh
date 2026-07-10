#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SKILL_FILE="$ROOT_DIR/skills/t-executing-plans/SKILL.md"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

grep -Fq 'Create a todo list for the plan items' "$SKILL_FILE" ||
  fail "$SKILL_FILE is missing a harness-neutral todo-list instruction"
grep -Fq 'If the current harness supports subagents' "$SKILL_FILE" ||
  fail "$SKILL_FILE is missing capability-based subagent selection"
grep -Fq 't-superpowers:t-subagent-driven-development' "$SKILL_FILE" ||
  fail "$SKILL_FILE lost the internal SDD handoff"

if grep -Eq 'TodoWrite|Claude Code|Codex CLI|Codex App|Copilot|Kimi|Pi|Antigravity|\.\./using-superpowers/references' "$SKILL_FILE"; then
  fail "$SKILL_FILE still hard-codes a harness, tool, unsupported platform, or relative platform reference"
fi

grep -Fq 'Never start implementation on main/master branch without explicit user consent' "$SKILL_FILE" ||
  fail "$SKILL_FILE lost its branch safety boundary"

printf 'PASS: executing-plans selects subagents and todo tracking by capability, not harness-specific tools\n'
