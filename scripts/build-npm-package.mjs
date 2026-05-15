#!/usr/bin/env node
import {
  cpSync,
  existsSync,
  mkdirSync,
  readFileSync,
  rmSync,
  writeFileSync
} from 'node:fs';
import { dirname, join, relative, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { PACKAGE_NAME } from '../lib/constants.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, '..');
const DIST = join(ROOT, 'dist/npm-package');

const COPY_DIRS = [
  '.cursor-plugin',
  '.codex-plugin',
  'skills',
  'agents',
  'commands',
  'hooks',
  'assets',
  'cli',
  'lib'
];
const COPY_FILES = ['LICENSE', 'CHANGELOG.md'];
const PACKAGE_FILES = [
  'cli/',
  'lib/',
  '.cursor-plugin/',
  '.claude-plugin/plugin.json',
  '.codex-plugin/',
  'skills/',
  'agents/',
  'commands/',
  'hooks/',
  'assets/',
  'LICENSE',
  'README.md',
  'CHANGELOG.md'
];

function readJson(file) {
  return JSON.parse(readFileSync(file, 'utf8'));
}

function rel(file) {
  return relative(ROOT, file);
}

function ensureExists(file) {
  if (!existsSync(file)) {
    throw new Error(`missing required build file: ${rel(file)}`);
  }
}

function copyDir(source, target) {
  ensureExists(source);
  cpSync(source, target, {
    recursive: true,
    dereference: false,
    filter: (src) => !src.endsWith('.DS_Store')
  });
}

function runVersionCheck() {
  const result = spawnSync(process.execPath, ['tools/sync-versions.mjs', '--check'], {
    cwd: ROOT,
    encoding: 'utf8'
  });

  if (result.status !== 0) {
    const output = `${result.stdout || ''}${result.stderr || ''}`.trim();
    throw new Error(output || 'version sync check failed');
  }
}

function writePackageJson() {
  const rootPkg = readJson(join(ROOT, 'package.json'));
  const packageJson = {
    name: PACKAGE_NAME,
    version: rootPkg.version,
    description: 'Internal t-superpowers fork installer and plugin payload for 4399 teams.',
    license: 'MIT',
    type: 'module',
    engines: {
      node: '>=18'
    },
    bin: {
      'tdata-t-superpowers': 'cli/tdata-t-superpowers.js'
    },
    files: PACKAGE_FILES
  };

  writeFileSync(join(DIST, 'package.json'), `${JSON.stringify(packageJson, null, 2)}\n`);
}

function validateLayout() {
  ensureExists(join(DIST, '.cursor-plugin/plugin.json'));
  ensureExists(join(DIST, '.claude-plugin/plugin.json'));
  if (existsSync(join(DIST, '.claude-plugin/marketplace.json'))) {
    throw new Error('dev Claude marketplace must not be packaged');
  }
  ensureExists(join(DIST, '.codex-plugin/plugin.json'));
  ensureExists(join(DIST, 'skills/t-brainstorming/SKILL.md'));
  ensureExists(join(DIST, 'README.md'));
}

function main() {
  runVersionCheck();

  rmSync(DIST, { recursive: true, force: true });
  mkdirSync(DIST, { recursive: true });

  for (const dir of COPY_DIRS) {
    copyDir(join(ROOT, dir), join(DIST, dir));
  }

  mkdirSync(join(DIST, '.claude-plugin'), { recursive: true });
  cpSync(join(ROOT, '.claude-plugin/plugin.json'), join(DIST, '.claude-plugin/plugin.json'));

  for (const file of COPY_FILES) {
    cpSync(join(ROOT, file), join(DIST, file));
  }
  cpSync(join(ROOT, 'docsDev/t-superpowers-installer.md'), join(DIST, 'README.md'));

  writePackageJson();
  validateLayout();
}

try {
  main();
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
