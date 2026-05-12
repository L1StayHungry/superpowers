---
change_id: 20260512-docsdev-paths
created_at: 2026-05-12T03:26:23Z
updated_at: 2026-05-12T03:26:23Z
owner: lihuajun
---

# DocsDev Runtime Path Migration Spec

## Change History

- 2026-05-12: Initial design for stage 2 runtime artifact path migration.

## Overview

Stage 2 part 1 narrowed when `t-superpowers` should trigger. Part 2 should now fix where complex-work runtime artifacts are written.

The current `t-brainstorming` and `t-writing-plans` skill bodies still point new specs and plans at upstream paths under `docs/superpowers/`. That conflicts with the internal fork rule that new complex-work artifacts belong under `docsDev/changes/<change-id>/`.

This change migrates only the runtime artifact paths used by the design and planning workflow:

- `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
  becomes `docsDev/changes/<change-id>/spec.md`
- `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
  becomes `docsDev/changes/<change-id>/plan.md`

This change does not implement archiving, long-term specs, or archive precheck tooling.

## Goals

- `t-brainstorming` must write approved design specs to `docsDev/changes/<change-id>/spec.md`.
- `t-writing-plans` must write implementation plans to `docsDev/changes/<change-id>/plan.md`.
- A single complex change should keep spec, plan, and future transcripts together under one `docsDev/changes/<change-id>/` directory.
- New runtime artifact instructions must not point agents to `docs/superpowers/`.
- Existing stage 1 namespace behavior and stage 2 trigger convergence must remain unchanged.

## Non-Goals

- No `t-archive` skill.
- No `tools/t-archive-precheck`.
- No migration of historical `docs/superpowers/` files.
- No broad cleanup of release notes, legacy fixtures, or upstream reference text.
- No new status machine, `status_history`, acceptance evidence, transcript hashing, or PR online verification.
- No further trigger-boundary changes beyond avoiding old-path wording.
- No change to `vendor/superpowers/`.

## Approach

Use the existing `docsDev/changes/<change-id>/` structure as the single runtime container for one complex change.

`t-brainstorming` owns change creation. When writing the design spec, it must:

- Derive or ask for a concise slug.
- Build `change-id` as `YYYYMMDD-<slug>` using UTC date from `date -u +%Y%m%d`.
- Require slug characters to be lowercase `a-z`, digits, and hyphen, with length 3-40.
- Refuse to overwrite an existing `docsDev/changes/<change-id>/` directory.
- Create `docsDev/changes/<change-id>/spec.md`.
- Use minimal frontmatter: `change_id`, `created_at`, `updated_at`, `owner`.
- Keep future transcript evidence under `docsDev/changes/<change-id>/transcripts/` when such evidence is produced.

`t-writing-plans` owns plan creation for an approved spec. It must:

- Prefer the approved spec's existing change directory.
- Save the implementation plan to `docsDev/changes/<change-id>/plan.md`.
- Use the same minimal frontmatter fields as the spec.
- Avoid creating a separate plan-only change directory when the spec already lives under `docsDev/changes/<change-id>/spec.md`.

Supporting prompts and examples that influence runtime behavior should be updated to the new paths. Historical docs, release notes, and old test fixtures may keep `docs/superpowers/` when they are not used as live instructions for new artifact creation.

## Files

Expected implementation files:

- Modify `skills/t-brainstorming/SKILL.md`: spec output path, change-id rules, user review message, and path examples.
- Modify `skills/t-writing-plans/SKILL.md`: plan output path, handoff message, and path examples.
- Modify `skills/t-brainstorming/spec-document-reviewer-prompt.md`: reviewer dispatch path reference.
- Modify `skills/t-subagent-driven-development/SKILL.md`: example plan path if it is used as an execution handoff prompt.

Expected validation artifacts may be added under `docsDev/changes/20260512-docsdev-paths/transcripts/` if manual harness checks are run.

## Behavior Rules

### Requirement: Brainstorming Writes Specs Under DocsDev Changes

`t-brainstorming` must write new design specs under `docsDev/changes/<change-id>/spec.md`.

#### Scenario: Explicit complex request creates spec in docsDev

- Given the user explicitly asks to use `t-superpowers` for a complex feature
- When `t-brainstorming` writes the approved design spec
- Then the spec path must be `docsDev/changes/<change-id>/spec.md`
- And the spec frontmatter must include `change_id`, `created_at`, `updated_at`, and `owner`
- And no new `docs/superpowers/specs/` file should be created

#### Scenario: Existing change-id collision is rejected

- Given `docsDev/changes/<change-id>/` already exists
- When `t-brainstorming` attempts to create the same `change-id`
- Then it must stop and ask for a different slug or change-id
- And it must not overwrite the existing spec, plan, or transcripts

### Requirement: Writing Plans Writes Plan Beside Approved Spec

`t-writing-plans` must write implementation plans beside the approved spec.

#### Scenario: Approved docsDev spec gets colocated plan

- Given an approved spec exists at `docsDev/changes/<change-id>/spec.md`
- When `t-writing-plans` creates the implementation plan
- Then the plan path must be `docsDev/changes/<change-id>/plan.md`
- And no new `docs/superpowers/plans/` file should be created

#### Scenario: User provides legacy spec path

- Given a user explicitly asks to write a plan from a legacy `docs/superpowers/specs/...` spec
- When `t-writing-plans` cannot infer a `docsDev/changes/<change-id>/` directory
- Then it should ask for the target `change-id` or docsDev change directory before writing
- And it must not silently create a new `docs/superpowers/plans/` plan

### Requirement: Runtime Instructions Do Not Point To Old Artifact Paths

Live t-superpowers instructions must not tell agents to create new runtime artifacts in `docs/superpowers/`.

#### Scenario: Skill path scan has no live old-output paths

- Given the implementation has updated the scoped runtime skills and reviewer prompts
- When scanning those files for `docs/superpowers/specs` or `docs/superpowers/plans`
- Then no live instruction should still direct new specs or plans to the old paths

## Error Handling

- If the slug is missing, invalid, or too vague, ask the user for a valid slug before writing the spec.
- If `docsDev/changes/<change-id>/` already exists, stop and report the collision.
- If a plan is requested for a spec outside `docsDev/changes/<change-id>/spec.md`, ask for the target change directory rather than guessing.
- If validation finds a live old-path instruction in scoped runtime skills, treat it as a failed path-migration regression.

## Validation

Required checks for this change:

- `git diff --check -- skills/t-brainstorming/SKILL.md skills/t-writing-plans/SKILL.md skills/t-brainstorming/spec-document-reviewer-prompt.md skills/t-subagent-driven-development/SKILL.md docsDev/changes/20260512-docsdev-paths/spec.md`
- Scoped live-path scan returns no matches:
  `rg -n "docs/superpowers/(specs|plans)" skills/t-brainstorming skills/t-writing-plans skills/t-subagent-driven-development --glob "!vendor/**"`
- Scoped new-path scan confirms the live skills mention `docsDev/changes/<change-id>/spec.md` and `docsDev/changes/<change-id>/plan.md`.
- Explicit complex brainstorming harness: a prompt such as "用 t-superpowers，我要做一个 PDF 导出功能" writes the design spec to `docsDev/changes/<change-id>/spec.md`, not `docs/superpowers/specs/`.
- Writing-plans harness: given an approved spec at `docsDev/changes/<change-id>/spec.md`, `t-writing-plans` writes `docsDev/changes/<change-id>/plan.md`, not `docs/superpowers/plans/`.
- File-state assertion after harness runs: `docs/superpowers/` has no new files from the new workflow.
- If `bash tools/t-stage1-check.sh` remains blocked by unrelated dirty entry/instruction files, document the blocker and do not count it as passed.

## Risks

- If only `t-brainstorming` is updated, plans may still be written to `docs/superpowers/plans/`. That is why `t-writing-plans` is in scope.
- If `t-writing-plans` creates a new change directory instead of reusing the spec directory, spec and plan evidence will split. The plan must be colocated with the approved spec.
- If tests or legacy fixtures are changed too broadly, this path migration may become a large unrelated cleanup. Keep historical references unless they are live runtime instructions.
- If collision handling is vague, agents may overwrite an existing change. Existing change directories must be treated as hard collisions.
- Existing `tools/t-stage1-check.sh` may still fail because unrelated entry/instruction files are dirty. That should remain a documented blocker, not a reason to broaden this change.
- Upstream rebases may restore `docs/superpowers/` wording in `t-brainstorming` or `t-writing-plans`; reconcile these paths manually during rebase.

## Archive Patch

### runtime-artifacts

Target: docsDev/specs/runtime-artifacts/spec.md
Action: create

#### ADDED Requirements

##### Requirement: Complex Change Artifacts Live Under DocsDev Changes

The system must store new complex-work runtime artifacts under `docsDev/changes/<change-id>/`.

###### Scenario: Brainstorming spec path

- Given `t-brainstorming` writes a new design spec for a complex change
- When the spec is saved
- Then it must be saved as `docsDev/changes/<change-id>/spec.md`
- And it must not be saved under `docs/superpowers/specs/`

###### Scenario: Writing-plans plan path

- Given `t-writing-plans` writes a plan for an approved spec
- When the approved spec lives at `docsDev/changes/<change-id>/spec.md`
- Then the plan must be saved as `docsDev/changes/<change-id>/plan.md`
- And it must not be saved under `docs/superpowers/plans/`

###### Scenario: Change-id collision

- Given `docsDev/changes/<change-id>/` already exists
- When a new brainstorming flow tries to use the same change-id
- Then the flow must stop and ask for a different slug or change-id
- And it must not overwrite existing change artifacts
