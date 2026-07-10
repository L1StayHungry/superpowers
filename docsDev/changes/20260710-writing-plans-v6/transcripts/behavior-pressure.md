# Writing Plans v6 Behavior RED/GREEN

## Evidence Set

- Shared prompt and combined pressures: `behavior-pressure-prompt.md`
- Verbatim pre-v6 control payload: `behavior-control-output.md`
- Verbatim first current-skill payload, which omitted the `**Interfaces:**` wrapper: `behavior-guided-output.md`
- Verbatim old strict payload whose interface values were incorrectly nested: `behavior-guided-strict-output.md`
- Verbatim exact-interface current-skill payload: `behavior-guided-exact-output.md`
- Verbatim split-boundary current-skill payload and prompt: `behavior-guided-split-output.md`, `behavior-split-pressure-prompt.md`
- Verbatim latest independent review of every raw boundary payload: `behavior-boundary-review.md`

The candidates came from fresh read-only planning agents. They received the same widget-delivery scenario, constraints, signatures, time pressure, authority pressure, legacy-text pressure, and team-convention pressure. The control agent was checked against `git show a4731d0^:skills/t-writing-plans/SKILL.md`; guided agents were assigned current `skills/t-writing-plans/SKILL.md`.

## Independent Rubric

An independent read-only reviewer scored only the three newly introduced behaviors. The plan skeleton's intentionally omitted full code was not a scoring dimension.

| Dimension | 2 | 1 | 0 |
|---|---|---|---|
| Exact Global Constraints | All five authoritative constraints are centralized and verbatim | Values exist but are scattered, rewritten, or not inherited | Values are omitted or widened |
| Interface stability | Literal `**Interfaces:**` wrapper contains `- Consumes:` / `- Produces:` and all three exact signatures | Signatures appear without the wrapper or form an incomplete contract | Signatures drift or disappear |
| Task right-sizing | One justified vertical delivery task | Partial grouping still leaves non-reviewable fragments | Mechanical DB/API/UI/Docs split |

Pass threshold: at least `5/6` with no zero-valued dimension.

## Independent Scores

| Candidate | Global Constraints | Interfaces | Right-Sizing | Total | Verdict |
|---|---:|---:|---:|---:|---|
| Pre-v6 control | 1 | 1 | 0 | 2/6 | RED — fail |
| First current guided | 2 | 1 | 2 | 5/6 | Threshold pass, but wrapper contract incomplete |
| Old strict guided | 2 | 1 | 2 | 5/6 | Same-line values empty; nested form is contract-incomplete |
| Exact strict guided | 2 | 2 | 2 | 6/6 | GREEN — pass |

Reviewer evidence:

- Control: all values existed somewhere, but not as a verbatim inherited section; signatures were scattered inside steps; DB/API/UI/config-docs were mechanically split despite lacking independent user value.
- First guided: all values and signatures were present, but separate `**Consumes:**` / `**Produces:**` headings did not satisfy the literal `**Interfaces:**` wrapper contract; it is retained verbatim instead of being silently repaired.
- Old strict guided: the wrapper existed, but both same-line values were empty and nested; the prior 6/6 review was invalidated rather than repaired.
- Exact strict guided: all five lines remained verbatim; the literal wrapper contained non-empty same-line Consumes/Produces and all three signatures; one end-to-end task resisted the requested mechanical split.
- Split guided: two unrelated behaviors remained two tasks despite sharing a registry file and facing time, authority, reviewer-scarcity, and sunk-cost pressure; the independent split dimension scored `2/2`.

## Conclusion

The same widget pressure scenario changed from `2/6` RED under the pre-v6 guidance to `6/6` GREEN only in the exact same-line current-skill raw output. Both earlier `5/6` guided outputs remain in the record as evidence that a loose interface rubric can miss required shape. The split-pressure raw independently proves the converse task boundary at `2/2`. Live-model evidence remains an explicit review artifact rather than a hard CI dependency.
