# NPM Installer Distribution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `t-superpowers:t-subagent-driven-development` (recommended) or `t-superpowers:t-executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and publishable npm package `@4399/tdata-t-superpowers` with explicit installers for Cursor, Claude Code, and Codex.

**Architecture:** Add a small dependency-free Node.js installer CLI. The repository remains the source tree; `npm run build` generates `dist/npm-package/` as the npm package root and plugin payload. Cursor and Codex use managed file-copy installs with receipts; Claude Code uses its native npm-source marketplace commands.

**Tech Stack:** Node.js ESM, built-in `node:test`, built-in `fs/path/child_process/os`, npm pack, shell smoke checks, existing `tools/t-stage1-check.sh`.

---

## File Structure

- Modify: `package.json`
  - Add `scripts.build`, `scripts.test:npm-installer`, and `scripts.pack:dry-run`.
  - Do not change root `name: "superpowers"` or `main: ".opencode/plugins/superpowers.js"`.
- Modify: `.gitignore`
  - Ignore generated `dist/`.
- Create: `CHANGELOG.md`
  - Internal npm release changelog with `## [Unreleased]`.
- Create: `docsDev/t-superpowers-installer.md`
  - Team install/update/doctor instructions. Build copies this into package `README.md`.
- Create: `scripts/build-npm-package.mjs`
  - Generates `dist/npm-package/`, copies allowlisted payload, strips dev marketplace, writes package manifest, validates layout, and runs optional pack check when requested.
- Create: `tools/sync-versions.mjs`
  - Single-purpose version sync/check tool. It updates version fields only and preserves root package identity.
- Create: `cli/tdata-t-superpowers.js`
  - Executable CLI entry that imports `lib/cli.mjs`.
- Create: `lib/constants.mjs`
  - Package name, plugin name, marketplace name, registry URL, receipt name, supported targets.
- Create: `lib/fs-ops.mjs`
  - Safe JSON helpers, directory copy, atomic replacement, backup, symlink detection, chmod, and path helpers.
- Create: `lib/payload.mjs`
  - Locate package root, validate plugin payload, list `t-*` skills, create payload metadata.
- Create: `lib/receipt.mjs`
  - Read/write install receipts and classify owned versus user-owned targets.
- Create: `lib/targets/cursor.mjs`
  - Cursor install/update/doctor/uninstall.
- Create: `lib/targets/codex.mjs`
  - Codex skills adapter install/update/doctor/uninstall.
- Create: `lib/targets/claude.mjs`
  - Claude marketplace generation, command invocation, update, doctor.
- Create: `lib/cli.mjs`
  - Argument parser, target dispatch, JSON/text output, error handling.
- Create: `tests/npm-installer/helpers.mjs`
  - Temporary fixture repo/package setup, command helpers, JSON helpers.
- Create: `tests/npm-installer/fs-ops.test.mjs`
  - Shared helper behavior tests.
- Create: `tests/npm-installer/build.test.mjs`
  - Build/package layout tests.
- Create: `tests/npm-installer/sync-versions.test.mjs`
  - Version sync identity-preservation tests.
- Create: `tests/npm-installer/cursor.test.mjs`
  - Cursor install/update/doctor/uninstall tests against temporary `HOME`.
- Create: `tests/npm-installer/codex.test.mjs`
  - Codex skills adapter tests against temporary `CODEX_HOME`.
- Create: `tests/npm-installer/claude.test.mjs`
  - Claude installer tests with a stub `claude` binary.
- Create: `tests/npm-installer/cli.test.mjs`
  - CLI parser and `all` target behavior tests.
- Create: `docsDev/changes/20260515-npm-installer-distribution/transcripts/npm-smoke.md`
  - npm build/pack/install smoke evidence.

## Task 1: Add CLI Skeleton And Test Harness

**Files:**
- Modify: `package.json`
- Modify: `.gitignore`
- Create: `cli/tdata-t-superpowers.js`
- Create: `lib/constants.mjs`
- Create: `lib/cli.mjs`
- Create: `tests/npm-installer/helpers.mjs`
- Create: `tests/npm-installer/cli.test.mjs`

- [ ] **Step 1: Write failing CLI tests**

Create `tests/npm-installer/helpers.mjs`:

```js
import { mkdtempSync, rmSync, readFileSync, writeFileSync, mkdirSync } from 'node:fs';
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
```

Create `tests/npm-installer/cli.test.mjs`:

```js
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
```

- [ ] **Step 2: Run tests and verify they fail**

Run:

```bash
node --test tests/npm-installer/cli.test.mjs
```

Expected: fails because `lib/cli.mjs` does not exist.

- [ ] **Step 3: Add root scripts without changing package identity**

Modify `package.json` to this shape, preserving `name` and `main`:

```json
{
  "name": "superpowers",
  "version": "5.1.0",
  "type": "module",
  "main": ".opencode/plugins/superpowers.js",
  "scripts": {
    "build": "node scripts/build-npm-package.mjs",
    "pack:dry-run": "npm pack ./dist/npm-package --dry-run",
    "test:npm-installer": "node --test tests/npm-installer/*.test.mjs"
  }
}
```

Modify `.gitignore` by appending:

```gitignore
dist/
```

- [ ] **Step 4: Implement CLI skeleton**

Create `lib/constants.mjs`:

```js
export const PACKAGE_NAME = '@4399/tdata-t-superpowers';
export const PLUGIN_NAME = 't-superpowers';
export const PLUGIN_DISPLAY_NAME = 'T-Superpowers';
export const CLAUDE_MARKETPLACE_NAME = 't-superpowers-internal';
export const INTERNAL_REGISTRY = 'https://registry-npm.gz4399.com/';
export const RECEIPT_FILE = '.t-superpowers-install.json';
export const SUPPORTED_TARGETS = ['cursor', 'claude', 'codex'];
export const SUPPORTED_COMMANDS = ['install', 'update', 'doctor', 'uninstall'];
```

Create `lib/cli.mjs`:

```js
import { SUPPORTED_COMMANDS, SUPPORTED_TARGETS, PACKAGE_NAME } from './constants.mjs';

function usage() {
  return [
    `${PACKAGE_NAME}`,
    '',
    'Usage:',
    `  npx ${PACKAGE_NAME}@latest install cursor|claude|codex|all`,
    `  npx ${PACKAGE_NAME}@latest update cursor|claude|codex|all`,
    `  npx ${PACKAGE_NAME}@latest doctor cursor|claude|codex|all`,
    `  npx ${PACKAGE_NAME}@latest uninstall cursor|claude|codex|all`,
    '',
    'Options:',
    '  --force',
    '  --adopt',
    '  --dry-run',
    '  --json',
    '  --scope user|project|local'
  ].join('\n');
}

export function parseArgs(argv) {
  const options = { force: false, adopt: false, dryRun: false, json: false, scope: 'user' };
  const positional = [];

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--help' || arg === '-h') return { help: true, options, positional };
    if (arg === '--force') options.force = true;
    else if (arg === '--adopt') options.adopt = true;
    else if (arg === '--dry-run') options.dryRun = true;
    else if (arg === '--json') options.json = true;
    else if (arg === '--scope') {
      i += 1;
      options.scope = argv[i];
      if (!['user', 'project', 'local'].includes(options.scope)) {
        throw new Error(`invalid scope: ${options.scope}`);
      }
    } else if (arg.startsWith('--')) {
      throw new Error(`unknown option: ${arg}`);
    } else {
      positional.push(arg);
    }
  }

  return { help: false, options, positional };
}

export async function runCli(argv, io = {}) {
  const stdout = io.stdout || ((line) => console.log(line));
  const stderr = io.stderr || ((line) => console.error(line));

  try {
    const parsed = parseArgs(argv);
    if (parsed.help) {
      stdout(usage());
      return 0;
    }

    const [command, target] = parsed.positional;
    if (!SUPPORTED_COMMANDS.includes(command)) {
      stderr(`unknown command: ${command || ''}`.trim());
      stderr(usage());
      return 2;
    }
    if (![...SUPPORTED_TARGETS, 'all'].includes(target)) {
      stderr(`unknown target: ${target || ''}`.trim());
      stderr(usage());
      return 2;
    }

    stderr(`command dispatch not implemented yet: ${command} ${target}`);
    return 70;
  } catch (error) {
    stderr(error.message);
    return 2;
  }
}
```

Create `cli/tdata-t-superpowers.js`:

```js
#!/usr/bin/env node
import { runCli } from '../lib/cli.mjs';

const code = await runCli(process.argv.slice(2));
process.exitCode = code;
```

- [ ] **Step 5: Run CLI tests**

Run:

```bash
npm run test:npm-installer -- tests/npm-installer/cli.test.mjs
```

Expected: CLI parser tests pass.

- [ ] **Step 6: Commit**

```bash
git add package.json .gitignore cli/tdata-t-superpowers.js lib/constants.mjs lib/cli.mjs tests/npm-installer/helpers.mjs tests/npm-installer/cli.test.mjs
git commit -m "feat: add t-superpowers installer cli skeleton"
```

## Task 2: Implement Version Sync Tool

**Files:**
- Create: `tools/sync-versions.mjs`
- Create: `tests/npm-installer/sync-versions.test.mjs`

- [ ] **Step 1: Write failing version sync tests**

Create `tests/npm-installer/sync-versions.test.mjs`:

```js
import test from 'node:test';
import assert from 'node:assert/strict';
import path from 'node:path';
import { mkdirSync, cpSync } from 'node:fs';
import { tempDir, cleanup, readJson, writeJson, runNode } from './helpers.mjs';

const toolPath = path.resolve('tools/sync-versions.mjs');

function createVersionFixture() {
  const dir = tempDir('tsp-version-');
  writeJson(path.join(dir, 'package.json'), {
    name: 'superpowers',
    version: '5.1.0',
    type: 'module',
    main: '.opencode/plugins/superpowers.js'
  });
  mkdirSync(path.join(dir, '.cursor-plugin'), { recursive: true });
  mkdirSync(path.join(dir, '.claude-plugin'), { recursive: true });
  mkdirSync(path.join(dir, '.codex-plugin'), { recursive: true });
  writeJson(path.join(dir, '.cursor-plugin/plugin.json'), { name: 't-superpowers', version: '5.1.0' });
  writeJson(path.join(dir, '.claude-plugin/plugin.json'), { name: 't-superpowers', version: '5.1.0' });
  writeJson(path.join(dir, '.codex-plugin/plugin.json'), { name: 't-superpowers', version: '5.1.0' });
  writeJson(path.join(dir, '.claude-plugin/marketplace.json'), {
    name: 't-superpowers-dev',
    plugins: [{ name: 't-superpowers', version: '5.1.0', source: './' }]
  });
  return dir;
}

test('sync writes only version fields and preserves root package identity', () => {
  const dir = createVersionFixture();
  try {
    const result = runNode([toolPath, '--repo', dir, '--set', '5.2.0']);
    assert.equal(result.status, 0, result.stderr);
    const root = readJson(path.join(dir, 'package.json'));
    assert.equal(root.name, 'superpowers');
    assert.equal(root.main, '.opencode/plugins/superpowers.js');
    assert.equal(root.version, '5.2.0');
    assert.equal(readJson(path.join(dir, '.cursor-plugin/plugin.json')).version, '5.2.0');
    assert.equal(readJson(path.join(dir, '.claude-plugin/marketplace.json')).plugins[0].version, '5.2.0');
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
```

- [ ] **Step 2: Run tests and verify they fail**

Run:

```bash
node --test tests/npm-installer/sync-versions.test.mjs
```

Expected: fails because `tools/sync-versions.mjs` does not exist.

- [ ] **Step 3: Implement version sync tool**

Create `tools/sync-versions.mjs`:

```js
#!/usr/bin/env node
import { readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';

const VERSION_FILES = [
  { file: 'package.json', path: ['version'] },
  { file: '.cursor-plugin/plugin.json', path: ['version'] },
  { file: '.claude-plugin/plugin.json', path: ['version'] },
  { file: '.codex-plugin/plugin.json', path: ['version'] },
  { file: '.claude-plugin/marketplace.json', path: ['plugins', 0, 'version'] }
];

function usage() {
  return 'usage: tools/sync-versions.mjs [--repo PATH] --check | --set X.Y.Z';
}

function get(obj, keyPath) {
  return keyPath.reduce((value, key) => value?.[key], obj);
}

function set(obj, keyPath, value) {
  let cursor = obj;
  for (let i = 0; i < keyPath.length - 1; i += 1) cursor = cursor[keyPath[i]];
  cursor[keyPath.at(-1)] = value;
}

function readJson(file) {
  return JSON.parse(readFileSync(file, 'utf8'));
}

function writeJson(file, value) {
  writeFileSync(file, `${JSON.stringify(value, null, 2)}\n`);
}

function parse(argv) {
  const options = { repo: process.cwd(), check: false, setVersion: null };
  for (let i = 0; i < argv.length; i += 1) {
    if (argv[i] === '--repo') options.repo = path.resolve(argv[++i]);
    else if (argv[i] === '--check') options.check = true;
    else if (argv[i] === '--set') options.setVersion = argv[++i];
    else throw new Error(`unknown argument: ${argv[i]}`);
  }
  if (options.check === Boolean(options.setVersion)) throw new Error(usage());
  if (options.setVersion && !/^[0-9]+\.[0-9]+\.[0-9]+(?:[-+][0-9A-Za-z.-]+)?$/.test(options.setVersion)) {
    throw new Error(`invalid version: ${options.setVersion}`);
  }
  return options;
}

function main(argv) {
  const options = parse(argv);
  const versions = [];

  for (const entry of VERSION_FILES) {
    const file = path.join(options.repo, entry.file);
    const json = readJson(file);
    const version = get(json, entry.path);
    versions.push([entry.file, version]);
    if (options.setVersion) {
      set(json, entry.path, options.setVersion);
      writeJson(file, json);
    }
  }

  if (options.check) {
    const unique = new Set(versions.map(([, version]) => version));
    if (unique.size !== 1) {
      console.error(`version drift: ${versions.map(([file, version]) => `${file}=${version}`).join(', ')}`);
      return 1;
    }
    console.log(`versions in sync: ${versions[0][1]}`);
  }

  return 0;
}

try {
  process.exitCode = main(process.argv.slice(2));
} catch (error) {
  console.error(error.message);
  process.exitCode = 2;
}
```

- [ ] **Step 4: Run tests**

Run:

```bash
node --test tests/npm-installer/sync-versions.test.mjs
node tools/sync-versions.mjs --check
```

Expected: tests pass and `--check` prints `versions in sync: 5.1.0`.

- [ ] **Step 5: Commit**

```bash
git add tools/sync-versions.mjs tests/npm-installer/sync-versions.test.mjs
git commit -m "feat: add t-superpowers version sync tool"
```

## Task 3: Implement NPM Package Build

**Files:**
- Create: `scripts/build-npm-package.mjs`
- Create: `tests/npm-installer/build.test.mjs`
- Create: `CHANGELOG.md`
- Create: `docsDev/t-superpowers-installer.md`

- [ ] **Step 1: Write failing build tests**

Create `tests/npm-installer/build.test.mjs`:

```js
import test from 'node:test';
import assert from 'node:assert/strict';
import path from 'node:path';
import { existsSync } from 'node:fs';
import { readJson, runNode } from './helpers.mjs';

test('build creates clean npm package layout and strips dev marketplace', () => {
  const result = runNode(['scripts/build-npm-package.mjs'], { cwd: path.resolve('.') });
  assert.equal(result.status, 0, result.stderr);

  const pkg = readJson('dist/npm-package/package.json');
  assert.equal(pkg.name, '@4399/tdata-t-superpowers');
  assert.equal(pkg.bin['tdata-t-superpowers'], 'cli/tdata-t-superpowers.js');
  assert.equal(existsSync('dist/npm-package/.cursor-plugin/plugin.json'), true);
  assert.equal(existsSync('dist/npm-package/.claude-plugin/plugin.json'), true);
  assert.equal(existsSync('dist/npm-package/.claude-plugin/marketplace.json'), false);
  assert.equal(existsSync('dist/npm-package/.codex-plugin/plugin.json'), true);
  assert.equal(existsSync('dist/npm-package/skills/t-brainstorming/SKILL.md'), true);
  assert.equal(existsSync('dist/npm-package/hooks/hooks-cursor.json'), true);
  assert.equal(existsSync('dist/npm-package/README.md'), true);
  assert.equal(existsSync('dist/npm-package/CHANGELOG.md'), true);
});
```

- [ ] **Step 2: Run tests and verify they fail**

Run:

```bash
node --test tests/npm-installer/build.test.mjs
```

Expected: fails because `scripts/build-npm-package.mjs` does not exist.

- [ ] **Step 3: Add internal changelog and package README source**

Create `CHANGELOG.md`:

```markdown
# Changelog

All notable changes to the internal `@4399/tdata-t-superpowers` package are recorded here.

## [Unreleased]
```

Create `docsDev/t-superpowers-installer.md`:

````markdown
# T-Superpowers Installer

Install the internal package from the 4399 npm registry:

```bash
npm config set @4399:registry https://registry-npm.gz4399.com/
npx @4399/tdata-t-superpowers@latest install all
npx @4399/tdata-t-superpowers@latest doctor all
```

## Cursor

Cursor installation copies a physical plugin directory to:

```text
~/.cursor/plugins/local/t-superpowers
```

Do not use a symlink for Cursor. Local smoke showed Cursor recognized the physical directory and did not reliably activate the symlink created by `/add-plugin`.

## Claude Code

Claude Code installation creates a local marketplace named `t-superpowers-internal` that points to the npm package, then uses `claude plugin install`.

## Codex

Codex installation copies `t-*` skills into `${CODEX_HOME:-~/.codex}/skills/`. This skills adapter does not install session-start hooks. `doctor codex` reports this as a warning.
````

- [ ] **Step 4: Implement build script**

Create `scripts/build-npm-package.mjs`:

```js
#!/usr/bin/env node
import { cpSync, existsSync, mkdirSync, rmSync, writeFileSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { PACKAGE_NAME } from '../lib/constants.mjs';

const ROOT = path.resolve(new URL('..', import.meta.url).pathname);
const DIST = path.join(ROOT, 'dist/npm-package');
const COPY_DIRS = ['.cursor-plugin', '.codex-plugin', 'skills', 'agents', 'commands', 'hooks', 'assets', 'cli', 'lib'];
const COPY_FILES = ['LICENSE', 'CHANGELOG.md'];

function readJson(file) {
  return JSON.parse(readFileSync(file, 'utf8'));
}

function copyDir(source, target) {
  cpSync(source, target, { recursive: true, dereference: false, filter: (src) => !src.endsWith('.DS_Store') });
}

function ensure(file) {
  if (!existsSync(file)) throw new Error(`missing required build file: ${path.relative(ROOT, file)}`);
}

function main() {
  const sync = spawnSync(process.execPath, ['tools/sync-versions.mjs', '--check'], { cwd: ROOT, encoding: 'utf8' });
  if (sync.status !== 0) throw new Error(sync.stderr || sync.stdout);

  rmSync(DIST, { recursive: true, force: true });
  mkdirSync(DIST, { recursive: true });

  for (const dir of COPY_DIRS) copyDir(path.join(ROOT, dir), path.join(DIST, dir));
  mkdirSync(path.join(DIST, '.claude-plugin'), { recursive: true });
  cpSync(path.join(ROOT, '.claude-plugin/plugin.json'), path.join(DIST, '.claude-plugin/plugin.json'));
  for (const file of COPY_FILES) cpSync(path.join(ROOT, file), path.join(DIST, file));
  cpSync(path.join(ROOT, 'docsDev/t-superpowers-installer.md'), path.join(DIST, 'README.md'));

  const rootPkg = readJson(path.join(ROOT, 'package.json'));
  const packageJson = {
    name: PACKAGE_NAME,
    version: rootPkg.version,
    type: 'module',
    bin: { 'tdata-t-superpowers': 'cli/tdata-t-superpowers.js' },
    files: [
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
    ],
    license: 'MIT'
  };
  writeFileSync(path.join(DIST, 'package.json'), `${JSON.stringify(packageJson, null, 2)}\n`);

  ensure(path.join(DIST, '.cursor-plugin/plugin.json'));
  ensure(path.join(DIST, '.claude-plugin/plugin.json'));
  if (existsSync(path.join(DIST, '.claude-plugin/marketplace.json'))) {
    throw new Error('dev marketplace must not be packaged');
  }
  ensure(path.join(DIST, '.codex-plugin/plugin.json'));
  ensure(path.join(DIST, 'skills/t-brainstorming/SKILL.md'));
  ensure(path.join(DIST, 'hooks/hooks-cursor.json'));
}

try {
  main();
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
```

- [ ] **Step 5: Run build tests and pack dry run**

Run:

```bash
node --test tests/npm-installer/build.test.mjs
npm run build
npm run pack:dry-run
```

Expected: tests pass, build succeeds, `npm pack` lists package contents without `.claude-plugin/marketplace.json`.

- [ ] **Step 6: Commit**

```bash
git add scripts/build-npm-package.mjs tests/npm-installer/build.test.mjs CHANGELOG.md docsDev/t-superpowers-installer.md package.json .gitignore
git commit -m "feat: build internal t-superpowers npm package"
```

## Task 4: Add Payload, Receipt, And Filesystem Helpers

**Files:**
- Create: `lib/fs-ops.mjs`
- Create: `lib/payload.mjs`
- Create: `lib/receipt.mjs`
- Create: `tests/npm-installer/fs-ops.test.mjs`

- [ ] **Step 1: Write failing helper tests**

Create `tests/npm-installer/fs-ops.test.mjs`:

```js
import test from 'node:test';
import assert from 'node:assert/strict';
import path from 'node:path';
import { mkdirSync, writeFileSync } from 'node:fs';
import { tempDir, cleanup } from './helpers.mjs';
import { copyDirectory, exists, readJson, writeJson } from '../../lib/fs-ops.mjs';
import { listSkillDirs } from '../../lib/payload.mjs';
import { isManagedReceipt, readReceipt, writeReceipt } from '../../lib/receipt.mjs';

test('copyDirectory copies files and skips .DS_Store', () => {
  const dir = tempDir('tsp-fs-');
  try {
    const source = path.join(dir, 'source');
    const target = path.join(dir, 'target');
    mkdirSync(source, { recursive: true });
    writeFileSync(path.join(source, 'keep.txt'), 'ok');
    writeFileSync(path.join(source, '.DS_Store'), 'skip');
    copyDirectory(source, target);
    assert.equal(exists(path.join(target, 'keep.txt')), true);
    assert.equal(exists(path.join(target, '.DS_Store')), false);
  } finally {
    cleanup(dir);
  }
});

test('receipt helpers classify installer-managed receipts', () => {
  const dir = tempDir('tsp-receipt-');
  try {
    writeReceipt(dir, { version: '5.1.0', target: 'cursor', managedDirs: ['.'] });
    const receipt = readReceipt(dir);
    assert.equal(receipt.package, '@4399/tdata-t-superpowers');
    assert.equal(isManagedReceipt(receipt, 'cursor'), true);
    assert.equal(isManagedReceipt(receipt, 'codex'), false);
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
    assert.deepEqual(listSkillDirs(dir), ['t-a', 't-z']);
  } finally {
    cleanup(dir);
  }
});
```

- [ ] **Step 2: Run tests and verify they fail**

Run:

```bash
node --test tests/npm-installer/fs-ops.test.mjs
```

Expected: fails because `lib/fs-ops.mjs`, `lib/payload.mjs`, and `lib/receipt.mjs` do not exist.

- [ ] **Step 3: Implement filesystem helpers**

Create `lib/fs-ops.mjs`:

```js
import { cpSync, existsSync, lstatSync, mkdirSync, readFileSync, renameSync, rmSync, writeFileSync, chmodSync } from 'node:fs';
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
  return existsSync(file) && lstatSync(file).isSymbolicLink();
}

export function copyDirectory(source, target) {
  mkdirSync(path.dirname(target), { recursive: true });
  cpSync(source, target, {
    recursive: true,
    dereference: false,
    filter: (src) => !src.endsWith('.DS_Store')
  });
}

export function removePath(target) {
  rmSync(target, { recursive: true, force: true });
}

export function atomicReplace(staging, target) {
  mkdirSync(path.dirname(target), { recursive: true });
  removePath(target);
  renameSync(staging, target);
}

export function makeExecutable(file) {
  if (existsSync(file)) chmodSync(file, 0o755);
}
```

Create `lib/payload.mjs`:

```js
import path from 'node:path';
import { readdirSync } from 'node:fs';
import { exists, readJson } from './fs-ops.mjs';
import { PLUGIN_NAME, PLUGIN_DISPLAY_NAME } from './constants.mjs';

export function packageRootFromModule(metaUrl = import.meta.url) {
  return path.resolve(new URL('..', metaUrl).pathname);
}

export function listSkillDirs(payloadRoot) {
  const skillsRoot = path.join(payloadRoot, 'skills');
  return readdirSync(skillsRoot, { withFileTypes: true })
    .filter((entry) => entry.isDirectory() && entry.name.startsWith('t-'))
    .map((entry) => entry.name)
    .sort();
}

export function validateCursorPayload(payloadRoot) {
  const manifest = readJson(path.join(payloadRoot, '.cursor-plugin/plugin.json'));
  if (manifest.name !== PLUGIN_NAME) throw new Error(`unexpected cursor plugin name: ${manifest.name}`);
  if (manifest.displayName !== PLUGIN_DISPLAY_NAME) throw new Error(`unexpected cursor displayName: ${manifest.displayName}`);
  const required = [
    'skills/t-brainstorming/SKILL.md',
    'skills/t-using-superpowers/SKILL.md',
    'hooks/hooks-cursor.json',
    'hooks/session-start'
  ];
  for (const rel of required) {
    if (!exists(path.join(payloadRoot, rel))) throw new Error(`missing cursor payload file: ${rel}`);
  }
  return manifest;
}
```

Create `lib/receipt.mjs`:

```js
import path from 'node:path';
import { PACKAGE_NAME, RECEIPT_FILE } from './constants.mjs';
import { exists, readJson, writeJson } from './fs-ops.mjs';

export function receiptPath(targetRoot) {
  return path.join(targetRoot, RECEIPT_FILE);
}

export function readReceipt(targetRoot) {
  const file = receiptPath(targetRoot);
  return exists(file) ? readJson(file) : null;
}

export function writeReceipt(targetRoot, receipt) {
  writeJson(receiptPath(targetRoot), {
    package: PACKAGE_NAME,
    installedAt: new Date().toISOString(),
    source: 'npm',
    managedBy: 'tdata-t-superpowers',
    ...receipt
  });
}

export function isManagedReceipt(receipt, target) {
  return Boolean(receipt && receipt.package === PACKAGE_NAME && receipt.target === target);
}
```

- [ ] **Step 4: Run helper tests**

Run:

```bash
node --test tests/npm-installer/fs-ops.test.mjs
```

Expected: tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/fs-ops.mjs lib/payload.mjs lib/receipt.mjs tests/npm-installer/fs-ops.test.mjs
git commit -m "feat: add installer filesystem and receipt helpers"
```

## Task 5: Implement Cursor Target

**Files:**
- Create: `lib/targets/cursor.mjs`
- Create: `tests/npm-installer/cursor.test.mjs`
- Modify: `lib/cli.mjs`

- [ ] **Step 1: Write failing Cursor tests**

Create `tests/npm-installer/cursor.test.mjs`:

```js
import { before, test } from 'node:test';
import assert from 'node:assert/strict';
import path from 'node:path';
import { existsSync, mkdirSync, symlinkSync } from 'node:fs';
import { tempDir, cleanup, readJson, runNode } from './helpers.mjs';
import { installCursor, doctorCursor } from '../../lib/targets/cursor.mjs';

const payloadRoot = path.resolve('dist/npm-package');

before(() => {
  const result = runNode(['scripts/build-npm-package.mjs'], { cwd: path.resolve('.') });
  assert.equal(result.status, 0, result.stderr);
});

test('cursor install copies physical plugin directory and writes receipt', async () => {
  const home = tempDir('tsp-cursor-home-');
  try {
    const result = await installCursor({ payloadRoot, home, adopt: false, force: false, dryRun: false });
    assert.equal(result.status, 'PASS');
    const target = path.join(home, '.cursor/plugins/local/t-superpowers');
    assert.equal(existsSync(path.join(target, '.cursor-plugin/plugin.json')), true);
    assert.equal(existsSync(path.join(target, 'skills/t-brainstorming/SKILL.md')), true);
    const receipt = readJson(path.join(target, '.t-superpowers-install.json'));
    assert.equal(receipt.target, 'cursor');
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
    assert.equal(result.details.skillCount >= 15, true);
  } finally {
    cleanup(home);
  }
});

test('cursor install refuses existing symlink without adopt', async () => {
  const home = tempDir('tsp-cursor-symlink-');
  const external = tempDir('tsp-cursor-external-');
  try {
    const target = path.join(home, '.cursor/plugins/local/t-superpowers');
    mkdirSync(path.dirname(target), { recursive: true });
    symlinkSync(external, target);
    await assert.rejects(
      installCursor({ payloadRoot, home, adopt: false, force: false, dryRun: false }),
      /requires --adopt/
    );
  } finally {
    cleanup(home);
    cleanup(external);
  }
});
```

- [ ] **Step 2: Run tests and verify they fail**

Run:

```bash
node --test tests/npm-installer/cursor.test.mjs
```

Expected: fails because `lib/targets/cursor.mjs` does not exist.

- [ ] **Step 3: Implement Cursor target**

Create `lib/targets/cursor.mjs`:

```js
import path from 'node:path';
import { mkdirSync } from 'node:fs';
import { PLUGIN_NAME } from '../constants.mjs';
import { atomicReplace, copyDirectory, exists, isSymlink, makeExecutable, readJson, removePath } from '../fs-ops.mjs';
import { validateCursorPayload, listSkillDirs } from '../payload.mjs';
import { isManagedReceipt, readReceipt, writeReceipt } from '../receipt.mjs';

export function cursorTarget(home = process.env.HOME) {
  return path.join(home, '.cursor/plugins/local', PLUGIN_NAME);
}

function currentVersion(payloadRoot) {
  return readJson(path.join(payloadRoot, 'package.json')).version;
}

function assertCanReplace(target, options) {
  if (!exists(target)) return;
  const receipt = readReceipt(target);
  if (isManagedReceipt(receipt, 'cursor')) return;
  if (!options.adopt) throw new Error(`cursor target exists and requires --adopt: ${target}`);
}

export async function installCursor(options) {
  const home = options.home || process.env.HOME;
  const target = cursorTarget(home);
  const payloadRoot = options.payloadRoot;
  validateCursorPayload(payloadRoot);
  assertCanReplace(target, options);

  if (options.dryRun) return { target: 'cursor', status: 'PASS', changed: false, dryRun: true };

  const staging = path.join(path.dirname(target), `.t-superpowers-staging-${process.pid}`);
  removePath(staging);
  mkdirSync(path.dirname(staging), { recursive: true });
  copyDirectory(payloadRoot, staging);
  makeExecutable(path.join(staging, 'hooks/session-start'));
  makeExecutable(path.join(staging, 'hooks/run-hook.cmd'));
  writeReceipt(staging, {
    version: currentVersion(payloadRoot),
    target: 'cursor',
    managedDirs: ['.']
  });
  atomicReplace(staging, target);
  return doctorCursor({ home, payloadRoot });
}

export async function updateCursor(options) {
  return installCursor(options);
}

export async function uninstallCursor(options) {
  const target = cursorTarget(options.home || process.env.HOME);
  const receipt = readReceipt(target);
  if (!isManagedReceipt(receipt, 'cursor') && !options.adopt) {
    throw new Error(`cursor target is not installer-managed and requires --adopt: ${target}`);
  }
  if (!options.dryRun) removePath(target);
  return { target: 'cursor', status: 'PASS', changed: !options.dryRun };
}

export async function doctorCursor(options) {
  const target = cursorTarget(options.home || process.env.HOME);
  if (!exists(target)) return { target: 'cursor', status: 'FAIL', message: 'cursor plugin target missing' };
  if (isSymlink(target)) return { target: 'cursor', status: 'FAIL', message: 'cursor target is a symlink' };
  const manifest = readJson(path.join(target, '.cursor-plugin/plugin.json'));
  if (manifest.name !== PLUGIN_NAME) return { target: 'cursor', status: 'FAIL', message: `unexpected plugin name: ${manifest.name}` };
  const skillCount = listSkillDirs(target).length;
  const required = ['skills/t-brainstorming/SKILL.md', 'skills/t-using-superpowers/SKILL.md', 'hooks/hooks-cursor.json', 'hooks/session-start'];
  for (const rel of required) {
    if (!exists(path.join(target, rel))) return { target: 'cursor', status: 'FAIL', message: `missing ${rel}` };
  }
  return {
    target: 'cursor',
    status: 'PASS',
    message: 'disk-level Cursor install is valid; restart Cursor and open a new Agent session',
    details: { skillCount }
  };
}
```

- [ ] **Step 4: Wire Cursor into CLI dispatch**

Modify `lib/cli.mjs` imports and dispatch:

```js
import { installCursor, updateCursor, doctorCursor, uninstallCursor } from './targets/cursor.mjs';
```

Import package-root discovery:

```js
import { packageRootFromModule } from './payload.mjs';
```

Add a `TARGETS` map and replace the `command dispatch not implemented yet` block:

```js
const TARGETS = {
  cursor: { install: installCursor, update: updateCursor, doctor: doctorCursor, uninstall: uninstallCursor }
};

async function dispatch(command, target, options) {
  const targets = target === 'all' ? Object.keys(TARGETS) : [target];
  const results = [];
  const payloadRoot = options.payloadRoot || packageRootFromModule(import.meta.url);
  for (const name of targets) {
    const runner = TARGETS[name]?.[command];
    if (!runner) {
      results.push({ target: name, status: 'UNKNOWN', message: `${command} not implemented for ${name}` });
      continue;
    }
    results.push(await runner({ ...options, payloadRoot, home: process.env.HOME }));
  }
  return results;
}
```

Then print JSON when `--json` is set and plain summary otherwise.

- [ ] **Step 5: Run Cursor tests**

Run:

```bash
node --test tests/npm-installer/cursor.test.mjs
node --test tests/npm-installer/cli.test.mjs
```

Expected: tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/targets/cursor.mjs lib/cli.mjs tests/npm-installer/cursor.test.mjs
git commit -m "feat: add cursor installer target"
```

## Task 6: Implement Codex Skills Target

**Files:**
- Create: `lib/targets/codex.mjs`
- Create: `tests/npm-installer/codex.test.mjs`
- Modify: `lib/cli.mjs`

- [ ] **Step 1: Write failing Codex tests**

Create `tests/npm-installer/codex.test.mjs`:

```js
import { before, test } from 'node:test';
import assert from 'node:assert/strict';
import path from 'node:path';
import { existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { tempDir, cleanup, readJson, runNode } from './helpers.mjs';
import { installCodex, doctorCodex } from '../../lib/targets/codex.mjs';

const payloadRoot = path.resolve('dist/npm-package');

before(() => {
  const result = runNode(['scripts/build-npm-package.mjs'], { cwd: path.resolve('.') });
  assert.equal(result.status, 0, result.stderr);
});

test('codex install copies t skills and writes managedDirs receipt', async () => {
  const codexHome = tempDir('tsp-codex-home-');
  try {
    const result = await installCodex({ payloadRoot, codexHome, adopt: false, force: false, dryRun: false });
    assert.equal(result.status, 'WARN');
    assert.equal(existsSync(path.join(codexHome, 'skills/t-brainstorming/SKILL.md')), true);
    assert.equal(existsSync(path.join(codexHome, 'skills/t-using-superpowers/SKILL.md')), true);
    const receipt = readJson(path.join(codexHome, 'skills/.t-superpowers-install.json'));
    assert.equal(receipt.target, 'codex');
    assert.equal(receipt.managedDirs.includes('t-brainstorming'), true);
  } finally {
    cleanup(codexHome);
  }
});

test('codex install refuses user-owned skill without adopt', async () => {
  const codexHome = tempDir('tsp-codex-owned-');
  try {
    const skillDir = path.join(codexHome, 'skills/t-brainstorming');
    mkdirSync(skillDir, { recursive: true });
    writeFileSync(path.join(skillDir, 'SKILL.md'), '# user skill\n');
    await assert.rejects(
      installCodex({ payloadRoot, codexHome, adopt: false, force: false, dryRun: false }),
      /requires --adopt/
    );
  } finally {
    cleanup(codexHome);
  }
});

test('codex doctor warns about missing session-start injection', async () => {
  const codexHome = tempDir('tsp-codex-doctor-');
  try {
    await installCodex({ payloadRoot, codexHome, adopt: false, force: false, dryRun: false });
    const result = await doctorCodex({ codexHome });
    assert.equal(result.status, 'WARN');
    assert.match(result.message, /session-start hook injection is not installed/);
  } finally {
    cleanup(codexHome);
  }
});
```

- [ ] **Step 2: Run tests and verify they fail**

Run:

```bash
node --test tests/npm-installer/codex.test.mjs
```

Expected: fails because `lib/targets/codex.mjs` does not exist.

- [ ] **Step 3: Implement Codex target**

Create `lib/targets/codex.mjs`:

```js
import path from 'node:path';
import { mkdirSync } from 'node:fs';
import { copyDirectory, exists, readJson, removePath } from '../fs-ops.mjs';
import { listSkillDirs } from '../payload.mjs';
import { isManagedReceipt, readReceipt, writeReceipt } from '../receipt.mjs';

export function codexSkillsRoot(codexHome = process.env.CODEX_HOME || path.join(process.env.HOME, '.codex')) {
  return path.join(codexHome, 'skills');
}

function assertCanReplaceSkill(skillsRoot, skill, options) {
  const target = path.join(skillsRoot, skill);
  if (!exists(target)) return;
  const receipt = readReceipt(skillsRoot);
  if (isManagedReceipt(receipt, 'codex') && receipt.managedDirs?.includes(skill)) return;
  if (!options.adopt) throw new Error(`codex skill ${skill} exists and requires --adopt`);
}

export async function installCodex(options) {
  const payloadRoot = options.payloadRoot;
  const skillsRoot = codexSkillsRoot(options.codexHome);
  const skills = listSkillDirs(payloadRoot);
  for (const skill of skills) assertCanReplaceSkill(skillsRoot, skill, options);

  if (!options.dryRun) {
    mkdirSync(skillsRoot, { recursive: true });
    for (const skill of skills) {
      const target = path.join(skillsRoot, skill);
      removePath(target);
      copyDirectory(path.join(payloadRoot, 'skills', skill), target);
    }
    writeReceipt(skillsRoot, {
      version: readJson(path.join(payloadRoot, 'package.json')).version,
      target: 'codex',
      managedDirs: skills
    });
  }

  return doctorCodex({ codexHome: options.codexHome });
}

export async function updateCodex(options) {
  return installCodex(options);
}

export async function uninstallCodex(options) {
  const skillsRoot = codexSkillsRoot(options.codexHome);
  const receipt = readReceipt(skillsRoot);
  if (!isManagedReceipt(receipt, 'codex') && !options.adopt) {
    throw new Error(`codex skills install is not installer-managed and requires --adopt`);
  }
  for (const skill of receipt?.managedDirs || []) {
    if (!options.dryRun) removePath(path.join(skillsRoot, skill));
  }
  if (!options.dryRun) removePath(path.join(skillsRoot, '.t-superpowers-install.json'));
  return { target: 'codex', status: 'PASS', changed: !options.dryRun };
}

export async function doctorCodex(options = {}) {
  const skillsRoot = codexSkillsRoot(options.codexHome);
  const required = ['t-brainstorming/SKILL.md', 't-using-superpowers/SKILL.md'];
  for (const rel of required) {
    if (!exists(path.join(skillsRoot, rel))) return { target: 'codex', status: 'FAIL', message: `missing ${rel}` };
  }
  const receipt = readReceipt(skillsRoot);
  if (!isManagedReceipt(receipt, 'codex')) return { target: 'codex', status: 'FAIL', message: 'missing codex install receipt' };
  return {
    target: 'codex',
    status: 'WARN',
    message: 'Codex skills are installed; session-start hook injection is not installed by the skills adapter'
  };
}
```

- [ ] **Step 4: Wire Codex into CLI**

Modify `lib/cli.mjs`:

```js
import { installCodex, updateCodex, doctorCodex, uninstallCodex } from './targets/codex.mjs';
```

Extend `TARGETS`:

```js
codex: { install: installCodex, update: updateCodex, doctor: doctorCodex, uninstall: uninstallCodex }
```

Pass `codexHome: process.env.CODEX_HOME` into runners.

- [ ] **Step 5: Run Codex tests**

Run:

```bash
node --test tests/npm-installer/codex.test.mjs
node --test tests/npm-installer/cli.test.mjs
```

Expected: tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/targets/codex.mjs lib/cli.mjs tests/npm-installer/codex.test.mjs
git commit -m "feat: add codex skills installer target"
```

## Task 7: Implement Claude Code Target

**Files:**
- Create: `lib/targets/claude.mjs`
- Create: `tests/npm-installer/claude.test.mjs`
- Modify: `lib/cli.mjs`

- [ ] **Step 1: Write failing Claude tests**

Create `tests/npm-installer/claude.test.mjs`:

```js
import test from 'node:test';
import assert from 'node:assert/strict';
import path from 'node:path';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { tempDir, cleanup, readJson } from './helpers.mjs';
import { installClaude, updateClaude } from '../../lib/targets/claude.mjs';

function makeStubClaude(binDir) {
  mkdirSync(binDir, { recursive: true });
  const log = path.join(binDir, 'claude.log');
  const stub = path.join(binDir, 'claude');
  writeFileSync(stub, `#!/usr/bin/env node
const fs = require('fs');
fs.appendFileSync(${JSON.stringify(log)}, process.argv.slice(2).join(' ') + '\\n');
if (process.argv.includes('list') && process.argv.includes('--json')) {
  console.log(JSON.stringify([{ name: 't-superpowers-internal' }]));
}
`, { mode: 0o755 });
  return { stub, log };
}

test('claude install writes npm-source marketplace and invokes native commands', async () => {
  const home = tempDir('tsp-claude-home-');
  const bin = tempDir('tsp-claude-bin-');
  try {
    const { log } = makeStubClaude(bin);
    const result = await installClaude({
      home,
      payloadRoot: path.resolve('.'),
      env: { PATH: `${bin}:${process.env.PATH}` },
      scope: 'user',
      dryRun: false
    });
    assert.equal(result.status, 'PASS');
    const marketplace = readJson(path.join(home, '.t-superpowers/claude-marketplace/.claude-plugin/marketplace.json'));
    assert.equal(marketplace.name, 't-superpowers-internal');
    assert.equal(marketplace.plugins[0].source.package, '@4399/tdata-t-superpowers');
    assert.match(readFileSync(log, 'utf8'), /plugin marketplace add/);
    assert.match(readFileSync(log, 'utf8'), /plugin install t-superpowers@t-superpowers-internal/);
  } finally {
    cleanup(home);
    cleanup(bin);
  }
});

test('claude update delegates to marketplace update and plugin update', async () => {
  const home = tempDir('tsp-claude-update-');
  const bin = tempDir('tsp-claude-update-bin-');
  try {
    const { log } = makeStubClaude(bin);
    const result = await updateClaude({
      home,
      env: { PATH: `${bin}:${process.env.PATH}` },
      scope: 'user',
      dryRun: false
    });
    assert.equal(result.status, 'PASS');
    const output = readFileSync(log, 'utf8');
    assert.match(output, /plugin marketplace update t-superpowers-internal/);
    assert.match(output, /plugin update t-superpowers@t-superpowers-internal/);
  } finally {
    cleanup(home);
    cleanup(bin);
  }
});
```

- [ ] **Step 2: Run tests and verify they fail**

Run:

```bash
node --test tests/npm-installer/claude.test.mjs
```

Expected: fails because `lib/targets/claude.mjs` does not exist.

- [ ] **Step 3: Implement Claude target**

Create `lib/targets/claude.mjs`:

```js
import path from 'node:path';
import { mkdirSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { CLAUDE_MARKETPLACE_NAME, INTERNAL_REGISTRY, PACKAGE_NAME, PLUGIN_NAME } from '../constants.mjs';
import { writeJson, exists } from '../fs-ops.mjs';

export function claudeMarketplaceDir(home = process.env.HOME) {
  return path.join(home, '.t-superpowers/claude-marketplace');
}

function runClaude(args, options) {
  const result = spawnSync('claude', args, {
    env: { ...process.env, ...(options.env || {}) },
    encoding: 'utf8'
  });
  if (result.status !== 0) throw new Error(result.stderr || result.stdout || `claude ${args.join(' ')} failed`);
  return result;
}

function writeMarketplace(home) {
  const root = claudeMarketplaceDir(home);
  const dir = path.join(root, '.claude-plugin');
  mkdirSync(dir, { recursive: true });
  writeJson(path.join(dir, 'marketplace.json'), {
    name: CLAUDE_MARKETPLACE_NAME,
    owner: { name: '4399' },
    metadata: { description: 'Internal t-superpowers marketplace' },
    plugins: [{
      name: PLUGIN_NAME,
      source: {
        source: 'npm',
        package: PACKAGE_NAME,
        registry: INTERNAL_REGISTRY
      },
      description: 'Internal t-superpowers fork for complex development workflows'
    }]
  });
  return root;
}

export async function installClaude(options) {
  const scope = options.scope || 'user';
  const marketplaceDir = writeMarketplace(options.home || process.env.HOME);
  if (!options.dryRun) {
    runClaude(['plugin', 'marketplace', 'add', marketplaceDir, '--scope', scope], options);
    runClaude(['plugin', 'install', `${PLUGIN_NAME}@${CLAUDE_MARKETPLACE_NAME}`, '--scope', scope], options);
  }
  return { target: 'claude', status: 'PASS', message: 'Claude marketplace and plugin install commands completed' };
}

export async function updateClaude(options) {
  const scope = options.scope || 'user';
  if (!options.dryRun) {
    runClaude(['plugin', 'marketplace', 'update', CLAUDE_MARKETPLACE_NAME], options);
    runClaude(['plugin', 'update', `${PLUGIN_NAME}@${CLAUDE_MARKETPLACE_NAME}`, '--scope', scope], options);
  }
  return { target: 'claude', status: 'PASS', message: 'Claude update commands completed' };
}

export async function doctorClaude(options) {
  try {
    runClaude(['plugin', 'marketplace', 'list', '--json'], options);
    runClaude(['plugin', 'list', '--json'], options);
    return { target: 'claude', status: 'UNKNOWN', message: 'Claude commands ran; version verification depends on Claude CLI output shape' };
  } catch (error) {
    return { target: 'claude', status: 'FAIL', message: error.message };
  }
}

export async function uninstallClaude(options) {
  const scope = options.scope || 'user';
  if (!options.dryRun) runClaude(['plugin', 'uninstall', `${PLUGIN_NAME}@${CLAUDE_MARKETPLACE_NAME}`, '--scope', scope], options);
  return { target: 'claude', status: 'PASS', message: 'Claude uninstall command completed' };
}
```

- [ ] **Step 4: Wire Claude into CLI**

Modify `lib/cli.mjs`:

```js
import { installClaude, updateClaude, doctorClaude, uninstallClaude } from './targets/claude.mjs';
```

Extend `TARGETS`:

```js
claude: { install: installClaude, update: updateClaude, doctor: doctorClaude, uninstall: uninstallClaude }
```

Pass `env: process.env` and `scope: parsed.options.scope`.

- [ ] **Step 5: Run Claude tests**

Run:

```bash
node --test tests/npm-installer/claude.test.mjs
node --test tests/npm-installer/cli.test.mjs
```

Expected: tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/targets/claude.mjs lib/cli.mjs tests/npm-installer/claude.test.mjs
git commit -m "feat: add claude code installer target"
```

## Task 8: Finish CLI Dispatch, JSON Output, And Target All

**Files:**
- Modify: `lib/cli.mjs`
- Modify: `tests/npm-installer/cli.test.mjs`

- [ ] **Step 1: Extend CLI tests**

Add to `tests/npm-installer/cli.test.mjs`:

```js
test('doctor all returns one result per target in json mode', async () => {
  const writes = [];
  const code = await runCli(['doctor', 'all', '--json'], {
    stdout: (line) => writes.push(line),
    stderr: () => {}
  });
  assert.equal([0, 1].includes(code), true);
  const parsed = JSON.parse(writes.join('\n'));
  assert.equal(Array.isArray(parsed.results), true);
  assert.deepEqual(parsed.results.map((item) => item.target).sort(), ['claude', 'codex', 'cursor']);
});
```

- [ ] **Step 2: Implement final output behavior**

In `lib/cli.mjs`, make `dispatch()` catch target-level errors so `all` continues:

```js
try {
  const payloadRoot = options.payloadRoot || packageRootFromModule(import.meta.url);
  results.push(await runner({ ...options, payloadRoot, home: process.env.HOME, codexHome: process.env.CODEX_HOME, env: process.env }));
} catch (error) {
  results.push({ target: name, status: 'FAIL', message: error.message });
}
```

After dispatch:

```js
const results = await dispatch(command, target, parsed.options);
if (parsed.options.json) stdout(JSON.stringify({ results }, null, 2));
else for (const result of results) stdout(`${result.target}: ${result.status}${result.message ? ` - ${result.message}` : ''}`);
return results.some((result) => result.status === 'FAIL') ? 1 : 0;
```

- [ ] **Step 3: Run CLI tests**

Run:

```bash
node --test tests/npm-installer/cli.test.mjs
```

Expected: tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/cli.mjs tests/npm-installer/cli.test.mjs
git commit -m "feat: finish installer cli dispatch"
```

## Task 9: Update Team Documentation

**Files:**
- Modify: `docsDev/getting-started.md`
- Modify: `docsDev/t-superpowers-installer.md`
- Create: `docsDev/changes/20260515-npm-installer-distribution/transcripts/npm-smoke.md`

- [ ] **Step 1: Update getting started**

Add a new section near the existing Cursor/Codex/Claude setup guidance in `docsDev/getting-started.md`:

````markdown
## Recommended Internal NPM Install

For normal team usage, install the internal package instead of using Cursor `/add-plugin` against the repository checkout:

```bash
npm config set @4399:registry https://registry-npm.gz4399.com/
npx @4399/tdata-t-superpowers@latest install all
npx @4399/tdata-t-superpowers@latest doctor all
```

Cursor must receive a physical plugin directory. Local smoke showed Cursor did not reliably expose skills from the symlink created by `/add-plugin /Users/lihuajun/WorkProject/superpowers`, while the same payload worked after copying into `~/.cursor/plugins/local/t-superpowers`.

Codex installation currently uses a skills adapter. It installs `t-*` skills but does not install session-start hooks.
````

- [ ] **Step 2: Update package README source**

Ensure `docsDev/t-superpowers-installer.md` includes:

````markdown
## Update

```bash
npx @4399/tdata-t-superpowers@latest update all
npx @4399/tdata-t-superpowers@latest doctor all
```

## Uninstall

```bash
npx @4399/tdata-t-superpowers@latest uninstall cursor
npx @4399/tdata-t-superpowers@latest uninstall codex
```

Claude Code uninstall delegates to Claude's native plugin command.
````

- [ ] **Step 3: Create smoke evidence file**

Create `docsDev/changes/20260515-npm-installer-distribution/transcripts/npm-smoke.md`:

````markdown
# NPM Installer Smoke

Date: 2026-05-15

## Build

- Result: NOT VERIFIED
- Command: `npm run build`
- Observation:

## Pack

- Result: NOT VERIFIED
- Command: `npm pack ./dist/npm-package --dry-run`
- Observation:

## Cursor

- Result: NOT VERIFIED
- Command: `node dist/npm-package/cli/tdata-t-superpowers.js install cursor`
- Observation:

## Claude Code

- Result: NOT VERIFIED
- Command: `npx @4399/tdata-t-superpowers@latest install claude`
- Observation:

## Codex

- Result: NOT VERIFIED
- Command: `CODEX_HOME=<tmp> node dist/npm-package/cli/tdata-t-superpowers.js install codex`
- Observation:
````

- [ ] **Step 4: Commit**

```bash
git add docsDev/getting-started.md docsDev/t-superpowers-installer.md docsDev/changes/20260515-npm-installer-distribution/transcripts/npm-smoke.md
git commit -m "docs: add npm installer usage guidance"
```

## Task 10: Final Validation And Smoke

**Files:**
- Modify: `docsDev/changes/20260515-npm-installer-distribution/transcripts/npm-smoke.md`

- [ ] **Step 1: Run unit tests**

Run:

```bash
npm run test:npm-installer
```

Expected: all `tests/npm-installer/*.test.mjs` tests pass.

- [ ] **Step 2: Run build and pack**

Run:

```bash
npm run build
npm run pack:dry-run
```

Expected:
- `dist/npm-package/package.json` has `name: "@4399/tdata-t-superpowers"`.
- `dist/npm-package/.claude-plugin/marketplace.json` is absent.
- `npm pack` exits `0`.

- [ ] **Step 3: Run local Cursor install smoke from built package**

Use a temporary home first:

```bash
TMP_HOME="$(mktemp -d)"
HOME="$TMP_HOME" node dist/npm-package/cli/tdata-t-superpowers.js install cursor
HOME="$TMP_HOME" node dist/npm-package/cli/tdata-t-superpowers.js doctor cursor
test -f "$TMP_HOME/.cursor/plugins/local/t-superpowers/skills/t-brainstorming/SKILL.md"
rm -rf "$TMP_HOME"
```

Expected: install and doctor exit `0`.

Run against the real Cursor home only after reviewing output:

```bash
node dist/npm-package/cli/tdata-t-superpowers.js install cursor --adopt
node dist/npm-package/cli/tdata-t-superpowers.js doctor cursor
```

Expected: physical install remains valid. Manual Cursor UI smoke should show `T Superpowers` with 15 skills.

- [ ] **Step 4: Run local Codex install smoke**

Run:

```bash
TMP_CODEX_HOME="$(mktemp -d)"
CODEX_HOME="$TMP_CODEX_HOME" node dist/npm-package/cli/tdata-t-superpowers.js install codex
CODEX_HOME="$TMP_CODEX_HOME" node dist/npm-package/cli/tdata-t-superpowers.js doctor codex
rm -rf "$TMP_CODEX_HOME"
```

Expected: install exits `0`; doctor reports `WARN` about missing session-start hook injection.

- [ ] **Step 5: Run Claude stub test and optional real command check**

Run:

```bash
node --test tests/npm-installer/claude.test.mjs
```

Expected: stub tests pass.

If the internal registry package has been published and `claude` is installed, run:

```bash
npx @4399/tdata-t-superpowers@latest install claude --dry-run
```

Expected: prints planned marketplace and plugin commands without changing Claude state.

- [ ] **Step 6: Run repository guardrails**

Run:

```bash
git diff --check
bash tools/t-stage1-check.sh
rg -n 'docs/superpowers/(specs|plans)' skills hooks .claude-plugin .cursor-plugin .codex-plugin README.md docsDev/getting-started.md && exit 1 || true
```

Expected:
- `git diff --check` exits `0`.
- `tools/t-stage1-check.sh` exits `0`.
- `rg` command finds no forbidden live-surface runtime path instructions.

- [ ] **Step 7: Update smoke transcript**

Replace each `NOT VERIFIED` in `docsDev/changes/20260515-npm-installer-distribution/transcripts/npm-smoke.md` with `PASS`, `WARN`, `FAIL`, or `BLOCKED`, and include the exact command output summary.

- [ ] **Step 8: Commit final evidence**

```bash
git add docsDev/changes/20260515-npm-installer-distribution/transcripts/npm-smoke.md
git commit -m "docs: record npm installer smoke results"
```

## Self-Review

- Spec coverage:
  - Build/package layout: Task 3.
  - Dev Claude marketplace exclusion: Task 3 build test.
  - Version sync preserving root identity: Task 2.
  - Cursor physical copy install and doctor: Task 5 and Task 10.
  - Codex skills adapter and hook warning: Task 6 and Task 10.
  - Claude native marketplace/install/update: Task 7.
  - Doctor status model and `all` target: Task 8.
  - Docs and smoke evidence: Task 9 and Task 10.
- Placeholder scan: this plan contains concrete file paths, commands, snippets, and expected outcomes.
- Type consistency:
  - Receipt field is `managedDirs` everywhere.
  - Targets use `cursor`, `claude`, and `codex`.
  - Package name is `@4399/tdata-t-superpowers`.
  - Root package identity remains `name: "superpowers"` and `main: ".opencode/plugins/superpowers.js"`.
