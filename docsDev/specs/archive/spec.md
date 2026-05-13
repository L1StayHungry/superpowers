---
capability: archive
owner: lihuajun
updated_at: 2026-05-13T09:51:48Z
source: t-superpowers
---

# Archive Spec

## Change History

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

## Notes
