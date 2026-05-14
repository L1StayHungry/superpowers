---
capability: triggering
owner: lihuajun
updated_at: 2026-05-14T02:04:57Z
source: t-superpowers
---

# Triggering Spec

## Change History

- 2026-05-14: archived from docsDev/changes/20260512-trigger-convergence (Trigger Convergence)

## Overview

Archived long-term requirements for triggering.

## Requirements

### Requirement: T-Superpowers Trigger Boundary For Explicit And Complex Work

The system must require `t-superpowers` skills for explicit requests and complex development work.

#### Scenario: Explicit request enters requested skill

- Given a user explicitly asks to use `t-superpowers` or names a `t-*` skill
- When the requested skill exists
- Then the agent must use the requested skill before implementation

#### Scenario: Complex request enters t-superpowers

- Given a user asks for a multi-file feature, behavior change, or root-cause-unknown bugfix
- When a relevant `t-*` skill exists
- Then the agent must use the relevant `t-*` skill before implementation

#### Scenario: Ambiguous request does not silently enter workflow

- Given a user asks for a request that may be complex but is not clearly in scope for the full workflow
- When the user does not explicitly request `t-superpowers` or a `t-*` skill
- Then the agent must either ask whether to use `t-superpowers` or explicitly proceed in direct mode as a simple request

### Requirement: Simple Requests Are Not Forced Into T-Superpowers

The system must not force `t-superpowers` for simple edits, Q&A, pure code reading, or small mechanical changes.

#### Scenario: Simple request remains direct

- Given a user asks for a simple single-file copy, style, config, Q&A, or code-reading task
- When the user does not explicitly request `t-superpowers` or a `t-*` skill
- Then the agent may handle the task directly without entering `t-brainstorming`

#### Scenario: Codex description does not trigger simple request

- Given Codex sees a simple single-file README, copy, style, config, Q&A, or code-reading request
- When no explicit `t-superpowers` or `t-*` skill is requested
- Then the narrowed descriptions must not implicitly select `t-brainstorming`

## Notes
