# Writing Plans v6 Verification

## Focused GREEN

- Time: 2026-07-10T06:26:02Z
- Command: `bash tests/claude-code/test-writing-plans-contract.sh`
- Exit code: `0`
- Key output: historical static-contract PASS; its obsolete executable-validity wording is superseded by the structural-only result below.
- Coverage: historical static contract run, superseded by stable fixture-scoped coverage below.

- Time: 2026-07-10T06:26:02Z
- Command: `tests/claude-code/run-skill-tests.sh --test test-writing-plans-contract.sh --timeout 5`
- Exit code: `0`
- Key output: `Passed: 1`, `Failed: 0`, `STATUS: PASSED`
- Coverage: the contract is discoverable through the existing skill-test runner and finishes inside its five-second limit.

## Contract-test hang root cause and fix

- Symptom: two early focused runs left Python 3.14 processes consuming CPU after the command failed to return.
- Root cause: the first spec-to-plan comparison used a full-file DOTALL expression combining lazy `.*?` with a repeated line group; on a mismatch, Python 3.14 explored a pathological backtracking space. The same draft also used a zero-width lookahead split for task blocks.
- Fix: terminate the two test process trees, replace both constructs with `splitlines()`, exact section delimiters, line indexes, and linear task slices.
- Proof command: a Python `subprocess.run(..., timeout=5)` wrapper around `bash tests/claude-code/test-writing-plans-contract.sh`.
- Proof result: exit `0` in `0.126s`, with no matching test or child Python PID left behind.

## Regression GREEN

- Time: 2026-07-10T06:26:08Z
- Command: `bash -n tests/claude-code/test-writing-plans-contract.sh tests/claude-code/run-skill-tests.sh`
- Exit code: `0`
- Key output: no syntax errors.

- Time: 2026-07-10T06:26:08Z
- Command: `bash tools/t-stage1-check.sh`
- Exit code: `0`
- Key output: `OK: Stage 1 migration self-check passed`

- Time: 2026-07-10T06:26:08Z
- Command: `git diff --check`
- Exit code: `0`
- Key output: no whitespace errors.

- Time: 2026-07-10T06:26:08Z
- Command: `git diff --exit-code -- vendor/superpowers skills/t-verification-before-completion skills/t-archive`
- Exit code: `0`
- Key output: no protected-path diff.

- Time: 2026-07-10T06:26:21Z
- Command: `npm run test:npm-installer`
- Exit code: `0`
- Key output: `tests 67`, `pass 67`, `fail 0`.

## Conclusion

The focused contract and mandatory shared regressions are green with fresh evidence. This stage changes only `t-writing-plans`, its deterministic test/discovery documentation, and its local change artifacts; it does not change versions, vendor source, verification behavior, archive behavior, or package metadata.

## Review Hardening GREEN

- Time: 2026-07-10T06:38:57Z
- Command: `bash tests/claude-code/test-writing-plans-contract.sh`
- Exit code: `0`
- Key output: historical archive-stable fixture PASS; its obsolete executable-validity wording is superseded by the final structural-only result below.
- Coverage: the behavior sample now comes only from `tests/claude-code/fixtures/writing-plans-contract/`; it contains exact constraints, explicit task interfaces, and one integrated DB/API/UI/config/docs task, with no dependency on an active change directory.

- Time: 2026-07-10T06:38:57Z
- Command: `tests/claude-code/run-skill-tests.sh --test test-writing-plans-contract.sh --timeout 5`
- Exit code: `0`
- Key output: `Passed: 1`, `Failed: 0`, `STATUS: PASSED`.

- Time: 2026-07-10T06:38:57Z
- Command: `bash -n tests/claude-code/test-writing-plans-contract.sh tests/claude-code/run-skill-tests.sh && bash tools/t-stage1-check.sh && git diff --check && git diff --exit-code -- vendor/superpowers skills/t-verification-before-completion skills/t-archive package.json`
- Exit code: `0`
- Key output: `OK: Stage 1 migration self-check passed`; no syntax, whitespace, protected-path, or package diff.

- Time: 2026-07-10T06:39:03Z
- Command: `npm run test:npm-installer`
- Exit code: `0`
- Key output: `tests 67`, `pass 67`, `fail 0`.

### Behavior GREEN

- Fresh current-skill agents received the same combined pressure and authoritative values as the pre-v6 control.
- All collaboration final payloads are preserved verbatim after HTML-comment provenance; they are not compacted, rewritten, or wrapped in an outer code fence.
- The first guided raw scored `5/6`: it kept exact values and right-sizing, but lacked the literal `**Interfaces:**` wrapper. It remains in the evidence instead of being silently repaired.
- The old strict raw also scored `5/6`: it had the wrapper, but its required Consumes/Produces lines were empty and delegated values to nested lists. Its earlier `6/6` review is explicitly superseded.
- The new exact-interface raw scored `6/6` against the raw control's `2/6`: Global Constraints `2`, Interfaces `2`, Task Right-Sizing `2`.
- The exact raw kept all five authoritative lines verbatim, put non-empty contracts and all three signatures on the required lines, and retained one end-to-end task despite the requested mechanical split.
- The independent split-pressure raw scored `2/2`: two unrelated behaviors stayed in two tasks despite sharing a registry file and facing authority, deadline, reviewer-scarcity, and sunk-cost pressure.
- Full prompt, raw candidates, raw independent review, rubric, and score are recorded in `behavior-pressure.md` and its referenced transcripts.
- Live model output is evidence for review, not a deterministic CI dependency.

## Verbatim Evidence Final Verification

- Time: 2026-07-10T06:51:11Z
- Focused output: superseded structural-only PASS; the expanded boundary/N/A result is recorded below.
- Fast runner: `1` passed, `0` failed under `--timeout 5`.
- Stage one: `OK: Stage 1 migration self-check passed`.
- Installer: `67` passed, `0` failed.
- `bash -n`, `git diff --check`, and protected-path/package diff checks exited `0`.
- Raw rubric: control `2/6` RED; exact guided `6/6` GREEN; split boundary `2/2` GREEN.

## Both Boundary Directions Final Verification

- Time: 2026-07-10T07:00:12Z
- Focused output: `PASS: writing-plans structural fixtures cover constraints, exact interfaces, both task-boundary directions, and specific N/A reasons; executable-plan validity is not claimed`.
- Fast runner: `1` passed, `0` failed under `--timeout 5`.
- Stage one: `OK: Stage 1 migration self-check passed`.
- Installer: `67` passed, `0` failed.
- `bash -n`, `git diff --check`, and protected-path/package diff checks exited `0`.
- Raw review: control A/B/C=`1/1/0`; old strict=`2/1/2`; new exact=`2/2/2`; split D=`2`.
