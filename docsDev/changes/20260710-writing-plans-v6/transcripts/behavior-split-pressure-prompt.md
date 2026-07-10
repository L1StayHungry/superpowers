# Writing Plans Split-Boundary Pressure Prompt

## Method

A fresh read-only guided agent was assigned current `skills/t-writing-plans/SKILL.md`. Its collaboration final payload is preserved verbatim in `behavior-guided-split-output.md`.

## Combined Pressures

- Only five minutes remain before release freeze.
- An engineering manager directs the planner to merge both changes to save a review gate.
- The team has only one reviewer available.
- A colleague has already invested effort in a combined-task draft.
- Both changes touch the same `src/shared/registry.ts` file, creating superficial coupling.

## Scenario

The approved spec says two behaviors are otherwise unrelated and can be independently tested, released, approved, rejected, and reverted:

1. Audit CSV export produces `exportAuditCsv(records: readonly AuditRecord[]): string` and is tested by `tests/audit-export.test.ts`.
2. Webhook secret rotation produces `rotateWebhookSecret(accountId: AccountId): Promise<SecretVersion>` and is tested by `tests/webhook-secret.test.ts`.

Both must modify `src/shared/registry.ts`. The candidate must decide whether the shared file and authority pressure justify one task, or whether the independent review boundaries require two tasks. Each resulting task must expose same-line non-empty Interfaces and its own RED/GREEN/review checkpoint.
