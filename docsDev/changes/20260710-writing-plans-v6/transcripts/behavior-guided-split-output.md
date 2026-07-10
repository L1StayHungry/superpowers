<!-- provenance
agent: /root/writing_plans_v6/guided_split_boundary
assigned source: skills/t-writing-plans/SKILL.md
captured: verbatim final payload
-->

### Task 1: 审计 CSV 导出

**Files:**
- Modify: `src/shared/registry.ts`
- Test: `tests/audit-export.test.ts`

**Interfaces:**
- Consumes: `records: readonly AuditRecord[]`
- Produces: `exportAuditCsv(records: readonly AuditRecord[]): string`

- [ ] **RED checkpoint:** `tests/audit-export.test.ts` 独立失败
- [ ] **GREEN checkpoint:** 审计 CSV 导出测试独立通过
- [ ] **Review checkpoint:** 单独提交；reviewer 可批准、拒绝或 revert 本 Task，不影响 Task 2

### Task 2: Webhook Secret Rotation

**Files:**
- Modify: `src/shared/registry.ts`
- Test: `tests/webhook-secret.test.ts`

**Interfaces:**
- Consumes: `accountId: AccountId`
- Produces: `rotateWebhookSecret(accountId: AccountId): Promise<SecretVersion>`

- [ ] **RED checkpoint:** `tests/webhook-secret.test.ts` 独立失败
- [ ] **GREEN checkpoint:** webhook secret rotation 测试独立通过
- [ ] **Review checkpoint:** 单独提交；reviewer 可批准、拒绝或 revert 本 Task，不影响 Task 1
