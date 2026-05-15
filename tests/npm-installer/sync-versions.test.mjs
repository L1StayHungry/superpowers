import test from 'node:test';
import assert from 'node:assert/strict';
import path from 'node:path';
import { mkdirSync } from 'node:fs';
import { tempDir, cleanup, readJson, writeJson, runNode } from './helpers.mjs';

const toolPath = path.resolve('tools/sync-versions.mjs');

function createVersionFixture() {
  const dir = tempDir('tsp-version-');
  writeJson(path.join(dir, 'package.json'), {
    name: 'superpowers',
    version: '5.1.0',
    type: 'module',
    main: '.opencode/plugins/superpowers.js',
    scripts: {
      build: 'node scripts/build-npm-package.mjs'
    }
  });
  mkdirSync(path.join(dir, '.cursor-plugin'), { recursive: true });
  mkdirSync(path.join(dir, '.claude-plugin'), { recursive: true });
  mkdirSync(path.join(dir, '.codex-plugin'), { recursive: true });
  writeJson(path.join(dir, '.cursor-plugin/plugin.json'), {
    name: 't-superpowers',
    version: '5.1.0',
    skills: './skills/'
  });
  writeJson(path.join(dir, '.claude-plugin/plugin.json'), {
    name: 't-superpowers',
    version: '5.1.0',
    keywords: ['skills']
  });
  writeJson(path.join(dir, '.codex-plugin/plugin.json'), {
    name: 't-superpowers',
    version: '5.1.0',
    hooks: []
  });
  writeJson(path.join(dir, '.claude-plugin/marketplace.json'), {
    name: 't-superpowers-dev',
    plugins: [{ name: 't-superpowers', version: '5.1.0', source: './' }]
  });
  return dir;
}

test('sync writes only version fields and preserves root package identity', () => {
  const dir = createVersionFixture();
  try {
    const beforeRoot = readJson(path.join(dir, 'package.json'));
    const beforeCursor = readJson(path.join(dir, '.cursor-plugin/plugin.json'));
    const beforeClaude = readJson(path.join(dir, '.claude-plugin/plugin.json'));
    const beforeCodex = readJson(path.join(dir, '.codex-plugin/plugin.json'));
    const beforeMarketplace = readJson(path.join(dir, '.claude-plugin/marketplace.json'));

    const result = runNode([toolPath, '--repo', dir, '--set', '5.2.0']);
    assert.equal(result.status, 0, result.stderr);

    const root = readJson(path.join(dir, 'package.json'));
    const cursor = readJson(path.join(dir, '.cursor-plugin/plugin.json'));
    const claude = readJson(path.join(dir, '.claude-plugin/plugin.json'));
    const codex = readJson(path.join(dir, '.codex-plugin/plugin.json'));
    const marketplace = readJson(path.join(dir, '.claude-plugin/marketplace.json'));

    assert.equal(root.name, 'superpowers');
    assert.equal(root.main, '.opencode/plugins/superpowers.js');
    assert.equal(root.type, 'module');
    assert.deepEqual({ ...root, version: beforeRoot.version }, beforeRoot);

    assert.deepEqual({ ...cursor, version: beforeCursor.version }, beforeCursor);
    assert.deepEqual({ ...claude, version: beforeClaude.version }, beforeClaude);
    assert.deepEqual({ ...codex, version: beforeCodex.version }, beforeCodex);
    assert.deepEqual({
      ...marketplace,
      plugins: [{ ...marketplace.plugins[0], version: beforeMarketplace.plugins[0].version }]
    }, beforeMarketplace);

    assert.equal(root.version, '5.2.0');
    assert.equal(cursor.version, '5.2.0');
    assert.equal(claude.version, '5.2.0');
    assert.equal(codex.version, '5.2.0');
    assert.equal(marketplace.plugins[0].version, '5.2.0');
  } finally {
    cleanup(dir);
  }
});

test('check exits non-zero when versions drift', () => {
  const dir = createVersionFixture();
  try {
    writeJson(path.join(dir, '.codex-plugin/plugin.json'), { name: 't-superpowers', version: '9.9.9' });
    const result = runNode([toolPath, '--repo', dir, '--check']);
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /version drift/);
  } finally {
    cleanup(dir);
  }
});
