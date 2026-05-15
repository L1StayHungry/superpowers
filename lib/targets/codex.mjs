import { mkdirSync, readFileSync, statSync } from 'node:fs';
import path from 'node:path';
import { PACKAGE_NAME } from '../constants.mjs';
import { copyDirectory, exists, readJson, removePath } from '../fs-ops.mjs';
import { listSkillDirs } from '../payload.mjs';
import { hasValidInstalledAt, isManagedReceipt, readReceipt, writeReceipt } from '../receipt.mjs';

export function codexSkillsRoot(codexHome = process.env.CODEX_HOME || path.join(process.env.HOME, '.codex')) {
  return path.join(codexHome, 'skills');
}

function currentVersion(payloadRoot) {
  return readJson(path.join(payloadRoot, 'package.json')).version;
}

function skillPath(skillsRoot, skill) {
  return path.join(skillsRoot, skill);
}

function isDirectory(target) {
  try {
    return statSync(target).isDirectory();
  } catch (error) {
    if (error.code === 'ENOENT') return false;
    throw error;
  }
}

function isSafeSkillDirName(dir) {
  return dir.startsWith('t-') && !dir.includes('/') && !dir.includes('\\') && dir !== '..' && dir !== '.';
}

function assertSafeManagedDirs(managedDirs) {
  if (!Array.isArray(managedDirs)) {
    throw new Error('codex install receipt has invalid managedDirs');
  }
  for (const dir of managedDirs) {
    if (typeof dir !== 'string' || !isSafeSkillDirName(dir)) {
      throw new Error(`codex install receipt has unsafe managed dir: ${dir}`);
    }
  }
}

function managedSkillSet(receipt) {
  if (!isManagedReceipt(receipt, 'codex')) return new Set();
  assertSafeManagedDirs(receipt.managedDirs);
  return new Set(receipt.managedDirs);
}

function assertCanInstall({ skillsRoot, payloadSkills, adopt }) {
  const receipt = readReceipt(skillsRoot);
  const managed = managedSkillSet(receipt);

  for (const skill of payloadSkills) {
    const target = skillPath(skillsRoot, skill);
    if (!exists(target)) continue;
    if (managed.has(skill)) continue;
    if (adopt) continue;
    throw new Error(`codex skill exists and requires --adopt: ${target}`);
  }
}

function copyPayloadSkills({ payloadRoot, skillsRoot, payloadSkills }) {
  mkdirSync(skillsRoot, { recursive: true });

  for (const skill of payloadSkills) {
    const source = path.join(payloadRoot, 'skills', skill);
    const target = skillPath(skillsRoot, skill);
    removePath(target);
    copyDirectory(source, target);
  }
}

function hasFrontmatterField(frontmatter, field) {
  const pattern = new RegExp(`(^|\\n)${field}\\s*:\\s*\\S`, 'm');
  return pattern.test(frontmatter);
}

function validateSkillFrontmatter(skillMd, skill) {
  let contents;
  try {
    contents = readFileSync(skillMd, 'utf8');
  } catch (error) {
    if (error.code === 'ENOENT') return `missing ${skill}/SKILL.md`;
    throw error;
  }

  if (!contents.startsWith('---\n')) return `${skill}/SKILL.md is missing YAML frontmatter`;
  const end = contents.indexOf('\n---', 4);
  if (end === -1) return `${skill}/SKILL.md is missing closing frontmatter marker`;

  const frontmatter = contents.slice(4, end);
  if (!hasFrontmatterField(frontmatter, 'name')) return `${skill}/SKILL.md frontmatter is missing name`;
  if (!hasFrontmatterField(frontmatter, 'description')) {
    return `${skill}/SKILL.md frontmatter is missing description`;
  }
  return null;
}

export async function installCodex(options = {}) {
  const payloadRoot = options.payloadRoot;
  const skillsRoot = codexSkillsRoot(options.codexHome);
  const payloadSkills = listSkillDirs(payloadRoot);

  assertCanInstall({ skillsRoot, payloadSkills, adopt: options.adopt });

  if (options.dryRun) {
    return {
      target: 'codex',
      status: 'PASS',
      changed: false,
      dryRun: true,
      message: `would install Codex skills adapter to ${skillsRoot}`
    };
  }

  copyPayloadSkills({ payloadRoot, skillsRoot, payloadSkills });
  writeReceipt(skillsRoot, {
    version: currentVersion(payloadRoot),
    target: 'codex',
    managedDirs: payloadSkills
  });

  return doctorCodex({ codexHome: options.codexHome, payloadRoot });
}

export async function updateCodex(options = {}) {
  return installCodex(options);
}

export async function uninstallCodex(options = {}) {
  const skillsRoot = codexSkillsRoot(options.codexHome);
  const receipt = readReceipt(skillsRoot);

  if (!isManagedReceipt(receipt, 'codex')) {
    if (!options.adopt) {
      throw new Error(`codex skills root is not installer-managed and requires --adopt: ${skillsRoot}`);
    }
    return {
      target: 'codex',
      status: 'PASS',
      changed: false,
      message: 'no managed Codex receipt found; no skills removed'
    };
  }

  assertSafeManagedDirs(receipt.managedDirs);

  if (options.dryRun) {
    return {
      target: 'codex',
      status: 'PASS',
      changed: false,
      dryRun: true,
      message: `would remove ${receipt.managedDirs.length} managed Codex skill directories`
    };
  }

  for (const dir of receipt.managedDirs) {
    removePath(skillPath(skillsRoot, dir));
  }
  removePath(path.join(skillsRoot, '.t-superpowers-install.json'));

  return {
    target: 'codex',
    status: 'PASS',
    changed: true,
    message: 'removed managed Codex skills adapter'
  };
}

export async function doctorCodex(options = {}) {
  const skillsRoot = codexSkillsRoot(options.codexHome);
  const receipt = readReceipt(skillsRoot);

  if (!receipt) {
    return { target: 'codex', status: 'FAIL', message: 'missing codex install receipt' };
  }
  if (!isManagedReceipt(receipt, 'codex')) {
    return { target: 'codex', status: 'FAIL', message: 'codex install receipt has invalid ownership fields' };
  }
  if (receipt.package !== PACKAGE_NAME) {
    return { target: 'codex', status: 'FAIL', message: 'codex install receipt has unexpected package' };
  }
  if (!hasValidInstalledAt(receipt)) {
    return { target: 'codex', status: 'FAIL', message: 'codex install receipt has invalid installedAt' };
  }
  if (typeof receipt.version !== 'string' || receipt.version.length === 0) {
    return { target: 'codex', status: 'FAIL', message: 'codex receipt version is invalid' };
  }

  try {
    assertSafeManagedDirs(receipt.managedDirs);
  } catch (error) {
    return { target: 'codex', status: 'FAIL', message: error.message };
  }

  if (options.payloadRoot && receipt.version !== currentVersion(options.payloadRoot)) {
    return {
      target: 'codex',
      status: 'FAIL',
      message: `codex receipt version ${receipt.version} does not match payload version ${currentVersion(options.payloadRoot)}`
    };
  }

  const required = ['t-brainstorming/SKILL.md', 't-using-superpowers/SKILL.md'];
  for (const rel of required) {
    if (!exists(path.join(skillsRoot, rel))) {
      return { target: 'codex', status: 'FAIL', message: `missing ${rel}` };
    }
  }

  for (const skill of receipt.managedDirs) {
    if (!isDirectory(skillPath(skillsRoot, skill))) {
      return { target: 'codex', status: 'FAIL', message: `missing managed skill directory: ${skill}` };
    }
    const error = validateSkillFrontmatter(path.join(skillsRoot, skill, 'SKILL.md'), skill);
    if (error) return { target: 'codex', status: 'FAIL', message: error };
  }

  return {
    target: 'codex',
    status: 'WARN',
    message: 'Codex skills adapter is valid; session-start hook injection is not installed by the skills adapter',
    details: { skillCount: receipt.managedDirs.length }
  };
}
