---
capability: archive
owner: lihuajun
updated_at: 2026-05-13T09:51:48Z
source: t-superpowers
---

# Archive Spec

## Change History

- 2026-05-14: archived from docsDev/changes/20260513-archive-skill (Archive Skill)
- 2026-05-13: archived from docsDev/changes/20260512-archive-precheck (Archive Precheck)

## Overview

Archived long-term requirements for archive.

## Requirements

### Requirement: Archive Precheck Guards Repository Safety

The system must run a deterministic archive precheck before any archive workflow mutates repository files.

#### Scenario: Valid archive input passes

- Given a change has a valid Archive Patch targeting `docsDev/specs/<capability>/spec.md`
- And the archive destination does not exist
- And the working tree is clean
- When the archive precheck runs for that change-id
- Then it must exit `0`
- And it must print success JSON with the change-id and Archive Patch metadata

#### Scenario: Invalid change-id is rejected

- Given a change-id argument does not match `YYYYMMDD-<slug>`
- When the archive precheck runs for that argument
- Then it must exit `1`
- And the archive workflow must not construct source or archive paths from that value

#### Scenario: Malformed Archive Patch is rejected

- Given a change spec lacks a valid Archive Patch, Target, Action, Requirement, or Scenario
- When the archive precheck runs for that change-id
- Then it must exit `2`
- And the archive workflow must not mutate files

#### Scenario: Target path escape is rejected

- Given an Archive Patch Target resolves outside `docsDev/specs/` or equals the specs root
- When the archive precheck runs for that change-id
- Then it must exit `3`
- And the archive workflow must not mutate files

#### Scenario: Existing archive destination is rejected

- Given `docsDev/archive/<change-id>/` already exists
- When the archive precheck runs for that change-id
- Then it must exit `4`
- And the archive workflow must not mutate files

#### Scenario: Dirty working tree is rejected

- Given `git status --porcelain` is not empty
- When the archive precheck runs for a change-id
- Then it must exit `5`
- And the archive workflow must not stash, reset, clean, or mutate files

### Requirement: Archive Skill Is Explicitly Triggered

The archive workflow must only run when the user explicitly requests archiving a concrete change-id into long-term specs.

#### Scenario: Explicit archive request proceeds

- Given the user explicitly asks to archive `20260512-trigger-convergence`
- When `t-archive` starts
- Then it must run precheck for that change-id

#### Scenario: Vague approval does not archive

- Given a change has passed verification
- When the user says `可以了`, `ok`, or `looks good`
- Then `t-archive` must not run
- And no archive commit may be created

### Requirement: Archive Skill Uses Precheck As Mutation Gate

The archive workflow must call `tools/t-archive-precheck <change-id>` and refuse to mutate files unless precheck exits successfully.

#### Scenario: Precheck failure stops archive

- Given precheck exits non-zero
- When `t-archive` receives the failure
- Then it must report the exit code meaning
- And it must not modify, stage, stash, reset, or clean files

### Requirement: Archive Skill Merges Archive Patch Into Specs

The archive workflow must merge Archive Patch requirements into `docsDev/specs/<capability>/spec.md`.

#### Scenario: Create spec from Archive Patch

- Given a patch with `Action: create`
- And the target spec does not exist
- When `t-archive` applies the patch
- Then it must create the target spec with frontmatter, Change History, Overview, Requirements, and Notes sections

#### Scenario: Update spec from Archive Patch

- Given a patch with `Action: update`
- And the target spec exists
- When `t-archive` applies the patch
- Then it must apply ADDED, MODIFIED, REMOVED, and RENAMED requirements by exact heading name

### Requirement: Archive Skill Commits Specs And Snapshot Together

The archive workflow must move the completed change to `docsDev/archive/` and commit specs plus archive snapshot together.

#### Scenario: Legal archive creates archive commit

- Given precheck succeeds
- And the Archive Patch merge succeeds
- When `t-archive` runs
- Then `docsDev/specs/<capability>/spec.md` must contain the merged content
- And `docsDev/archive/<change-id>/` must exist
- And `docsDev/changes/<change-id>/` must not exist
- And git log must contain one `archive <change-id>: <summary>` commit

#### Scenario: Archive parent directory is created before move

- Given `docsDev/archive/` does not exist
- And precheck succeeds
- When `t-archive` moves the completed change snapshot
- Then it must create `docsDev/archive/` before `git mv`
- And the archive must not fail solely because the archive parent directory was missing

#### Scenario: Failure before commit rolls back

- Given precheck succeeds
- And a later archive step fails before commit
- When `t-archive` handles the failure
- Then it must reset and clean back to the pre-archive HEAD
- And it must not retry automatically

### Requirement: Archive Skill Verifies And Records Successful Archive Evidence

After a successful archive commit, the archive workflow must verify the resulting filesystem state and preserve useful evidence.

#### Scenario: Post-archive verification passes

- Given the archive commit was created
- When `t-archive` verifies the result
- Then `docsDev/archive/<change-id>/` must exist
- And `docsDev/changes/<change-id>/` must not exist
- And every Archive Patch target must exist
- And every Archive Patch target must contain `archived from docsDev/changes/<change-id>`
- And `git status --short` must be empty

#### Scenario: Active plan receives archive evidence

- Given the archive was run while executing an active plan under `docsDev/changes/<active-change-id>/plan.md`
- And that plan file still exists after the archive commit
- When `t-archive` records evidence
- Then it must append the precheck stdout JSON, derived summary, archive commit sha, and post-archive verification results to that plan's Verification Log
- And it must commit that evidence in a separate docs commit after the archive commit
- And `git status --short` must be empty after the evidence commit

#### Scenario: No active plan path is clear

- Given no active plan file can be identified safely
- When `t-archive` finishes successfully
- Then it must report the same evidence in the final response
- And it must not invent or create a plan path

## Notes
