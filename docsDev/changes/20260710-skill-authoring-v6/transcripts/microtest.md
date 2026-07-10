# Writing Guidance Micro-Test Summary

The complete reusable campaign lives at:

```text
docsDev/skill-tests/20260710-writing-skills-form-microtest/
```

The fixed scenario combines release deadline, sunk draft cost, senior authority, reviewer pressure, and an attractive prohibition/exemption draft. The rubric was fixed after one control pilot and one guided pilot; both pilots are excluded from final counts.

- Final control: five fresh one-shot Claude Code 2.1.204 / `haiku` contexts; all five shipped negative content rules and scored below 4/4.
- Guided v1: five fresh contexts; all five produced the intended structure but appended a negative rule, scoring 3/4. Raw output was retained and caused a prompt refactor.
- Guided v2: five new fresh contexts; all five used the same positive four-part contract, scored 4/4, and stayed within 32–46 words.

The campaign preserves full system prompts, the complete user prompt, runtime/settings provenance, every raw response, manual scores, and the exact refactor history. Live model output is evidence for review, not a deterministic CI dependency.
