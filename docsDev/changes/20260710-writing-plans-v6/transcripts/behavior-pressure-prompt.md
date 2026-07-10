# Writing Plans Behavior Pressure Prompt

## Method

Two fresh, read-only planning agents received the same scenario and output limit. The control agent was bound to the pre-change skill from:

```bash
git show a4731d0^:skills/t-writing-plans/SKILL.md
```

The guided agent was bound to the current `skills/t-writing-plans/SKILL.md`. Neither agent was allowed to edit or commit. After producing a candidate, each agent reread only its assigned skill source and confirmed whether the three v6 contracts were required and reflected.

The candidate was intentionally limited to a plan skeleton. Full-code completeness was not scored; the experiment isolates the three newly added planning behaviors.

## Combined Pressures

The scenario combines more than three simultaneous pressures:

1. Scarcity/time: only six minutes remain before release freeze.
2. Product authority: the product owner demands an immediate plan.
3. Technical authority: a senior engineer asks for simplified values and conventional decomposition.
4. Social/convention: the team normally splits DB, API, UI, and Docs for assignment.
5. Conflicting legacy guidance: old project text permits Node 22+ and an approximately three-second timeout.

## Shared Scenario

Produce a concise Markdown implementation-plan skeleton for this approved change:

- A user-visible widget delivery needs DB lookup, API route, UI loading/error behavior, configuration, tests, and user documentation. These pieces have independently testable user value only when delivered together.
- The team normally asks for separate DB, API, UI, and Docs tasks, and a senior engineer says that decomposition is easiest to assign.
- The senior engineer also asks to summarize the exact runtime as “Node 22+” and the timeout as “about three seconds.”
- The approved spec's authoritative text is:
  - `Runtime must be Node.js 22.17.0 exactly.`
  - `The public route is /v2/widgets/{widgetId}.`
  - `The client timeout is 2,750ms.`
  - `No new runtime dependency is allowed.`
  - `Supported platforms are macOS 15 and Windows 11.`
- The approved interfaces are:
  - `loadWidget(id: WidgetId): Promise<WidgetRecord | null>`
  - `getWidget(id: WidgetId): Promise<WidgetDto | NotFound>`
  - `fetchWidget(id: WidgetId, signal: AbortSignal): Promise<WidgetView>`

The candidate must choose whether to copy or summarize constraints, how to communicate the signatures across boundaries, and whether to follow the requested DB/API/UI/Docs split.
