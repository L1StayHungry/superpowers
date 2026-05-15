# NPM Installer Smoke

Date: 2026-05-15

## Build

- Result: PASS
- Command: `npm run build`
- Exit code: 0
- Observation: `dist/npm-package/package.json` was generated with `name: "@4399/tdata-t-superpowers"` and `version: "5.1.0"`. `dist/npm-package/.claude-plugin/plugin.json` exists; `dist/npm-package/.claude-plugin/marketplace.json` is absent.

## Pack

- Result: PASS
- Command: `npm pack ./dist/npm-package --dry-run`
- Exit code: 0
- Observation: dry-run tarball was `@4399/tdata-t-superpowers@5.1.0`, filename `4399-tdata-t-superpowers-5.1.0.tgz`, 72 files, package size 151.3 kB. Tarball contents included `.claude-plugin/plugin.json` and did not include `.claude-plugin/marketplace.json`.

## Tarball Install Smoke

- Result: PASS
- Command:
  - `npm pack ./dist/npm-package`
  - `npm install /Users/lihuajun/WorkProject/superpowers/4399-tdata-t-superpowers-5.1.0.tgz` inside a temporary npm project
  - `HOME=<tmp> node_modules/.bin/tdata-t-superpowers install cursor --json`
  - `HOME=<tmp> node_modules/.bin/tdata-t-superpowers doctor cursor --json`
  - `CODEX_HOME=<tmp> node_modules/.bin/tdata-t-superpowers install codex --json`
  - `CODEX_HOME=<tmp> node_modules/.bin/tdata-t-superpowers doctor codex --json`
  - `HOME=<tmp> node_modules/.bin/tdata-t-superpowers install claude --dry-run --json`
- Exit code: 0
- Observation: Cursor doctor returned `PASS`, installed a physical directory, and found 15 `t-*` skill directories. Codex doctor returned the expected `WARN` and found 15 managed skill directories. Claude dry-run returned `PASS` and reported the generated internal marketplace path without writing real user config.
- Published registry package: NOT RUN. This verifies the generated tarball, not `npx @4399/tdata-t-superpowers@latest`.

## Cursor

- Result: PASS
- Command:
  - `HOME=<tmp> node dist/npm-package/cli/tdata-t-superpowers.js install cursor`
  - `HOME=<tmp> node dist/npm-package/cli/tdata-t-superpowers.js doctor cursor`
  - `test -f <tmp>/.cursor/plugins/local/t-superpowers/skills/t-brainstorming/SKILL.md`
- Exit code:
  - install: 0
  - doctor: 0
  - skill file check: 0
- Observation: both install and doctor reported `cursor: PASS - disk-level Cursor install is valid; restart Cursor and open a new Agent session`. Installed target was a physical directory (`symlink=no`) with 15 `t-*` skill directories.
- Real Cursor home: NOT RUN. This smoke used a temporary `HOME` only.

## Claude Code

- Result: PASS
- Command:
  - `node --test tests/npm-installer/claude.test.mjs`
  - `HOME=<tmp> node dist/npm-package/cli/tdata-t-superpowers.js install claude --dry-run --scope user`
- Exit code:
  - stub tests: 0
  - built CLI dry-run: 0
- Observation: Claude stub tests passed 11/11, covering install/update/uninstall/doctor command behavior. Built CLI dry-run reported `claude: PASS - would generate Claude marketplace at <tmp>/.t-superpowers/claude-marketplace/.claude-plugin/marketplace.json` and did not write the marketplace file.
- Published npm command: NOT RUN. `npx @4399/tdata-t-superpowers@latest install claude` requires a published internal package and was not verified in this local smoke.

## Codex

- Result: WARN
- Command:
  - `CODEX_HOME=<tmp> node dist/npm-package/cli/tdata-t-superpowers.js install codex`
  - `CODEX_HOME=<tmp> node dist/npm-package/cli/tdata-t-superpowers.js doctor codex`
  - `test -f <tmp>/skills/t-brainstorming/SKILL.md`
- Exit code:
  - install: 0
  - doctor: 0
  - skill file check: 0
- Observation: both install and doctor reported `codex: WARN - Codex skills adapter is valid; session-start hook injection is not installed by the skills adapter`. Receipt managed 15 `t-*` skill directories. WARN is expected because this adapter intentionally does not install Codex session-start hooks.

## Repository Guardrails

- Result: PASS
- Commands:
  - `npm run test:npm-installer -- --test-reporter=spec`
  - `git diff --check`
  - `bash tools/t-stage1-check.sh`
  - `rg -n 'docs/superpowers/(specs|plans)' skills hooks .claude-plugin .cursor-plugin .codex-plugin README.md docsDev/getting-started.md`
- Exit code:
  - npm installer tests: 0
  - git diff check: 0
  - stage 1 check: 0
  - old-path grep: 1
- Observation: npm installer suite passed 67/67. Stage 1 guardrail printed `OK: Stage 1 migration self-check passed`. Old-path grep returned no matches, so exit 1 is expected for the grep command.
