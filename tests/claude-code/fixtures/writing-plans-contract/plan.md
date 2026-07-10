---
change_id: fixture-widget-delivery
created_at: 2026-07-10T00:00:00Z
updated_at: 2026-07-10T00:00:00Z
owner: fixture
---

# Widget Delivery Structural Contract Fixture — NOT a Generated Executable Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use t-superpowers:t-subagent-driven-development or t-superpowers:t-executing-plans to implement this task. Steps use checkbox syntax for tracking.

**Goal:** Deliver one user-visible widget flow across persistence, transport, presentation, configuration, tests, and documentation.

**Architecture:** Preserve the approved signatures from the repository through the route and client. Keep all supporting edits in one task because only the completed vertical behavior has independent test and review value.

**Tech Stack:** Node.js, TypeScript, Vitest, React.

## Global Constraints

- Runtime must be Node.js 22.17.0 exactly.
- The public route is `/v2/widgets/{widgetId}`.
- The client timeout is `2,750ms`.
- No new runtime dependency is allowed.
- Supported platforms are macOS 15 and Windows 11.

---

### Task 1: Deliver the end-to-end widget behavior

**Files:**
- Create: `src/db/widgets.ts`
- Create: `src/api/widgets.ts`
- Create: `src/ui/WidgetPanel.tsx`
- Modify: `config/runtime.json`
- Create: `tests/widget-delivery.test.tsx`
- Create: `docs/widgets.md`

**Interfaces:**
- Consumes: `type WidgetId = string & { readonly __brand: "WidgetId" }`, platform `AbortSignal`, and approved route parameter `{widgetId}: WidgetId`.
- Produces: `loadWidget(id: WidgetId): Promise<WidgetRecord | null>`, `getWidget(id: WidgetId): Promise<WidgetDto | NotFound>`, and `fetchWidget(id: WidgetId, signal: AbortSignal): Promise<WidgetView>` with loading, not-found, error, and success UI states.

- [ ] **Step 1: Write the failing end-to-end test**

Add one test that calls the route through the client, observes the repository lookup, and asserts loading, not-found, error, and success states under the exact timeout.

- [ ] **Step 2: Run the test to verify RED**

Run: `npm test -- tests/widget-delivery.test.tsx`

Expected: FAIL because the widget route and client do not exist.

- [ ] **Step 3: Implement the minimal vertical behavior**

Implement the three exact signatures, the exact route, the timeout configuration, and the UI states without adding a runtime dependency; document the same public behavior in `docs/widgets.md`.

- [ ] **Step 4: Run the test to verify GREEN**

Run: `npm test -- tests/widget-delivery.test.tsx`

Expected: PASS on the supported platform matrix.

- [ ] **Step 5: Create the checkpoint commit**

```bash
git add src/db/widgets.ts src/api/widgets.ts src/ui/WidgetPanel.tsx config/runtime.json tests/widget-delivery.test.tsx docs/widgets.md
git commit -m "feat: deliver widget flow"
```
