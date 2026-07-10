---
change_id: 20260710-v6-adoption-followup
created_at: 2026-07-10T18:38:00+08:00
updated_at: 2026-07-10T18:38:00+08:00
owner: lihuajun
---

# v6.1.1 Adoption Follow-up Spec

## Change History

- 2026-07-10: Initial approved design for closing three consistency gaps left after the seven v6.1.1 adoption commits.

## Context

The fork adopted upstream Superpowers v6.1.1 across seven commits (`99c89c6`→`1439aa0`,
with the runtime baseline split into a sync commit and a hardening commit). A follow-up
review found three residual gaps against the fork's own approved contracts:

- The internal SDD skill condensed upstream's `Constructing Reviewer Prompts` guidance
  and dropped the controller-side anti-pre-judge guard, so the controller can still bias
  a reviewer by writing dismissive directives into a dispatch prompt.
- `skills/t-writing-skills/persuasion-principles.md` still names the Claude-specific
  `TodoWrite` primitive, contradicting the harness-neutral goal already established by
  `20260710-skill-authoring-v6`.
- `tests/claude-code/test-document-review-system.sh` still writes and reads
  `docs/superpowers/specs/`, violating the fork's `docsDev/` artifact policy.

Upstream v6.1.1 keeps `spec-document-reviewer-prompt.md` and
`plan-document-reviewer-prompt.md` on disk and uses inline self-review, so those files are
intentionally retained and out of scope here.

## Goals

- Restore the controller-side anti-pre-judge discipline to `t-subagent-driven-development`
  so a reviewer dispatch cannot instruct a reviewer to ignore, downgrade, or not flag a
  finding.
- Make `persuasion-principles.md` name a harness-neutral todo primitive matching the
  upstream supporting file.
- Move the document-review integration test onto the fork's `docsDev/` artifact path.

## Non-Goals

- Do not neutralize `anthropic-best-practices.md`, add SDD model-tier rationale, or expand
  `codex-tools.md` in this change.
- Do not modify `vendor/superpowers/`, package versions, `t-verification-before-completion`,
  or `t-archive`.
- Do not delete `spec-document-reviewer-prompt.md` or `plan-document-reviewer-prompt.md`.
- Do not push, publish, archive, or prepare an upstream PR.

## Global Constraints Source

The following project-wide constraints are the verbatim source for this change's plan:

- The change identifier is `20260710-v6-adoption-followup`.
- The plan artifact path is `docsDev/changes/20260710-v6-adoption-followup/plan.md`.
- Skill references use the `t-superpowers:t-*` namespace.
- The repository and Codex plugin versions remain `5.1.1`.
- Do not modify `vendor/superpowers/`, `skills/t-verification-before-completion/`, or `skills/t-archive/`.
- The stage regression commands are `bash tools/t-stage1-check.sh`, `npm run test:npm-installer`, and `git diff --check`.
- The deterministic skill-test command is `bash tests/claude-code/run-skill-tests.sh`.

## Requirements

### Requirement: Reviewer Dispatch Must Not Pre-Judge Findings

`t-subagent-driven-development` must instruct the controller never to bias a reviewer
dispatch. A dispatch prompt must not tell a reviewer to ignore, downgrade, or not flag a
specific finding. Directives such as `do not flag`, `don't treat X as a defect`,
`at most Minor`, or `the plan chose` are a stop signal: the controller must let the
reviewer raise the finding and adjudicate it in the review loop. This guard must appear in
the dispatch guidance and in the `Red Flags` list.

#### Scenario: Controller is tempted to spare a review loop

- Given the controller is filling the task reviewer template
- And it believes a likely finding is a false positive
- When it writes the reviewer dispatch
- Then it does not add any instruction to ignore, downgrade, or not flag that finding
- And it lets the reviewer report the finding for adjudication in the review loop

### Requirement: Persuasion Guidance Uses a Harness-Neutral Todo Primitive

`skills/t-writing-skills/persuasion-principles.md` must describe checklist tracking with a
generic todo primitive rather than one harness's tool name, consistent with the fork's
harness-neutral skill-authoring contract.

#### Scenario: A skill author reads the commitment guidance

- Given the author reads the commitment and example sections
- When the guidance names checklist tracking
- Then it uses a generic todo tracking term
- And it does not name a single harness's `TodoWrite` tool

### Requirement: Document-Review Test Uses the docsDev Artifact Path

`tests/claude-code/test-document-review-system.sh` must create and review its fixture spec
under the fork's `docsDev/` artifact path, not `docs/superpowers/`.

#### Scenario: The document-review test runs

- Given the integration test provisions a fixture spec
- When it writes and reviews that spec
- Then the fixture path is under `docsDev/`
- And no `docs/superpowers/` path remains in the test

## Validation

- Run `bash tools/t-stage1-check.sh`, `npm run test:npm-installer`, and `bash tests/claude-code/run-skill-tests.sh`.
- Run `bash -n tests/claude-code/test-document-review-system.sh` for syntax.
- Run `git diff --check`.
- Scoped `rg`: confirm no `TodoWrite` in `persuasion-principles.md`, no `docs/superpowers`
  in the document-review test, and the anti-pre-judge wording present in the SDD skill.

## Risks

- The anti-pre-judge guard is behavior-shaping prose; static wording cannot guarantee every
  model complies. This change relies on aligning with the upstream-validated guard plus a
  Red Flag and a deterministic grep rather than multi-model pressure testing.

## Archive Patch

### sdd

Target: docsDev/specs/sdd/spec.md
Action: create

#### ADDED Requirements

##### Requirement: Reviewer Dispatches Preserve Independent Review

Internal subagent-driven development must keep reviewer dispatches unbiased: the controller
may not instruct a reviewer to ignore, downgrade, or not flag a finding, and must let the
reviewer raise findings for adjudication in the review loop.

###### Scenario: The controller drafts a reviewer dispatch

- Given the controller prepares a task or final reviewer dispatch
- When it believes a likely finding is a false positive
- Then it does not embed any instruction to ignore, downgrade, or suppress that finding
- And the reviewer raises the finding for adjudication in the review loop
