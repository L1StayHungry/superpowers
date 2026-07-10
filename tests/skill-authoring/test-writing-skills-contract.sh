#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SKILL_FILE="$ROOT_DIR/skills/t-writing-skills/SKILL.md"
CAMPAIGN_DIR="$ROOT_DIR/docsDev/skill-tests/20260710-writing-skills-form-microtest"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

require_text() {
  local needle="$1"
  grep -Fq -- "$needle" "$SKILL_FILE" || fail "$SKILL_FILE is missing required contract: $needle"
}

for contract in \
  '## Skill Discovery Optimization (SDO)' \
  '## Match the Form to the Failure' \
  'Knowledge gap' \
  'Discipline gap' \
  'Mechanical or machine-checkable error' \
  'executable validator, linter, or test' \
  '### Micro-Test Wording Before Full Scenarios' \
  'no-guidance control' \
  '5+ reps per variant' \
  'same pressure scenario' \
  'Define the rubric before sampling' \
  'preserve every raw response verbatim' \
  'model/runtime, sampling settings, timestamp' \
  'docsDev/skill-tests/' \
  '[testing-skills-with-subagents.md](testing-skills-with-subagents.md)' \
  't-superpowers:t-test-driven-development'; do
  require_text "$contract"
done

if grep -Eq 'Claude Search Optimization|Future Claude|TodoWrite|@testing-skills-with-subagents\.md|@graphviz-conventions\.dot|TWO reviews \(spec compliance then code quality\)|two-stage review process' "$SKILL_FILE"; then
  fail "$SKILL_FILE still contains harness-specific or force-loading authoring guidance"
fi

for required in README.md prompt.md rubric.md scores.md control-pilot.md guided-pilot.md; do
  [[ -f "$CAMPAIGN_DIR/$required" ]] || fail "missing stable micro-test evidence: $CAMPAIGN_DIR/$required"
done

for variant in control guided; do
  [[ -f "$CAMPAIGN_DIR/$variant/provenance.md" ]] || fail "missing provenance for $variant"
  [[ -f "$CAMPAIGN_DIR/$variant/system-prompt.md" ]] || fail "missing complete system prompt for $variant"
  count="$(find "$CAMPAIGN_DIR/$variant" -maxdepth 1 -type f -name 'run-*.md' | wc -l | tr -d ' ')"
  [[ "$count" -ge 5 ]] || fail "$variant requires at least 5 verbatim raw runs, found $count"
  find "$CAMPAIGN_DIR/$variant" -maxdepth 1 -type f -name 'run-*.md' -empty -print -quit | grep -q . &&
    fail "$variant contains an empty raw response"
done

grep -Fq 'after `rubric.md` was fixed' "$CAMPAIGN_DIR/control/provenance.md" ||
  fail "control provenance must prove final runs were sampled after the rubric was fixed"
grep -Fq 'after `rubric.md` was fixed' "$CAMPAIGN_DIR/guided/provenance.md" ||
  fail "guided provenance must prove final runs were sampled after the rubric was fixed"
[[ "$(grep -Ec '^\| guided-v2-0[1-5] .*\| 4/4 \|$' "$CAMPAIGN_DIR/scores.md")" -eq 5 ]] ||
  fail "all five final guided runs must score 4/4"
[[ "$(grep -Ec '^\| control-0[1-5] .*\| [0-3]/4 \|$' "$CAMPAIGN_DIR/scores.md")" -ge 1 ]] ||
  fail "the final no-guidance control must exhibit the target failure"

printf 'PASS: writing-skills uses SDO, failure-matched guidance, and archive-stable 5+ rep micro-test evidence\n'
