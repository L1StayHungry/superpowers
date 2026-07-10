# Guided v2 Provenance

- Variant: final candidate after the v1 failure added an explicit invalid-candidate criterion and a pure positive dispatch-contract example.
- System prompt: verbatim `system-prompt.md`, the final pre-commit `skills/t-writing-skills/SKILL.md` candidate.
- System prompt SHA-256: `f1b95753ce8e9b19ee84535c2eaa6929f2097df576943a14c65c3d8d5979222d`.
- User prompt: verbatim `../prompt.md` fenced text.
- Runtime/model: Claude Code `2.1.204`; model alias `haiku`; effort `low`.
- Sampling/tool state: one-shot `--safe-mode`; `--tools ""`; text output; no session persistence. No temperature flag is exposed by this harness.
- Invocation shape: `claude --safe-mode -p "$PROMPT" --tools "" --model haiku --effort low --output-format text --no-session-persistence --system-prompt "$SYSTEM"`.
- Capture window: 2026-07-10T08:35Z–2026-07-10T08:36Z, after `rubric.md` was fixed.
- Run IDs: `guided-v2-01` through `guided-v2-05`; each was a separate CLI process with fresh context.

Each `run-*.md` is the complete stdout payload, preserved verbatim before manual scoring.
