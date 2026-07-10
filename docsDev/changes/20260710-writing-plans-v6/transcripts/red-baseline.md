# Writing Plans v6 RED Baseline

## Baseline 1: missing planning contracts

- Time: 2026-07-10T06:14:00Z
- Command: `tests/claude-code/test-writing-plans-contract.sh`
- Exit code: `1`
- Key output: `FAIL: .../skills/t-writing-plans/SKILL.md is missing required contract: ## Global Constraints`
- Conclusion: the pre-v6 local skill had no global-constraint contract; execution stopped at the first missing requirement before reaching Interfaces and right-sizing assertions.

## Baseline 2: implementation artifact contract

- Time: 2026-07-10T06:17:00Z
- Command: `tests/claude-code/test-writing-plans-contract.sh`
- Exit code: `1`
- Key output: `FAIL: missing change spec: .../docsDev/changes/20260710-writing-plans-v6/spec.md`
- Conclusion: after the minimal skill wording was present, the contract correctly required a local spec and generated plan example under the approved change path.

## Baseline 3: discoverable test entrypoint

- Time: 2026-07-10T06:18:00Z
- Command: `tests/claude-code/test-writing-plans-contract.sh`
- Exit code: `1`
- Key output: `FAIL: package.json must expose test:writing-plans-contract`
- Conclusion: the standalone test existed but had no shared discovery entrypoint. A root npm script was tested first, then rejected after the mandatory stage-one gate proved that `package.json` is intentionally excluded from internal-fork migrations.

## Baseline 4: preserve the stage-one package boundary

- Time: 2026-07-10T06:23:00Z
- Command: `bash tools/t-stage1-check.sh`
- Exit code: `1`
- Key output: `FAIL: excluded entry/instruction files have uncommitted changes`
- Conclusion: adding a root npm script violated the existing package-identity boundary. The package edit was removed; the focused test was instead registered in the existing `tests/claude-code/run-skill-tests.sh` fast-test list and documented in its README.

## Baseline 5: runner discovery

- Time: 2026-07-10T06:25:00Z
- Command: `bash tests/claude-code/test-writing-plans-contract.sh`
- Exit code: `1`
- Key output: `FAIL: .../tests/claude-code/run-skill-tests.sh is missing required contract: "test-writing-plans-contract.sh"`
- Conclusion: the replacement discovery contract was observed failing before adding the test to the existing fast-test runner.

## Baseline 6: archive-stable behavior fixture

- Time: 2026-07-10T06:32:00Z
- Command: `bash tests/claude-code/test-writing-plans-contract.sh`
- Exit code: `1`
- Key output: `FAIL: missing change spec: .../tests/claude-code/fixtures/writing-plans-contract/spec.md`
- Conclusion: after removing the hard-coded active change path, the focused test correctly failed until the stable approved-spec and generated-plan fixtures existed.

## Behavior RED

- Scenario: same combined deadline, product-authority, senior-authority, legacy-guidance, and team-convention pressure used for the current-skill comparison.
- Control source: `git show a4731d0^:skills/t-writing-plans/SKILL.md`.
- Independent score: `2/6` — Global Constraints `1`, Interfaces `1`, Task Right-Sizing `0`.
- Key failure: the candidate mechanically split DB/API/UI/config-docs into four tasks even though only their combined vertical delivery had independent user value.
- Full evidence: `behavior-pressure.md`, `behavior-control-output.md`.

## Boundary-direction RED

- Time: 2026-07-10T06:55:00Z
- Command: `bash tests/claude-code/test-writing-plans-contract.sh`
- Exit code: `1`
- Key output: `FAIL: missing split-boundary fixture: .../tests/claude-code/fixtures/writing-plans-contract/split-plan.md`
- Conclusion: the previous structural suite proved only when related edits must merge; it had no stable counterexample for unrelated behaviors sharing a file and no specific N/A fixture.
- Behavior correction: the old strict raw's empty same-line Consumes/Produces values score Interfaces `1`, not `2`; only the new exact raw reaches `6/6`.
