import { after, before, test } from 'node:test';
import assert from 'node:assert/strict';
import path from 'node:path';
import { cpSync, existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { buildDistPayloadCopy, cleanup, readJson, tempDir, writeJson } from './helpers.mjs';
import { runCli } from '../../lib/cli.mjs';
import { RECEIPT_FILE } from '../../lib/constants.mjs';
import {
  codexSkillsRoot,
  doctorCodex,
  installCodex,
  uninstallCodex,
  updateCodex
} from '../../lib/targets/codex.mjs';

let payloadRoot;

before(() => {
  payloadRoot = buildDistPayloadCopy('tsp-codex-payload-');
});

after(() => {
  cleanup(payloadRoot);
});

function receiptFile(codexHome) {
  return path.join(codexSkillsRoot(codexHome), RECEIPT_FILE);
}

test('codexSkillsRoot resolves CODEX_HOME skills directory with fallback', () => {
  assert.equal(codexSkillsRoot('/tmp/example-codex'), path.join('/tmp/example-codex', 'skills'));
  assert.equal(codexSkillsRoot(''), path.join(process.env.HOME, '.codex', 'skills'));
});

test('codex install copies t skills and writes managedDirs receipt', async () => {
  const codexHome = tempDir('tsp-codex-home-');
  try {
    const result = await installCodex({ payloadRoot, codexHome, adopt: false, force: false, dryRun: false });
    assert.equal(result.status, 'WARN');
    assert.match(result.message, /session-start hook injection is not installed/);

    const skillsRoot = codexSkillsRoot(codexHome);
    assert.equal(existsSync(path.join(skillsRoot, 't-brainstorming/SKILL.md')), true);
    assert.equal(existsSync(path.join(skillsRoot, 't-using-superpowers/SKILL.md')), true);

    const receipt = readJson(receiptFile(codexHome));
    assert.equal(receipt.target, 'codex');
    assert.equal(receipt.version, readJson(path.join(payloadRoot, 'package.json')).version);
    assert.equal(receipt.managedDirs.every((dir) => dir.startsWith('t-')), true);
    assert.deepEqual([...receipt.managedDirs].sort(), receipt.managedDirs);
  } finally {
    cleanup(codexHome);
  }
});

test('codex install does not copy non-t skill directories', async () => {
  const codexHome = tempDir('tsp-codex-non-t-home-');
  const payloadCopy = tempDir('tsp-codex-non-t-payload-');
  try {
    cpSync(payloadRoot, payloadCopy, { recursive: true });
    mkdirSync(path.join(payloadCopy, 'skills/plain-skill'), { recursive: true });
    writeFileSync(path.join(payloadCopy, 'skills/plain-skill/SKILL.md'), '---\nname: plain\n---\n');

    const result = await installCodex({ payloadRoot: payloadCopy, codexHome, adopt: false, force: false, dryRun: false });
    assert.equal(result.status, 'WARN');
    assert.equal(existsSync(path.join(codexSkillsRoot(codexHome), 'plain-skill')), false);
  } finally {
    cleanup(codexHome);
    cleanup(payloadCopy);
  }
});

test('codex install refuses existing user-owned t skill without adopt and leaves it intact', async () => {
  const codexHome = tempDir('tsp-codex-user-owned-');
  try {
    const userSkill = path.join(codexSkillsRoot(codexHome), 't-brainstorming');
    mkdirSync(userSkill, { recursive: true });
    writeFileSync(path.join(userSkill, 'SKILL.md'), 'user-owned\n');

    await assert.rejects(
      installCodex({ payloadRoot, codexHome, adopt: false, force: false, dryRun: false }),
      /requires --adopt/
    );
    assert.equal(existsSync(path.join(userSkill, 'SKILL.md')), true);
    assert.equal(existsSync(receiptFile(codexHome)), false);
    assert.equal(readFileSync(path.join(userSkill, 'SKILL.md'), 'utf8'), 'user-owned\n');
  } finally {
    cleanup(codexHome);
  }
});

test('codex install with adopt replaces t-superpowers skill', async () => {
  const codexHome = tempDir('tsp-codex-adopt-');
  try {
    const userSkill = path.join(codexSkillsRoot(codexHome), 't-brainstorming');
    mkdirSync(userSkill, { recursive: true });
    writeFileSync(path.join(userSkill, 'SKILL.md'), 'user-owned\n');

    const result = await installCodex({ payloadRoot, codexHome, adopt: true, force: false, dryRun: false });
    assert.equal(result.status, 'WARN');
    assert.match(readFileSync(path.join(userSkill, 'SKILL.md'), 'utf8'), /name: t-brainstorming/);
  } finally {
    cleanup(codexHome);
  }
});

test('codex update with receipt leaves unrelated skill directories alone', async () => {
  const codexHome = tempDir('tsp-codex-update-');
  try {
    await installCodex({ payloadRoot, codexHome, adopt: false, force: false, dryRun: false });
    const unrelated = path.join(codexSkillsRoot(codexHome), 'custom-user-skill');
    mkdirSync(unrelated, { recursive: true });
    writeFileSync(path.join(unrelated, 'SKILL.md'), 'custom\n');

    const result = await updateCodex({ payloadRoot, codexHome, adopt: false, force: false, dryRun: false });
    assert.equal(result.status, 'WARN');
    assert.equal(readFileSync(path.join(unrelated, 'SKILL.md'), 'utf8'), 'custom\n');
  } finally {
    cleanup(codexHome);
  }
});

test('codex update prunes stale receipt-managed skills and leaves unrelated user skills alone', async () => {
  const codexHome = tempDir('tsp-codex-update-prune-');
  const payloadWithRetired = tempDir('tsp-codex-retired-payload-');
  try {
    cpSync(payloadRoot, payloadWithRetired, { recursive: true });
    const retiredSkill = path.join(payloadWithRetired, 'skills/t-retired');
    mkdirSync(retiredSkill, { recursive: true });
    writeFileSync(path.join(retiredSkill, 'SKILL.md'), '---\nname: t-retired\ndescription: retired test skill\n---\n');

    await installCodex({ payloadRoot: payloadWithRetired, codexHome, adopt: false, force: false, dryRun: false });

    const skillsRoot = codexSkillsRoot(codexHome);
    const unrelated = path.join(skillsRoot, 'custom-user-skill');
    mkdirSync(unrelated, { recursive: true });
    writeFileSync(path.join(unrelated, 'SKILL.md'), 'custom\n');

    const result = await updateCodex({ payloadRoot, codexHome, adopt: false, force: false, dryRun: false });
    assert.equal(result.status, 'WARN');
    assert.equal(existsSync(path.join(skillsRoot, 't-retired')), false);
    assert.equal(readFileSync(path.join(unrelated, 'SKILL.md'), 'utf8'), 'custom\n');

    const receipt = readJson(receiptFile(codexHome));
    assert.equal(receipt.managedDirs.includes('t-retired'), false);
  } finally {
    cleanup(codexHome);
    cleanup(payloadWithRetired);
  }
});

test('codex doctor warns about missing session-start hook injection', async () => {
  const codexHome = tempDir('tsp-codex-doctor-warn-');
  try {
    await installCodex({ payloadRoot, codexHome, adopt: false, force: false, dryRun: false });
    const result = await doctorCodex({ codexHome, payloadRoot });
    assert.equal(result.status, 'WARN');
    assert.match(result.message, /session-start hook injection is not installed/);
  } finally {
    cleanup(codexHome);
  }
});

test('codex doctor fails for missing receipt', async () => {
  const codexHome = tempDir('tsp-codex-missing-receipt-');
  try {
    await installCodex({ payloadRoot, codexHome, adopt: false, force: false, dryRun: false });
    rmSync(receiptFile(codexHome));

    const result = await doctorCodex({ codexHome, payloadRoot });
    assert.equal(result.status, 'FAIL');
    assert.match(result.message, /missing codex install receipt/);
  } finally {
    cleanup(codexHome);
  }
});

test('codex doctor fails for missing required skill', async () => {
  const codexHome = tempDir('tsp-codex-missing-required-');
  try {
    await installCodex({ payloadRoot, codexHome, adopt: false, force: false, dryRun: false });
    rmSync(path.join(codexSkillsRoot(codexHome), 't-brainstorming'), { recursive: true, force: true });

    const result = await doctorCodex({ codexHome, payloadRoot });
    assert.equal(result.status, 'FAIL');
    assert.match(result.message, /missing t-brainstorming\/SKILL.md/);
  } finally {
    cleanup(codexHome);
  }
});

test('codex doctor fails for malformed frontmatter name or description', async () => {
  const cases = [
    ['missing frontmatter', 'name: t-bad\n'],
    ['missing name', '---\ndescription: desc\n---\n'],
    ['missing description', '---\nname: t-bad\n---\n']
  ];

  for (const [name, contents] of cases) {
    const codexHome = tempDir(`tsp-codex-frontmatter-${name.replaceAll(' ', '-')}-`);
    try {
      await installCodex({ payloadRoot, codexHome, adopt: false, force: false, dryRun: false });
      writeFileSync(path.join(codexSkillsRoot(codexHome), 't-brainstorming/SKILL.md'), contents);

      const result = await doctorCodex({ codexHome, payloadRoot });
      assert.equal(result.status, 'FAIL');
      assert.match(result.message, /frontmatter|name|description/);
    } finally {
      cleanup(codexHome);
    }
  }
});

test('codex doctor fails for missing or invalid receipt version', async () => {
  const cases = [
    ['missing', undefined],
    ['empty', ''],
    ['non-string', 123]
  ];

  for (const [name, version] of cases) {
    const codexHome = tempDir(`tsp-codex-version-${name}-`);
    try {
      await installCodex({ payloadRoot, codexHome, adopt: false, force: false, dryRun: false });
      const receipt = readJson(receiptFile(codexHome));
      if (version === undefined) delete receipt.version;
      else receipt.version = version;
      writeJson(receiptFile(codexHome), receipt);

      const result = await doctorCodex({ codexHome });
      assert.equal(result.status, 'FAIL');
      assert.match(result.message, /receipt version/);
    } finally {
      cleanup(codexHome);
    }
  }
});

test('codex doctor fails for malformed receipt ownership fields', async () => {
  const cases = [
    ['source', 'local'],
    ['managedBy', 'someone-else'],
    ['installedAt', 'not-a-date']
  ];

  for (const [field, value] of cases) {
    const codexHome = tempDir(`tsp-codex-bad-receipt-${field}-`);
    try {
      await installCodex({ payloadRoot, codexHome, adopt: false, force: false, dryRun: false });
      writeJson(receiptFile(codexHome), { ...readJson(receiptFile(codexHome)), [field]: value });

      const result = await doctorCodex({ codexHome, payloadRoot });
      assert.equal(result.status, 'FAIL');
      assert.match(result.message, /receipt/);
    } finally {
      cleanup(codexHome);
    }
  }
});

test('codex uninstall managed removes only receipt-managed skills and leaves unrelated user skill', async () => {
  const codexHome = tempDir('tsp-codex-uninstall-');
  try {
    await installCodex({ payloadRoot, codexHome, adopt: false, force: false, dryRun: false });
    const unrelated = path.join(codexSkillsRoot(codexHome), 'custom-user-skill');
    mkdirSync(unrelated, { recursive: true });
    writeFileSync(path.join(unrelated, 'SKILL.md'), 'custom\n');

    const result = await uninstallCodex({ codexHome, adopt: false, dryRun: false });
    assert.equal(result.status, 'PASS');
    assert.equal(existsSync(path.join(codexSkillsRoot(codexHome), 't-brainstorming')), false);
    assert.equal(existsSync(unrelated), true);
    assert.equal(existsSync(receiptFile(codexHome)), false);
  } finally {
    cleanup(codexHome);
  }
});

test('codex dryRun does not create skills root or call doctor', async () => {
  const codexHome = tempDir('tsp-codex-dry-run-');
  try {
    const result = await installCodex({ payloadRoot, codexHome, adopt: false, force: false, dryRun: true });
    assert.equal(result.status, 'PASS');
    assert.equal(result.changed, false);
    assert.equal(result.dryRun, true);
    assert.equal(existsSync(codexSkillsRoot(codexHome)), false);
  } finally {
    cleanup(codexHome);
  }
});

test('CLI doctor codex honors CODEX_HOME env', async () => {
  const codexHome = tempDir('tsp-codex-cli-');
  const originalCodexHome = process.env.CODEX_HOME;
  try {
    await installCodex({ payloadRoot, codexHome, adopt: false, force: false, dryRun: false });
    process.env.CODEX_HOME = codexHome;
    const writes = [];
    const code = await runCli(['doctor', 'codex', '--json'], {
      stdout: (line) => writes.push(line),
      stderr: () => {}
    });

    assert.equal(code, 0);
    const output = JSON.parse(writes.join('\n'));
    assert.equal(output.results[0].target, 'codex');
    assert.equal(output.results[0].status, 'WARN');
  } finally {
    if (originalCodexHome === undefined) delete process.env.CODEX_HOME;
    else process.env.CODEX_HOME = originalCodexHome;
    cleanup(codexHome);
  }
});
