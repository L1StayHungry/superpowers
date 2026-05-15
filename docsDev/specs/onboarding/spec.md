---
capability: onboarding
owner: lihuajun
updated_at: 2026-05-15T00:57:52Z
source: t-superpowers
---

# Onboarding Spec

## Change History

- 2026-05-15: archived from docsDev/changes/20260514-landing-hardening (Landing Hardening)

## Overview

Archived long-term requirements for onboarding.

## Requirements

### Requirement: T-Superpowers Landing Surface Describes Complex-Work Scope

The system must present `t-superpowers` as an internal fork for complex development workflows while preserving lightweight handling for simple requests.

#### Scenario: Plugin metadata is scoped

- Given a team member sees the Claude, Cursor, Codex, or marketplace metadata
- When they read what `t-superpowers` does
- Then the metadata must say it is for complex planning, TDD, debugging, review, archive, or multi-step development workflows
- And it must not imply all edits should enter the workflow

#### Scenario: Codex default prompt is scoped

- Given the Codex plugin exposes default prompts
- When a user chooses a prompt
- Then the prompt must explicitly mention complex work or `t-superpowers`
- And it must not use broad upstream feature-starting wording

### Requirement: Team Setup Guide Exists

The system must provide a team-facing setup guide for enabling and using `t-superpowers`.

#### Scenario: Guide covers supported harnesses

- Given a team member opens `docsDev/getting-started.md`
- When they look for setup instructions
- Then the guide must cover Claude Code, Cursor, and Codex
- And it must warn that official Superpowers and `t-superpowers` should normally not both be enabled

#### Scenario: Guide explains artifact paths

- Given a team member reads the guide
- When they look for complex-change artifacts
- Then the guide must identify `docsDev/changes/<change-id>/spec.md`, `docsDev/changes/<change-id>/plan.md`, `docsDev/specs/<capability>/spec.md`, and `docsDev/archive/<change-id>/`

### Requirement: Landing Guardrails Catch Obvious Regressions

The repository must include lightweight CI guardrails for namespace and stage-2 path regressions.

#### Scenario: Stage-one check runs in CI

- Given a pull request is opened
- When CI runs
- Then `bash tools/t-stage1-check.sh` must be executed
- And a failure must fail the pull request check

#### Scenario: Forbidden live runtime paths are rejected

- Given CI scans live runtime and onboarding surfaces
- When those surfaces reintroduce `docs/superpowers/specs` or `docs/superpowers/plans` as new runtime output paths
- Then CI must fail

## Notes
