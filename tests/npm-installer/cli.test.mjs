import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { runCli } from '../../lib/cli.mjs';
import { installCodex } from '../../lib/targets/codex.mjs';
import { installCursor } from '../../lib/targets/cursor.mjs';
import { buildDistPayloadCopy, cleanup, tempDir } from './helpers.mjs';

function makeClaudeStub(binDir) {
  const logFile = path.join(binDir, 'claude.log');
  mkdirSync(binDir, { recursive: true });
  writeFileSync(
    path.join(binDir, 'claude'),
    `#!/usr/bin/env node
const fs = require('node:fs');
const args = process.argv.slice(2);
fs.appendFileSync(${JSON.stringify(logFile)}, args.join(' ') + '\\n');
if (args.join(' ') === 'plugin marketplace list --json') {
  console.log(JSON.stringify([{ name: 't-superpowers-internal' }]));
  process.exit(0);
}
if (args.join(' ') === 'plugin list --json') {
  console.log(JSON.stringify([{ name: 't-superpowers', marketplace: 't-superpowers-internal' }]));
  process.exit(0);
}
process.exit(0);
`,
    { mode: 0o755 }
  );
  return logFile;
}

test('help lists supported commands and targets', async () => {
  const writes = [];
  const code = await runCli(['--help'], {
    stdout: (line) => writes.push(line),
    stderr: (line) => writes.push(line)
  });

  assert.equal(code, 0);
  assert.match(writes.join('\n'), /install cursor/);
  assert.match(writes.join('\n'), /update all/);
  assert.match(writes.join('\n'), /doctor all/);
});

test('unknown command exits non-zero with useful error', async () => {
  const errors = [];
  const code = await runCli(['publish', 'cursor'], {
    stdout: () => {},
    stderr: (line) => errors.push(line)
  });

  assert.equal(code, 2);
  assert.match(errors.join('\n'), /unknown command: publish/);
});

test('unknown target exits non-zero with useful error', async () => {
  const errors = [];
  const code = await runCli(['install', 'vscode'], {
    stdout: () => {},
    stderr: (line) => errors.push(line)
  });

  assert.equal(code, 2);
  assert.match(errors.join('\n'), /unknown target: vscode/);
});

test('extra positional arguments exit non-zero with useful error', async () => {
  const errors = [];
  const code = await runCli(['install', 'cursor', 'extra'], {
    stdout: () => {},
    stderr: (line) => errors.push(line)
  });

  assert.equal(code, 2);
  assert.match(errors.join('\n'), /too many positional arguments/);
});

test('plain output uses stable target status message format', async () => {
  const home = tempDir('tsp-cli-plain-');
  const originalHome = process.env.HOME;
  const writes = [];
  try {
    process.env.HOME = home;
    const code = await runCli(['doctor', 'cursor'], {
      stdout: (line) => writes.push(line),
      stderr: () => {}
    });

    assert.equal(code, 1);
    assert.deepEqual(writes, ['cursor: FAIL - cursor plugin target missing']);
  } finally {
    process.env.HOME = originalHome;
    cleanup(home);
  }
});

test('doctor all --json includes implemented claude target using native doctor', async () => {
  const home = tempDir('tsp-cli-doctor-all-');
  const codexHome = tempDir('tsp-cli-doctor-all-codex-');
  const binDir = tempDir('tsp-cli-doctor-all-bin-');
  const payloadRoot = buildDistPayloadCopy('tsp-cli-payload-');
  const originalHome = process.env.HOME;
  const originalCodexHome = process.env.CODEX_HOME;
  const originalPath = process.env.PATH;
  const writes = [];
  try {
    const logFile = makeClaudeStub(binDir);
    await installCursor({ payloadRoot, home, adopt: false, force: false, dryRun: false });
    await installCodex({ payloadRoot, codexHome, adopt: false, force: false, dryRun: false });
    process.env.HOME = home;
    process.env.CODEX_HOME = codexHome;
    process.env.PATH = `${binDir}${path.delimiter}${originalPath || ''}`;
    const code = await runCli(['doctor', 'all', '--json'], {
      stdout: (line) => writes.push(line),
      stderr: () => {}
    });

    assert.equal(code, 1);
    const output = JSON.parse(writes.join('\n'));
    assert.deepEqual(
      output.results.map((result) => result.target),
      ['cursor', 'claude', 'codex']
    );
    assert.equal(output.results.find((result) => result.target === 'cursor')?.status, 'PASS');
    assert.equal(output.results.find((result) => result.target === 'codex')?.status, 'WARN');
    assert.equal(output.results.find((result) => result.target === 'claude')?.status, 'UNKNOWN');
    for (const result of output.results) {
      assert.match(result.status, /^(PASS|WARN|FAIL|UNKNOWN)$/);
    }
    assert.deepEqual(readFileSync(logFile, 'utf8').trim().split('\n'), [
      'plugin marketplace list --json',
      'plugin list --json'
    ]);
  } finally {
    process.env.HOME = originalHome;
    if (originalCodexHome === undefined) delete process.env.CODEX_HOME;
    else process.env.CODEX_HOME = originalCodexHome;
    process.env.PATH = originalPath;
    cleanup(home);
    cleanup(codexHome);
    cleanup(binDir);
    cleanup(payloadRoot);
  }
});

test('all dispatch records target-level failures and continues other targets', async () => {
  const home = tempDir('tsp-cli-all-continues-');
  const codexHomeParent = tempDir('tsp-cli-all-continues-codex-');
  const codexHome = path.join(codexHomeParent, 'not-a-directory');
  const originalHome = process.env.HOME;
  const originalCodexHome = process.env.CODEX_HOME;
  const originalPath = process.env.PATH;
  const writes = [];
  try {
    writeFileSync(codexHome, 'not a directory');
    process.env.HOME = home;
    process.env.CODEX_HOME = codexHome;
    process.env.PATH = '';
    const code = await runCli(['install', 'all', '--json'], {
      stdout: (line) => writes.push(line),
      stderr: () => {}
    });

    assert.equal(code, 1);
    const output = JSON.parse(writes.join('\n'));
    assert.deepEqual(
      output.results.map((result) => result.target),
      ['cursor', 'claude', 'codex']
    );
    assert.equal(output.results.length, 3);
    assert.equal(output.results.find((result) => result.target === 'cursor')?.status, 'PASS');
    assert.equal(output.results.find((result) => result.target === 'claude')?.status, 'FAIL');
    assert.equal(output.results.find((result) => result.target === 'codex')?.status, 'FAIL');
  } finally {
    process.env.HOME = originalHome;
    if (originalCodexHome === undefined) delete process.env.CODEX_HOME;
    else process.env.CODEX_HOME = originalCodexHome;
    process.env.PATH = originalPath;
    cleanup(home);
    cleanup(codexHomeParent);
  }
});
