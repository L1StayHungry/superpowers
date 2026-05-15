import test from 'node:test';
import assert from 'node:assert/strict';
import path from 'node:path';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { readJson, runNode, withDistBuildLock } from './helpers.mjs';

const ROOT = path.resolve('.');
const DIST = path.join(ROOT, 'dist/npm-package');

function runBuild() {
  return runNode(['scripts/build-npm-package.mjs'], { cwd: ROOT });
}

test('build creates clean npm package layout and strips dev marketplace', () => {
  withDistBuildLock(() => {
    mkdirSync(path.join(DIST, '.claude-plugin'), { recursive: true });
    writeFileSync(path.join(DIST, 'stale.txt'), 'stale\n');
    writeFileSync(path.join(DIST, '.claude-plugin/marketplace.json'), '{}\n');

    const rootPackageBefore = readFileSync(path.join(ROOT, 'package.json'), 'utf8');
    const result = runBuild();
    assert.equal(result.status, 0, result.stderr || result.stdout);

    const pkg = readJson(path.join(DIST, 'package.json'));
    assert.equal(pkg.name, '@4399/tdata-t-superpowers');
    assert.equal(pkg.type, 'module');
    assert.equal(pkg.bin['tdata-t-superpowers'], 'cli/tdata-t-superpowers.js');
    assert.deepEqual(pkg.files, [
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
    ]);

    assert.equal(existsSync(path.join(DIST, '.cursor-plugin/plugin.json')), true);
    assert.equal(existsSync(path.join(DIST, '.claude-plugin/plugin.json')), true);
    assert.equal(existsSync(path.join(DIST, '.claude-plugin/marketplace.json')), false);
    assert.equal(existsSync(path.join(DIST, '.codex-plugin/plugin.json')), true);
    assert.equal(existsSync(path.join(DIST, 'skills/t-brainstorming/SKILL.md')), true);
    assert.equal(existsSync(path.join(DIST, 'hooks/hooks-cursor.json')), true);
    assert.equal(existsSync(path.join(DIST, 'README.md')), true);
    assert.equal(existsSync(path.join(DIST, 'CHANGELOG.md')), true);
    assert.equal(existsSync(path.join(DIST, 'stale.txt')), false);

    const rootPackageAfter = readFileSync(path.join(ROOT, 'package.json'), 'utf8');
    assert.equal(rootPackageAfter, rootPackageBefore);
    const rootPkg = JSON.parse(rootPackageAfter);
    assert.equal(rootPkg.name, 'superpowers');
    assert.equal(rootPkg.main, '.opencode/plugins/superpowers.js');
  });
});
