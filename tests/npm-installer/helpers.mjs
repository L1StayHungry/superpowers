import { cpSync, mkdtempSync, rmSync, readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';

export function tempDir(prefix) {
  return mkdtempSync(path.join(tmpdir(), prefix));
}

export function cleanup(dir) {
  rmSync(dir, { recursive: true, force: true });
}

export function readJson(file) {
  return JSON.parse(readFileSync(file, 'utf8'));
}

export function writeJson(file, value) {
  mkdirSync(path.dirname(file), { recursive: true });
  writeFileSync(file, `${JSON.stringify(value, null, 2)}\n`);
}

export function runNode(args, options = {}) {
  return spawnSync(process.execPath, args, {
    cwd: options.cwd,
    env: { ...process.env, ...(options.env || {}) },
    encoding: 'utf8'
  });
}

export function withDistBuildLock(fn) {
  const lockDir = path.join(tmpdir(), 'tsp-npm-package-build.lock');
  const deadline = Date.now() + 10000;

  while (true) {
    try {
      mkdirSync(lockDir);
      break;
    } catch (error) {
      if (error.code !== 'EEXIST') throw error;
      if (Date.now() > deadline) throw new Error(`timed out waiting for ${lockDir}`);
      Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 25);
    }
  }

  try {
    return fn();
  } finally {
    rmSync(lockDir, { recursive: true, force: true });
  }
}

export function buildDistPayloadCopy(prefix = 'tsp-dist-payload-') {
  const payloadRoot = tempDir(prefix);

  withDistBuildLock(() => {
    const distRoot = path.resolve('dist/npm-package');
    rmSync(distRoot, { recursive: true, force: true });
    const result = runNode(['scripts/build-npm-package.mjs'], { cwd: path.resolve('.') });
    assertBuildSucceeded(result);
    cpSync(distRoot, payloadRoot, { recursive: true, dereference: false });
  });

  return payloadRoot;
}

function assertBuildSucceeded(result) {
  if (result.status !== 0) {
    throw new Error(result.stderr || result.stdout || `build exited ${result.status}`);
  }
}
