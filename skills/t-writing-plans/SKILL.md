---
name: t-writing-plans
description: "Use ONLY when a complex approved spec or requirements need a multi-step implementation plan before coding. Do NOT use for simple single-file edits, Q&A, or pure code reading."
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** If working in an isolated worktree, it should have been created via the `t-superpowers:t-using-git-worktrees` skill at execution time.

**Save plans to:** `docsDev/changes/<change-id>/plan.md`
- If the approved spec is `docsDev/changes/<change-id>/spec.md`, save the plan beside it as `docsDev/changes/<change-id>/plan.md`.
- If the approved spec is outside `docsDev/changes/<change-id>/spec.md`, ask for the target `change-id` or docsDev change directory before writing.
- (User preferences for plan location override this default.)

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Task Right-Sizing

A task is the smallest delivery boundary that carries its own RED/GREEN test cycle and is worth a fresh reviewer's gate. Fold setup, configuration, scaffolding, and documentation into the delivery task they serve. Split only where one boundary can be tested and reviewed independently, and a reviewer could meaningfully approve it while rejecting a neighboring task.

Do not split tasks mechanically by file or technical layer. A database task, API task, UI task, or documentation-only task is too small when it cannot prove useful behavior on its own; combine those edits into the end-to-end deliverable that needs them. Conversely, do not combine unrelated behaviors merely because they touch the same file.

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**Every plan MUST start with frontmatter followed by this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use t-superpowers:t-subagent-driven-development (recommended) or t-superpowers:t-executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

## Global Constraints

- [Copy the approved spec's project-wide versions, dependencies, naming, platforms, and exact values verbatim, one constraint per item.]

---
```

Use only these frontmatter fields:

```yaml
---
change_id: <change-id>
created_at: <ISO-8601 UTC timestamp>
updated_at: <ISO-8601 UTC timestamp>
owner: <owner>
---
```

### Build Global Constraints from the Approved Spec

Before defining tasks, reread the approved spec and copy each constraint verbatim into `## Global Constraints`. Include versions, dependencies, naming, platforms, and exact values such as paths, command names, protocol limits, ports, timeouts, identifiers, and required copy.

- Do not paraphrase, normalize, weaken, or infer a replacement.
- Preserve exact spelling, capitalization, numbers, units, operators, and quoted text.
- Add a source section reference after the verbatim text when useful, without rewriting the constraint itself.
- If two spec statements conflict, stop and ask the human partner; do not choose one silently.
- If the approved spec states no project-wide constraint, write `- N/A — the approved spec states no project-wide constraint.` Do not invent one.

Every task implicitly inherits this section. Task steps may point back to a constraint, but must not restate it with different wording.

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Interfaces:**
- Consumes: [exact signatures, types, and data contracts used from existing code or earlier tasks; otherwise `N/A — <specific reason why this task has no consumed interface>`]
- Produces: [exact signatures, types, and data contracts exposed to later tasks or callers; otherwise `N/A — <specific reason why this task exposes no interface>`]

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task

## Remember
- Exact file paths always
- Complete code in every step — if a step changes code, show the code
- Exact commands with expected output
- DRY, YAGNI, TDD, and a checkpoint commit after every independently reviewed task

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Constraint fidelity:** Compare `## Global Constraints` against the approved spec line by line. Confirm every project-wide version, dependency, naming, platform, and exact value constraint is present verbatim, with no inferred or softened substitute.

**4. Interface consistency:** Does every task contain `Consumes` and `Produces` with exact signatures, types, and data contracts, or an explicit `N/A — <specific reason>`? Do names and types match across task boundaries? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

**5. Task right-sizing:** Can each task complete its own RED/GREEN cycle and pass an independent review? Merge setup/configuration/scaffolding/documentation-only fragments into the delivery they serve, and split unrelated behaviors even when they share a file.

**6. Local contract:** Confirm the output path remains `docsDev/changes/<change-id>/plan.md`, every skill reference uses the `t-superpowers:t-*` namespace, and no upstream artifact path appears.

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

## Execution Handoff

After saving the plan, offer execution choice:

**"Plan complete and saved to `docsDev/changes/<change-id>/plan.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh implementer per task, run one consolidated task review between tasks, and finish with a whole-branch review

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?"**

**If Subagent-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use t-superpowers:t-subagent-driven-development
- Fresh implementer per task + one consolidated reviewer returning separate specification and quality verdicts

**If Inline Execution chosen:**
- **REQUIRED SUB-SKILL:** Use t-superpowers:t-executing-plans
- Batch execution with checkpoints for review
