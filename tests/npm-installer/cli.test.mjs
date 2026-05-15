import test from 'node:test';
import assert from 'node:assert/strict';
import path from 'node:path';
import { runCli } from '../../lib/cli.mjs';
import { installCursor } from '../../lib/targets/cursor.mjs';
import { cleanup, tempDir } from './helpers.mjs';

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

test('doctor all --json treats UNKNOWN targets as non-success', async () => {
  const home = tempDir('tsp-cli-doctor-all-');
  const originalHome = process.env.HOME;
  const writes = [];
  try {
    await installCursor({ payloadRoot: path.resolve('.'), home, adopt: false, force: false, dryRun: false });
    process.env.HOME = home;
    const code = await runCli(['doctor', 'all', '--json'], {
      stdout: (line) => writes.push(line),
      stderr: () => {}
    });

    assert.equal(code, 1);
    const output = JSON.parse(writes.join('\n'));
    assert.equal(output.find((result) => result.target === 'cursor')?.status, 'PASS');
    assert.equal(output.find((result) => result.target === 'claude')?.status, 'UNKNOWN');
    assert.equal(output.find((result) => result.target === 'codex')?.status, 'UNKNOWN');
  } finally {
    process.env.HOME = originalHome;
    cleanup(home);
  }
});
