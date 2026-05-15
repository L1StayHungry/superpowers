import { SUPPORTED_COMMANDS, SUPPORTED_TARGETS, PACKAGE_NAME } from './constants.mjs';

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

    stderr(`command dispatch not implemented yet: ${command} ${target}`);
    return 70;
  } catch (error) {
    stderr(error.message);
    return 2;
  }
}
