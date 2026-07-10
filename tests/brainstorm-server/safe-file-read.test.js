const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');

const TEST_DIR = fs.mkdtempSync(path.join(os.tmpdir(), 'brainstorm-safe-read-'));
const CONTENT_DIR = path.join(TEST_DIR, 'content');
const OUTSIDE_FILE = path.join(TEST_DIR, 'outside-secret.txt');
fs.mkdirSync(CONTENT_DIR);
fs.writeFileSync(OUTSIDE_FILE, 'outside secret');
process.env.BRAINSTORM_DIR = TEST_DIR;

const {
  readContentFileSafely
} = require('../../skills/t-brainstorming/scripts/server.cjs');

let passed = 0;
let failed = 0;

function test(name, fn) {
  try {
    fn();
    console.log(`  PASS: ${name}`);
    passed++;
  } catch (error) {
    console.log(`  FAIL: ${name}`);
    console.log(`    ${error.message}`);
    failed++;
  }
}

console.log('\n--- Safe content-file reads ---');

test('reads a regular single-link file from the opened descriptor', () => {
  const candidate = path.join(CONTENT_DIR, 'screen.html');
  fs.writeFileSync(candidate, '<h1>safe</h1>');
  const result = readContentFileSafely(candidate, 'utf8');
  assert(result, 'safe file should be readable');
  assert.strictEqual(result.data, '<h1>safe</h1>');
  assert(result.stat.isFile());
});

test('repeatably rejects a symlink swap between validation and open', () => {
  const candidate = path.join(CONTENT_DIR, 'swap.txt');
  for (let i = 0; i < 25; i++) {
    try { fs.unlinkSync(candidate); } catch (error) {}
    fs.writeFileSync(candidate, `safe-${i}`);
    const result = readContentFileSafely(candidate, 'utf8', {
      beforeOpen() {
        fs.unlinkSync(candidate);
        fs.symlinkSync(OUTSIDE_FILE, candidate);
      }
    });
    assert.strictEqual(result, null, `iteration ${i} must fail closed`);
  }
});

test('repeatably rejects rename replacement after open', () => {
  const candidate = path.join(CONTENT_DIR, 'rename.txt');
  const openedFile = path.join(CONTENT_DIR, 'opened.txt');
  for (let i = 0; i < 25; i++) {
    for (const file of [candidate, openedFile]) {
      try { fs.unlinkSync(file); } catch (error) {}
    }
    fs.writeFileSync(candidate, `safe-${i}`);
    const result = readContentFileSafely(candidate, 'utf8', {
      afterOpen() {
        fs.renameSync(candidate, openedFile);
        fs.writeFileSync(candidate, `replacement-${i}`);
      }
    });
    assert.strictEqual(result, null, `iteration ${i} must fail closed`);
  }
});

fs.rmSync(TEST_DIR, { recursive: true, force: true });
console.log(`\n--- Results: ${passed} passed, ${failed} failed ---`);
if (failed > 0) process.exit(1);
