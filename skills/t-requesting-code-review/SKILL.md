---
name: t-requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements
---

# Requesting Code Review

Dispatch a reviewer subagent to catch issues before they cascade. The reviewer
gets precisely crafted context for evaluation, never the controller session's
history. Keep the reviewer on a read-only checkout: it may inspect the named
range but may not edit files, change the index, move HEAD, switch branches, or
commit.

**Core principle:** Review early, review often.

## When to Request Review

**Mandatory:**
- After completing major feature
- Before merge to main

In `t-superpowers:t-subagent-driven-development`, the combined task reviewer
already satisfies the per-task gate. Use this skill there for the final
whole-branch review, not as a second reviewer after every task.

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing complex bug

## How to Request

**1. Get git SHAs:**
```bash
# Record BASE_SHA before implementation; do not infer it with HEAD~1 for a
# multi-commit task because that silently drops earlier commits.
BASE_SHA=<recorded-task-base-or-branch-merge-base>
HEAD_SHA=$(git rev-parse HEAD)
```

`HEAD~1` is acceptable only for a deliberately verified single-commit range.
The default is always the recorded BASE.

**2. Dispatch code reviewer subagent:**

Use the current harness's general-purpose subagent capability and fill the
template at [code-reviewer.md](code-reviewer.md). Do not depend on a
harness-specific tool name.

**Placeholders:**
- `{DESCRIPTION}` - Brief summary of what you built
- `{PLAN_OR_REQUIREMENTS}` - What it should do
- `{BASE_SHA}` - Starting commit
- `{HEAD_SHA}` - Ending commit
- `{REVIEW_PACKAGE}` - Optional package containing commit list, stat, and full
  diff. SDD final review should provide it.

**3. Act on feedback:**
- Fix Critical issues immediately
- Fix Important issues before proceeding
- Note Minor issues for later
- Push back if reviewer is wrong (with reasoning)

## Example

```
[Just completed Task 2: Add verification function]

You: Let me request code review before proceeding.

BASE_SHA=$(git log --format=%H --grep='Task 1' -1)
HEAD_SHA=$(git rev-parse HEAD)

[Dispatch code reviewer subagent]
  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types
  PLAN_OR_REQUIREMENTS: Task 2 from docsDev/changes/20260512-deployment-plan/plan.md
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661

[Subagent returns]:
  Strengths: Clean architecture, real tests
  Issues:
    Important: Missing progress indicators
    Minor: Magic number (100) for reporting interval
  Assessment: Ready to proceed

You: [Fix progress indicators]
[Continue to Task 3]
```

## Integration with Workflows

**Subagent-Driven Development:**
- The combined task reviewer handles each task's spec and quality gate
- Use this skill once for the final whole-branch review
- Provide the branch review package and accumulated Minor ledger findings

**Executing Plans:**
- Review after each task or at natural checkpoints
- Get feedback, apply, continue

**Ad-Hoc Development:**
- Review before merge
- Review when stuck

## Red Flags

**Never:**
- Skip review because "it's simple"
- Ignore Critical issues
- Proceed with unfixed Important issues
- Argue with valid technical feedback

**If reviewer wrong:**
- Push back with technical reasoning
- Show code/tests that prove it works
- Request clarification

See template at: t-requesting-code-review/code-reviewer.md
