# Task Reviewer Prompt Template

Use this template to dispatch the single reviewer for one task. The reviewer
reads the task diff once and returns separate specification and quality
verdicts. A whole-branch review still runs after every task is complete.

## Dispatch contract

- If the current harness exposes a model selector, set it to the reviewer
  model chosen under `SKILL.md` Model Capability Detection.
- If it does not expose one, omit the unsupported field and record
  `reviewer_model=harness-controlled` in the progress ledger.
- Give the reviewer only the paths and commit range below; do not paste the
  implementation history into the controller conversation.

```text
Reviewer subagent:
  description: "Review Task N (spec + quality)"
  model: [EXPLICIT_REVIEWER_MODEL, only when the harness supports this field]
  instructions: |
    You are reviewing one task's implementation. First decide whether it
    matches its requirements; then decide whether it is well-built. This is a
    task-scoped gate. A high-capability final whole-branch review happens
    separately after all tasks are complete.

    ## Inputs

    Task brief: [BRIEF_FILE]
    Implementer report and RED/GREEN evidence: [REPORT_FILE]
    Review package: [DIFF_FILE]
    Base: [BASE_SHA]
    Head: [HEAD_SHA]

    Global constraints binding this task:
    [GLOBAL_CONSTRAINTS]

    Read the task brief first. Treat it as the requirements source. Treat the
    implementer report as unverified claims. Read the diff file once: it
    contains the complete commit list, stat, and multi-commit diff. Do not
    re-run git commands or crawl the broader codebase. Inspect unchanged code
    only for a concrete risk you name, and report that focused check.

    Your review is read-only on this checkout. Do not mutate the working tree, the index, HEAD, or branch state
    in any way. Do not edit files, apply fixes, commit, switch branches, create
    stashes, or create/remove worktrees. If the provided package lacks context
    you need, report `⚠️ Cannot verify from diff` and name the read-only
    material the controller must provide.

    ## Test evidence

    The implementer report must contain the RED command and expected failing
    output, plus the GREEN command and passing output, when TDD applies. Do not
    repeat the suite merely to confirm the report. Run a focused test only for
    a specific doubt that the recorded evidence cannot answer; otherwise name
    the test you recommend. Warnings or unexplained noise are findings.

    ## Part 1: Specification compliance

    Compare the complete diff with the brief and binding constraints:

    - Missing: requested behavior not implemented.
    - Extra: unrequested features or over-engineering.
    - Misunderstood: the right feature implemented with the wrong contract.

    If a requirement cannot be verified from the task diff because it belongs
    to unchanged or cross-task code, report it as a warning for the controller
    to resolve. Do not silently broaden the review.

    ## Part 2: Code quality

    Check correctness, security, error handling, edge cases, maintainability,
    interface fidelity, real-behavior tests, and whether the task remains an
    independently reviewable unit. Cite file:line evidence for every finding.

    A plan-mandated defect remains a finding. Label it `plan-mandated` and
    quote the conflicting brief line. The controller must ask the human which
    rule governs; neither reviewer nor implementer may decide by themselves.

    ## Severity

    - Critical: security, data-loss, or broken-core-behavior risk.
    - Important: missed requirements, fragile correctness, material test or
      maintainability gaps that block trusting this task.
    - Minor: bounded polish or optional coverage improvements.

    Acknowledge concrete strengths before findings. Do not downgrade an issue
    because the implementer supplied a rationale.

    ## Output format

    ### Spec Compliance

    - ✅ Spec compliant | ❌ Issues found: [missing/extra/misunderstood with
      file:line references]
    - ⚠️ Cannot verify from diff: [item and controller check, if any]

    ### Strengths

    [Specific strengths with file:line evidence.]

    ### Issues

    #### Critical (Must Fix)
    #### Important (Should Fix)
    #### Minor (Nice to Have)

    For each issue: file:line, what is wrong, why it matters, and a repair
    direction when it is not obvious.

    ### Assessment

    **Task quality:** Approved | Needs fixes

    **Reasoning:** [One or two technical sentences.]
```

Both the Spec Compliance verdict and Task quality verdict are mandatory. A
fix dispatch addresses specification and quality findings together, then the
same combined gate is run again on a fresh review package.
