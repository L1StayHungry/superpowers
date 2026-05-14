---
capability: runtime-artifacts
owner: lihuajun
updated_at: 2026-05-14T02:57:28Z
source: t-superpowers
---

# Runtime Artifacts Spec

## Change History

- 2026-05-14: archived from docsDev/changes/20260512-docsdev-paths (DocsDev Runtime Path Migration)

## Overview

Archived long-term requirements for runtime-artifacts.

## Requirements

### Requirement: Complex Change Artifacts Live Under DocsDev Changes

The system must store new complex-work runtime artifacts under `docsDev/changes/<change-id>/`.

#### Scenario: Brainstorming spec path

- Given `t-brainstorming` writes a new design spec for a complex change
- When the spec is saved
- Then it must be saved as `docsDev/changes/<change-id>/spec.md`
- And it must not be saved under `docs/superpowers/specs/`

#### Scenario: Writing-plans plan path

- Given `t-writing-plans` writes a plan for an approved spec
- When the approved spec lives at `docsDev/changes/<change-id>/spec.md`
- Then the plan must be saved as `docsDev/changes/<change-id>/plan.md`
- And it must not be saved under `docs/superpowers/plans/`

#### Scenario: Change-id collision

- Given `docsDev/changes/<change-id>/` already exists
- When a new brainstorming flow tries to use the same change-id
- Then the flow must stop and ask for a different slug or change-id
- And it must not overwrite existing change artifacts

#### Scenario: Existing spec revision

- Given `docsDev/changes/<change-id>/spec.md` already exists
- When the user explicitly asks to revise that spec
- Then the flow may edit the existing spec
- And it must append a `Change History` entry describing the revision reason

#### Scenario: Unrelated complex need gets a new change-id

- Given a current change-id is already being implemented or planned
- When the user raises an unrelated complex need
- Then the flow must create a separate `docsDev/changes/<new-change-id>/`
- And it must not fold the unrelated need into the existing change

## Notes
