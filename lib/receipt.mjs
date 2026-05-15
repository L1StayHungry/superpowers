import path from 'node:path';
import { PACKAGE_NAME, RECEIPT_FILE } from './constants.mjs';
import { exists, readJson, writeJson } from './fs-ops.mjs';

export function receiptPath(targetRoot) {
  return path.join(targetRoot, RECEIPT_FILE);
}

export function readReceipt(targetRoot) {
  const file = receiptPath(targetRoot);
  return exists(file) ? readJson(file) : null;
}

export function writeReceipt(targetRoot, receipt) {
  writeJson(receiptPath(targetRoot), {
    ...receipt,
    package: PACKAGE_NAME,
    installedAt: new Date().toISOString(),
    source: 'npm',
    managedBy: 'tdata-t-superpowers'
  });
}

export function isManagedReceipt(receipt, target) {
  return Boolean(receipt && receipt.package === PACKAGE_NAME && receipt.target === target);
}
