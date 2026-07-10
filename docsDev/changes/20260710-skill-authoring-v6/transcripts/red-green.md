# Skill Authoring v6 RED/GREEN Evidence

## `t-writing-skills`

- RED command: `bash tests/skill-authoring/test-writing-skills-contract.sh`
- RED exit: `1`
- First failure: missing `## Skill Discovery Optimization (SDO)`.
- Intermediate RED: after the prompt contract was added, the test failed because the stable micro-test campaign did not exist.
- GREEN: focused contract passes with SDO, failure-form matching, portable links, exact 5+ repetition evidence, pilots excluded from final sampling, and manually scored raw output.

## `t-dispatching-parallel-agents`

- RED exit: `1` — missing same-response parallel dispatch guidance.
- GREEN: generic subagent examples are dispatched in the same response; harness-specific `Task(...)` is absent.

## `t-executing-plans`

- RED exit: `1` — missing harness-neutral todo-list instruction.
- GREEN: todo tracking and subagent use are selected by capability; branch and finishing gates remain.

## `t-receiving-code-review`

- RED exit: `1` — the skill still named `CLAUDE.md`.
- GREEN: instructions-file, direct tension reporting, and forge-neutral thread replies replace harness/provider-specific wording.

## `t-systematic-debugging`

- RED exit: `1` — missing delimiter-safe `Ultra-think` signal.
- GREEN: token corrected; complex-only description and internal TDD/verification references remain.

## `t-test-driven-development`

- RED exit: `1` — missing portable `[testing-anti-patterns.md](testing-anti-patterns.md)` link.
- GREEN: portable link present; force-load syntax absent; complex-only description and RED iron law remain.

## Documentation

- RED exit: `1` — getting-started lacked `## Selectively Adopted From Upstream v6.1.1`.
- GREEN: getting-started, installer guide, and Changelog Unreleased describe the selective sync and only supported internal targets.
