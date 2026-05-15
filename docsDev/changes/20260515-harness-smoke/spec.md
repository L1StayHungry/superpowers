---
change_id: 20260515-harness-smoke
created_at: 2026-05-15T01:02:15Z
updated_at: 2026-05-15T01:02:15Z
owner: lihuajun
---

# Harness Smoke Spec

## Change History

- 2026-05-15: Initial design for CLI and App smoke validation after landing hardening.

## Overview

The `20260514-landing-hardening` change made `t-superpowers` easier for the team to understand and enable. This smoke change verifies the real harness behavior that matters for rollout:

- simple requests stay lightweight and do not enter `t-brainstorming`
- explicit complex requests enter `t-superpowers`
- observed results are recorded in `docsDev/changes/<change-id>/transcripts/`

The smoke intentionally separates command-line checks, which can usually be automated, from app checks, which depend on the user's installed Cursor.app and Codex App state.

## Goals

- Record reproducible CLI smoke evidence for Claude Code CLI and, where available, Codex CLI.
- Provide an exact manual checklist for Cursor.app and Codex App.
- Classify each harness result as `PASS`, `FAIL`, `BLOCKED`, or `NOT VERIFIED`.
- Capture raw logs or user-provided screenshots/text under the change transcript directory.
- Avoid mutating the repository under test while running smoke prompts.

## Non-Goals

- No runtime behavior changes to `t-superpowers`.
- No changes to plugin metadata, hooks, skills, or archive tooling.
- No changes to `vendor/superpowers/`.
- No bulk migration of legacy upstream tests that still mention `docs/superpowers/`.
- No archive until the user explicitly requests it after reviewing smoke results.

## Approach

Use a scratch project for prompt execution so smoke prompts cannot accidentally edit this repository. Store all evidence under:

```text
docsDev/changes/20260515-harness-smoke/transcripts/
docsDev/changes/20260515-harness-smoke/transcripts/raw/
```

For CLI harnesses, capture raw JSONL or stderr logs. For app harnesses, use the manual checklist in `transcripts/app-smoke.md`; screenshots may be referenced if provided by the user, but the minimum acceptable record is copied response text plus a result classification.

## Result Classification

- `PASS`: observed behavior matches expected behavior and evidence is recorded.
- `FAIL`: harness ran, but behavior contradicted expected behavior.
- `BLOCKED`: harness could not be tested because local install, plugin loading, login, UI access, or export path is unavailable.
- `NOT VERIFIED`: test has not been run yet.

## Behavior Rules

### Requirement: Simple Requests Stay Direct

Simple copy, README, style, config, or code-reading requests must not force `t-brainstorming`.

#### Scenario: Claude simple request

- Given Claude Code CLI runs with `--plugin-dir /Users/lihuajun/WorkProject/superpowers`
- When the user asks `帮我把按钮文案从“确定”改成“OK”`
- Then the transcript must not show `t-superpowers:t-brainstorming`
- And the run must not create a new repository change directory solely for that prompt

#### Scenario: Codex simple request

- Given Codex CLI or Codex App has access to internal `t-superpowers`
- When the user asks `帮我加一个 README 段落`
- Then the transcript or observed response must not show `t-superpowers:t-brainstorming`
- And the response should proceed directly or ask for file context

#### Scenario: Cursor simple request

- Given Cursor.app has internal `t-superpowers` enabled
- When the user asks `帮我把按钮文案从“确定”改成“OK”`
- Then Cursor should not force the full `t-brainstorming` workflow

### Requirement: Explicit Complex Requests Enter T-Superpowers

Explicit `t-superpowers` requests must enter the relevant complex-work workflow.

#### Scenario: Claude explicit complex request

- Given Claude Code CLI runs with `--plugin-dir /Users/lihuajun/WorkProject/superpowers`
- When the user asks `用 t-superpowers，我要做一个 PDF 导出功能`
- Then the transcript must show `t-superpowers` and `t-brainstorming` behavior
- And the agent should ask clarifying questions or start the planning flow instead of directly implementing

#### Scenario: Codex explicit complex request

- Given Codex CLI or Codex App has access to internal `t-superpowers`
- When the user asks `用 t-superpowers，我要做一个 PDF 导出功能`
- Then the transcript or observed response must show `t-superpowers` or `t-brainstorming`
- And the agent should ask clarifying questions or start the planning flow

#### Scenario: Cursor explicit complex request

- Given Cursor.app has internal `t-superpowers` enabled
- When the user asks `用 t-superpowers，我要做一个 PDF 导出功能`
- Then Cursor should enter `t-superpowers` or `t-brainstorming`
- And it should not directly implement the feature

### Requirement: Smoke Evidence Is Stored With The Change

Smoke evidence must stay with this change until archive.

#### Scenario: CLI evidence

- Given a CLI smoke check runs
- When raw output is produced
- Then JSONL, stderr, and summary files must be saved under `docsDev/changes/20260515-harness-smoke/transcripts/`

#### Scenario: App evidence

- Given a user manually runs Cursor.app or Codex App smoke
- When the user reports the observation
- Then the result must be recorded in `docsDev/changes/20260515-harness-smoke/transcripts/app-smoke.md`

## Error Handling

- If a CLI command cannot find the harness binary, record `BLOCKED` with the missing command name.
- If Codex CLI cannot load local `t-superpowers`, record `BLOCKED` and do not mutate the user's global Codex configuration.
- If Cursor.app or Codex App cannot load the local plugin, record `BLOCKED: install path unclear`.
- If a simple prompt triggers `t-brainstorming`, record `FAIL` with the transcript location.
- If a complex explicit prompt does not enter `t-superpowers`, record `FAIL` with the transcript location.

## Validation

Required validation after smoke execution:

- `bash tools/t-stage1-check.sh` exits `0`.
- `git diff --check` exits `0` for changed smoke artifacts.
- Raw CLI logs exist for each CLI check that ran.
- `transcripts/app-smoke.md` records `PASS`, `FAIL`, `BLOCKED`, or `NOT VERIFIED` for Cursor.app and Codex App checks.
- No new runtime artifacts are written under `docs/superpowers/`.
- `git status --short` is clean after committing smoke evidence.

## Risks

- Cursor.app and Codex App may not support local plugin loading in the current user setup.
- Codex CLI local plugin cache setup is not a stable team install path yet; failures there should be recorded as install/distribution blockers, not prompt regressions.
- App transcripts may be hard to export. A copied response or screenshot summary is acceptable evidence if the raw transcript is unavailable.

## Archive Patch

### harness-validation

Target: docsDev/specs/harness-validation/spec.md
Action: create

#### ADDED Requirements

##### Requirement: Harness Smoke Classifies Real Runtime Behavior

The system must classify each supported harness smoke check as `PASS`, `FAIL`, `BLOCKED`, or `NOT VERIFIED`.

###### Scenario: Simple prompt smoke

- Given a harness runs a simple copy, README, style, config, or code-reading prompt
- When internal `t-superpowers` is enabled
- Then the recorded result must say whether `t-brainstorming` was avoided

###### Scenario: Explicit complex prompt smoke

- Given a harness runs an explicit `t-superpowers` complex prompt
- When internal `t-superpowers` is enabled
- Then the recorded result must say whether the harness entered `t-superpowers` or `t-brainstorming`

##### Requirement: Smoke Evidence Stays With The Change

The system must store smoke evidence under the active `docsDev/changes/<change-id>/transcripts/` directory.

###### Scenario: CLI smoke evidence

- Given a CLI smoke check produces raw output
- When evidence is stored
- Then JSONL, stderr, and summaries must be stored under the active change transcript directory

###### Scenario: App smoke evidence

- Given a user manually runs Cursor.app or Codex App smoke
- When the observation is reported
- Then the result must be recorded in the active change transcript summary
