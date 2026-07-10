---
change_id: 20260710-writing-plans-v6
created_at: 2026-07-10T06:19:43Z
updated_at: 2026-07-10T07:00:12Z
owner: lihuajun
---

# Writing Plans v6 Contract Spec

## Change History

- 2026-07-10: Initial approved design for selectively adopting the upstream v6.1.1 planning improvements.
- 2026-07-10: Review hardening added stable structural fixtures and verbatim live RED/GREEN pressure evidence without treating either fixture as an executable plan.

## Context

The internal `t-writing-plans` skill already keeps complex work behind a narrow trigger and writes plans beside approved specs in `docsDev/changes/<change-id>/`. Upstream v6.1.1 improves plan fidelity by carrying project-wide constraints into every task, declaring task interfaces, and sizing tasks around independently testable delivery boundaries. This change adopts those planning contracts without widening local triggers or restoring upstream artifact paths and namespaces.

## Goals

- Require plans to copy project-wide constraints from the approved spec without paraphrasing exact values.
- Give every task an explicit `Consumes` and `Produces` interface contract, including a reason when either side does not apply.
- Size tasks around one independently testable and reviewable deliverable instead of files, technical layers, or setup-only work.
- Retain complete implementation code, exact RED/GREEN commands and expected output, no placeholders, and one checkpoint commit per task.
- Add a deterministic contract test that is directly runnable and exposed through the existing Claude skill-test runner.

## Non-Goals

- Do not widen `t-writing-plans` to simple single-file edits, Q&A, pure code reading, or ordinary planning that does not enter the complex-work flow.
- Do not replace the local plan frontmatter, change directory, namespace, handoff choices, or TDD discipline with upstream defaults.
- Do not add a general plan validator, state machine, remote eval dependency, version bump, publish, push, archive, or upstream contribution workflow.

## Global Constraints Source

The following project-wide constraints are the verbatim source for this change's implementation plan:

- The change identifier is `20260710-writing-plans-v6`.
- The plan artifact path is `docsDev/changes/20260710-writing-plans-v6/plan.md`.
- Skill references use the `t-superpowers:t-*` namespace.
- The repository and Codex plugin versions remain `5.1.1`.
- Do not modify `vendor/superpowers/`, `skills/t-verification-before-completion/`, or `skills/t-archive/`.
- The focused contract command is `bash tests/claude-code/test-writing-plans-contract.sh`.
- The stage regression commands are `bash tools/t-stage1-check.sh`, `npm run test:npm-installer`, and `git diff --check`.

## Requirements

### Requirement: Verbatim Global Constraints

Every generated plan must contain a `## Global Constraints` section before its tasks. The planner must reread the approved spec and copy every project-wide version, dependency, naming, platform, exact path, command, protocol, numeric, and required-copy constraint verbatim. It must not normalize, soften, infer, or silently resolve contradictory constraints.

#### Scenario: Exact values survive planning

- Given an approved spec pins a version, platform, timeout, path, command, or literal string
- When the implementation plan is written
- Then the exact spelling, capitalization, number, unit, and operator appear in `## Global Constraints`
- And every task inherits the constraint without a rewritten substitute

### Requirement: Explicit Task Interfaces

Every task must declare `Consumes` and `Produces` with exact symbol signatures, types, and data contracts used across existing code, prior tasks, later tasks, or callers. When one side has no interface, the planner must write `N/A` with a task-specific reason rather than leaving the field blank.

#### Scenario: An isolated documentation delivery

- Given a task exposes no callable or data interface
- When its task block is written
- Then both interface fields still exist
- And each non-applicable field explains why it is not applicable

### Requirement: Reviewable Task Right-Sizing

A task must be the smallest boundary that completes its own RED/GREEN cycle and is worth an independent reviewer gate. Configuration, scaffolding, setup, and documentation must be folded into the delivery that needs them. Tasks must not be split mechanically by file or technical layer, and unrelated behavior must not be combined only because it shares a file.

#### Scenario: One end-to-end behavior crosses layers

- Given one behavior needs a configuration entry, a source edit, a test, and documentation
- When tasks are decomposed
- Then those edits remain in one independently testable delivery task
- And file or layer boundaries do not create review fragments with no useful behavior

#### Scenario: Unrelated behaviors share one file

- Given two behaviors modify the same registry file
- And each behavior has an independent test, interface, release, and reviewer verdict
- When tasks are decomposed
- Then they remain two independently reviewable tasks
- And the shared file does not justify merging unrelated behavior

### Requirement: Explicit N/A Reasons

When a task has no consumed or produced interface, the corresponding field must contain `N/A — <specific reason>` on the same line. Empty values, bare `N/A`, and generic reasons such as “not applicable” or “no interface” are invalid.

#### Scenario: An isolated removal has no boundary interface

- Given a removal task reads and exposes no symbol, type, or data contract
- When its Interfaces block is written
- Then both N/A fields explain the task-specific absence
- And neither field uses an empty or generic placeholder

### Requirement: Detailed TDD Plans Remain Executable

Plans must continue to include exact file paths, complete code for every code-changing step, a failing test and observed RED command, the minimal GREEN implementation, passing commands with expected output, no placeholder instructions, and a checkpoint commit after each independently reviewed task.

#### Scenario: A context-free implementer executes a task

- Given an implementer sees only one task and the plan's global constraints
- When the task is executed
- Then no missing code, implicit interface, placeholder, or guessed command is required

### Requirement: Local Trigger, Path, and Namespace Contracts Remain Stable

The skill frontmatter must continue to restrict invocation to complex approved specs or requirements needing a multi-step plan. Plans stay in the local change directory and all required sub-skill references keep the internal prefix.

#### Scenario: Simple request does not enter the heavy flow

- Given a simple single-file edit, Q&A request, or pure code-reading request
- When skills are discovered
- Then `t-writing-plans` does not claim that request

### Requirement: Deterministic Contract Regression

A repository-local contract test must check the skill's trigger, paths, namespace, and durable wording, then use stable structural fixtures only for verbatim Global Constraints, exact task Interfaces, both right-sizing directions, and specific N/A reasons. The fixtures must live under `tests/claude-code/fixtures/` so later explicit change archival cannot break the regression, and must explicitly disclaim executable-plan validity. The existing Claude skill-test runner must discover the focused test.

#### Scenario: A future upstream sync regresses local planning

- Given a later edit drops an interface block or restores an upstream path
- When `bash tests/claude-code/test-writing-plans-contract.sh` runs directly or through `run-skill-tests.sh`
- Then it exits non-zero with a focused contract failure

## Validation

- Run the focused contract test before and after editing the skill, recording expected RED and GREEN output.
- Run the stage-one namespace regression and npm installer suite to cover shared package and namespace behavior.
- Run shell syntax and whitespace checks on the final scoped diff.
- Confirm no diff exists under the protected vendor, verification, or archive paths.

## Risks

- Static prompt contracts cannot prove that every model will follow the planning discipline under every pressure scenario; focused reviewer pressure tests remain useful evidence.
- Requiring all exact values can create noisy plans when a spec mixes constraints with examples; the skill must distinguish authoritative project-wide requirements without rewriting them.
- Interface blocks can become boilerplate unless specific reasons and exact contracts are required.

## Archive Patch

### planning

Target: docsDev/specs/planning/spec.md
Action: create

#### ADDED Requirements

##### Requirement: Implementation Plans Preserve Constraints and Task Interfaces

Complex implementation plans must copy project-wide constraints verbatim from the approved spec, declare exact consumed and produced interfaces for every task, and size each task around one independently testable and reviewable delivery boundary.

###### Scenario: A plan crosses files and technical layers

- Given an approved complex change contains exact platform, dependency, naming, or numeric constraints
- And one behavior requires source, test, configuration, and documentation edits
- When the implementation plan is written
- Then all exact project-wide constraints appear before the tasks without paraphrasing
- And the related edits remain one reviewable task with explicit consumed and produced contracts
