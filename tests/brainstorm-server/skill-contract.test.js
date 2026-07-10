/** Static contract tests for the fork-specific brainstorming workflow. */

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '../..');
const SKILL = fs.readFileSync(path.join(ROOT, 'skills/t-brainstorming/SKILL.md'), 'utf-8');
const GUIDE = fs.readFileSync(path.join(ROOT, 'skills/t-brainstorming/visual-companion.md'), 'utf-8');
const START = fs.readFileSync(path.join(ROOT, 'skills/t-brainstorming/scripts/start-server.sh'), 'utf-8');
const STOP = fs.readFileSync(path.join(ROOT, 'skills/t-brainstorming/scripts/stop-server.sh'), 'utf-8');

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

console.log('\n--- Brainstorming Skill Contract ---');

test('retains the fork trigger boundary and docsDev spec path', () => {
  assert(SKILL.includes('Use ONLY for complex multi-file features'));
  assert(SKILL.includes('docsDev/changes/<change-id>/spec.md'));
  assert(!SKILL.includes('docs/superpowers/'));
  assert(!/Every project goes through this process/i.test(SKILL));
  assert(/every legitimately triggered complex project/i.test(SKILL));
  assert(!/applies to EVERY project regardless of perceived simplicity/i.test(SKILL));
});

test('waits until the first genuinely visual question to offer the companion', () => {
  assert(/first genuinely visual question/i.test(SKILL));
  assert(/do not offer.*conceptual|conceptual.*do not offer/is.test(SKILL));
  assert(!/When you anticipate that upcoming questions will involve visual content/i.test(SKILL));
  assert(!/^\d+\. \*\*Offer the visual companion/m.test(SKILL),
    'the JIT checkpoint must not be an ordered checklist step before clarification');
});

test('uses a separate opt-in question, opens on acceptance, and never repeats after refusal', () => {
  assert(/own message|separate.*question/is.test(SKILL));
  assert(/--open/.test(SKILL), 'acceptance should launch start-server.sh with --open');
  assert(SKILL.includes('skills/t-brainstorming/scripts/start-server.sh'));
  assert(/declin|refus/i.test(SKILL));
  assert(/do not (?:offer|ask) again|never (?:offer|ask) again/i.test(SKILL));
});

test('guide keeps per-question visual decisions and authenticated launch URL handling', () => {
  assert(/Decide per-question/i.test(GUIDE));
  assert(/\?key=|authenticated/i.test(GUIDE));
  assert(/--open/.test(GUIDE));
});

test('uses the fork-local t-superpowers companion cache namespace', () => {
  assert(START.includes('.t-superpowers/brainstorm/'));
  assert(![GUIDE, START, STOP].join('\n').includes('.superpowers/brainstorm/'));
  assert(GUIDE.includes('$TMPDIR/t-superpowers-brainstorm/<stable-project-id>'));
  assert(!GUIDE.includes('--project-dir /path/to/project'));
  assert(GUIDE.includes('docsDev/changes/<change-id>/transcripts/visual-companion'));
});

test('routes only to the t-prefixed planning skill', () => {
  assert(SKILL.includes('t-superpowers:t-writing-plans'));
  assert(!/invoke writing-plans/i.test(SKILL));
});

console.log(`\n--- Results: ${passed} passed, ${failed} failed ---`);
if (failed > 0) process.exit(1);
