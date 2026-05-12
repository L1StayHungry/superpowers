---
change_id: 20260512-archive-precheck
created_at: 2026-05-12T09:45:05Z
updated_at: 2026-05-12T09:45:05Z
owner: lihuajun
---

# Archive Precheck Spec

## Change History

- 2026-05-12: Initial design for the archive precheck safety tool.

## Overview

Stage 2 part 3 introduces the long-term spec archive workflow. The first safe slice is the deterministic precheck tool that future `t-archive` will call before it reads an Archive Patch, writes `docsDev/specs/`, moves a change to `docsDev/archive/`, or commits.

This change adds only `tools/t-archive-precheck`. It performs read-only validation and exits with stable codes. It must not modify files, stage changes, move directories, merge markdown, or commit.

## Goals

- Provide a small deterministic command: `tools/t-archive-precheck <change-id>`.
- Verify that `docsDev/changes/<change-id>/spec.md` exists and contains a valid `## Archive Patch` block.
- Reject Archive Patch targets outside `docsDev/specs/`, including `..`, absolute-path escape, symlink escape, and target equal to the specs root.
- Reject duplicate archive destinations at `docsDev/archive/<change-id>/`.
- Reject dirty working trees before any archive operation can proceed.
- Return stable exit codes `0-5` for `t-archive` and humans to report.
- Keep the tool lightweight: one file, no network, no LLM calls, no state machine.

## Non-Goals

- No `skills/t-archive/` skill in this change.
- No Archive Patch merge implementation.
- No creation or update of `docsDev/specs/<capability>/spec.md`.
- No `git mv docsDev/changes/<change-id> docsDev/archive/<change-id>`.
- No archive commit.
- No migration of existing changes.
- No status fields, `acceptance_evidence`, transcript hashing, PR online checks, or transaction backup directories.
- No generalized `tools/t-validate` or `tools/t-state`.

## Approach

Implement `tools/t-archive-precheck` as a single Python script. Python is preferred over Bash because path normalization, symlink resolution, and simple block parsing are easier to keep readable within the line budget.

The command interface is:

```bash
tools/t-archive-precheck <change-id>
```

The tool should run from anywhere inside the repository. It should locate the repository root from the script location, not from the current working directory.

The checks run in this order:

1. Validate the argument and required source files:
   - exactly one `<change-id>` argument is required
   - `docsDev/changes/<change-id>/` exists
   - `docsDev/changes/<change-id>/spec.md` exists
2. Parse the `## Archive Patch` block in `spec.md`:
   - block must exist
   - each archive patch section must include `Target: ...`
   - each archive patch section must include `Action: create` or `Action: update`
   - each archive patch section must contain at least one `Requirement:` and one `Scenario:`
3. Normalize each Target:
   - resolve the target path against the repository root
   - resolve symlinks
   - require the resolved target to be strictly below the resolved `docsDev/specs/` directory
   - reject the specs root itself as a target
4. Verify idempotency:
   - `docsDev/archive/<change-id>/` must not exist
5. Verify the working tree:
   - `git status --porcelain` must be empty, including untracked files

The tool prints a concise human-readable result to stdout or stderr. On failure it should name the failed check and include the exit code meaning.

## Files

Expected implementation files:

- Create `tools/t-archive-precheck`: read-only precheck command.
- Add focused tests if the repository has an appropriate existing shell or Python test pattern for tools. If no clear test harness exists, use documented fixture directories under `/tmp` during validation rather than adding a large new test framework.

Expected documentation artifacts:

- Update `docsDev/changes/20260512-archive-precheck/plan.md` during planning.
- Keep any manual command transcripts under `docsDev/changes/20260512-archive-precheck/transcripts/` only if runtime harness checks are run.

## Behavior Rules

### Requirement: Precheck Validates Archive Input Before Mutation

The tool must validate archive readiness without modifying the repository.

#### Scenario: Missing change argument

- Given no `<change-id>` is passed
- When `tools/t-archive-precheck` runs
- Then it must exit `1`
- And it must not modify files

#### Scenario: Missing change directory or spec

- Given `docsDev/changes/<change-id>/` or `spec.md` does not exist
- When `tools/t-archive-precheck <change-id>` runs
- Then it must exit `1`
- And it must report the missing path
- And it must not modify files

### Requirement: Archive Patch Shape Is Checked

The tool must reject specs that cannot be safely archived.

#### Scenario: Missing Archive Patch

- Given `docsDev/changes/<change-id>/spec.md` has no `## Archive Patch` block
- When the precheck runs
- Then it must exit `2`
- And it must report that Archive Patch is missing

#### Scenario: Archive Patch missing required fields

- Given the Archive Patch omits `Target`, omits `Action`, uses an unsupported action, or lacks any `Requirement:` or `Scenario:`
- When the precheck runs
- Then it must exit `2`
- And it must name the missing or invalid field

### Requirement: Archive Patch Target Cannot Escape DocsDev Specs

The tool must reject targets outside the long-term spec root after normalization and symlink resolution.

#### Scenario: Target escapes with dot-dot

- Given Archive Patch Target is `docsDev/specs/../outside/spec.md`
- When the precheck runs
- Then it must exit `3`
- And it must not modify files

#### Scenario: Target is outside docsDev specs

- Given Archive Patch Target is `docs/superpowers/foo/spec.md` or an absolute path outside `docsDev/specs/`
- When the precheck runs
- Then it must exit `3`
- And it must not modify files

#### Scenario: Target equals specs root

- Given Archive Patch Target is `docsDev/specs/`
- When the precheck runs
- Then it must exit `3`
- And it must not modify files

#### Scenario: Target escapes through symlink

- Given a path below `docsDev/specs/` resolves through a symlink to a location outside `docsDev/specs/`
- When the precheck runs
- Then it must exit `3`
- And it must not modify files

### Requirement: Archive Destination Is Idempotent

The tool must refuse to archive a change more than once.

#### Scenario: Archive destination exists

- Given `docsDev/archive/<change-id>/` already exists
- When the precheck runs
- Then it must exit `4`
- And it must report the archive path conflict
- And it must not modify files

### Requirement: Working Tree Must Be Clean

The tool must prevent archive flows from running when rollback could discard user work.

#### Scenario: Working tree has tracked or untracked changes

- Given `git status --porcelain` is not empty
- When the precheck runs
- Then it must exit `5`
- And it must report that the working tree is not clean
- And it must not stash, stage, reset, clean, or modify files

#### Scenario: Valid archive input passes

- Given the change directory exists
- And `spec.md` has a valid Archive Patch whose Target resolves strictly under `docsDev/specs/`
- And `docsDev/archive/<change-id>/` does not exist
- And `git status --porcelain` is empty
- When `tools/t-archive-precheck <change-id>` runs
- Then it must exit `0`
- And it must report that precheck passed
- And it must not modify files

## Exit Codes

```text
0   all checks passed
1   argument, change directory, or spec.md missing
2   Archive Patch missing, malformed, or missing required fields
3   Archive Patch Target path escape or invalid specs-root target
4   archive destination already exists
5   working tree is dirty
```

## Error Handling

- Stop at the first failed check and return that check's exit code.
- Print enough context for a human or `t-archive` to understand the failure.
- Do not attempt recovery, cleanup, stash, reset, git clean, or retry.
- Treat parse ambiguity as exit `2`, not as a best-effort pass.
- Treat target path ambiguity as exit `3`, not as a best-effort pass.

## Validation

Required checks for this change:

- `tools/t-archive-precheck` with no argument exits `1`.
- Missing `docsDev/changes/<change-id>/` exits `1`.
- Missing `## Archive Patch` exits `2`.
- Missing `Target`, missing `Action`, unsupported `Action`, missing `Requirement:`, or missing `Scenario:` exits `2`.
- Target `docsDev/specs/../outside/spec.md` exits `3`.
- Target outside `docsDev/specs/`, such as `docs/superpowers/foo/spec.md`, exits `3`.
- Target equal to `docsDev/specs/` exits `3`.
- Symlink escape under `docsDev/specs/` exits `3`.
- Existing `docsDev/archive/<change-id>/` exits `4`.
- Dirty working tree exits `5` and does not modify files.
- Valid fixture with clean working tree exits `0`.
- `git diff --check -- tools/t-archive-precheck docsDev/changes/20260512-archive-precheck/spec.md docsDev/changes/20260512-archive-precheck/plan.md` exits `0` after implementation and planning.
- `bash tools/t-stage1-check.sh` exits `0`.

If dirty-working-tree validation requires temporary repository state, run it inside a temporary git repository under `/tmp` or document why it was not run in the main repository. Do not intentionally dirty the main worktree unless the test itself creates and cleans up the fixture deterministically.

## Risks

- Path safety can be wrong if the implementation only checks string prefixes. The implementation must use resolved paths and a strict descendant check.
- The Archive Patch parser can become too ambitious. It should only check the shape required by precheck; merge semantics belong to the later `t-archive` change.
- The working tree check can block local development. That is intentional for actual archive safety and should be reported clearly.
- A future `t-archive` skill might bypass the tool. Its spec must require calling this precheck before any mutation.
- Upstream rebases may not know about `tools/t-archive-precheck`; preserve it as fork-specific infrastructure.

## Archive Patch

### archive

Target: docsDev/specs/archive/spec.md
Action: create

#### ADDED Requirements

##### Requirement: Archive Precheck Guards Repository Safety

The system must run a deterministic archive precheck before any archive workflow mutates repository files.

###### Scenario: Valid archive input passes

- Given a change has a valid Archive Patch targeting `docsDev/specs/<capability>/spec.md`
- And the archive destination does not exist
- And the working tree is clean
- When the archive precheck runs for that change-id
- Then it must exit `0`

###### Scenario: Malformed Archive Patch is rejected

- Given a change spec lacks a valid Archive Patch, Target, Action, Requirement, or Scenario
- When the archive precheck runs for that change-id
- Then it must exit `2`
- And the archive workflow must not mutate files

###### Scenario: Target path escape is rejected

- Given an Archive Patch Target resolves outside `docsDev/specs/` or equals the specs root
- When the archive precheck runs for that change-id
- Then it must exit `3`
- And the archive workflow must not mutate files

###### Scenario: Existing archive destination is rejected

- Given `docsDev/archive/<change-id>/` already exists
- When the archive precheck runs for that change-id
- Then it must exit `4`
- And the archive workflow must not mutate files

###### Scenario: Dirty working tree is rejected

- Given `git status --porcelain` is not empty
- When the archive precheck runs for a change-id
- Then it must exit `5`
- And the archive workflow must not stash, reset, clean, or mutate files
