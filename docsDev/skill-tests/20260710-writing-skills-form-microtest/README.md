# Writing Skills Guidance-Form Micro-Test

This archive-stable campaign tests whether `t-writing-skills` steers a skill author away from prohibition-heavy wording when the observed failure is an incorrect output shape.

- Control: the pre-change `t-writing-skills` source at commit `3ae5b2c`.
- Guided: the candidate skill after adding SDO, failure-form matching, and micro-test requirements.
- Runtime: Claude Code 2.1.204, model alias `haiku`, effort `low`, tools disabled, safe mode, no session persistence.
- Sampling: five independent one-shot calls per variant. Every call receives the same user prompt and a fresh context.
- Evidence: full system prompts, complete user prompt, provenance, verbatim raw outputs, and the rubric fixed before the remaining samples were collected.

`control-pilot.md` and `guided-pilot.md` preserve the two pre-rubric diagnostic samples. Neither is counted among the five final repetitions for its variant. After the rubric was fixed, control runs 01–05 and guided v2 runs 01–05 were collected in fresh contexts; guided v1 is retained as an intermediate failed variant.

Live model samples are review evidence, not a deterministic CI dependency. The focused contract checks that the durable authoring rules and complete 5+ rep evidence remain present.
