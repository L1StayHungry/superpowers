import { readdirSync } from 'node:fs';
import path, { dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { PLUGIN_DISPLAY_NAME, PLUGIN_NAME } from './constants.mjs';
import { exists, readJson } from './fs-ops.mjs';

function hasPackageRootMarkers(dir) {
  return (
    exists(path.join(dir, 'package.json')) &&
    exists(path.join(dir, '.cursor-plugin/plugin.json')) &&
    exists(path.join(dir, 'skills'))
  );
}

function fallbackPackageRoot(moduleDir) {
  const base = path.basename(moduleDir);
  if (base === 'cli') return dirname(moduleDir);

  if (base === 'lib') return dirname(moduleDir);

  const parent = dirname(moduleDir);
  if (path.basename(parent) === 'lib') return dirname(parent);

  return dirname(moduleDir);
}

export function packageRootFromModule(metaUrl = import.meta.url) {
  const moduleDir = dirname(fileURLToPath(metaUrl));
  let current = moduleDir;

  while (true) {
    if (hasPackageRootMarkers(current)) return current;

    const parent = dirname(current);
    if (parent === current) break;
    current = parent;
  }

  return fallbackPackageRoot(moduleDir);
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
