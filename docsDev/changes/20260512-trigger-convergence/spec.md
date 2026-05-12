---
change_id: 20260512-trigger-convergence
created_at: 2026-05-12T01:35:57Z
updated_at: 2026-05-12T02:03:24Z
owner: lihuajun
---

# Trigger Convergence Spec

## Change History

- 2026-05-12: Initial design for stage 2 trigger convergence.
- 2026-05-12: Added positive Codex implicit-trigger validation, tighter ambiguous-request handling, richer Archive Patch scenarios, and rebase risk coverage.

## Overview

Stage 1 preserved upstream Superpowers behavior after namespace migration. That behavior is intentionally aggressive: `t-using-superpowers` says a skill must be invoked when there is even a 1% chance it applies, and key skill descriptions tell Codex to trigger broad workflows for ordinary feature, bugfix, and planning language.

Stage 2 starts by narrowing that trigger boundary. This change makes `t-superpowers` mandatory for explicit requests and genuinely complex development work, while allowing simple edits, Q&A, pure code reading, and small mechanical changes to proceed through the harness default flow.

This change is limited to trigger behavior. It does not move runtime artifacts to `docsDev/changes/`, does not add `t-archive`, and does not introduce status machines or validation tools.

## Goals

- Simple requests should not be forced into `t-superpowers`.
- Complex work should still enter the relevant `t-*` skill path.
- Codex should not implicitly trigger heavyweight skills from broad descriptions for simple copy, style, config, Q&A, or code-reading requests.
- Explicit user requests such as "use t-superpowers", "走 brainstorming", or naming a `t-*` skill must continue to trigger the requested skill.
- The implementation should remain prompt-based and lightweight, with no `allow_implicit_invocation: false` policy change.

## Non-Goals

- No path migration from `docs/superpowers/` to `docsDev/changes/`.
- No `t-archive` skill.
- No `tools/t-archive-precheck`.
- No state machine, `status_history`, `acceptance_evidence`, transcript hash, PR online verification, or unified `t-validate` tool.
- No forced subagent dispatch template.
- No broad rewrite of unrelated skills.

## Approach

Use a two-channel trigger convergence.

First, soften `skills/t-using-superpowers/SKILL.md`. Replace the absolute "1% chance" rule with a boundary table:

- Explicit user request for `t-superpowers` or a `t-*` skill: use the requested skill.
- Complex multi-file feature, behavior change, or underspecified development request: use `t-brainstorming` and then `t-writing-plans` when implementation planning is needed.
- Complex bug, failing test, or root cause unknown: use `t-systematic-debugging`; use `t-test-driven-development` when implementing the fix.
- Simple single-file copy, style, config, Q&A, pure code reading, or mechanical edit: do not force a skill.
- Ambiguous but potentially complex request: do not auto-enter the full workflow. Either ask one concise question such as "这看起来比较复杂，要走 t-brainstorming 吗？" or proceed in direct mode while explicitly stating "按简单请求处理；如需走 t-superpowers 请说明". Never silently default into `t-brainstorming`.

Second, narrow the Codex-visible frontmatter descriptions for the key skills whose current descriptions are too broad:

- `skills/t-brainstorming/SKILL.md`
- `skills/t-writing-plans/SKILL.md`
- `skills/t-test-driven-development/SKILL.md`
- `skills/t-systematic-debugging/SKILL.md`
- `skills/t-subagent-driven-development/SKILL.md`

The descriptions should say "use only for complex..." and explicitly exclude single-file edits, copy/style/config tweaks, Q&A, and pure code reading where applicable.

## Files

Expected implementation files:

- Modify `skills/t-using-superpowers/SKILL.md`: body rules and trigger decision table.
- Modify `skills/t-brainstorming/SKILL.md`: frontmatter `description`.
- Modify `skills/t-writing-plans/SKILL.md`: frontmatter `description`.
- Modify `skills/t-test-driven-development/SKILL.md`: frontmatter `description`.
- Modify `skills/t-systematic-debugging/SKILL.md`: frontmatter `description`.
- Modify `skills/t-subagent-driven-development/SKILL.md`: frontmatter `description`.

Expected validation artifacts may be added under `docs/二开规划/harness-transcripts/` or a focused test fixture if the implementation plan chooses to automate part of the trigger checks.

## Behavior Rules

### Requirement: Simple Requests Do Not Force Skills

The system must not require `t-superpowers` for simple requests that are clearly small in scope.

#### Scenario: Single copy edit

- Given the user asks for a small copy change such as changing a button label from "确定" to "OK"
- When no explicit `t-superpowers` or `t-*` skill is requested
- Then the agent may handle the edit directly
- And the agent must not claim that `t-brainstorming` is mandatory
- And no new change directory should be created only because the request looked like development work

#### Scenario: Pure code reading

- Given the user asks where a behavior is implemented
- When the task is only reading or explaining code
- Then the agent should answer from code context without forcing a planning workflow

### Requirement: Complex Work Still Uses T-Superpowers

The system must still require the relevant `t-*` skill for complex development work.

#### Scenario: Explicit t-superpowers request

- Given the user explicitly says "用 t-superpowers" or names a `t-*` skill
- When the requested skill exists
- Then the agent must use that skill before proceeding

#### Scenario: Multi-file feature request

- Given the user asks to add a new feature that changes behavior across multiple files
- When the request spans multiple files or requires design choices before implementation
- Then the agent must enter the `t-brainstorming` flow before implementation

#### Scenario: Root cause unknown bug

- Given the user reports a bug, failing test, or unexpected behavior
- When the root cause is not already known
- Then the agent must use `t-systematic-debugging` before proposing a fix

#### Scenario: Ambiguous request asks before workflow

- Given the user asks for a request that may be complex but does not clearly require the full workflow
- When no explicit `t-superpowers` or `t-*` skill is requested
- Then the agent must not silently default into `t-brainstorming`
- And the agent must either ask whether to use `t-superpowers` or state that it is proceeding in direct mode as a simple request

### Requirement: Codex Descriptions Are Narrow

Codex-visible skill descriptions must not cause heavyweight skills to trigger for simple requests.

#### Scenario: README paragraph edit

- Given Codex sees a request to add a small README paragraph
- When the request is single-file and mechanical
- Then `t-brainstorming` should not be implicitly selected only because its description says "any creative work"

#### Scenario: Complex behavior change

- Given Codex sees a request for a complex multi-file behavior change
- When the matching description says it is for complex work
- Then the relevant `t-*` skill should be implicitly selected

## Error Handling

- If a request is ambiguous, the agent should not silently enter the full workflow. It should either ask whether to use `t-superpowers` or explain that it will proceed directly because the current request appears simple.
- If a user explicitly requests a missing skill, report that the skill is unavailable and continue with the closest safe process.
- If validation shows a simple prompt still triggers `t-brainstorming`, treat that as a failed trigger-convergence regression and revise the relevant description or bootstrap wording.

## Validation

Required checks for this change:

- `bash tools/t-stage1-check.sh` exits 0.
- Simple bootstrap prompt check: "帮我把按钮文案从'确定'改成'OK'" does not enter `t-brainstorming` and does not create an additional change directory for that prompt.
- Codex description prompt check: "帮我加一个 README 段落" does not implicitly trigger `t-brainstorming`.
- Codex positive implicit-trigger check: "我要做一个支持多种格式的 PDF 导出功能，涉及前端按钮、后端 API 和模板生成" does not mention `t-superpowers`, but still implicitly selects `t-brainstorming`.
- Explicit complex prompt check: "用 t-superpowers，我要做一个 PDF 导出功能" enters the complex-work skill path.
- Repository scan confirms `policy.allow_implicit_invocation: false` was not introduced.
- Description regression grep: the five scoped frontmatter descriptions mention `ONLY` or `complex`, and do not contain broad phrases such as "any creative work", "any work", or "before any".

## Risks

- If only `t-using-superpowers` is changed, Codex may still mis-trigger from broad descriptions. That is why the description changes are in scope.
- If descriptions become too narrow, complex work may no longer trigger automatically. The wording must preserve explicit and complex-work triggers.
- Existing tests may assume the old strict "1% chance" wording. Any test updates must reflect the new internal fork policy, not upstream behavior.
- This change does not solve `docs/superpowers/` path output. That is intentionally deferred to the next stage 2 iteration.
- Future upstream rebases may try to restore the original 1% wording and broad descriptions through mechanical merges. Reconcile manually per `docs/二开规划/二次开发规划.md` §7.2 step 3; do not let `vendor/` diffs overwrite the converged text.

## Archive Patch

### triggering

Target: docsDev/specs/triggering/spec.md
Action: create

#### ADDED Requirements

##### Requirement: T-Superpowers Trigger Boundary For Explicit And Complex Work

The system must require `t-superpowers` skills for explicit requests and complex development work.

###### Scenario: Explicit request enters requested skill

- Given a user explicitly asks to use `t-superpowers` or names a `t-*` skill
- When the requested skill exists
- Then the agent must use the requested skill before implementation

###### Scenario: Complex request enters t-superpowers

- Given a user asks for a multi-file feature, behavior change, or root-cause-unknown bugfix
- When a relevant `t-*` skill exists
- Then the agent must use the relevant `t-*` skill before implementation

###### Scenario: Ambiguous request does not silently enter workflow

- Given a user asks for a request that may be complex but is not clearly in scope for the full workflow
- When the user does not explicitly request `t-superpowers` or a `t-*` skill
- Then the agent must either ask whether to use `t-superpowers` or explicitly proceed in direct mode as a simple request

##### Requirement: Simple Requests Are Not Forced Into T-Superpowers

The system must not force `t-superpowers` for simple edits, Q&A, pure code reading, or small mechanical changes.

###### Scenario: Simple request remains direct

- Given a user asks for a simple single-file copy, style, config, Q&A, or code-reading task
- When the user does not explicitly request `t-superpowers` or a `t-*` skill
- Then the agent may handle the task directly without entering `t-brainstorming`

###### Scenario: Codex description does not trigger simple request

- Given Codex sees a simple single-file README, copy, style, config, Q&A, or code-reading request
- When no explicit `t-superpowers` or `t-*` skill is requested
- Then the narrowed descriptions must not implicitly select `t-brainstorming`
