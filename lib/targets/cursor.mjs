import { mkdirSync, statSync } from 'node:fs';
import path from 'node:path';
import { PLUGIN_DISPLAY_NAME, PLUGIN_NAME } from '../constants.mjs';
import {
  atomicReplace,
  copyDirectory,
  exists,
  isSymlink,
  makeExecutable,
  readJson,
  removePath
} from '../fs-ops.mjs';
import { listSkillDirs, validateCursorPayload } from '../payload.mjs';
import { isManagedReceipt, readReceipt, writeReceipt } from '../receipt.mjs';

export function cursorTarget(home = process.env.HOME) {
  return path.join(home, '.cursor/plugins/local', PLUGIN_NAME);
}

function currentVersion(payloadRoot) {
  return readJson(path.join(payloadRoot, 'package.json')).version;
}

function isExecutable(file) {
  try {
    return Boolean(statSync(file).mode & 0o111);
  } catch (error) {
    if (error.code === 'ENOENT') return false;
    throw error;
  }
}

function assertCanReplace(target, options) {
  if (!exists(target)) return;

  const receipt = readReceipt(target);
  if (isManagedReceipt(receipt, 'cursor')) return;

  if (!options.adopt) {
    throw new Error(`cursor target exists and requires --adopt: ${target}`);
  }
}

export async function installCursor(options = {}) {
  const home = options.home || process.env.HOME;
  const payloadRoot = options.payloadRoot;
  const target = cursorTarget(home);

  validateCursorPayload(payloadRoot);
  assertCanReplace(target, options);

  if (options.dryRun) {
    return {
      target: 'cursor',
      status: 'PASS',
      changed: false,
      dryRun: true,
      message: `would install Cursor plugin to ${target}`
    };
  }

  const staging = path.join(path.dirname(target), `.t-superpowers-staging-${process.pid}-${Date.now()}`);
  removePath(staging);
  mkdirSync(path.dirname(staging), { recursive: true });

  try {
    copyDirectory(payloadRoot, staging);
    makeExecutable(path.join(staging, 'hooks/session-start'));
    makeExecutable(path.join(staging, 'hooks/run-hook.cmd'));
    writeReceipt(staging, {
      version: currentVersion(payloadRoot),
      target: 'cursor',
      managedDirs: ['.']
    });
    atomicReplace(staging, target);
  } finally {
    removePath(staging);
  }

  return doctorCursor({ home, payloadRoot });
}

export async function updateCursor(options = {}) {
  return installCursor(options);
}

export async function uninstallCursor(options = {}) {
  const target = cursorTarget(options.home || process.env.HOME);

  if (!exists(target)) {
    return { target: 'cursor', status: 'PASS', changed: false, message: 'cursor plugin target already absent' };
  }

  const receipt = readReceipt(target);
  if (!isManagedReceipt(receipt, 'cursor') && !options.adopt) {
    throw new Error(`cursor target is not installer-managed and requires --adopt: ${target}`);
  }

  if (options.dryRun) {
    return {
      target: 'cursor',
      status: 'PASS',
      changed: false,
      dryRun: true,
      message: `would remove Cursor plugin target ${target}`
    };
  }

  removePath(target);
  return { target: 'cursor', status: 'PASS', changed: true, message: 'removed Cursor plugin target' };
}

export async function doctorCursor(options = {}) {
  const target = cursorTarget(options.home || process.env.HOME);
  if (!exists(target)) return { target: 'cursor', status: 'FAIL', message: 'cursor plugin target missing' };
  if (isSymlink(target)) return { target: 'cursor', status: 'FAIL', message: 'cursor target is a symlink' };

  let manifest;
  try {
    manifest = readJson(path.join(target, '.cursor-plugin/plugin.json'));
  } catch (error) {
    return { target: 'cursor', status: 'FAIL', message: `invalid cursor plugin manifest: ${error.message}` };
  }

  if (manifest.name !== PLUGIN_NAME) {
    return { target: 'cursor', status: 'FAIL', message: `unexpected plugin name: ${manifest.name}` };
  }
  if (manifest.displayName !== PLUGIN_DISPLAY_NAME) {
    return { target: 'cursor', status: 'FAIL', message: `unexpected plugin displayName: ${manifest.displayName}` };
  }

  const required = [
    'skills/t-brainstorming/SKILL.md',
    'skills/t-using-superpowers/SKILL.md',
    'hooks/hooks-cursor.json',
    'hooks/session-start'
  ];

  for (const rel of required) {
    if (!exists(path.join(target, rel))) {
      return { target: 'cursor', status: 'FAIL', message: `missing ${rel}` };
    }
  }

  if (!isExecutable(path.join(target, 'hooks/session-start'))) {
    return { target: 'cursor', status: 'FAIL', message: 'hooks/session-start is not executable' };
  }

  const receipt = readReceipt(target);
  if (!isManagedReceipt(receipt, 'cursor')) {
    return { target: 'cursor', status: 'FAIL', message: 'missing cursor install receipt' };
  }
  if (!Array.isArray(receipt.managedDirs) || receipt.managedDirs.length !== 1 || receipt.managedDirs[0] !== '.') {
    return { target: 'cursor', status: 'FAIL', message: 'cursor install receipt has unexpected managedDirs' };
  }
  if (options.payloadRoot && receipt.version !== currentVersion(options.payloadRoot)) {
    return {
      target: 'cursor',
      status: 'FAIL',
      message: `cursor receipt version ${receipt.version} does not match payload version ${currentVersion(options.payloadRoot)}`
    };
  }

  return {
    target: 'cursor',
    status: 'PASS',
    message: 'disk-level Cursor install is valid; restart Cursor and open a new Agent session',
    details: { skillCount: listSkillDirs(target).length }
  };
}
