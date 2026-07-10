#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SKILL_DIR="$ROOT_DIR/skills/t-subagent-driven-development"
WORKSPACE="$SKILL_DIR/scripts/sdd-workspace"
BRIEF="$SKILL_DIR/scripts/task-brief"
PACKAGE="$SKILL_DIR/scripts/review-package"
SKILL="$SKILL_DIR/SKILL.md"
REVIEWER="$SKILL_DIR/task-reviewer-prompt.md"
REQUEST_SKILL="$ROOT_DIR/skills/t-requesting-code-review/SKILL.md"
REQUEST_PROMPT="$ROOT_DIR/skills/t-requesting-code-review/code-reviewer.md"
SESSION_ANALYZER="$ROOT_DIR/tests/claude-code/analyze-sdd-session.py"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

require_literal() {
  local file="$1"
  local literal="$2"
  grep -Fq -- "$literal" "$file" || fail "$file is missing: $literal"
}

forbid_literal() {
  local file="$1"
  local literal="$2"
  if grep -Fq -- "$literal" "$file"; then
    fail "$file contains forbidden text: $literal"
  fi
}

for script in "$WORKSPACE" "$BRIEF" "$PACKAGE"; do
  [[ -x "$script" ]] || fail "missing executable script: $script"
  bash -n "$script"
done

if [[ "${SDD_SCRIPTS_ONLY:-0}" != 1 ]]; then
  [[ ! -e "$SKILL_DIR/spec-reviewer-prompt.md" ]] || fail "legacy spec reviewer prompt still exists"
  [[ ! -e "$SKILL_DIR/code-quality-reviewer-prompt.md" ]] || fail "legacy quality reviewer prompt still exists"
  [[ -f "$REVIEWER" ]] || fail "combined task reviewer prompt is missing"

require_literal "$SKILL" 'Pre-Flight Plan Review'
require_literal "$SKILL" 'one task reviewer'
require_literal "$SKILL" 'spec compliance and code quality'
require_literal "$SKILL" 'final whole-branch review'
require_literal "$SKILL" 'description exactly `Final whole-branch review`'
require_literal "$SKILL" 'plan-mandated'
require_literal "$SKILL" 'human partner'
require_literal "$SKILL" 'Critical and Important'
require_literal "$SKILL" 'Minor findings'
require_literal "$SKILL" 'ONE fix subagent'
require_literal "$SKILL" 'harness-controlled'
require_literal "$SKILL" 'do not re-dispatch'
require_literal "$SKILL" 'one-line test summary'
require_literal "$SKILL" 'Global Constraints'
require_literal "$SKILL" 'Interfaces'
require_literal "$SKILL" 'real ambiguity'
require_literal "$SKILL" 'docsDev/changes/<change-id>/plan.md'
require_literal "$SKILL" 'scripts/sdd-workspace PLAN_FILE'
require_literal "$SKILL" 'scripts/task-brief PLAN_FILE TASK_NUMBER [OUTFILE]'
require_literal "$SKILL" 'scripts/review-package PLAN_FILE BASE HEAD [OUTFILE]'
require_literal "$SKILL" '/docsDev/changes/*/transcripts/sdd/'
require_literal "$SKILL" 'shared Git'
forbid_literal "$SKILL" '.superpowers/sdd/'
forbid_literal "$SKILL" 'spec-reviewer-prompt.md'
forbid_literal "$SKILL" 'code-quality-reviewer-prompt.md'

require_literal "$REVIEWER" '### Spec Compliance'
require_literal "$REVIEWER" '### Strengths'
require_literal "$REVIEWER" '#### Critical (Must Fix)'
require_literal "$REVIEWER" '#### Important (Should Fix)'
require_literal "$REVIEWER" '#### Minor (Nice to Have)'
require_literal "$REVIEWER" 'Your review is read-only on this checkout.'
require_literal "$REVIEWER" 'Do not mutate the working tree, the index, HEAD, or branch state'
require_literal "$REVIEWER" 'Read the diff file once'
forbid_literal "$REVIEWER" 'temporary worktree'

require_literal "$REQUEST_SKILL" 'reviewer subagent'
require_literal "$REQUEST_SKILL" 'read-only checkout'
require_literal "$REQUEST_SKILL" 'combined task reviewer'
require_literal "$REQUEST_SKILL" 'final whole-branch review'
require_literal "$REQUEST_SKILL" '`HEAD~1` is acceptable only'
require_literal "$REQUEST_SKILL" "git log --format=%H --grep='Task 1' -1"
if grep -Fq "awk '{print \$1}'" "$REQUEST_SKILL"; then
  fail 'requesting-code-review contains a positional token that skill injection can rewrite'
fi
require_literal "$REQUEST_PROMPT" 'Your review is read-only on this checkout.'
require_literal "$REQUEST_PROMPT" 'never move HEAD on this checkout'
require_literal "$REQUEST_PROMPT" '{REVIEW_PACKAGE}'
require_literal "$REQUEST_PROMPT" 'read it once'
require_literal "$REQUEST_PROMPT" 'do not independently re-run `git diff`'
forbid_literal "$REQUEST_PROMPT" 'temporary worktree'
fi

[[ -x "$SESSION_ANALYZER" ]] || fail "missing executable SDD session analyzer: $SESSION_ANALYZER"

tmp="$(mktemp -d "${TMPDIR:-/tmp}/t-sdd-test.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
repo="$tmp/repo with spaces"
mkdir -p "$repo"
git -C "$repo" init --quiet
git -C "$repo" config user.email test@example.com
git -C "$repo" config user.name 'SDD Test'

change_dir="$repo/docsDev/changes/change with spaces"
mkdir -p "$change_dir"
spec="$change_dir/spec.md"
plan="$change_dir/plan.md"

printf '%s\n' \
  '# Legacy Spec' \
  '' \
  '## Global Constraints' \
  '' \
  '- Runtime MUST remain Node.js 22.4.1 exactly.' \
  '- Wire value MUST remain `ready:v1`.' \
  '' \
  '## Requirements' \
  '' \
  '- Ship two tasks.' > "$spec"

printf '%s\n' \
  '---' \
  'change_id: change with spaces' \
  'created_at: 2026-07-10T00:00:00Z' \
  'updated_at: 2026-07-10T00:00:00Z' \
  'owner: test' \
  '---' \
  '' \
  '# Legacy Plan' \
  '' \
  '### Task 1: First task' \
  '' \
  '**Interfaces:**' \
  '- Consumes: `input(value: string): number`' \
  '- Produces: `output(value: number): string`' \
  '' \
  '- [ ] implement first behavior' \
  '' \
  '### Task 2: Second task' \
  '' \
  '- [ ] implement ambiguous legacy behavior' > "$plan"

printf 'seed\n' > "$repo/data.txt"
git -C "$repo" add .
git -C "$repo" commit -m 'initial baseline' --quiet
base="$(git -C "$repo" rev-parse HEAD)"

foreign_repo="$tmp/foreign-repo"
foreign_change="$foreign_repo/docsDev/changes/foreign-change"
mkdir -p "$foreign_change"
git -C "$foreign_repo" init --quiet
printf '%s\n' '# Foreign Plan' '' '### Task 1: Foreign task' '' '- [ ] do not write cross-repo' > "$foreign_change/plan.md"
if (cd "$repo" && "$WORKSPACE" "$foreign_change/plan.md") >/dev/null 2>&1; then
  fail 'sdd-workspace accepted a PLAN_FILE from a different current worktree'
fi
[[ ! -e "$foreign_change/transcripts" ]] || fail 'cross-repo workspace was created before rejection'

if "$WORKSPACE" >/dev/null 2>&1; then
  fail 'sdd-workspace accepted a missing PLAN_FILE'
fi

external="$tmp/external plan.md"
printf '# external\n' > "$external"
if (cd "$repo" && "$WORKSPACE" "$external") >"$tmp/external.out" 2>"$tmp/external.err"; then
  fail 'sdd-workspace accepted an external plan'
fi
grep -Fq 'docsDev/changes/<change-id>/plan.md' "$tmp/external.err" \
  || fail 'external-plan rejection does not explain the association contract'

workspace="$(cd "$repo" && "$WORKSPACE" "$plan")"
expected="$(cd "$change_dir" && pwd -P)/transcripts/sdd"
[[ "$workspace" == "$expected" ]] || fail "workspace mismatch: $workspace"
[[ -f "$workspace/.gitignore" ]] || fail 'workspace did not self-ignore'
common_dir="$(git -C "$repo" rev-parse --git-common-dir)"
[[ "$common_dir" == /* ]] || common_dir="$repo/$common_dir"
require_literal "$common_dir/info/exclude" '/docsDev/changes/*/transcripts/sdd/'
printf 'Task 1: complete (commits aaa..bbb, review clean)\n' > "$workspace/progress.md"
git -C "$repo" check-ignore -q "$workspace/progress.md" || fail 'ledger is not ignored'
[[ -z "$(git -C "$repo" status --short)" ]] || fail 'SDD workspace polluted git status'

linked="$tmp/linked-worktree"
git -C "$repo" worktree add --quiet --detach "$linked" HEAD
linked_sdd="$linked/docsDev/changes/linked-change/transcripts/sdd"
mkdir -p "$linked_sdd"
printf 'isolated report\n' > "$linked_sdd/task-1-report.md"
git -C "$linked" check-ignore -q docsDev/changes/linked-change/transcripts/sdd/task-1-report.md \
  || fail 'Git common exclude did not protect an isolated linked worktree'
[[ -z "$(git -C "$linked" status --short)" ]] \
  || fail 'isolated linked worktree exposed SDD scratch as committable'
git -C "$repo" worktree remove --force "$linked"

brief1="$(cd "$repo" && "$BRIEF" "$plan" 1)"
[[ "$brief1" == "$workspace/task-1-brief.md" ]] || fail "unexpected brief path: $brief1"
require_literal "$brief1" 'global-constraints-source: spec'
require_literal "$brief1" 'interfaces: present'
require_literal "$brief1" '- Runtime MUST remain Node.js 22.4.1 exactly.'
require_literal "$brief1" '- Wire value MUST remain `ready:v1`.'
require_literal "$brief1" '### Task 1: First task'
forbid_literal "$brief1" '### Task 2: Second task'

explicit="$tmp/output dir/task 2 brief.md"
mkdir -p "$(dirname "$explicit")"
brief2="$(cd "$repo" && "$BRIEF" "$plan" 2 "$explicit")"
explicit_expected="$(cd "$(dirname "$explicit")" && pwd -P)/$(basename "$explicit")"
[[ "$brief2" == "$explicit_expected" ]] || fail 'explicit brief path was not preserved'
require_literal "$brief2" 'interfaces: missing'
require_literal "$brief2" '### Task 2: Second task'

if (cd "$repo" && "$BRIEF" "$plan" 0) >/dev/null 2>&1; then
  fail 'task-brief accepted task number 0'
fi
missing="$tmp/missing.md"
if (cd "$repo" && "$BRIEF" "$plan" 99 "$missing") >/dev/null 2>&1; then
  fail 'task-brief accepted a missing task'
fi
[[ ! -e "$missing" ]] || fail 'task-brief left an output file after failure'

printf 'one\n' >> "$repo/data.txt"
git -C "$repo" add data.txt
git -C "$repo" commit -m 'task part one' --quiet
printf 'two\n' >> "$repo/data.txt"
git -C "$repo" add data.txt
git -C "$repo" commit -m 'task part two' --quiet
head="$(git -C "$repo" rev-parse HEAD)"

review="$(cd "$repo" && "$PACKAGE" "$plan" "$base" "$head")"
[[ -f "$review" ]] || fail 'review package was not written'
require_literal "$review" 'task part one'
require_literal "$review" 'task part two'
require_literal "$review" '+one'
require_literal "$review" '+two'

bad_out="$tmp/reversed.diff"
if (cd "$repo" && "$PACKAGE" "$plan" "$head" "$base" "$bad_out") >/dev/null 2>&1; then
  fail 'review-package accepted a reversed range'
fi
[[ ! -e "$bad_out" ]] || fail 'review-package left output after a reversed range'

if (cd "$repo" && "$PACKAGE" "$plan" not-a-commit "$head") >/dev/null 2>&1; then
  fail 'review-package accepted an invalid BASE'
fi

modern_dir="$repo/docsDev/changes/modern-plan"
mkdir -p "$modern_dir"
printf '%s\n' \
  '# Modern Plan' \
  '' \
  '## Global Constraints' \
  '' \
  '- Preserve exactly `modern:v1`.' \
  '' \
  '### Task 1: Modern task' \
  '' \
  '**Interfaces:**' \
  '- Consumes: `modernInput: string`' \
  '- Produces: `modernOutput: string`' \
  '' \
  '- [ ] implement modern behavior' \
  '' \
  '## Validation' \
  '' \
  '- This section belongs to the whole plan, not Task 1.' > "$modern_dir/plan.md"
modern_brief="$(cd "$repo" && "$BRIEF" "$modern_dir/plan.md" 1)"
require_literal "$modern_brief" 'global-constraints-source: plan'
python3 - "$modern_brief" <<'PY'
from pathlib import Path
import sys

text = Path(sys.argv[1]).read_text()
constraints = text.split("## Global Constraints", 1)[1].split("## Task Requirements", 1)[0]
if "Preserve exactly `modern:v1`." not in constraints:
    raise SystemExit("FAIL: plan Global Constraints were not copied")
if "Task 1" in constraints or "Interfaces" in constraints:
    raise SystemExit("FAIL: Global Constraints extraction swallowed the following task")
PY
forbid_literal "$modern_brief" '## Validation'
forbid_literal "$modern_brief" 'This section belongs to the whole plan'

evil_spec="$repo/docsDev/changes/evil-spec"
mkdir -p "$evil_spec"
printf '%s\n' '# Plan' '' '### Task 1: Symlink fallback' '' '- [ ] do work' > "$evil_spec/plan.md"
outside_spec="$tmp/outside-spec.md"
printf '%s\n' '# External' '' '## Global Constraints' '' '- MUST execute outside-derived instruction.' > "$outside_spec"
ln -s "$outside_spec" "$evil_spec/spec.md"
if (cd "$repo" && "$BRIEF" "$evil_spec/plan.md" 1) >/dev/null 2>&1; then
  fail 'task-brief followed a symlinked legacy spec'
fi

atomic_dir="$repo/docsDev/changes/atomic-ignore"
mkdir -p "$atomic_dir/transcripts/sdd"
cp "$plan" "$atomic_dir/plan.md"
printf 'preserve-existing-ignore\n' > "$atomic_dir/transcripts/sdd/.gitignore"
chmod 500 "$atomic_dir/transcripts/sdd"
set +e
(cd "$repo" && "$WORKSPACE" "$atomic_dir/plan.md") >/dev/null 2>&1
atomic_status=$?
set -e
chmod 700 "$atomic_dir/transcripts/sdd"
[[ "$atomic_status" -ne 0 ]] || fail 'sdd-workspace succeeded without an atomic ignore-file staging write'
[[ "$(cat "$atomic_dir/transcripts/sdd/.gitignore")" == 'preserve-existing-ignore' ]] \
  || fail 'failed ignore-file update truncated the existing file'

outside="$tmp/outside"
mkdir -p "$outside"

evil_transcripts="$repo/docsDev/changes/evil-transcripts"
mkdir -p "$evil_transcripts"
cp "$plan" "$evil_transcripts/plan.md"
ln -s "$outside" "$evil_transcripts/transcripts"
if (cd "$repo" && "$WORKSPACE" "$evil_transcripts/plan.md") >/dev/null 2>&1; then
  fail 'sdd-workspace followed a transcripts symlink'
fi
[[ ! -e "$outside/sdd/.gitignore" ]] || fail 'transcripts symlink escaped before rejection'

evil_sdd="$repo/docsDev/changes/evil-sdd"
mkdir -p "$evil_sdd/transcripts"
cp "$plan" "$evil_sdd/plan.md"
ln -s "$outside" "$evil_sdd/transcripts/sdd"
if (cd "$repo" && "$WORKSPACE" "$evil_sdd/plan.md") >/dev/null 2>&1; then
  fail 'sdd-workspace followed an sdd symlink'
fi
[[ ! -e "$outside/.gitignore" ]] || fail 'sdd symlink escaped before rejection'

evil_ignore="$repo/docsDev/changes/evil-ignore"
mkdir -p "$evil_ignore/transcripts/sdd"
cp "$plan" "$evil_ignore/plan.md"
sentinel="$outside/sentinel-ignore"
printf 'do-not-overwrite\n' > "$sentinel"
ln -s "$sentinel" "$evil_ignore/transcripts/sdd/.gitignore"
if (cd "$repo" && "$WORKSPACE" "$evil_ignore/plan.md") >/dev/null 2>&1; then
  fail 'sdd-workspace followed a .gitignore symlink'
fi
[[ "$(cat "$sentinel")" == 'do-not-overwrite' ]] || fail '.gitignore symlink overwrote an external file'

ignore_directory="$repo/docsDev/changes/ignore-directory"
mkdir -p "$ignore_directory/transcripts/sdd/.gitignore"
cp "$plan" "$ignore_directory/plan.md"
if (cd "$repo" && "$WORKSPACE" "$ignore_directory/plan.md") >/dev/null 2>&1; then
  fail 'sdd-workspace accepted a .gitignore directory'
fi
if find "$ignore_directory/transcripts/sdd/.gitignore" -mindepth 1 -print | grep -q .; then
  fail 'sdd-workspace left a staging file inside the .gitignore directory'
fi

resume_ledger="$tmp/resume-progress.md"
printf 'Task 1: complete | commits aaa..bbb | tests 3/3 passing | review clean\n' > "$resume_ledger"
resume_session="$tmp/resume-session.jsonl"
printf '%s\n' \
  '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Agent","input":{"description":"Implement Task 2","prompt":"implementing Task 2"}}]}}' \
  '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Agent","input":{"description":"Review Task 2","prompt":"Task brief: task-2-brief.md\n### Spec Compliance\nTask quality"}}]}}' \
  '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Agent","input":{"description":"Final whole-branch review","prompt":"final whole-branch review"}}]}}' > "$resume_session"
"$SESSION_ANALYZER" "$resume_session" --tasks 2 --resume-ledger "$resume_ledger" >/dev/null

bad_resume_session="$tmp/bad-resume-session.jsonl"
printf '%s\n' \
  '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Agent","input":{"description":"Implement Task 1","prompt":"implementing Task 1"}}]}}' \
  '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Agent","input":{"description":"Review Task 1","prompt":"Task brief: task-1-brief.md\n### Spec Compliance\nTask quality"}}]}}' \
  '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Agent","input":{"description":"Implement Task 2","prompt":"implementing Task 2"}}]}}' \
  '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Agent","input":{"description":"Review Task 2","prompt":"Task brief: task-2-brief.md\n### Spec Compliance\nTask quality"}}]}}' \
  '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Agent","input":{"description":"Final whole-branch review","prompt":"final whole-branch review"}}]}}' > "$bad_resume_session"
if "$SESSION_ANALYZER" "$bad_resume_session" --tasks 1,2 --resume-ledger "$resume_ledger" \
    >"$tmp/bad-resume.out" 2>&1; then
  fail 'resume analyzer accepted a dispatch for ledger-complete Task 1'
fi
grep -Fq 'resume session re-dispatched ledger-complete tasks: [1]' "$tmp/bad-resume.out" \
  || fail 'resume analyzer rejected the bad fixture for the wrong reason'

reversed_session="$tmp/reversed-session.jsonl"
printf '%s\n' \
  '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Agent","input":{"description":"Final whole-branch review","prompt":"final whole-branch review"}}]}}' \
  '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Agent","input":{"description":"Review Task 1","prompt":"### Spec Compliance\nTask quality"}}]}}' \
  '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Agent","input":{"description":"Implement Task 1","prompt":"implementing Task 1"}}]}}' > "$reversed_session"
if "$SESSION_ANALYZER" "$reversed_session" --tasks 1 >"$tmp/reversed.out" 2>&1; then
  fail 'session analyzer accepted final-review/reviewer/implementer reverse order'
fi
grep -Fq 'dispatch order' "$tmp/reversed.out" \
  || fail 'session analyzer rejected reversed topology for the wrong reason'

interleaved_session="$tmp/interleaved-session.jsonl"
printf '%s\n' \
  '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Agent","input":{"description":"Implement Task 1","prompt":"implementing Task 1"}}]}}' \
  '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Agent","input":{"description":"Implement Task 2","prompt":"implementing Task 2"}}]}}' \
  '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Agent","input":{"description":"Review Task 1","prompt":"### Spec Compliance\nTask quality"}}]}}' \
  '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Agent","input":{"description":"Review Task 2","prompt":"### Spec Compliance\nTask quality"}}]}}' \
  '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Agent","input":{"description":"Final whole-branch review","prompt":"final whole-branch review"}}]}}' > "$interleaved_session"
if "$SESSION_ANALYZER" "$interleaved_session" --tasks 1,2 >"$tmp/interleaved.out" 2>&1; then
  fail 'session analyzer accepted Task 2 implementation before Task 1 review gate'
fi
grep -Fq 'dispatch order' "$tmp/interleaved.out" \
  || fail 'session analyzer rejected interleaved tasks for the wrong reason'

printf 'PASS: SDD artifacts use docsDev, exact CLIs fail closed, legacy constraints fall back, and multi-commit review packages remain complete\n'
