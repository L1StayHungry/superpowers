<!-- provenance
agent: /root/guided_strict_fast
assigned source: skills/t-writing-plans/SKILL.md
captured: verbatim second final payload
status: contract-incomplete because Consumes and Produces are empty on their required lines and nested below
-->

# Implementation Plan

## Global Constraints

- Runtime must be Node.js 22.17.0 exactly.
- The public route is /v2/widgets/{widgetId}.
- The client timeout is 2,750ms.
- No new runtime dependency is allowed.
- Supported platforms are macOS 15 and Windows 11.

## Task 1: Implement the widget vertical slice

Cover the database lookup, API route and DTO mapping, UI data loading and rendering, timeout/config wiring, and public documentation in one end-to-end change.

**Interfaces:**

- Consumes:
  - WidgetId
  - Existing database client
  - AbortSignal

- Produces:
  - loadWidget(id: WidgetId): Promise<WidgetRecord | null>
  - getWidget(id: WidgetId): Promise<WidgetDto | NotFound>
  - fetchWidget(id: WidgetId, signal: AbortSignal): Promise<WidgetView>

Validate database hit/miss behavior, route responses, UI success/not-found/timeout states, exact runtime and timeout configuration, supported-platform behavior, and documentation accuracy.
