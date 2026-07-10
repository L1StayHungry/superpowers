---
change_id: 20260710-writing-plans-v6
created_at: 2026-07-10T06:19:43Z
updated_at: 2026-07-10T07:00:12Z
owner: lihuajun
---

# Writing Plans v6 Contract Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use t-superpowers:t-subagent-driven-development (recommended) or t-superpowers:t-executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Strengthen complex implementation plans with verbatim global constraints, exact task interfaces, and reviewable task boundaries while preserving all local fork contracts.

**Architecture:** Keep planning judgment in `t-writing-plans` and protect its durable prompt contracts with one deterministic shell test. Treat the skill edit, test entrypoint, and change documentation as one delivery because they share one RED/GREEN cycle and have no independently useful behavior when separated.

**Tech Stack:** Markdown skills and change artifacts, Bash contract tests, Python 3 structural checks, Node.js package scripts, Git.

## Global Constraints

- The change identifier is `20260710-writing-plans-v6`.
- The plan artifact path is `docsDev/changes/20260710-writing-plans-v6/plan.md`.
- Skill references use the `t-superpowers:t-*` namespace.
- The repository and Codex plugin versions remain `5.1.1`.
- Do not modify `vendor/superpowers/`, `skills/t-verification-before-completion/`, or `skills/t-archive/`.
- The focused contract command is `bash tests/claude-code/test-writing-plans-contract.sh`.
- The stage regression commands are `bash tools/t-stage1-check.sh`, `npm run test:npm-installer`, and `git diff --check`.

---

### Task 1: Deliver the strengthened planning contract

**Files:**
- Modify: `skills/t-writing-plans/SKILL.md`
- Create: `tests/claude-code/test-writing-plans-contract.sh`
- Modify: `tests/claude-code/run-skill-tests.sh`
- Modify: `tests/claude-code/README.md`
- Create: `tests/claude-code/fixtures/writing-plans-contract/spec.md`
- Create: `tests/claude-code/fixtures/writing-plans-contract/plan.md`
- Create: `tests/claude-code/fixtures/writing-plans-contract/split-plan.md`
- Create: `tests/claude-code/fixtures/writing-plans-contract/na-plan.md`
- Create: `tests/claude-code/fixtures/writing-plans-contract/README.md`
- Create: `docsDev/changes/20260710-writing-plans-v6/spec.md`
- Create: `docsDev/changes/20260710-writing-plans-v6/plan.md`
- Create: `docsDev/changes/20260710-writing-plans-v6/transcripts/red-baseline.md`
- Create: `docsDev/changes/20260710-writing-plans-v6/transcripts/verification.md`

**Interfaces:**
- Consumes: the approved requirements in `docsDev/changes/20260710-writing-plans-v6/spec.md`; the existing `t-writing-plans` frontmatter contract `name: t-writing-plans` plus its exact complex-only `description`; and the `tests/claude-code/run-skill-tests.sh` fast-test list `tests: Bash array<string>`.
- Produces: the planning document contract `Global Constraints -> Task[]`, where every `Task` contains `Interfaces.Consumes: string` and `Interfaces.Produces: string`; and the command interface `bash tests/claude-code/test-writing-plans-contract.sh -> exit 0 on compliance, non-zero with a focused FAIL message on contract drift`, discoverable through `run-skill-tests.sh --test test-writing-plans-contract.sh --timeout 5`.

- [ ] **Step 1: Write the failing contract test**

Create an executable Bash test that asserts the trigger, local path, internal sub-skill names, required planning sections, TDD details, existing Claude fast-test runner entry, allowed frontmatter, every task's two interface fields, and a complete Archive Patch. Keep the audited behavior samples under the stable test-fixture directory so explicit change archival cannot break the test. The structural audit is:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SKILL_FILE="$ROOT_DIR/skills/t-writing-plans/SKILL.md"
FIXTURE_DIR="$ROOT_DIR/tests/claude-code/fixtures/writing-plans-contract"
SPEC_FILE="$FIXTURE_DIR/spec.md"
PLAN_FILE="$FIXTURE_DIR/plan.md"

grep -Fq '## Global Constraints' "$SKILL_FILE"
grep -Fq 'copy each constraint verbatim' "$SKILL_FILE"
grep -Fq '## Task Right-Sizing' "$SKILL_FILE"
grep -Fq '**Interfaces:**' "$SKILL_FILE"
grep -Fq 't-superpowers:t-subagent-driven-development' "$SKILL_FILE"

python3 - "$SPEC_FILE" "$PLAN_FILE" <<'PY'
from pathlib import Path
import re
import sys

spec = Path(sys.argv[1]).read_text()
plan = Path(sys.argv[2]).read_text()
lines = plan.splitlines()
frontmatter_end = lines.index("---", 1)
fields = [line.split(":", 1)[0] for line in lines[1:frontmatter_end] if ":" in line]
assert fields == ["change_id", "created_at", "updated_at", "owner"]
global_index = lines.index("## Global Constraints")
task_indexes = [index for index, line in enumerate(lines) if re.fullmatch(r"### Task \d+: .+", line)]
assert global_index < task_indexes[0]
for position, start in enumerate(task_indexes):
    end = task_indexes[position + 1] if position + 1 < len(task_indexes) else len(lines)
    block = lines[start:end]
    assert any(line.startswith("- Consumes: ") for line in block)
    assert any(line.startswith("- Produces: ") for line in block)
patch = spec.rsplit("## Archive Patch", 1)[1]
for field in ("Target:", "Action:", "Requirement:", "Scenario:"):
    assert field in patch
PY
```

- [ ] **Step 2: Run the contract to verify the old planning behavior fails**

Run: `bash tests/claude-code/test-writing-plans-contract.sh`

Expected: exit `1` with `FAIL: .../skills/t-writing-plans/SKILL.md is missing required contract: ## Global Constraints`. Record the exact command, exit code, key output, and conclusion in `transcripts/red-baseline.md` before editing the skill.

- [ ] **Step 3: Add the minimal planning behavior required by the failing contract**

Add these complete contract blocks to `skills/t-writing-plans/SKILL.md`, retaining the current frontmatter, local output path, complete-code rules, RED/GREEN steps, and handoff:

```markdown
## Task Right-Sizing

A task is the smallest delivery boundary that carries its own RED/GREEN test cycle and is worth a fresh reviewer's gate. Fold setup, configuration, scaffolding, and documentation into the delivery task they serve. Split only where one boundary can be tested and reviewed independently, and a reviewer could meaningfully approve it while rejecting a neighboring task.

Do not split tasks mechanically by file or technical layer. A database task, API task, UI task, or documentation-only task is too small when it cannot prove useful behavior on its own; combine those edits into the end-to-end deliverable that needs them. Conversely, do not combine unrelated behaviors merely because they touch the same file.

### Build Global Constraints from the Approved Spec

Before defining tasks, reread the approved spec and copy each constraint verbatim into `## Global Constraints`. Include versions, dependencies, naming, platforms, and exact values such as paths, command names, protocol limits, ports, timeouts, identifiers, and required copy.

- Do not paraphrase, normalize, weaken, or infer a replacement.
- Preserve exact spelling, capitalization, numbers, units, operators, and quoted text.
- If two spec statements conflict, stop and ask the human partner; do not choose one silently.

**Interfaces:**
- Consumes: [exact signatures, types, and data contracts used from existing code or earlier tasks; otherwise `N/A — <specific reason why this task has no consumed interface>`]
- Produces: [exact signatures, types, and data contracts exposed to later tasks or callers; otherwise `N/A — <specific reason why this task exposes no interface>`]
```

Extend self-review to compare global constraints against the approved spec line by line, verify exact interfaces across tasks, merge setup-only fragments into their delivery, and reject any local-path or namespace regression.

- [ ] **Step 4: Expose the focused command and complete the local change artifacts**

Add the deterministic test to the existing fast-test runner and its test catalog without changing package metadata:

```bash
tests=(
    "test-subagent-driven-development.sh"
    "test-writing-plans-contract.sh"
)
```

Write the approved spec, this task-sized plan, and RED/GREEN evidence under the change directory. Keep only `change_id`, `created_at`, `updated_at`, and `owner` in plan frontmatter, and append the spec's complete Archive Patch without invoking archive behavior.

- [ ] **Step 5: Run the focused command to verify GREEN**

Run: `bash tests/claude-code/test-writing-plans-contract.sh`

Expected: exit `0` with `PASS: writing-plans structural fixtures cover constraints, exact interfaces, both task-boundary directions, and specific N/A reasons; executable-plan validity is not claimed`.

- [ ] **Step 6: Run scoped regressions and inspect protected paths**

Run:

```bash
bash -n tests/claude-code/test-writing-plans-contract.sh
bash tools/t-stage1-check.sh
npm run test:npm-installer
git diff --check
git diff --exit-code -- vendor/superpowers skills/t-verification-before-completion skills/t-archive
```

Expected: every command exits `0`; stage-one reports all checks passed; npm installer reports all tests passed; protected-path diff is empty. Record timestamps, exit codes, and key output in `transcripts/verification.md`.

- [ ] **Step 7: Create the checkpoint commit**

```bash
git add skills/t-writing-plans/SKILL.md tests/claude-code/test-writing-plans-contract.sh tests/claude-code/run-skill-tests.sh tests/claude-code/README.md docsDev/changes/20260710-writing-plans-v6
git commit -m "feat: strengthen implementation planning contracts"
```
