import { mkdirSync } from 'node:fs';
import path from 'node:path';
import { copyDirectory } from './fs-ops.mjs';

function safeSegment(value) {
  return String(value || 'unknown').replace(/[^0-9A-Za-z._-]/g, '-');
}

export function backupRoot(home = process.env.HOME, target) {
  return path.join(home, '.t-superpowers/backups', target);
}

export function createBackupDir({ home = process.env.HOME, target, version }) {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const root = backupRoot(home, target);
  mkdirSync(root, { recursive: true });
  let candidate = path.join(root, `${timestamp}-${safeSegment(version)}`);
  let suffix = 1;
  while (true) {
    try {
      mkdirSync(candidate, { recursive: false });
      return candidate;
    } catch (error) {
      if (error.code !== 'EEXIST') throw error;
      candidate = path.join(root, `${timestamp}-${safeSegment(version)}-${suffix}`);
      suffix += 1;
    }
  }
}

export function backupDirectory({ source, home = process.env.HOME, target, version }) {
  const backup = createBackupDir({ home, target, version });
  copyDirectory(source, backup);
  return backup;
}
