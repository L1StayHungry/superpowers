import {
  chmodSync,
  cpSync,
  existsSync,
  lstatSync,
  mkdirSync,
  readFileSync,
  renameSync,
  rmSync,
  writeFileSync
} from 'node:fs';
import path from 'node:path';

export function readJson(file) {
  return JSON.parse(readFileSync(file, 'utf8'));
}

export function writeJson(file, value) {
  mkdirSync(path.dirname(file), { recursive: true });
  writeFileSync(file, `${JSON.stringify(value, null, 2)}\n`);
}

export function exists(file) {
  return existsSync(file);
}

export function isSymlink(file) {
  try {
    return lstatSync(file).isSymbolicLink();
  } catch (error) {
    if (error.code === 'ENOENT') return false;
    throw error;
  }
}

export function copyDirectory(source, target) {
  mkdirSync(path.dirname(target), { recursive: true });
  cpSync(source, target, {
    recursive: true,
    dereference: false,
    filter: (src) => path.basename(src) !== '.DS_Store'
  });
}

export function removePath(target) {
  rmSync(target, { recursive: true, force: true });
}

export function atomicReplace(staging, target) {
  mkdirSync(path.dirname(target), { recursive: true });
  try {
    lstatSync(target);
  } catch (error) {
    if (error.code !== 'ENOENT') throw error;
    renameSync(staging, target);
    return;
  }

  const backup = `${target}.backup-${process.pid}-${Date.now()}`;
  renameSync(target, backup);
  try {
    renameSync(staging, target);
    removePath(backup);
  } catch (error) {
    renameSync(backup, target);
    throw error;
  }
}

export function makeExecutable(file) {
  if (existsSync(file)) chmodSync(file, 0o755);
}
