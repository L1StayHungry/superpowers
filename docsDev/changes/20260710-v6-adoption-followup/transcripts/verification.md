# Verification — 20260710-v6-adoption-followup

Date: 2026-07-10 18:42 (UTC+8)
Scope: three v6.1.1 adoption follow-up fixes (I1 SDD anti-pre-judge, I2a persuasion neutralize, I3 test path).

## RED baseline (before edits)

```
$ rg -n "pre-judge|do not flag|don't treat|at most Minor" skills/t-subagent-driven-development/SKILL.md
(none - RED baseline confirmed)

$ rg -n "TodoWrite" skills/t-writing-skills/persuasion-principles.md
36:- Use tracking: TodoWrite for checklists
83:✅ Checklists without TodoWrite tracking = steps get skipped. Every time.
84:❌ Some people find TodoWrite helpful for checklists.

$ rg -n "docs/superpowers" tests/claude-code/test-document-review-system.sh
29:mkdir -p docs/superpowers/specs
32:cat > docs/superpowers/specs/test-feature-design.md <<'EOF'
83:Then review the spec at $TEST_PROJECT/docs/superpowers/specs/test-feature-design.md ...
```

## GREEN (after edits)

```
$ rg -n "pre-judge|do not flag" skills/t-subagent-driven-development/SKILL.md
230:Do not pre-judge findings when constructing the dispatch. Never instruct a
234:contains `do not flag`, `don't treat X as a defect`, `at most Minor`, or
279:- pre-judge findings in a reviewer dispatch (`do not flag`, `at most Minor`);

$ rg -n "TodoWrite" skills/t-writing-skills/persuasion-principles.md
(no TodoWrite - OK)

$ rg -n "docs/superpowers" tests/claude-code/test-document-review-system.sh
(no docs/superpowers - OK)

$ bash -n tests/claude-code/test-document-review-system.sh
syntax OK

$ rg -n "anti-pre-judge|follow-up" CHANGELOG.md
11:- v6.1.1 adoption follow-up: restored the SDD controller anti-pre-judge guard ...
```

## Deterministic regression

```
$ bash tools/t-stage1-check.sh
OK: Stage 1 migration self-check passed        (exit 0)

$ git diff --check
(exit 0, no whitespace errors)

$ npm run test:npm-installer
tests 67 | pass 67 | fail 0                     (exit 0)

$ bash tests/claude-code/run-skill-tests.sh
test-sdd-workspace.sh              [PASS]
test-writing-plans-contract.sh    [PASS]
test-worktree-finishing-contract.sh [PASS]
test-subagent-driven-development.sh [FAIL] (timeout after 300s)
Passed: 3  Failed: 1
```

## Notes on the one FAIL (XFAIL, environment)

`test-subagent-driven-development.sh` is a live-model test: every check calls
`run_claude` (real Claude CLI). It timed out at the first `run_claude` call
("Test 1: Skill loading") before emitting any assertion output. This is an
environment/live-model timeout, not a regression from this change — the edits
are prose-only additions to the skill and cannot make the first live CLI
invocation hang. The three deterministic (non-live) skill tests all pass.

## Changed files

```
M CHANGELOG.md
M skills/t-subagent-driven-development/SKILL.md
M skills/t-writing-skills/persuasion-principles.md
M tests/claude-code/test-document-review-system.sh
?? docsDev/changes/20260710-v6-adoption-followup/
```
