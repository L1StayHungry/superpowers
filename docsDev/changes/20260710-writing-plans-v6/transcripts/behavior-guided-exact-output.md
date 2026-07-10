<!-- provenance
agent: /root/writing_plans_v6/guided_exact_interfaces
assigned source: skills/t-writing-plans/SKILL.md
captured: verbatim final payload
-->

---
change_id: widget-end-to-end
created_at: 2026-07-10T00:00:00Z
updated_at: 2026-07-10T00:00:00Z
owner: widget-team
---

# Widget End-to-End Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use t-superpowers:t-subagent-driven-development (recommended) or t-superpowers:t-executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver widget loading from persistence through the public API to the client view.

**Architecture:** Implement the repository, service, route, client, configuration, and documentation as one reviewable delivery boundary. One integration test proves the complete user-visible behavior.

**Tech Stack:** Node.js, TypeScript, existing project dependencies.

## Global Constraints

- Runtime must be Node.js 22.17.0 exactly.
- The public route is /v2/widgets/{widgetId}.
- The client timeout is 2,750ms.
- No new runtime dependency is allowed.
- Supported platforms are macOS 15 and Windows 11.

---

### Task 1: Deliver Widget Loading End to End

**Files:**
- Modify: `package.json`
- Modify: `src/widgets/widget-repository.ts`
- Modify: `src/widgets/widget-service.ts`
- Modify: `src/http/routes/widgets.ts`
- Modify: `src/client/fetch-widget.ts`
- Modify: `src/ui/widget-view.ts`
- Modify: `docs/widgets.md`
- Test: `tests/widgets/widget-flow.test.ts`

**Interfaces:**
- Consumes: `id: WidgetId`, `signal: AbortSignal`, the existing widget persistence schema, and the existing `WidgetId`, `WidgetRecord`, `WidgetDto`, `NotFound`, and `WidgetView` type contracts.
- Produces: `loadWidget(id: WidgetId): Promise<WidgetRecord | null>`; `getWidget(id: WidgetId): Promise<WidgetDto | NotFound>`; `fetchWidget(id: WidgetId, signal: AbortSignal): Promise<WidgetView>`.

- [ ] **Step 1: Write the failing end-to-end test**
- [ ] **Step 2: Run `npm test -- tests/widgets/widget-flow.test.ts` and verify failure identifies the missing widget flow**
- [ ] **Step 3: Implement the minimal repository, service, route, client, UI, configuration, and documentation changes**
- [ ] **Step 4: Run `npm test -- tests/widgets/widget-flow.test.ts` and verify PASS**
- [ ] **Step 5: Run the full project validation on Node.js 22.17.0 and verify all checks pass**
- [ ] **Step 6: Commit with `git commit -m "feat: deliver widget loading end to end"`**
