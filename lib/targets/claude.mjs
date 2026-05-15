import { mkdirSync } from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import {
  CLAUDE_MARKETPLACE_NAME,
  INTERNAL_REGISTRY,
  PACKAGE_NAME,
  PLUGIN_NAME
} from '../constants.mjs';
import { readJson, writeJson } from '../fs-ops.mjs';

const CLAUDE_PLUGIN_REF = `${PLUGIN_NAME}@${CLAUDE_MARKETPLACE_NAME}`;

export function claudeMarketplaceDir(home = process.env.HOME) {
  return path.join(home, '.t-superpowers/claude-marketplace');
}

function currentClaudePluginVersion(payloadRoot) {
  return readJson(path.join(payloadRoot, '.claude-plugin/plugin.json')).version;
}

function generatedMarketplace() {
  return {
    name: CLAUDE_MARKETPLACE_NAME,
    owner: {
      name: '4399'
    },
    metadata: {
      description: 'Internal t-superpowers marketplace'
    },
    plugins: [
      {
        name: PLUGIN_NAME,
        source: {
          source: 'npm',
          package: PACKAGE_NAME,
          registry: INTERNAL_REGISTRY
        },
        description: 'Internal t-superpowers fork for complex development workflows'
      }
    ]
  };
}

function commandString(args) {
  return `claude ${args.join(' ')}`;
}

function runClaude(args, env = process.env) {
  const result = spawnSync('claude', args, {
    env,
    encoding: 'utf8'
  });

  if (result.error) {
    if (result.error.code === 'ENOENT') {
      throw new Error('claude command is not available on PATH');
    }
    throw result.error;
  }

  if (result.status !== 0) {
    const detail = (result.stderr || result.stdout || '').trim();
    throw new Error(detail || `claude ${args.join(' ')} exited ${result.status}`);
  }

  return result.stdout || '';
}

function dryRunResult({ command, commands, message, marketplacePath }) {
  return {
    target: 'claude',
    status: 'PASS',
    changed: false,
    dryRun: true,
    message,
    details: {
      marketplacePath,
      commands: commands.map(commandString),
      command
    }
  };
}

export async function installClaude(options = {}) {
  const home = options.home || process.env.HOME;
  const env = options.env || process.env;
  const scope = options.scope || 'user';
  const marketplaceDir = claudeMarketplaceDir(home);
  const marketplacePath = path.join(marketplaceDir, '.claude-plugin/marketplace.json');
  const commands = [
    ['plugin', 'marketplace', 'add', marketplaceDir, '--scope', scope],
    ['plugin', 'install', CLAUDE_PLUGIN_REF, '--scope', scope]
  ];

  if (options.dryRun) {
    return dryRunResult({
      command: 'install',
      commands,
      marketplacePath,
      message: `would generate Claude marketplace at ${marketplacePath}`
    });
  }

  mkdirSync(path.dirname(marketplacePath), { recursive: true });
  writeJson(marketplacePath, generatedMarketplace());

  for (const args of commands) runClaude(args, env);

  return {
    target: 'claude',
    status: 'PASS',
    changed: true,
    message: 'installed Claude Code plugin through native marketplace commands',
    details: { marketplacePath }
  };
}

export async function updateClaude(options = {}) {
  const env = options.env || process.env;
  const scope = options.scope || 'user';
  const commands = [
    ['plugin', 'marketplace', 'update', CLAUDE_MARKETPLACE_NAME],
    ['plugin', 'update', CLAUDE_PLUGIN_REF, '--scope', scope]
  ];

  if (options.dryRun) {
    return dryRunResult({
      command: 'update',
      commands,
      message: 'would update Claude Code marketplace and plugin'
    });
  }

  for (const args of commands) runClaude(args, env);

  return {
    target: 'claude',
    status: 'PASS',
    changed: true,
    message: 'updated Claude Code plugin through native marketplace commands'
  };
}

export async function uninstallClaude(options = {}) {
  const env = options.env || process.env;
  const scope = options.scope || 'user';
  const commands = [['plugin', 'uninstall', CLAUDE_PLUGIN_REF, '--scope', scope]];

  if (options.dryRun) {
    return dryRunResult({
      command: 'uninstall',
      commands,
      message: 'would uninstall Claude Code plugin'
    });
  }

  for (const args of commands) runClaude(args, env);

  return {
    target: 'claude',
    status: 'PASS',
    changed: true,
    message: 'uninstalled Claude Code plugin through native plugin command'
  };
}

function parseJsonOutput(output, label) {
  try {
    return JSON.parse(output);
  } catch (error) {
    throw new Error(`claude ${label} did not return valid JSON: ${error.message}`);
  }
}

function entriesFromJson(value) {
  if (Array.isArray(value)) return value;
  if (!value || typeof value !== 'object') return [];

  for (const key of ['marketplaces', 'plugins', 'items', 'data', 'results']) {
    if (Array.isArray(value[key])) return value[key];
  }

  return [];
}

function entryName(entry) {
  if (!entry || typeof entry !== 'object') return undefined;
  return entry.name || entry.id || entry.marketplaceName || entry.pluginName;
}

function findByName(entries, name) {
  return entries.find((entry) => entryName(entry) === name);
}

function pluginMarketplace(entry) {
  if (!entry || typeof entry !== 'object') return undefined;
  if (typeof entry.marketplace === 'string') return entry.marketplace;
  if (typeof entry.marketplaceName === 'string') return entry.marketplaceName;
  if (entry.marketplace && typeof entry.marketplace.name === 'string') return entry.marketplace.name;
  if (entry.source && typeof entry.source.marketplace === 'string') return entry.source.marketplace;
  if (entry.source && typeof entry.source.marketplaceName === 'string') return entry.source.marketplaceName;
  return undefined;
}

function pluginVersion(entry) {
  if (!entry || typeof entry !== 'object') return undefined;
  for (const key of ['version', 'installedVersion', 'packageVersion']) {
    if (typeof entry[key] === 'string' && entry[key].length > 0) return entry[key];
  }
  if (entry.plugin && typeof entry.plugin.version === 'string' && entry.plugin.version.length > 0) {
    return entry.plugin.version;
  }
  return undefined;
}

export async function doctorClaude(options = {}) {
  const env = options.env || process.env;

  let marketplaceOutput;
  let pluginOutput;
  try {
    marketplaceOutput = runClaude(['plugin', 'marketplace', 'list', '--json'], env);
    pluginOutput = runClaude(['plugin', 'list', '--json'], env);
  } catch (error) {
    return { target: 'claude', status: 'FAIL', message: error.message };
  }

  let marketplaceJson;
  let pluginJson;
  try {
    marketplaceJson = parseJsonOutput(marketplaceOutput, 'plugin marketplace list --json');
    pluginJson = parseJsonOutput(pluginOutput, 'plugin list --json');
  } catch (error) {
    return { target: 'claude', status: 'FAIL', message: error.message };
  }

  const marketplace = findByName(entriesFromJson(marketplaceJson), CLAUDE_MARKETPLACE_NAME);
  if (!marketplace) {
    return { target: 'claude', status: 'FAIL', message: `missing Claude marketplace: ${CLAUDE_MARKETPLACE_NAME}` };
  }

  const plugin = findByName(entriesFromJson(pluginJson), PLUGIN_NAME);
  if (!plugin) {
    return { target: 'claude', status: 'FAIL', message: `missing Claude plugin: ${PLUGIN_NAME}` };
  }

  const marketplaceName = pluginMarketplace(plugin);
  if (marketplaceName && marketplaceName !== CLAUDE_MARKETPLACE_NAME) {
    return {
      target: 'claude',
      status: 'FAIL',
      message: `Claude plugin is installed from unexpected marketplace: ${marketplaceName}`
    };
  }

  if (!marketplaceName) {
    return {
      target: 'claude',
      status: 'UNKNOWN',
      message: 'Claude marketplace and plugin are present, but plugin marketplace association is unavailable'
    };
  }

  const actualVersion = pluginVersion(plugin);
  if (!actualVersion) {
    return {
      target: 'claude',
      status: 'UNKNOWN',
      message: 'Claude marketplace and plugin are present, but plugin version data is unavailable'
    };
  }

  if (!options.payloadRoot) {
    return {
      target: 'claude',
      status: 'UNKNOWN',
      message: 'Claude marketplace and plugin are present, but payload version is unavailable'
    };
  }

  const expectedVersion = currentClaudePluginVersion(options.payloadRoot);
  if (actualVersion !== expectedVersion) {
    return {
      target: 'claude',
      status: 'FAIL',
      message: `Claude plugin version ${actualVersion} does not match payload version ${expectedVersion}`
    };
  }

  return {
    target: 'claude',
    status: 'PASS',
    message: 'Claude Code marketplace and plugin are installed with matching version',
    details: { version: actualVersion }
  };
}
