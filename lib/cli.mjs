import { SUPPORTED_COMMANDS, SUPPORTED_TARGETS, PACKAGE_NAME } from './constants.mjs';
import { packageRootFromModule } from './payload.mjs';
import { doctorCursor, installCursor, uninstallCursor, updateCursor } from './targets/cursor.mjs';

const TARGETS = {
  cursor: {
    install: installCursor,
    update: updateCursor,
    doctor: doctorCursor,
    uninstall: uninstallCursor
  }
};

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
    '  --scope user|project|local',
    '',
    'Examples:',
    `  npx ${PACKAGE_NAME}@latest install cursor`,
    `  npx ${PACKAGE_NAME}@latest update all`,
    `  npx ${PACKAGE_NAME}@latest doctor all`
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

async function dispatch(command, target, options) {
  const targetNames = target === 'all' ? SUPPORTED_TARGETS : [target];
  const payloadRoot = options.payloadRoot || packageRootFromModule(import.meta.url);
  const results = [];

  for (const name of targetNames) {
    const runner = TARGETS[name]?.[command];
    if (!runner) {
      results.push({ target: name, status: 'UNKNOWN', message: `${command} not implemented for ${name}` });
      continue;
    }

    try {
      results.push(await runner({ ...options, payloadRoot, home: process.env.HOME }));
    } catch (error) {
      results.push({ target: name, status: 'FAIL', message: error.message });
    }
  }

  return results;
}

function formatPlainResult(result) {
  const message = result.message ? ` ${result.message}` : '';
  return `${result.target}: ${result.status}${message}`;
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

    if (parsed.positional.length > 2) {
      stderr(`too many positional arguments: ${parsed.positional.slice(2).join(' ')}`);
      stderr(usage());
      return 2;
    }
    if (parsed.positional.length < 2) {
      stderr('expected command and target');
      stderr(usage());
      return 2;
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

    const results = await dispatch(command, target, parsed.options);
    if (parsed.options.json) {
      stdout(JSON.stringify(results, null, 2));
    } else {
      for (const result of results) stdout(formatPlainResult(result));
    }

    return results.some((result) => result.status === 'FAIL' || result.status === 'UNKNOWN') ? 1 : 0;
  } catch (error) {
    stderr(error.message);
    return 2;
  }
}
