---
change_id: 20260710-skill-authoring-v6
created_at: 2026-07-10T08:25:00Z
updated_at: 2026-07-10T08:50:00Z
owner: lihuajun
---

# Skill Authoring v6 Spec

## Change History

- 2026-07-10: Adopted the upstream v6.1.1 skill-authoring improvements selectively while retaining internal trigger, namespace, artifact, and distribution contracts.

## Context

The local fork's skill authoring guide still used Claude-specific discovery and tool wording, applied discipline-style prohibitions too broadly, and had no controlled wording micro-test contract. Several small skills also named one harness's dispatch/todo/instruction primitives or used non-portable references. Upstream v6.1.1 provides useful corrections, but its broad TDD/debugging descriptions and unsupported distribution channels conflict with the internal fork.

## Goals

- Replace Claude Search Optimization with harness-neutral Skill Discovery Optimization.
- Match guidance form to observed failure: explanation for knowledge gaps, strong discipline controls for intentional violations, positive output contracts for shape failures, structural slots for omissions, and executable validation for mechanical errors.
- Require behavior-shaping wording to use a no-guidance control, a predeclared rubric, five or more fresh-context repetitions per variant, complete raw responses, and reproducible provenance.
- Make dispatching, plan execution, review reception, systematic debugging, and TDD wording portable across Claude Code, Cursor, and Codex.
- Update team onboarding, installer guidance, and Unreleased notes without changing the package version.

## Non-Goals

- Do not widen complex-only descriptions to upstream's “any feature/bug” trigger.
- Do not modify `t-verification-before-completion`, `t-archive`, `vendor/superpowers/`, or package versions.
- Do not add Kimi, Pi, Antigravity, Codex portal/marketplace, OpenCode, Gemini, Copilot, or other unsupported distribution channels.
- Do not remove Cursor `agents/` or `commands/` packaging placeholders.
- Do not publish, push, archive, or prepare an upstream PR.

## Requirements

### Requirement: Skill Discovery Optimization

`t-writing-skills` must describe discovery in agent-neutral terms, keep descriptions focused on triggering conditions, use portable Markdown references, and avoid harness-specific todo or instruction-file names.

#### Scenario: A skill is authored for multiple supported harnesses

- Given the skill may run in Claude Code, Cursor, or Codex
- When its discovery metadata and references are written
- Then the guidance uses agent, runtime skills directory, instructions file, and portable relative links
- And it does not assume one harness's tool names

### Requirement: Guidance Form Matches Observed Failure

The author must classify a demonstrated baseline failure before choosing guidance. Knowledge gaps use explanation and examples; discipline gaps use prohibitions, rationalization counters, and red flags; wrong output shapes use positive contracts; omissions use required structural slots; mechanical errors use executable validators, linters, or tests.

#### Scenario: Dispatch prompts are bloated

- Given baseline dispatch prompts restate an on-disk brief and bury operational fields
- When replacement guidance is authored
- Then it states the required dispatch-prompt parts in order
- And the shipped block does not append negative restatement rules or exemption clauses

### Requirement: Controlled Wording Micro-Tests

Behavior-shaping wording must be tested against an unguided control with the same pressure scenario, runtime, settings, and predeclared rubric. Each final variant must have at least five fresh-context samples. Complete system/user prompts, raw responses, provenance, manual scores, variance, and failed iterations must be preserved under `docsDev/skill-tests/`.

#### Scenario: The first guided wording still fails

- Given a guided variant produces the right structure but appends a forbidden form
- When the campaign is evaluated
- Then those responses remain in the evidence
- And a refactored variant receives five new fresh-context runs rather than relabeling the failed samples

### Requirement: Harness-Neutral Small Skills

The five selected small skills must use generic subagent, todo list, instructions file, and forge mechanisms. Systematic debugging must use the delimiter-safe `Ultra-think` form. TDD must use a portable Markdown link. Existing engineering discipline and internal `t-superpowers:t-*` references remain intact.

#### Scenario: A supported harness lacks another harness's named tool

- Given a plan or parallel workflow is invoked
- When the skill chooses tracking or dispatch
- Then it describes the capability and outcome instead of inventing an unavailable tool

### Requirement: Local Trigger Boundaries Remain Narrow

`t-systematic-debugging` and `t-test-driven-development` must retain their complex-only descriptions. Simple copy, style, config, Q&A, and pure code-reading requests must not be newly claimed.

#### Scenario: A simple documentation correction is requested

- Given the request does not involve complex behavior or an unknown root cause
- When skills are discovered
- Then the TDD and systematic-debugging descriptions do not claim it

### Requirement: Archive-Stable Regression Evidence

Deterministic contracts and reusable micro-test evidence must live outside the active change directory. Explicit later archival of this change must not break the focused test paths.

#### Scenario: The change is explicitly archived later

- Given `docsDev/changes/20260710-skill-authoring-v6/` is moved
- When the focused skill-authoring contracts run
- Then they continue reading `tests/skill-authoring/` and `docsDev/skill-tests/`

## Validation

- Run every focused contract under `tests/skill-authoring/`.
- Run `bash tools/t-stage1-check.sh`, the 67-test npm installer suite, build, pack dry run, Shell syntax checks, and `git diff --check`.
- Confirm no diff in vendor, version metadata, `t-verification-before-completion`, or `t-archive`.

## Risks

- Model wording remains probabilistic; the deterministic contract preserves the method and evidence, while live samples provide review evidence rather than a CI oracle.
- Explicitly rejecting negative rules for output-shape guidance is intentionally narrow; discipline failures still require strong prohibitions.
- The internal package version remains `5.1.1`, so release communication must rely on Unreleased notes until a separately approved release.

## Archive Patch

### skill-authoring

Target: docsDev/specs/skill-authoring/spec.md
Action: create

#### ADDED Requirements

##### Requirement: Skill Guidance Is Discovered, Shaped, and Tested Deliberately

Internal skills must optimize discovery across supported harnesses, select guidance form from observed failure type, preserve narrow trigger boundaries, and validate behavior-shaping wording with an unguided control, predeclared rubric, five or more fresh-context repetitions per variant, verbatim raw output, provenance, and manual scoring.

###### Scenario: An author changes behavior-shaping wording

- Given baseline evidence demonstrates a repeatable agent failure
- When the skill wording is changed
- Then the author selects explanation, discipline control, positive contract, structural slot, conditional, or executable check according to the failure
- And controlled RED/GREEN evidence is preserved outside the active change directory
