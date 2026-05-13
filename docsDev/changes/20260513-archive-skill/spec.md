---
change_id: 20260513-archive-skill
created_at: 2026-05-13T07:16:01Z
updated_at: 2026-05-13T07:35:48Z
owner: lihuajun
---

# Archive Skill Spec

## Change History

- 2026-05-13: Initial design for the explicit `t-archive` skill wrapper.
- 2026-05-13: Changed this change's Archive Patch to update the archive spec after `20260512-archive-precheck` creates it, and tightened archive execution details for target existence checks, commit summary source, UTC dates, staged checks, and stage1-check validation.

## Overview

Stage 2 part 3 already has the deterministic archive precheck tool. This change adds the missing `t-archive` skill so a user can explicitly archive an accepted change into the long-term `docsDev/specs/` library without remembering the manual merge, move, stage, and commit sequence.

The skill is a light wrapper. It calls `tools/t-archive-precheck`, consumes the success JSON metadata, applies the Archive Patch from the change spec, moves the completed change to `docsDev/archive/`, and creates one archive commit. It must not auto-trigger after verification or vague approval language.

## Goals

- Add `skills/t-archive/SKILL.md` as the Stage 2 only new skill entry.
- Require explicit archive intent and a concrete `change-id` before doing anything.
- Call `tools/t-archive-precheck <change-id>` before reading or mutating archive targets.
- Consume precheck stdout JSON for `change_id`, `capability`, `target`, and `action` metadata.
- Merge Archive Patch sections into `docsDev/specs/<capability>/spec.md` for `Action: create` and `Action: update`.
- Move the archived change with `git mv docsDev/changes/<change-id> docsDev/archive/<change-id>`.
- Commit specs and archive changes with `archive <change-id>: <summary>`.
- Report the archive commit sha and concise summary.
- Prove the flow with at least one real end-to-end archive run.

## Non-Goals

- No changes to `tools/t-archive-precheck` unless a plan-time or execution-time bug blocks this skill.
- No new deterministic merge tool.
- No transaction backup directory, checksum, atomic rename, or step-by-step rollback table.
- No `archive_failure`, `status`, `status_history`, `acceptance_evidence`, or acceptance state machine.
- No automatic archive trigger from `t-verification-before-completion`, `t-using-superpowers`, "looks good", "ok", or "可以了".
- No harness metadata convergence for `.codex-plugin`, `.cursor-plugin`, or `.claude-plugin`.
- No stage1-check rule changes.
- No vendor or upstream contribution work.

## Approach

Create `skills/t-archive/SKILL.md` with a narrow frontmatter description:

```yaml
description: Use ONLY when the user explicitly asks to archive a specific change-id into docsDev/specs/ (e.g. "archive 20260508-add-billing-export", "走 t-archive", "把 20260508-add-billing-export 沉淀到 specs"). Do NOT auto-trigger after verification succeeds. Do NOT infer archive intent from phrases like "looks good" / "ok" / "可以了". The user must provide explicit archive intent and a change-id.
```

The skill body should follow this flow:

1. Confirm that the current user message contains explicit archive intent and a concrete `YYYYMMDD-<slug>` change-id. If not, explain the boundary and stop without touching files.
2. Run `tools/t-archive-precheck <change-id>`.
3. If precheck exits non-zero, report the exit code meaning and stderr. Do not edit, stage, stash, reset, or clean anything.
4. If precheck exits zero, parse stdout as JSON. Use it as the authoritative metadata list for Archive Patch capability, target, and action.
5. Read `docsDev/changes/<change-id>/spec.md` and extract the body of each Archive Patch section. The skill may parse the markdown directly for Requirement bodies because precheck intentionally exposes only metadata.
6. Before writing any target files, validate target existence for every patch:
   - `Action: create` requires the target not to exist.
   - `Action: update` requires the target to exist.
   - If any target violates this rule, stop without rollback because no mutation has happened yet.
7. For each patch:
   - `Action: create`: the target must not already exist. Create a long-term spec file using the Stage 2 template.
   - `Action: update`: the target must already exist. Update it in place.
   - Append one new Change History entry at the top of the target's `## Change History` list: `<YYYY-MM-DD>: archived from docsDev/changes/<change-id>/ (<summary>)`.
   - Use `date -u +%Y-%m-%d` for the Change History date.
   - Apply `ADDED Requirements`, `MODIFIED Requirements`, `REMOVED Requirements`, and `RENAMED Requirements` by exact `### Requirement:` heading names in the target spec.
8. Run focused sanity checks before moving: `git diff --check -- docsDev/specs docsDev/changes/<change-id>`.
9. Derive `<summary>` from the first H1 in `docsDev/changes/<change-id>/spec.md`, stripping a trailing ` Spec`; if no H1 can be parsed, use the change-id.
10. Run `git mv docsDev/changes/<change-id> docsDev/archive/<change-id>`.
11. Run `git add docsDev/specs docsDev/archive`.
12. Run `git diff --cached --name-only -- docsDev/specs docsDev/archive/<change-id>` and confirm both the touched long-term spec target(s) and `docsDev/archive/<change-id>/` paths are staged.
13. Run `git commit -m "archive <change-id>: <summary>"`.
14. Report the commit sha and the files created or moved.

If any step after successful precheck and before commit fails, run `git reset --hard HEAD && git clean -fd`, report the failed step, and stop. This destructive rollback is allowed only because precheck requires the working tree to be clean before mutation. If the commit succeeds and a problem is found later, do not auto-retry or reset; the user chooses `git revert <archive-commit>` or a corrective commit.

### Long-Term Spec Template

For `Action: create`, write:

```markdown
---
capability: <capability>
owner: <owner from change spec frontmatter>
updated_at: <ISO-8601 UTC timestamp>
source: t-superpowers
---

# <Capability Title> Spec

## Change History

- <YYYY-MM-DD>: archived from docsDev/changes/<change-id>/ (<summary>)

## Overview

<Short overview derived from the Archive Patch capability and source change.>

## Requirements

<ADDED Requirements converted from Archive Patch level-5 headings to level-3 headings.>

## Notes
```

Archive Patch heading levels are normalized when copied into the long-term spec:

- `##### Requirement:` becomes `### Requirement:`
- `###### Scenario:` becomes `#### Scenario:`

## Files

Expected implementation files:

- Create `skills/t-archive/SKILL.md`: explicit-trigger archive workflow wrapper.
- Update `docsDev/changes/20260513-archive-skill/plan.md`: implementation plan.

Expected runtime validation artifacts:

- Create `docsDev/specs/archive/spec.md` by archiving `20260512-archive-precheck` before any later archive of `20260513-archive-skill`.
- Create `docsDev/specs/triggering/spec.md` during a real archive of `20260512-trigger-convergence`.
- Move `docsDev/changes/20260512-trigger-convergence/` to `docsDev/archive/20260512-trigger-convergence/` during that same real archive.
- Keep any transcripts or manual logs under `docsDev/changes/20260513-archive-skill/transcripts/`.

Files intentionally not touched:

- `tools/t-archive-precheck`
- `.codex-plugin/plugin.json`
- `.cursor-plugin/plugin.json`
- `.claude-plugin/plugin.json`
- `vendor/superpowers/`
- `docs/二开规划/二次开发规划.md`

## Behavior Rules

### Requirement: Archive Skill Requires Explicit User Intent

The skill must run only for explicit archive requests that name a concrete change-id.

#### Scenario: Explicit archive request with change-id

- Given the user says `归档 20260512-trigger-convergence`
- When `t-archive` starts
- Then it must proceed to precheck for `20260512-trigger-convergence`

#### Scenario: Vague approval does not archive

- Given a change has passed verification
- When the user says `可以了`, `ok`, or `looks good`
- Then `t-archive` must not run
- And no archive commit may be created

#### Scenario: Archive intent without change-id asks and stops

- Given the user says `走 t-archive`
- And no concrete `YYYYMMDD-<slug>` appears in the request or immediate context
- When `t-archive` starts
- Then it must ask for the change-id
- And it must not run precheck or modify files

### Requirement: Precheck Is The Archive Gate

The skill must not mutate files unless `tools/t-archive-precheck <change-id>` exits `0`.

#### Scenario: Precheck reports malformed Archive Patch

- Given precheck exits `2`
- When `t-archive` receives the failure
- Then it must report `Archive Patch 字段缺失或格式错误`
- And it must not modify files

#### Scenario: Precheck reports target path escape

- Given precheck exits `3`
- When `t-archive` receives the failure
- Then it must report `Target 路径越界`
- And it must not modify files

#### Scenario: Precheck reports existing archive destination

- Given precheck exits `4`
- When `t-archive` receives the failure
- Then it must report `archive 目录已存在`
- And it must not modify files

#### Scenario: Precheck reports dirty working tree

- Given precheck exits `5`
- When `t-archive` receives the failure
- Then it must report `工作区不干净`
- And it must not stash, reset, clean, or modify files

### Requirement: Archive Patch Merges Into Long-Term Specs

The skill must transform Archive Patch content into durable team specs under `docsDev/specs/`.

#### Scenario: Create a new long-term spec

- Given precheck succeeds for a patch with `Action: create`
- And the target spec does not exist
- When `t-archive` applies the patch
- Then it must create the target using the long-term spec template
- And it must include the Archive Patch `ADDED Requirements`
- And it must append a Change History entry for the archived change

#### Scenario: Create target already exists

- Given precheck succeeds for a patch with `Action: create`
- And the target spec already exists
- When `t-archive` applies the patch
- Then it must stop before `git mv`
- And it must roll back any partial edits
- And it must not create an archive commit

#### Scenario: Update an existing long-term spec

- Given precheck succeeds for a patch with `Action: update`
- And the target spec exists
- When `t-archive` applies the patch
- Then it must apply ADDED, MODIFIED, REMOVED, and RENAMED requirements by exact heading name
- And it must append a Change History entry for the archived change

#### Scenario: Update target is missing

- Given precheck succeeds for a patch with `Action: update`
- And the target spec does not exist
- When `t-archive` applies the patch
- Then it must stop before `git mv`
- And it must roll back any partial edits
- And it must not create an archive commit

### Requirement: Archive Commit Moves The Change Snapshot

The skill must preserve the completed change under `docsDev/archive/` and commit specs plus archive together.

#### Scenario: Legal archive commits one snapshot

- Given precheck succeeds
- And Archive Patch merge succeeds
- When `t-archive` runs `git mv`, `git add`, and `git commit`
- Then `docsDev/changes/<change-id>/` must disappear
- And `docsDev/archive/<change-id>/` must appear
- And `docsDev/specs/<capability>/spec.md` must contain the merged requirements
- And git log must contain `archive <change-id>: <summary>`

#### Scenario: Failure after mutation but before commit rolls back

- Given precheck has succeeded
- And a merge, move, add, or commit-preparation step fails before commit
- When `t-archive` handles the failure
- Then it must run `git reset --hard HEAD && git clean -fd`
- And it must report the failed step
- And it must not retry automatically

#### Scenario: Problem found after commit is not auto-retried

- Given the archive commit was created
- When a later problem is found
- Then `t-archive` must not run reset or retry automatically
- And the user must choose revert or a corrective commit

## Validation

Implementation validation must include:

- `rg -n "^description:.*Use ONLY.*archive.*change-id" skills/t-archive/SKILL.md`
- `rg -n "Do NOT auto-trigger|looks good|可以了|tools/t-archive-precheck|git mv docsDev/changes" skills/t-archive/SKILL.md`
- `tools/t-archive-precheck 20260512-archive-precheck` before the first real archive run; expected exit `0` and JSON metadata for `docsDev/specs/archive/spec.md`.
- A real explicit archive run for `20260512-archive-precheck`; expected archive commit, `docsDev/specs/archive/spec.md`, and moved change directory.
- `tools/t-archive-precheck 20260512-trigger-convergence` before the real archive run; expected exit `0` and JSON metadata for `docsDev/specs/triggering/spec.md`.
- A real explicit archive run for `20260512-trigger-convergence`; expected archive commit and moved change directory.
- `test -f docsDev/specs/archive/spec.md`
- `test -d docsDev/archive/20260512-archive-precheck`
- `test ! -e docsDev/changes/20260512-archive-precheck`
- `test -f docsDev/specs/triggering/spec.md`
- `test -d docsDev/archive/20260512-trigger-convergence`
- `test ! -e docsDev/changes/20260512-trigger-convergence`
- `rg -n "Archive Precheck Guards Repository Safety|archived from docsDev/changes/20260512-archive-precheck" docsDev/specs/archive/spec.md`
- `rg -n "T-Superpowers Trigger Boundary|Simple Requests Are Not Forced|archived from docsDev/changes/20260512-trigger-convergence" docsDev/specs/triggering/spec.md`
- `git log --oneline -2` includes `archive 20260512-trigger-convergence:` and `archive 20260512-archive-precheck:`
- `bash tools/t-stage1-check.sh` must exit `0`; if it does not, stop and fix or mark this change blocked until it can pass.

Manual prompt validation must include:

- Explicit archive request with change-id enters `t-archive`.
- `可以了` / `looks good` does not enter `t-archive`.
- `走 t-archive` without an identifiable change-id asks for the change-id and performs no mutation.

## Risks

- Markdown merge remains prompt-driven. Precheck provides deterministic target/action metadata, but Requirement body transforms still require careful review.
- Rollback uses destructive git commands after mutation. This is acceptable only because precheck enforces a clean worktree first.
- A real E2E archive moves `20260512-archive-precheck` and `20260512-trigger-convergence` out of `docsDev/changes/`; each must happen in its own archive commit after the skill implementation commit.
- Future upstream rebases may not know about `t-archive`; keep this skill fork-specific and do not copy it into `vendor/superpowers/`.

## Archive Patch

### archive

Target: docsDev/specs/archive/spec.md
Action: update

#### ADDED Requirements

##### Requirement: Archive Skill Is Explicitly Triggered

The archive workflow must only run when the user explicitly requests archiving a concrete change-id into long-term specs.

###### Scenario: Explicit archive request proceeds

- Given the user explicitly asks to archive `20260512-trigger-convergence`
- When `t-archive` starts
- Then it must run precheck for that change-id

###### Scenario: Vague approval does not archive

- Given a change has passed verification
- When the user says `可以了`, `ok`, or `looks good`
- Then `t-archive` must not run
- And no archive commit may be created

##### Requirement: Archive Skill Uses Precheck As Mutation Gate

The archive workflow must call `tools/t-archive-precheck <change-id>` and refuse to mutate files unless precheck exits successfully.

###### Scenario: Precheck failure stops archive

- Given precheck exits non-zero
- When `t-archive` receives the failure
- Then it must report the exit code meaning
- And it must not modify, stage, stash, reset, or clean files

##### Requirement: Archive Skill Merges Archive Patch Into Specs

The archive workflow must merge Archive Patch requirements into `docsDev/specs/<capability>/spec.md`.

###### Scenario: Create spec from Archive Patch

- Given a patch with `Action: create`
- And the target spec does not exist
- When `t-archive` applies the patch
- Then it must create the target spec with frontmatter, Change History, Overview, Requirements, and Notes sections

###### Scenario: Update spec from Archive Patch

- Given a patch with `Action: update`
- And the target spec exists
- When `t-archive` applies the patch
- Then it must apply ADDED, MODIFIED, REMOVED, and RENAMED requirements by exact heading name

##### Requirement: Archive Skill Commits Specs And Snapshot Together

The archive workflow must move the completed change to `docsDev/archive/` and commit specs plus archive snapshot together.

###### Scenario: Legal archive creates archive commit

- Given precheck succeeds
- And the Archive Patch merge succeeds
- When `t-archive` runs
- Then `docsDev/specs/<capability>/spec.md` must contain the merged content
- And `docsDev/archive/<change-id>/` must exist
- And `docsDev/changes/<change-id>/` must not exist
- And git log must contain one `archive <change-id>: <summary>` commit

###### Scenario: Failure before commit rolls back

- Given precheck succeeds
- And a later archive step fails before commit
- When `t-archive` handles the failure
- Then it must reset and clean back to the pre-archive HEAD
- And it must not retry automatically
