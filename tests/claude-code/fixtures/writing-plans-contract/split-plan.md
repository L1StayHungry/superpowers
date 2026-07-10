# Split-Boundary Structural Fixture — NOT a Generated Executable Plan

Two unrelated behaviors happen to register themselves in the same file. Each can be independently tested, reviewed, shipped, rejected, and reverted, so the shared file does not justify one combined task.

### Task 1: Export audit records as CSV

**Files:**
- Modify: `src/shared/registry.ts`
- Create: `src/audit/export-csv.ts`
- Test: `tests/audit-export.test.ts`

**Interfaces:**
- Consumes: `records: readonly AuditRecord[]` supplied by the existing audit query boundary.
- Produces: `exportAuditCsv(records: readonly AuditRecord[]): string` for the audit download caller.

- [ ] **Step 1: Write the independent audit export test**
- [ ] **Step 2: Run only `tests/audit-export.test.ts` to verify RED**
- [ ] **Step 3: Implement only the CSV export and its registry entry**
- [ ] **Step 4: Run only `tests/audit-export.test.ts` to verify GREEN**
- [ ] **Step 5: Create an independent review checkpoint for audit export**

### Task 2: Rotate webhook signing secrets

**Files:**
- Modify: `src/shared/registry.ts`
- Create: `src/webhooks/rotate-secret.ts`
- Test: `tests/webhook-secret.test.ts`

**Interfaces:**
- Consumes: `accountId: AccountId` supplied by the webhook administration boundary.
- Produces: `rotateWebhookSecret(accountId: AccountId): Promise<SecretVersion>` for the webhook signer.

- [ ] **Step 1: Write the independent secret rotation test**
- [ ] **Step 2: Run only `tests/webhook-secret.test.ts` to verify RED**
- [ ] **Step 3: Implement only secret rotation and its registry entry**
- [ ] **Step 4: Run only `tests/webhook-secret.test.ts` to verify GREEN**
- [ ] **Step 5: Create an independent review checkpoint for secret rotation**
