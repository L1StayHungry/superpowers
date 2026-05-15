import test from 'node:test';
import assert from 'node:assert/strict';
import { runCli } from '../../lib/cli.mjs';

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
