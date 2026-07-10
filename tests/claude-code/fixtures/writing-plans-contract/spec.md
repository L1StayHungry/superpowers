# Widget Delivery Structural Spec Fixture — NOT an Executable Plan

## Global Constraints Source

The following lines are authoritative and must be copied verbatim into the plan:

- Runtime must be Node.js 22.17.0 exactly.
- The public route is `/v2/widgets/{widgetId}`.
- The client timeout is `2,750ms`.
- No new runtime dependency is allowed.
- Supported platforms are macOS 15 and Windows 11.

## Requirements

The user-visible widget delivery combines its database query, API route, UI loading/error behavior, runtime configuration, tests, and user documentation. Those files have no independently testable user value when delivered separately, so they form one reviewable task.

The cross-file contracts are:

```typescript
type WidgetId = string & { readonly __brand: "WidgetId" };
loadWidget(id: WidgetId): Promise<WidgetRecord | null>;
getWidget(id: WidgetId): Promise<WidgetDto | NotFound>;
fetchWidget(id: WidgetId, signal: AbortSignal): Promise<WidgetView>;
```

## Archive Patch

### planning-fixture

Target: docsDev/specs/planning-fixture/spec.md
Action: create

#### ADDED Requirements

##### Requirement: Widget delivery remains one reviewable boundary

The widget behavior must be planned with exact project constraints and stable cross-file interfaces.

###### Scenario: End-to-end widget delivery

- Given the approved widget spec
- When an implementation plan is written
- Then database, API, UI, configuration, tests, and documentation remain one reviewable task
