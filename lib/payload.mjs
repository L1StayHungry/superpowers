import { readdirSync } from 'node:fs';
import path from 'node:path';
import { dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { PLUGIN_DISPLAY_NAME, PLUGIN_NAME } from './constants.mjs';
import { exists, readJson } from './fs-ops.mjs';

export function packageRootFromModule(metaUrl = import.meta.url) {
  const moduleDir = dirname(fileURLToPath(metaUrl));
  const parts = moduleDir.split(path.sep);
  const libIndex = parts.lastIndexOf('lib');

  if (libIndex !== -1) {
    const rootParts = parts.slice(0, libIndex);
    return rootParts.length === 0 ? path.sep : rootParts.join(path.sep) || path.sep;
  }

  return dirname(moduleDir);
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
  if (manifest.name !== PLUGIN_NAME) {
    throw new Error(`unexpected cursor plugin name: ${manifest.name}`);
  }
  if (manifest.displayName !== PLUGIN_DISPLAY_NAME) {
    throw new Error(`unexpected cursor displayName: ${manifest.displayName}`);
  }

  const required = [
    'skills/t-brainstorming/SKILL.md',
    'skills/t-using-superpowers/SKILL.md',
    'hooks/hooks-cursor.json',
    'hooks/session-start'
  ];

  for (const rel of required) {
    if (!exists(path.join(payloadRoot, rel))) {
      throw new Error(`missing cursor payload file: ${rel}`);
    }
  }

  return manifest;
}
