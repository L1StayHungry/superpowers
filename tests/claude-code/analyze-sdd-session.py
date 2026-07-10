#!/usr/bin/env python3
"""Verify a clean no-findings SDD fixture from tool calls, never prompt prose.

Exactly one reviewer dispatch per task is expected only for these deliberately
clean fixtures. Production Critical/Important fix loops may re-dispatch the
same combined reviewer role after fixes.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path
import re
import sys


def fail(message: str) -> None:
    raise SystemExit(f"FAIL: {message}")


def tool_calls(path: Path):
    for line_number, raw in enumerate(path.read_text().splitlines(), 1):
        if not raw.strip():
            continue
        try:
            event = json.loads(raw)
        except json.JSONDecodeError as error:
            fail(f"invalid JSONL at {path}:{line_number}: {error}")
        if event.get("type") != "assistant":
            continue
        content = event.get("message", {}).get("content", [])
        if not isinstance(content, list):
            continue
        for block in content:
            if not isinstance(block, dict) or block.get("type") != "tool_use":
                continue
            if block.get("name") not in {"Agent", "Task"}:
                continue
            inputs = block.get("input", {})
            if not isinstance(inputs, dict):
                continue
            description = str(inputs.get("description", ""))
            instructions = str(inputs.get("prompt", inputs.get("instructions", "")))
            yield description, instructions


def task_number(pattern: str, text: str):
    match = re.search(pattern, text, re.IGNORECASE)
    return int(match.group(1)) if match else None


parser = argparse.ArgumentParser(
    description="Analyze the clean no-findings SDD integration fixture; review-loop sessions use a different topology."
)
parser.add_argument("session", type=Path)
parser.add_argument("--tasks", required=True, help="comma-separated task numbers expected in this session")
parser.add_argument("--resume-ledger", type=Path)
args = parser.parse_args()

expected = {int(value) for value in args.tasks.split(",") if value.strip()}
if not expected:
    fail("--tasks must contain at least one task number")

implementers: Counter[int] = Counter()
reviewers: Counter[int] = Counter()
final_reviews = 0
implementer_positions: dict[int, list[int]] = {}
reviewer_positions: dict[int, list[int]] = {}
final_positions: list[int] = []

for position, (description, instructions) in enumerate(tool_calls(args.session)):
    joined = f"{description}\n{instructions}"
    review_task = task_number(r"Review\s+Task\s+(\d+)", description)
    if review_task is not None:
        normalized = instructions.lower()
        if "spec compliance" not in normalized or not (
            "task quality" in normalized or "code quality" in normalized
        ):
            fail(f"Task {review_task} reviewer lacks both spec and quality verdict contracts")
        reviewers[review_task] += 1
        reviewer_positions.setdefault(review_task, []).append(position)
        continue

    implement_task = task_number(r"Implement(?:ing)?\s+Task\s+(\d+)", joined)
    if implement_task is not None:
        implementers[implement_task] += 1
        implementer_positions.setdefault(implement_task, []).append(position)
        continue

    if re.fullmatch(r"Final whole-branch review", description.strip(), re.IGNORECASE):
        final_reviews += 1
        final_positions.append(position)

for task in sorted(expected):
    if implementers[task] != 1:
        fail(f"Task {task} expected exactly one implementer, found {implementers[task]}")
    if reviewers[task] != 1:
        fail(f"Task {task} expected exactly one combined reviewer, found {reviewers[task]}")
    if implementer_positions[task][0] >= reviewer_positions[task][0]:
        fail(f"dispatch order invalid for Task {task}: reviewer must follow implementer")

ordered_tasks = sorted(expected)
for current_task, next_task in zip(ordered_tasks, ordered_tasks[1:]):
    if reviewer_positions[current_task][0] >= implementer_positions[next_task][0]:
        fail(
            "dispatch order invalid: "
            f"Task {current_task} review gate must pass before Task {next_task} implementation"
        )

unexpected = (set(implementers) | set(reviewers)) - expected
if unexpected:
    fail(f"unexpected task dispatches: {sorted(unexpected)}")
if final_reviews != 1:
    fail(f"expected exactly one final whole-branch reviewer, found {final_reviews}")
if any(position >= final_positions[0] for positions in reviewer_positions.values() for position in positions):
    fail("dispatch order invalid: every task reviewer must precede the final whole-branch reviewer")

if args.resume_ledger:
    ledger = args.resume_ledger.read_text()
    completed = {int(value) for value in re.findall(r"^Task\s+(\d+):\s+complete\b", ledger, re.MULTILINE)}
    repeated = completed & (set(implementers) | set(reviewers))
    if repeated:
        fail(f"resume session re-dispatched ledger-complete tasks: {sorted(repeated)}")

print(
    "PASS: "
    f"implementers={dict(sorted(implementers.items()))} "
    f"combined_reviewers={dict(sorted(reviewers.items()))} "
    f"final_reviewers={final_reviews}"
)
