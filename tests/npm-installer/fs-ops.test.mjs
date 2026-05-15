import test from 'node:test';
import assert from 'node:assert/strict';
import path from 'node:path';
import {
  mkdirSync,
  readFileSync,
  statSync,
  symlinkSync,
  writeFileSync
} from 'node:fs';
import { pathToFileURL } from 'node:url';
import { tempDir, cleanup, writeJson as writeFixtureJson } from './helpers.mjs';
import {
  atomicReplace,
  copyDirectory,
  exists,
  isSymlink,
  makeExecutable,
  readJson,
  removePath,
  writeJson
} from '../../lib/fs-ops.mjs';
import {
  listSkillDirs,
  packageRootFromModule,
  validateCursorPayload
} from '../../lib/payload.mjs';
import {
  isManagedReceipt,
  readReceipt,
  writeReceipt
} from '../../lib/receipt.mjs';

test('copyDirectory copies files and skips .DS_Store', () => {
  const dir = tempDir('tsp-fs-');
  try {
    const source = path.join(dir, 'source');
    const target = path.join(dir, 'target');
    mkdirSync(path.join(source, 'nested'), { recursive: true });
    writeFileSync(path.join(source, 'keep.txt'), 'ok');
    writeFileSync(path.join(source, '.DS_Store'), 'skip');
    writeFileSync(path.join(source, 'nested/.DS_Store'), 'skip');

    copyDirectory(source, target);

    assert.equal(exists(path.join(target, 'keep.txt')), true);
    assert.equal(exists(path.join(target, '.DS_Store')), false);
    assert.equal(exists(path.join(target, 'nested/.DS_Store')), false);
  } finally {
    cleanup(dir);
  }
});

test('readJson and writeJson create parent dirs and round-trip data', () => {
  const dir = tempDir('tsp-json-');
  try {
    const file = path.join(dir, 'nested/value.json');
    writeJson(file, { ok: true });
    assert.deepEqual(readJson(file), { ok: true });
  } finally {
    cleanup(dir);
  }
});

test('isSymlink detects symlinks and returns false for absent paths', () => {
  const dir = tempDir('tsp-symlink-');
  try {
    const target = path.join(dir, 'target.txt');
    const link = path.join(dir, 'link.txt');
    writeFileSync(target, 'ok');
    symlinkSync(target, link);

    assert.equal(isSymlink(link), true);
    assert.equal(isSymlink(target), false);
    assert.equal(isSymlink(path.join(dir, 'missing')), false);
  } finally {
    cleanup(dir);
  }
});

test('removePath removes files and directories without failing on absent paths', () => {
  const dir = tempDir('tsp-remove-');
  try {
    const target = path.join(dir, 'nested');
    mkdirSync(target, { recursive: true });
    writeFileSync(path.join(target, 'value.txt'), 'ok');

    removePath(target);
    removePath(target);

    assert.equal(exists(target), false);
  } finally {
    cleanup(dir);
  }
});

test('atomicReplace replaces target and removes staging on success', () => {
  const dir = tempDir('tsp-atomic-');
  try {
    const staging = path.join(dir, 'staging');
    const target = path.join(dir, 'target');
    mkdirSync(staging, { recursive: true });
    mkdirSync(target, { recursive: true });
    writeFileSync(path.join(staging, 'value.txt'), 'new');
    writeFileSync(path.join(target, 'value.txt'), 'old');

    atomicReplace(staging, target);

    assert.equal(readFileSync(path.join(target, 'value.txt'), 'utf8'), 'new');
    assert.equal(exists(staging), false);
  } finally {
    cleanup(dir);
  }
});

test('atomicReplace restores target if staging rename fails', () => {
  const dir = tempDir('tsp-atomic-restore-');
  try {
    const staging = path.join(dir, 'missing-staging');
    const target = path.join(dir, 'target');
    mkdirSync(target, { recursive: true });
    writeFileSync(path.join(target, 'value.txt'), 'old');

    assert.throws(() => atomicReplace(staging, target), /ENOENT/);

    assert.equal(readFileSync(path.join(target, 'value.txt'), 'utf8'), 'old');
  } finally {
    cleanup(dir);
  }
});

test('makeExecutable sets executable bits and is a no-op for absent files', () => {
  const dir = tempDir('tsp-executable-');
  try {
    const file = path.join(dir, 'run.sh');
    writeFileSync(file, '#!/bin/sh\n');

    makeExecutable(file);
    makeExecutable(path.join(dir, 'missing.sh'));

    assert.equal((statSync(file).mode & 0o111) !== 0, true);
  } finally {
    cleanup(dir);
  }
});

test('receipt helpers classify installer-managed receipts and target mismatch', () => {
  const dir = tempDir('tsp-receipt-');
  try {
    writeReceipt(dir, { version: '5.1.0', target: 'cursor', managedDirs: ['.'] });
    const receipt = readReceipt(dir);

    assert.equal(receipt.package, '@4399/tdata-t-superpowers');
    assert.equal(receipt.source, 'npm');
    assert.equal(receipt.managedBy, 'tdata-t-superpowers');
    assert.match(receipt.installedAt, /^\d{4}-\d{2}-\d{2}T/);
    assert.equal(isManagedReceipt(receipt, 'cursor'), true);
    assert.equal(isManagedReceipt(receipt, 'codex'), false);
    assert.equal(isManagedReceipt({ ...receipt, package: 'other' }, 'cursor'), false);
    assert.equal(readReceipt(path.join(dir, 'missing')), null);
  } finally {
    cleanup(dir);
  }
});

test('listSkillDirs returns sorted t skills only', () => {
  const dir = tempDir('tsp-skills-');
  try {
    mkdirSync(path.join(dir, 'skills/t-z'), { recursive: true });
    mkdirSync(path.join(dir, 'skills/t-a'), { recursive: true });
    mkdirSync(path.join(dir, 'skills/other'), { recursive: true });
    writeFileSync(path.join(dir, 'skills/t-file'), 'not a directory');

    assert.deepEqual(listSkillDirs(dir), ['t-a', 't-z']);
  } finally {
    cleanup(dir);
  }
});

test('validateCursorPayload passes for current repo payload', () => {
  const manifest = validateCursorPayload(path.resolve('.'));

  assert.equal(manifest.name, 't-superpowers');
  assert.equal(manifest.displayName, 'T-Superpowers');
});

test('validateCursorPayload fails on wrong manifest name', () => {
  const dir = tempDir('tsp-payload-name-');
  try {
    writeFixtureJson(path.join(dir, '.cursor-plugin/plugin.json'), {
      name: 'wrong',
      displayName: 'T-Superpowers'
    });
    mkdirSync(path.join(dir, 'skills/t-brainstorming'), { recursive: true });
    mkdirSync(path.join(dir, 'skills/t-using-superpowers'), { recursive: true });
    mkdirSync(path.join(dir, 'hooks'), { recursive: true });
    writeFileSync(path.join(dir, 'skills/t-brainstorming/SKILL.md'), '');
    writeFileSync(path.join(dir, 'skills/t-using-superpowers/SKILL.md'), '');
    writeFileSync(path.join(dir, 'hooks/hooks-cursor.json'), '{}');
    writeFileSync(path.join(dir, 'hooks/session-start'), '');

    assert.throws(
      () => validateCursorPayload(dir),
      /unexpected cursor plugin name: wrong/
    );
  } finally {
    cleanup(dir);
  }
});

test('validateCursorPayload fails on missing required file', () => {
  const dir = tempDir('tsp-payload-missing-');
  try {
    writeFixtureJson(path.join(dir, '.cursor-plugin/plugin.json'), {
      name: 't-superpowers',
      displayName: 'T-Superpowers'
    });

    assert.throws(
      () => validateCursorPayload(dir),
      /missing cursor payload file: skills\/t-brainstorming\/SKILL\.md/
    );
  } finally {
    cleanup(dir);
  }
});

test('packageRootFromModule resolves package root from simulated lib module URL', () => {
  const dir = tempDir('tsp-root-');
  try {
    const moduleUrl = pathToFileURL(path.join(dir, 'lib/payload.mjs')).href;

    assert.equal(packageRootFromModule(moduleUrl), dir);
  } finally {
    cleanup(dir);
  }
});

test('packageRootFromModule walks up to package markers when path contains earlier lib segment and caller is under cli', () => {
  const dir = tempDir('tsp-root-lib-');
  try {
    const packageRoot = path.join(dir, 'lib/pkg/dist/npm-package');
    mkdirSync(path.join(packageRoot, 'cli'), { recursive: true });
    mkdirSync(path.join(packageRoot, '.cursor-plugin'), { recursive: true });
    mkdirSync(path.join(packageRoot, 'skills'), { recursive: true });
    writeFixtureJson(path.join(packageRoot, 'package.json'), {
      name: '@4399/tdata-t-superpowers'
    });
    writeFixtureJson(path.join(packageRoot, '.cursor-plugin/plugin.json'), {
      name: 't-superpowers'
    });
    const moduleUrl = pathToFileURL(path.join(packageRoot, 'cli/tdata-t-superpowers.js')).href;

    assert.equal(packageRootFromModule(moduleUrl), packageRoot);
  } finally {
    cleanup(dir);
  }
});
