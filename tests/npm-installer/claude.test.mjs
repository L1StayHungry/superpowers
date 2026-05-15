import test from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { claudeMarketplaceDir, doctorClaude, installClaude, uninstallClaude, updateClaude } from '../../lib/targets/claude.mjs';
import { buildDistPayloadCopy, cleanup, readJson, tempDir } from './helpers.mjs';

function makeClaudeStub({ binDir, marketplaceList, pluginList, fail = false }) {
  const logFile = path.join(binDir, 'claude.log');
  mkdirSync(binDir, { recursive: true });
  writeFileSync(
    path.join(binDir, 'claude'),
    `#!/usr/bin/env node
const fs = require('node:fs');
const path = require('node:path');
const args = process.argv.slice(2);
fs.appendFileSync(${JSON.stringify(logFile)}, args.join(' ') + '\\n');
if (${JSON.stringify(fail)}) process.exit(17);
if (args.join(' ') === 'plugin marketplace list --json') {
  console.log(${JSON.stringify(JSON.stringify(marketplaceList))});
  process.exit(0);
}
if (args.join(' ') === 'plugin list --json') {
  console.log(${JSON.stringify(JSON.stringify(pluginList))});
  process.exit(0);
}
process.exit(0);
`,
    { mode: 0o755 }
  );
  return logFile;
}

function readLog(logFile) {
  if (!existsSync(logFile)) return [];
  return readFileSync(logFile, 'utf8').trim().split('\n').filter(Boolean);
}

function envWithStub(binDir) {
  return { ...process.env, PATH: `${binDir}${path.delimiter}${process.env.PATH || ''}` };
}

test('claudeMarketplaceDir returns generated marketplace under home', () => {
  assert.equal(
    claudeMarketplaceDir('/tmp/example-home'),
    path.join('/tmp/example-home', '.t-superpowers/claude-marketplace')
  );
});

test('install writes npm-source marketplace and invokes native commands with scope', async () => {
  const home = tempDir('tsp-claude-home-');
  const binDir = tempDir('tsp-claude-bin-');
  const payloadRoot = buildDistPayloadCopy('tsp-claude-payload-');
  const logFile = makeClaudeStub({
    binDir,
    marketplaceList: [],
    pluginList: []
  });

  try {
    const result = await installClaude({
      home,
      env: envWithStub(binDir),
      payloadRoot,
      scope: 'project',
      dryRun: false
    });

    assert.equal(result.status, 'PASS');
    const marketplaceFile = path.join(home, '.t-superpowers/claude-marketplace/.claude-plugin/marketplace.json');
    const marketplace = readJson(marketplaceFile);
    assert.equal(marketplace.name, 't-superpowers-internal');
    assert.equal(marketplace.owner.name, '4399');
    assert.equal(marketplace.metadata.description, 'Internal t-superpowers marketplace');
    assert.equal(marketplace.plugins[0].name, 't-superpowers');
    assert.deepEqual(marketplace.plugins[0].source, {
      source: 'npm',
      package: '@4399/tdata-t-superpowers',
      registry: 'https://registry-npm.gz4399.com/'
    });
    assert.match(marketplace.plugins[0].description, /complex development workflows/);
    assert.deepEqual(readLog(logFile), [
      `plugin marketplace add ${claudeMarketplaceDir(home)} --scope project`,
      'plugin install t-superpowers@t-superpowers-internal --scope project'
    ]);
  } finally {
    cleanup(home);
    cleanup(binDir);
    cleanup(payloadRoot);
  }
});

test('dryRun install does not write marketplace or invoke claude', async () => {
  const home = tempDir('tsp-claude-home-');
  const binDir = tempDir('tsp-claude-bin-');
  const payloadRoot = buildDistPayloadCopy('tsp-claude-payload-');
  const logFile = makeClaudeStub({ binDir, marketplaceList: [], pluginList: [] });

  try {
    const result = await installClaude({
      home,
      env: envWithStub(binDir),
      payloadRoot,
      scope: 'local',
      dryRun: true
    });

    assert.equal(result.status, 'PASS');
    assert.equal(result.dryRun, true);
    assert.equal(existsSync(path.join(home, '.t-superpowers/claude-marketplace')), false);
    assert.deepEqual(readLog(logFile), []);
    assert.deepEqual(result.details.commands, [
      `claude plugin marketplace add ${claudeMarketplaceDir(home)} --scope local`,
      'claude plugin install t-superpowers@t-superpowers-internal --scope local'
    ]);
  } finally {
    cleanup(home);
    cleanup(binDir);
    cleanup(payloadRoot);
  }
});

test('update delegates to marketplace update and plugin update', async () => {
  const binDir = tempDir('tsp-claude-bin-');
  const logFile = makeClaudeStub({ binDir, marketplaceList: [], pluginList: [] });

  try {
    const result = await updateClaude({ env: envWithStub(binDir), scope: 'user', dryRun: false });

    assert.equal(result.status, 'PASS');
    assert.deepEqual(readLog(logFile), [
      'plugin marketplace update t-superpowers-internal',
      'plugin update t-superpowers@t-superpowers-internal --scope user'
    ]);
  } finally {
    cleanup(binDir);
  }
});

test('uninstall invokes plugin uninstall', async () => {
  const binDir = tempDir('tsp-claude-bin-');
  const logFile = makeClaudeStub({ binDir, marketplaceList: [], pluginList: [] });

  try {
    const result = await uninstallClaude({ env: envWithStub(binDir), scope: 'project', dryRun: false });

    assert.equal(result.status, 'PASS');
    assert.deepEqual(readLog(logFile), ['plugin uninstall t-superpowers@t-superpowers-internal --scope project']);
  } finally {
    cleanup(binDir);
  }
});

test('doctor returns UNKNOWN when marketplace and plugin exist without version data', async () => {
  const binDir = tempDir('tsp-claude-bin-');
  const payloadRoot = buildDistPayloadCopy('tsp-claude-payload-');
  makeClaudeStub({
    binDir,
    marketplaceList: [{ name: 't-superpowers-internal' }],
    pluginList: [{ name: 't-superpowers', marketplace: 't-superpowers-internal' }]
  });

  try {
    const result = await doctorClaude({ env: envWithStub(binDir), payloadRoot });

    assert.equal(result.status, 'UNKNOWN');
    assert.match(result.message, /version/i);
  } finally {
    cleanup(binDir);
    cleanup(payloadRoot);
  }
});

test('doctor returns UNKNOWN when matching plugin lacks marketplace association', async () => {
  const binDir = tempDir('tsp-claude-bin-');
  const payloadRoot = buildDistPayloadCopy('tsp-claude-payload-');
  const version = readJson(path.join(payloadRoot, '.claude-plugin/plugin.json')).version;
  makeClaudeStub({
    binDir,
    marketplaceList: [{ name: 't-superpowers-internal' }],
    pluginList: [{ name: 't-superpowers', version }]
  });

  try {
    const result = await doctorClaude({ env: envWithStub(binDir), payloadRoot });

    assert.equal(result.status, 'UNKNOWN');
    assert.match(result.message, /marketplace/i);
  } finally {
    cleanup(binDir);
    cleanup(payloadRoot);
  }
});

test('doctor returns FAIL when matching plugin belongs to dev marketplace', async () => {
  const binDir = tempDir('tsp-claude-bin-');
  const payloadRoot = buildDistPayloadCopy('tsp-claude-payload-');
  const version = readJson(path.join(payloadRoot, '.claude-plugin/plugin.json')).version;
  makeClaudeStub({
    binDir,
    marketplaceList: [{ name: 't-superpowers-internal' }],
    pluginList: [{ name: 't-superpowers', marketplace: 't-superpowers-dev', version }]
  });

  try {
    const result = await doctorClaude({ env: envWithStub(binDir), payloadRoot });

    assert.equal(result.status, 'FAIL');
    assert.match(result.message, /t-superpowers-dev/);
  } finally {
    cleanup(binDir);
    cleanup(payloadRoot);
  }
});

test('doctor returns FAIL when marketplace or plugin is missing', async () => {
  const binDir = tempDir('tsp-claude-bin-');
  const payloadRoot = buildDistPayloadCopy('tsp-claude-payload-');
  makeClaudeStub({
    binDir,
    marketplaceList: [{ name: 'different-marketplace' }],
    pluginList: [{ name: 'different-plugin' }]
  });

  try {
    const result = await doctorClaude({ env: envWithStub(binDir), payloadRoot });

    assert.equal(result.status, 'FAIL');
    assert.match(result.message, /marketplace/i);
  } finally {
    cleanup(binDir);
    cleanup(payloadRoot);
  }
});

test('doctor returns FAIL when claude binary is missing', async () => {
  const emptyPath = tempDir('tsp-claude-empty-path-');
  const payloadRoot = buildDistPayloadCopy('tsp-claude-payload-');

  try {
    const result = await doctorClaude({ env: { ...process.env, PATH: emptyPath }, payloadRoot });

    assert.equal(result.status, 'FAIL');
    assert.match(result.message, /claude.*not available/i);
  } finally {
    cleanup(emptyPath);
    cleanup(payloadRoot);
  }
});

test('doctor returns PASS when version data and marketplace association match', async () => {
  const binDir = tempDir('tsp-claude-bin-');
  const payloadRoot = buildDistPayloadCopy('tsp-claude-payload-');
  const version = readJson(path.join(payloadRoot, '.claude-plugin/plugin.json')).version;
  makeClaudeStub({
    binDir,
    marketplaceList: [{ name: 't-superpowers-internal' }],
    pluginList: [{ name: 't-superpowers', marketplace: 't-superpowers-internal', version }]
  });

  try {
    const result = await doctorClaude({ env: envWithStub(binDir), payloadRoot });

    assert.equal(result.status, 'PASS');
  } finally {
    cleanup(binDir);
    cleanup(payloadRoot);
  }
});
