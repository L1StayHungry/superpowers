---
name: t-using-superpowers
description: Use when the user explicitly requests t-superpowers or a t-* workflow, or when development work is clearly complex; do not use to force heavyweight workflows onto simple edits, Q&A, or code reading
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, skip this skill.
</SUBAGENT-STOP>

<COMPLEX-WORK-GATE>
For a clearly complex multi-file feature or user-visible behavior change, the first action MUST be invoking `t-brainstorming`. Do not ask questions, inspect files, or use any other tool before loading that skill.
</COMPLEX-WORK-GATE>

<TRIGGER-BOUNDARY>
Use `t-*` skills when the user explicitly requests `t-superpowers`/a named `t-*` workflow, or the work is clearly complex.

Enter the relevant workflow for:
- explicit `t-*` requests;
- complex multi-file features or user-visible behavior changes: as the first action, **MUST** invoke `t-brainstorming` before asking questions, reading/searching files, or implementing;
- root-cause-unknown bugs: invoke `t-systematic-debugging` before proposing fixes;
- high-risk changes or written multi-step plans: use the relevant planning and execution skills.

Keep the default agent flow for:
- copy, style, config, spelling, formatting, or mechanical edits;
- Q&A, explanations, code reading, or read-only investigation;
- low-risk direct implementation requests.

When complexity is genuinely ambiguous, ask one concise boundary question or proceed in direct mode while stating the assumption. Skill existence alone is not a trigger.
</TRIGGER-BOUNDARY>

## Instruction Priority

User instructions always take precedence:

1. Explicit user and repository instructions (`AGENTS.md`, direct requests)
2. Applicable `t-*` skills
3. Harness defaults

Use the smallest process that fits the request. Invoke requested or relevant `t-*` skills before implementation and follow their current contents rather than memory.

Codex-specific tool adaptation is documented in `references/codex-tools.md`; consult it only when a selected skill names tools or multi-agent operations that need mapping.

## Skill Priority

When several skills apply:

1. Process skills determine the approach: brainstorming, systematic debugging.
2. Planning skills turn an approved direction into executable steps.
3. Execution skills guide delivery: TDD, subagent execution, review, finishing.

Do not add `t-archive` to an automatic chain; it requires an explicit archive request with a change-id.

## Red Flags

Stop and re-check the boundary when thinking:

| Thought | Reality |
|---------|---------|
| "This is simple, but a skill exists" | Skill existence alone is not enough. Use direct mode for clearly simple requests. |
| "The task is complex, but planning is optional" | Use the relevant process and planning skills before implementation. |
| "I'll inspect the complex task first" | `t-brainstorming` is the first action; exploration comes after the skill is loaded. |
| "I remember the skill" | Skills evolve; use the current instructions. |
| "The bug seems obvious" | If the root cause is unproven, use `t-systematic-debugging`. |
| "I'll enter brainstorming just in case" | Ambiguity is not permission to force a heavyweight workflow. |
| "Verification passed, so archive next" | Only an explicit archive request may trigger `t-archive`. |
