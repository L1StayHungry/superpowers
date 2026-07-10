<!-- provenance
agent: /root/writing_plans_v6/guided_fast
assigned source: skills/t-writing-plans/SKILL.md
captured: verbatim final payload
status: contract-incomplete because the literal Interfaces wrapper is absent
-->

# Implementation Plan

## Global Constraints

- `Runtime must be Node.js 22.17.0 exactly.`
- `The public route is /v2/widgets/{widgetId}.`
- `The client timeout is 2,750ms.`
- `No new runtime dependency is allowed.`
- `Supported platforms are macOS 15 and Windows 11.`

## Task 1: Deliver widget loading end to end

**Delivery boundary:** DB、API、UI、config、docs 必须合并交付；任一部分单独完成均不构成可独立验收的用户价值。

**Consumes:**

- Route parameter: `widgetId`
- Domain type: `WidgetId`
- Repository result: `WidgetRecord | null`
- API result: `WidgetDto | NotFound`
- UI cancellation input: `AbortSignal`
- Runtime configuration: Node.js `22.17.0`
- Client timeout configuration: `2,750ms`

**Produces:**

- DB boundary: `loadWidget(id: WidgetId): Promise<WidgetRecord | null>`
- API boundary: `getWidget(id: WidgetId): Promise<WidgetDto | NotFound>`
- Public endpoint: `/v2/widgets/{widgetId}`
- UI boundary: `fetchWidget(id: WidgetId, signal: AbortSignal): Promise<WidgetView>`
- Config enforcing Node.js `22.17.0` and timeout `2,750ms`
- Documentation covering endpoint, not-found behavior, cancellation, runtime, timeout, supported platforms, and dependency constraint
- End-to-end tests covering found, not found, timeout, and cancellation paths on macOS 15 and Windows 11

**Implementation:**

1. Add the repository lookup and its found/not-found tests.
2. Add DTO mapping and API handling for `WidgetDto | NotFound`.
3. Expose `GET /v2/widgets/{widgetId}`.
4. Add the client fetch flow with `AbortSignal` and an exact `2,750ms` timeout.
5. Pin runtime configuration to Node.js `22.17.0` without adding runtime dependencies.
6. Update user-facing and operational documentation.
7. Verify the merged DB/API/UI/config/docs flow on macOS 15 and Windows 11.

**Review/acceptance:**

- Review and test this task as one atomic end-to-end change.
- Reject partial DB-only, API-only, UI-only, config-only, or docs-only delivery.
