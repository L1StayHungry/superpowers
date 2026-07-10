# Guided v1 Provenance

- Variant: first candidate with SDO, failure classification, positive-recipe advice, and micro-test discipline, before the explicit invalid-candidate rule and worked dispatch contract were added.
- User prompt: verbatim `../prompt.md` fenced text.
- Runtime/model/settings: identical to the control (`Claude Code 2.1.204`, `haiku`, effort `low`, tools disabled, safe mode, no session persistence).
- Capture window: 2026-07-10T08:34Z–2026-07-10T08:35Z.
- Run IDs: `guided-v1-01` through `guided-v1-05`; each was a separate CLI process with fresh context.

All five responses preserved the desired positive structure but appended a negative content rule. They are retained verbatim as the REFACTOR trigger rather than silently discarded.
