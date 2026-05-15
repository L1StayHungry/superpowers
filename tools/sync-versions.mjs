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

function get(value, keyPath) {
  return keyPath.reduce((cursor, key) => cursor?.[key], value);
}

function set(value, keyPath, nextValue) {
  let cursor = value;
  for (let i = 0; i < keyPath.length - 1; i += 1) {
    cursor = cursor[keyPath[i]];
  }
  cursor[keyPath.at(-1)] = nextValue;
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
    const arg = argv[i];
    if (arg === '--repo') {
      i += 1;
      if (!argv[i]) throw new Error(usage());
      options.repo = path.resolve(argv[i]);
    } else if (arg === '--check') {
      options.check = true;
    } else if (arg === '--set') {
      i += 1;
      if (!argv[i]) throw new Error(usage());
      options.setVersion = argv[i];
    } else {
      throw new Error(`unknown argument: ${arg}`);
    }
  }

  if (options.check === Boolean(options.setVersion)) {
    throw new Error(usage());
  }

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
