#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SKILL_FILE="$ROOT_DIR/skills/t-writing-plans/SKILL.md"
RUNNER_FILE="$ROOT_DIR/tests/claude-code/run-skill-tests.sh"
FIXTURE_DIR="$ROOT_DIR/tests/claude-code/fixtures/writing-plans-contract"
FIXTURE_README="$FIXTURE_DIR/README.md"
SPEC_FILE="$FIXTURE_DIR/spec.md"
PLAN_FILE="$FIXTURE_DIR/plan.md"
SPLIT_PLAN_FILE="$FIXTURE_DIR/split-plan.md"
NA_PLAN_FILE="$FIXTURE_DIR/na-plan.md"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

require_literal() {
  local file="$1"
  local text="$2"
  grep -Fq -- "$text" "$file" || fail "$file is missing required contract: $text"
}

forbid_literal() {
  local file="$1"
  local text="$2"
  if grep -Fq -- "$text" "$file"; then
    fail "$file contains forbidden upstream contract: $text"
  fi
}

require_literal "$SKILL_FILE" 'description: "Use ONLY when a complex approved spec or requirements need a multi-step implementation plan before coding. Do NOT use for simple single-file edits, Q&A, or pure code reading."'
require_literal "$SKILL_FILE" 'docsDev/changes/<change-id>/plan.md'
require_literal "$SKILL_FILE" 't-superpowers:t-subagent-driven-development'
require_literal "$SKILL_FILE" 't-superpowers:t-executing-plans'
forbid_literal "$SKILL_FILE" 'docs/superpowers/'
forbid_literal "$SKILL_FILE" 'two-stage review'

python3 - "$SKILL_FILE" <<'PY'
from pathlib import Path
import re
import sys

skill = Path(sys.argv[1]).read_text()
if re.search(r"(?<!t-)superpowers:", skill):
    raise SystemExit("FAIL: skill contains an unprefixed upstream namespace")
PY

require_literal "$SKILL_FILE" '## Global Constraints'
require_literal "$SKILL_FILE" 'copy each constraint verbatim'
require_literal "$SKILL_FILE" 'versions, dependencies, naming, platforms, and exact values'
require_literal "$SKILL_FILE" 'Do not paraphrase, normalize, weaken, or infer a replacement.'
require_literal "$SKILL_FILE" '## Task Right-Sizing'
require_literal "$SKILL_FILE" 'configuration, scaffolding, and documentation'
require_literal "$SKILL_FILE" 'Do not split tasks mechanically by file or technical layer.'
require_literal "$SKILL_FILE" 'Conversely, do not combine unrelated behaviors merely because they touch the same file.'
require_literal "$SKILL_FILE" '**Interfaces:**'
require_literal "$SKILL_FILE" '- Consumes: '
require_literal "$SKILL_FILE" '- Produces: '
require_literal "$SKILL_FILE" 'N/A — <specific reason why this task has no consumed interface>'
require_literal "$SKILL_FILE" 'N/A — <specific reason why this task exposes no interface>'
require_literal "$SKILL_FILE" 'exact signatures, types, and data contracts'
require_literal "$SKILL_FILE" 'Complete code in every step'
require_literal "$SKILL_FILE" 'Run test to verify it fails'
require_literal "$SKILL_FILE" 'Run test to verify it passes'
require_literal "$SKILL_FILE" 'checkpoint commit'
require_literal "$SKILL_FILE" 'one consolidated reviewer returning separate specification and quality verdicts'
require_literal "$RUNNER_FILE" '"test-writing-plans-contract.sh"'

[[ -f "$FIXTURE_README" ]] || fail "missing fixture disclaimer: $FIXTURE_README"
[[ -f "$SPEC_FILE" ]] || fail "missing stable spec fixture: $SPEC_FILE"
[[ -f "$PLAN_FILE" ]] || fail "missing stable plan fixture: $PLAN_FILE"
[[ -f "$SPLIT_PLAN_FILE" ]] || fail "missing split-boundary fixture: $SPLIT_PLAN_FILE"
[[ -f "$NA_PLAN_FILE" ]] || fail "missing N/A interface fixture: $NA_PLAN_FILE"
require_literal "$FIXTURE_README" 'structural contract fixtures, NOT generated executable plans'
require_literal "$SPEC_FILE" 'Structural Spec Fixture — NOT an Executable Plan'
require_literal "$PLAN_FILE" 'Structural Contract Fixture — NOT a Generated Executable Plan'
require_literal "$SPLIT_PLAN_FILE" 'Split-Boundary Structural Fixture — NOT a Generated Executable Plan'
require_literal "$NA_PLAN_FILE" 'N/A Interface Structural Fixture — NOT a Generated Executable Plan'

python3 - "$SPEC_FILE" "$PLAN_FILE" "$SPLIT_PLAN_FILE" "$NA_PLAN_FILE" <<'PY'
from pathlib import Path
import re
import sys

spec_path = Path(sys.argv[1])
plan_path = Path(sys.argv[2])
split_plan_path = Path(sys.argv[3])
na_plan_path = Path(sys.argv[4])
spec = spec_path.read_text()
plan = plan_path.read_text()
split_plan = split_plan_path.read_text()
na_plan = na_plan_path.read_text()

plan_lines = plan.splitlines()
if not plan_lines or plan_lines[0] != "---":
    raise SystemExit("FAIL: plan must begin with YAML frontmatter")
try:
    frontmatter_end = plan_lines.index("---", 1)
except ValueError:
    raise SystemExit("FAIL: plan frontmatter is not closed")
fields = [line.split(":", 1)[0] for line in plan_lines[1:frontmatter_end] if ":" in line]
allowed = ["change_id", "created_at", "updated_at", "owner"]
if fields != allowed:
    raise SystemExit(f"FAIL: plan frontmatter fields must be exactly {allowed}, got {fields}")

if "docs/superpowers/" in plan or re.search(r"(?<!t-)superpowers:", plan):
    raise SystemExit("FAIL: plan leaked an upstream path or namespace")

global_index = next((index for index, line in enumerate(plan_lines) if line == "## Global Constraints"), -1)
task_indexes = [index for index, line in enumerate(plan_lines) if re.fullmatch(r"### Task \d+: .+", line)]
if global_index < 0 or not task_indexes or global_index > task_indexes[0]:
    raise SystemExit("FAIL: Global Constraints must precede every task")

try:
    spec_section = spec.split("## Global Constraints Source\n", 1)[1].split("\n## Requirements", 1)[0]
    plan_section = plan.split("## Global Constraints\n", 1)[1].split("\n---", 1)[0]
except IndexError:
    raise SystemExit("FAIL: unable to locate comparable Global Constraints sections")
spec_constraints = [line for line in spec_section.splitlines() if line.startswith("- ")]
plan_constraints = [line for line in plan_section.splitlines() if line.startswith("- ")]
if spec_constraints != plan_constraints:
    raise SystemExit("FAIL: plan Global Constraints are not a verbatim copy of the approved spec")

task_blocks = []
for position, start in enumerate(task_indexes):
    end = task_indexes[position + 1] if position + 1 < len(task_indexes) else len(plan_lines)
    task_blocks.append(plan_lines[start:end])
if len(task_blocks) != 1:
    raise SystemExit("FAIL: fixture must keep DB, API, UI, configuration, and documentation in one reviewable task")
for number, block_lines in enumerate(task_blocks, 1):
    if "**Interfaces:**" not in block_lines:
        raise SystemExit(f"FAIL: Task {number} has no Interfaces block")
    if not any(line.startswith("- Consumes: ") and len(line) > len("- Consumes: ") for line in block_lines):
        raise SystemExit(f"FAIL: Task {number} has no concrete Consumes contract")
    if not any(line.startswith("- Produces: ") and len(line) > len("- Produces: ") for line in block_lines):
        raise SystemExit(f"FAIL: Task {number} has no concrete Produces contract")
fixture_task = "\n".join(task_blocks[0])
for path in (
    "src/db/widgets.ts",
    "src/api/widgets.ts",
    "src/ui/WidgetPanel.tsx",
    "config/runtime.json",
    "tests/widget-delivery.test.tsx",
    "docs/widgets.md",
):
    if path not in fixture_task:
        raise SystemExit(f"FAIL: right-sized fixture task is missing integrated artifact {path}")
for interface in (
    "loadWidget(id: WidgetId): Promise<WidgetRecord | null>",
    "getWidget(id: WidgetId): Promise<WidgetDto | NotFound>",
    "fetchWidget(id: WidgetId, signal: AbortSignal): Promise<WidgetView>",
):
    if interface not in fixture_task:
        raise SystemExit(f"FAIL: fixture task is missing exact interface {interface}")

archive_patch = spec.rsplit("## Archive Patch", 1)
if len(archive_patch) != 2:
    raise SystemExit("FAIL: spec must end with an Archive Patch")
for field in ("Target:", "Action:", "Requirement:", "Scenario:"):
    if field not in archive_patch[1]:
        raise SystemExit(f"FAIL: Archive Patch is missing {field}")


def blocks_for(text):
    lines = text.splitlines()
    indexes = [index for index, line in enumerate(lines) if re.fullmatch(r"### Task \d+: .+", line)]
    return [
        lines[start : indexes[position + 1] if position + 1 < len(indexes) else len(lines)]
        for position, start in enumerate(indexes)
    ]


def concrete_interface(block, prefix, label):
    matches = [line[len(prefix) :].strip() for line in block if line.startswith(prefix)]
    if len(matches) != 1 or not matches[0]:
        raise SystemExit(f"FAIL: {label} must contain exactly one non-empty same-line {prefix.strip()}")
    return matches[0]


split_blocks = blocks_for(split_plan)
if len(split_blocks) != 2:
    raise SystemExit("FAIL: unrelated shared-file behaviors must remain exactly two reviewable tasks")
split_contracts = (
    ("tests/audit-export.test.ts", "exportAuditCsv(records: readonly AuditRecord[]): string"),
    ("tests/webhook-secret.test.ts", "rotateWebhookSecret(accountId: AccountId): Promise<SecretVersion>"),
)
for number, (block, (test_path, signature)) in enumerate(zip(split_blocks, split_contracts), 1):
    joined = "\n".join(block)
    if "src/shared/registry.ts" not in joined or test_path not in joined or signature not in joined:
        raise SystemExit(f"FAIL: split Task {number} is missing its shared file, independent test, or exact contract")
    if "**Interfaces:**" not in block:
        raise SystemExit(f"FAIL: split Task {number} has no Interfaces wrapper")
    concrete_interface(block, "- Consumes: ", f"split Task {number}")
    concrete_interface(block, "- Produces: ", f"split Task {number}")
    for marker in ("verify RED", "verify GREEN", "review checkpoint"):
        if marker not in joined:
            raise SystemExit(f"FAIL: split Task {number} is missing independent {marker}")


def valid_na(value):
    if not value.startswith("N/A — "):
        return False
    reason = value[len("N/A — ") :].strip()
    if len(reason) < 30:
        return False
    return reason.lower() not in {"not applicable", "none", "no interface", "n/a"}


for invalid in ("", "N/A", "N/A — none", "N/A — not applicable", "N/A — no interface"):
    if valid_na(invalid):
        raise SystemExit(f"FAIL: generic N/A unexpectedly accepted: {invalid!r}")
na_blocks = blocks_for(na_plan)
if len(na_blocks) != 1 or "**Interfaces:**" not in na_blocks[0]:
    raise SystemExit("FAIL: N/A fixture must contain one Task with an Interfaces wrapper")
for prefix in ("- Consumes: ", "- Produces: "):
    value = concrete_interface(na_blocks[0], prefix, "N/A fixture")
    if not valid_na(value):
        raise SystemExit(f"FAIL: {prefix.strip()} needs a specific N/A reason, got {value!r}")

print("PASS: writing-plans structural fixtures cover constraints, exact interfaces, both task-boundary directions, and specific N/A reasons; executable-plan validity is not claimed")
PY
