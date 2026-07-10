# Bootstrap Skill Static Behavior Review — 2026-07-10

An independent read-only reviewer compared `git show HEAD:skills/t-using-superpowers/SKILL.md` with the working version and exercised three routing scenarios against the written rules.

## Result

`PASS` — no blocking finding and no reviewer file changes.

- Simple README copy or single-file config work remains in the default agent flow.
- Explicit `t-superpowers` / `t-test-driven-development` requests enter the named workflow.
- A high-risk multi-file authentication behavior change enters the relevant complex process and execution skills.
- `SUBAGENT-STOP`, user/repository instruction priority, Skill Priority, Red Flags, the Codex reference pointer, and the explicit `t-archive` boundary remain present.
- The runtime skill and Codex reference contain no 1% forcing rule, Graphviz, Copilot/Gemini access tutorial, or `close_agent` claim.

The reviewer initially measured the bootstrap at 387 words versus 886 words in the old revision. Quality-review hardening later raised it to 480 words by making the complex-work first-action gate explicit; it remains below the deterministic 500-word gate. It is above the authoring guide's aspirational 200-word target for frequently loaded skills; preserving the fork-specific trigger, priority, archive, and subagent gates was treated as the higher-priority constraint.

## Limitation

This was a static behavior review. The later live test in `live-bootstrap.md` supersedes any implication that static PASS proves model compliance: simple and explicit Claude cases passed, while the implicit complex case remains XFAIL.
