# N/A Interface Structural Fixture — NOT a Generated Executable Plan

This structural example records a self-contained removal task with no cross-task callable or data boundary. The reasons are specific to the task rather than empty or generic `N/A` placeholders.

### Task 1: Remove an isolated obsolete decision note

**Files:**
- Delete: `docs/decisions/obsolete-widget-draft.md`
- Test: `tests/docs/no-obsolete-widget-draft.test.ts`

**Interfaces:**
- Consumes: N/A — this isolated deletion reads no symbol, type, or data contract from existing code or another task.
- Produces: N/A — no later task or caller consumes a symbol or data contract from deleting this obsolete decision note.

- [ ] **Step 1: Add the structural absence test**
- [ ] **Step 2: Delete the isolated obsolete note**
- [ ] **Step 3: Verify the absence test passes and create its review checkpoint**
