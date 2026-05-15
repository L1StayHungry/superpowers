import { after, before, test } from 'node:test';
import assert from 'node:assert/strict';
import path from 'node:path';
import { cpSync, existsSync, lstatSync, mkdirSync, rmSync, symlinkSync, writeFileSync } from 'node:fs';
import { tempDir, cleanup, readJson, runNode, withDistBuildLock, writeJson } from './helpers.mjs';
import { runCli } from '../../lib/cli.mjs';
import { cursorTarget, doctorCursor, installCursor, uninstallCursor } from '../../lib/targets/cursor.mjs';

let payloadRoot;

before(() => {
  payloadRoot = tempDir('tsp-cursor-payload-');
  withDistBuildLock(() => {
    const distRoot = path.resolve('dist/npm-package');
    rmSync(distRoot, { recursive: true, force: true });
    const result = runNode(['scripts/build-npm-package.mjs'], { cwd: path.resolve('.') });
    assert.equal(result.status, 0, result.stderr);
    cpSync(distRoot, payloadRoot, { recursive: true, dereference: false });
  });
});

after(() => {
  cleanup(payloadRoot);
});

test('cursorTarget resolves physical local plugin path under home', () => {
  assert.equal(
    cursorTarget('/tmp/example-home'),
    path.join('/tmp/example-home', '.cursor/plugins/local/t-superpowers')
  );
});

test('cursor install copies physical plugin directory and writes receipt', async () => {
  const home = tempDir('tsp-cursor-home-');
  try {
    const result = await installCursor({ payloadRoot, home, adopt: false, force: false, dryRun: false });
    assert.equal(result.status, 'PASS');

    const target = cursorTarget(home);
    assert.equal(lstatSync(target).isDirectory(), true);
    assert.equal(lstatSync(target).isSymbolicLink(), false);
    assert.equal(existsSync(path.join(target, '.cursor-plugin/plugin.json')), true);
    assert.equal(existsSync(path.join(target, 'skills/t-brainstorming/SKILL.md')), true);

    const receipt = readJson(path.join(target, '.t-superpowers-install.json'));
    assert.equal(receipt.target, 'cursor');
    assert.equal(receipt.version, readJson(path.join(payloadRoot, 'package.json')).version);
    assert.deepEqual(receipt.managedDirs, ['.']);
  } finally {
    cleanup(home);
  }
});

test('cursor doctor passes for physical install', async () => {
  const home = tempDir('tsp-cursor-doctor-');
  try {
    await installCursor({ payloadRoot, home, adopt: false, force: false, dryRun: false });
    const result = await doctorCursor({ home, payloadRoot });
    assert.equal(result.status, 'PASS');
    assert.match(result.message, /restart Cursor/);
    assert.equal(result.details.skillCount >= 15, true);
  } finally {
    cleanup(home);
  }
});

test('cursor install refuses existing symlink without adopt', async () => {
  const home = tempDir('tsp-cursor-symlink-');
  const external = tempDir('tsp-cursor-external-');
  try {
    const target = cursorTarget(home);
    mkdirSync(path.dirname(target), { recursive: true });
    symlinkSync(external, target);

    await assert.rejects(
      installCursor({ payloadRoot, home, adopt: false, force: false, dryRun: false }),
      /requires --adopt/
    );
    assert.equal(existsSync(external), true);
    assert.equal(lstatSync(target).isSymbolicLink(), true);
  } finally {
    cleanup(home);
    cleanup(external);
  }
});

test('cursor install with adopt replaces symlink path and leaves symlink destination intact', async () => {
  const home = tempDir('tsp-cursor-adopt-');
  const external = tempDir('tsp-cursor-external-');
  try {
    writeFileSync(path.join(external, 'kept.txt'), 'keep me\n');
    const target = cursorTarget(home);
    mkdirSync(path.dirname(target), { recursive: true });
    symlinkSync(external, target);

    const result = await installCursor({ payloadRoot, home, adopt: true, force: false, dryRun: false });
    assert.equal(result.status, 'PASS');
    assert.equal(lstatSync(target).isDirectory(), true);
    assert.equal(lstatSync(target).isSymbolicLink(), false);
    assert.equal(existsSync(path.join(external, 'kept.txt')), true);
  } finally {
    cleanup(home);
    cleanup(external);
  }
});

test('cursor install with adopt refuses another plugin manifest and leaves it intact', async () => {
  const home = tempDir('tsp-cursor-other-plugin-');
  try {
    const target = cursorTarget(home);
    mkdirSync(path.join(target, '.cursor-plugin'), { recursive: true });
    writeJson(path.join(target, '.cursor-plugin/plugin.json'), {
      name: 'other-plugin',
      displayName: 'Other Plugin'
    });
    writeFileSync(path.join(target, 'kept.txt'), 'keep me\n');

    await assert.rejects(
      installCursor({ payloadRoot, home, adopt: true, force: false, dryRun: false }),
      /belongs to another plugin/
    );

    assert.equal(readJson(path.join(target, '.cursor-plugin/plugin.json')).name, 'other-plugin');
    assert.equal(readJson(path.join(target, '.cursor-plugin/plugin.json')).displayName, 'Other Plugin');
    assert.equal(existsSync(path.join(target, 'kept.txt')), true);
  } finally {
    cleanup(home);
  }
});

test('dangling cursor symlink requires adopt and is reported as symlink', async () => {
  const home = tempDir('tsp-cursor-dangling-');
  try {
    const target = cursorTarget(home);
    mkdirSync(path.dirname(target), { recursive: true });
    symlinkSync(path.join(home, 'missing-destination'), target);

    await assert.rejects(
      installCursor({ payloadRoot, home, adopt: false, force: false, dryRun: false }),
      /requires --adopt/
    );

    const doctor = await doctorCursor({ home, payloadRoot });
    assert.equal(doctor.status, 'FAIL');
    assert.match(doctor.message, /symlink/);

    await assert.rejects(uninstallCursor({ home, adopt: false, dryRun: false }), /requires --adopt/);
    assert.equal(lstatSync(target).isSymbolicLink(), true);
  } finally {
    cleanup(home);
  }
});

test('cursor doctor fails on symlink target', async () => {
  const home = tempDir('tsp-cursor-doctor-symlink-');
  const external = tempDir('tsp-cursor-external-');
  try {
    const target = cursorTarget(home);
    mkdirSync(path.dirname(target), { recursive: true });
    symlinkSync(external, target);

    const result = await doctorCursor({ home, payloadRoot });
    assert.equal(result.status, 'FAIL');
    assert.match(result.message, /symlink/);
  } finally {
    cleanup(home);
    cleanup(external);
  }
});

test('cursor doctor fails on malformed receipt ownership fields', async () => {
  const cases = [
    ['source', 'local'],
    ['managedBy', 'someone-else'],
    ['installedAt', 'not-a-date']
  ];

  for (const [field, value] of cases) {
    const home = tempDir(`tsp-cursor-bad-receipt-${field}-`);
    try {
      await installCursor({ payloadRoot, home, adopt: false, force: false, dryRun: false });
      const target = cursorTarget(home);
      const receiptPath = path.join(target, '.t-superpowers-install.json');
      writeJson(receiptPath, { ...readJson(receiptPath), [field]: value });

      const result = await doctorCursor({ home, payloadRoot });
      assert.equal(result.status, 'FAIL');
      assert.match(result.message, /receipt/);
    } finally {
      cleanup(home);
    }
  }
});

test('cursor dryRun does not create target', async () => {
  const home = tempDir('tsp-cursor-dry-');
  try {
    const result = await installCursor({ payloadRoot, home, adopt: false, force: false, dryRun: true });
    assert.equal(result.status, 'PASS');
    assert.equal(result.changed, false);
    assert.equal(result.dryRun, true);
    assert.equal(existsSync(cursorTarget(home)), false);
  } finally {
    cleanup(home);
  }
});

test('CLI doctor cursor emits result in JSON mode against temp HOME', async () => {
  const home = tempDir('tsp-cursor-cli-');
  const originalHome = process.env.HOME;
  try {
    await installCursor({ payloadRoot, home, adopt: false, force: false, dryRun: false });
    process.env.HOME = home;
    const writes = [];
    const code = await runCli(['doctor', 'cursor', '--json'], {
      stdout: (line) => writes.push(line),
      stderr: () => {}
    });

    assert.equal(code, 0);
    const output = JSON.parse(writes.join('\n'));
    assert.equal(output[0].target, 'cursor');
    assert.equal(output[0].status, 'PASS');
  } finally {
    process.env.HOME = originalHome;
    cleanup(home);
  }
});
