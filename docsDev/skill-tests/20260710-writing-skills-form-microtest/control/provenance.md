# Control Provenance

- Variant: no new failure-form or micro-test guidance.
- System prompt: verbatim `system-prompt.md` from `skills/t-writing-skills/SKILL.md` at commit `3ae5b2ca064496d5274e523f5c1ddba1b3ecbc33`.
- System prompt SHA-256: `07c59a03a1ab3aa80d3b1017139c9d292db3959c64f2380635bdd99be5e3bb6b`.
- User prompt: verbatim `../prompt.md` fenced text.
- Runtime/model: Claude Code `2.1.204`; model alias `haiku`; effort `low`.
- Sampling/tool state: one-shot `--safe-mode`; `--tools ""`; text output; no session persistence. No temperature flag is exposed by this harness.
- Invocation shape: `claude --safe-mode -p "$PROMPT" --tools "" --model haiku --effort low --output-format text --no-session-persistence --system-prompt "$SYSTEM"`.
- Capture window: 2026-07-10T08:32Z–2026-07-10T08:39Z, after `rubric.md` was fixed; the earlier diagnostic response is stored separately as `../control-pilot.md`.
- Run IDs: `control-01` through `control-05`; each was a separate CLI process with fresh context.

Each `run-*.md` is the complete stdout payload, preserved verbatim before manual scoring.
