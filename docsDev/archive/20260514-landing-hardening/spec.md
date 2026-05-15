---
change_id: 20260514-landing-hardening
created_at: 2026-05-14T10:51:49Z
updated_at: 2026-05-14T10:51:49Z
owner: lihuajun
---

# Landing Hardening Spec

## Change History

- 2026-05-14: Initial design for making the current t-superpowers fork installable, understandable, and guarded against obvious stage-2 regressions.

## Overview

Stage 2 has already delivered the core internal-fork behavior: trigger convergence, `docsDev/changes/` runtime artifacts, `docsDev/specs/` long-term specs, `t-archive`, and `tools/t-archive-precheck`.

The remaining blocker for team rollout is the landing surface. The visible plugin metadata and README still read like upstream Superpowers, including broad automatic-trigger language and Codex default prompts that suggest starting a feature through brainstorming. That undermines the fork's main boundary: simple requests should stay lightweight, while complex requests use `t-superpowers`.

This change hardens the user-facing entry points and adds a small regression guard. It does not alter archive semantics, introduce state machines, or migrate broad upstream test fixtures.

## Goals

- Make the installed plugin metadata say this is `t-superpowers`, an internal fork for complex development work.
- Remove default prompt wording that nudges Codex users into automatic brainstorming for ordinary feature ideas.
- Give team members one concise setup guide for Claude Code, Cursor, and Codex.
- Add a README top section that prevents confusion with official Superpowers while leaving the upstream README body mostly intact.
- Update session-start branding and boundary wording so injected context no longer says only "You have superpowers" without the internal fork distinction.
- Add a small CI guard that catches namespace and forbidden-path regressions on pull requests.

## Non-Goals

- No changes to `vendor/superpowers/`.
- No changes to `package.json`, `gemini-extension.json`, or `.opencode/plugins/superpowers.js`.
- No new `tools/t-validate`, `tools/t-state`, state machine, `acceptance_evidence`, transcript hashing, PR online checks, or transaction backup system.
- No broad rewrite of all historical tests that still model upstream `docs/superpowers/` paths.
- No Cursor.app or Codex App manual smoke execution in this implementation slice. Those are validation follow-ups after the landing surface is corrected.
- No automatic `t-archive` trigger from verification, approval phrases, or the complex-work chain.

## Approach

Make the landing surface match the behavior that already exists.

First, update the three plugin manifests and Claude marketplace metadata. The descriptions should emphasize "complex changes, planning, TDD, debugging, review, and archive discipline" and explicitly say simple edits and Q&A should stay in the default agent flow. Codex `defaultPrompt` should be changed from broad feature-starting prompts to explicit complex-change prompts, for example:

- `Plan a complex change with t-superpowers.`
- `Use t-superpowers for a multi-file behavior change that needs a spec and plan.`

Second, add `docsDev/getting-started.md` as the team-facing guide. It should cover local installation paths for Claude Code, Cursor, and Codex; warn that official Superpowers and `t-superpowers` should normally not both be enabled for one user workflow; explain the simple-vs-complex trigger boundary; and document where artifacts live.

Third, add a short fork notice at the top of `README.md`, linking to `docsDev/getting-started.md`. Keep the upstream README body available as reference instead of rewriting it wholesale.

Fourth, tune `hooks/session-start` branding. It should inject the same `t-using-superpowers` body, but the wrapper text should identify `t-superpowers` as the internal fork and say the skill content defines when to use t-* workflows. This is wording only; hook routing and JSON output shape must remain unchanged.

Fifth, add a small GitHub Action that runs `bash tools/t-stage1-check.sh` and a scoped grep guard over live runtime surfaces. The guard should fail if live skill, hook, manifest, or README onboarding text reintroduces upstream runtime namespace or forbidden new-artifact paths.

## Files

Expected implementation files:

- Modify `.codex-plugin/plugin.json`: `description`, `interface.shortDescription`, `interface.longDescription`, and `interface.defaultPrompt`.
- Modify `.cursor-plugin/plugin.json`: `description`.
- Modify `.claude-plugin/plugin.json`: `description`.
- Modify `.claude-plugin/marketplace.json`: marketplace and plugin descriptions.
- Modify `hooks/session-start`: wrapper branding only.
- Modify `README.md`: add a short `t-superpowers` fork notice and team guide link near the top.
- Add `docsDev/getting-started.md`: team setup and usage guide.
- Add `.github/workflows/t-superpowers-guardrails.yml`: stage-1 and stage-2 lightweight guardrails.

Out-of-scope but tracked follow-up files:

- `tests/explicit-skill-requests/**`
- `tests/claude-code/**`
- `tests/skill-triggering/**`

Those test fixtures still contain upstream `docs/superpowers/` paths in places. This change may document that status, but should not migrate the full fixture set in the same patch.

## Behavior Rules

### Requirement: Plugin Metadata Communicates The Internal Boundary

Installed plugin surfaces must describe `t-superpowers` as an internal fork for complex development work, not as a universal always-on workflow.

#### Scenario: Codex default prompt is explicit

- Given the Codex plugin manifest is displayed to a user
- When the user sees the default prompts
- Then the prompts must mention complex work or `t-superpowers`
- And they must not use broad upstream prompts such as "I've got an idea for something I'd like to build" or "Let's add a feature to this project"

#### Scenario: Manifest descriptions preserve lightweight simple work

- Given a user reads the Claude, Cursor, or Codex plugin description
- When they are deciding whether to use the plugin
- Then the description must say it is for complex planning, TDD, debugging, review, or archive workflows
- And it must not imply that every edit should enter the workflow

### Requirement: Team Guide Explains Installation And Usage

The repository must include one team-facing guide that explains how to enable and use the internal fork.

#### Scenario: Team member installs the fork

- Given a team member opens the guide
- When they need to enable `t-superpowers`
- Then the guide must provide local install or enablement steps for Claude Code, Cursor, and Codex
- And it must tell them not to enable official Superpowers and `t-superpowers` together for ordinary team work

#### Scenario: Team member chooses direct mode or t-superpowers

- Given a team member reads the guide
- When they need to decide how to ask the agent for work
- Then the guide must say simple edits, small style/config changes, Q&A, and code reading can stay in normal agent mode
- And complex multi-file features, behavior changes, root-cause-unknown bugs, and explicit `t-superpowers` requests should use the `t-*` workflow

#### Scenario: Team member locates artifacts

- Given a complex change uses `t-superpowers`
- When the team member looks for artifacts
- Then the guide must point specs and plans to `docsDev/changes/<change-id>/`
- And long-term specs to `docsDev/specs/<capability>/spec.md`
- And archived snapshots to `docsDev/archive/<change-id>/`

### Requirement: README Distinguishes Fork From Upstream

The root README must immediately tell readers they are in the internal fork.

#### Scenario: Reader opens README

- Given a reader opens `README.md`
- When they read the first screen
- Then they must see that this repository is `t-superpowers`, an internal fork of `obra/superpowers`
- And they must see a link to the team getting-started guide
- And the note must warn that official Superpowers and `t-superpowers` are normally alternatives, not both enabled together

### Requirement: Session Bootstrap Uses T-Superpowers Branding

Session-start injected wrapper text must identify the internal fork without changing hook routing behavior.

#### Scenario: Claude or Cursor session starts

- Given the session-start hook runs
- When it emits additional context
- Then the wrapper text must refer to `t-superpowers`
- And it must point to `t-superpowers:t-using-superpowers`
- And it must preserve the existing platform-specific JSON output fields

### Requirement: CI Blocks Obvious Stage-2 Regressions

Pull requests must fail on lightweight, deterministic regressions that would break the fork's landing boundary.

#### Scenario: Stage 1 namespace check regresses

- Given CI runs on a pull request
- When `bash tools/t-stage1-check.sh` fails
- Then CI must fail

#### Scenario: Live runtime surface reintroduces forbidden paths

- Given CI scans live skill, hook, manifest, README, and docsDev guide surfaces
- When those files contain new runtime instructions to write `docs/superpowers/specs` or `docs/superpowers/plans`
- Then CI must fail

#### Scenario: Live runtime surface reintroduces upstream runtime namespace

- Given CI scans live runtime surfaces
- When those files contain upstream skill runtime references such as `superpowers:brainstorming`
- Then CI must fail unless the reference is in an explicitly allowed upstream-history context

## Error Handling

- If a harness manifest schema rejects a new field or wording shape, keep the schema and revise only string values.
- If the GitHub Action's grep is too broad and catches historical or upstream-reference text, narrow the scan scope instead of weakening the forbidden-path rule.
- If README wording conflicts with the upstream README body, the new fork notice takes precedence and should explicitly say the rest of the README remains upstream-oriented reference until gradually localized.

## Validation

Required checks for this change:

- `bash tools/t-stage1-check.sh` exits `0`.
- `git diff --check` exits `0` for changed files.
- Manifest scan confirms `.codex-plugin/plugin.json`, `.cursor-plugin/plugin.json`, `.claude-plugin/plugin.json`, and `.claude-plugin/marketplace.json` mention `t-superpowers` or complex-work scope.
- Codex manifest scan confirms old default prompts are absent.
- README and `docsDev/getting-started.md` scan confirms the team guide links and `docsDev/` artifact paths are present.
- CI guard script or workflow syntax check passes locally as far as possible without GitHub Actions runtime.
- Repository scan confirms no `allow_implicit_invocation: false`, status machine, `acceptance_evidence`, `archive_failure`, `tools/t-validate`, or `tools/t-state` was introduced outside historical docs.

Recommended follow-up validation after implementation:

- Cursor.app manual smoke: simple copy edit does not enter `t-brainstorming`; explicit `t-superpowers` complex request enters the workflow.
- Codex App manual smoke: simple README edit does not enter `t-brainstorming`; explicit `t-superpowers` complex request enters the workflow.
- Add or clone t-superpowers-specific fixtures that use `docsDev/changes/<change-id>/plan.md` instead of mutating all upstream legacy fixture paths in one patch.

## Risks

- Metadata can promise the right behavior while installed harnesses still cache older plugin versions. Rollout notes should tell users to reinstall or refresh plugin cache after this change.
- A CI grep that scans too broadly can block legitimate upstream-history references. Keep the guard focused on live runtime surfaces and onboarding docs.
- Keeping the upstream README body may continue to confuse readers after the fork notice. The initial notice must be strong enough to redirect team users to `docsDev/getting-started.md`.
- Not migrating all old tests in this slice leaves fixture drift. That is acceptable only if the follow-up t-fixture work is tracked and the new CI guard covers live surfaces.

## Archive Patch

### onboarding

Target: docsDev/specs/onboarding/spec.md
Action: create

#### ADDED Requirements

##### Requirement: T-Superpowers Landing Surface Describes Complex-Work Scope

The system must present `t-superpowers` as an internal fork for complex development workflows while preserving lightweight handling for simple requests.

###### Scenario: Plugin metadata is scoped

- Given a team member sees the Claude, Cursor, Codex, or marketplace metadata
- When they read what `t-superpowers` does
- Then the metadata must say it is for complex planning, TDD, debugging, review, archive, or multi-step development workflows
- And it must not imply all edits should enter the workflow

###### Scenario: Codex default prompt is scoped

- Given the Codex plugin exposes default prompts
- When a user chooses a prompt
- Then the prompt must explicitly mention complex work or `t-superpowers`
- And it must not use broad upstream feature-starting wording

##### Requirement: Team Setup Guide Exists

The system must provide a team-facing setup guide for enabling and using `t-superpowers`.

###### Scenario: Guide covers supported harnesses

- Given a team member opens `docsDev/getting-started.md`
- When they look for setup instructions
- Then the guide must cover Claude Code, Cursor, and Codex
- And it must warn that official Superpowers and `t-superpowers` should normally not both be enabled

###### Scenario: Guide explains artifact paths

- Given a team member reads the guide
- When they look for complex-change artifacts
- Then the guide must identify `docsDev/changes/<change-id>/spec.md`, `docsDev/changes/<change-id>/plan.md`, `docsDev/specs/<capability>/spec.md`, and `docsDev/archive/<change-id>/`

##### Requirement: Landing Guardrails Catch Obvious Regressions

The repository must include lightweight CI guardrails for namespace and stage-2 path regressions.

###### Scenario: Stage-one check runs in CI

- Given a pull request is opened
- When CI runs
- Then `bash tools/t-stage1-check.sh` must be executed
- And a failure must fail the pull request check

###### Scenario: Forbidden live runtime paths are rejected

- Given CI scans live runtime and onboarding surfaces
- When those surfaces reintroduce `docs/superpowers/specs` or `docs/superpowers/plans` as new runtime output paths
- Then CI must fail
