---
change_id: 20260515-npm-installer-distribution
created_at: 2026-05-15T02:43:59Z
updated_at: 2026-05-15T03:27:36Z
owner: lihuajun
---

# NPM Installer Distribution Spec

## Change History

- 2026-05-15: Initial design for distributing `t-superpowers` through an internal npm package with explicit installers for Cursor, Claude Code, and Codex.
- 2026-05-15: Added implementation guardrails for Cursor preflight, dev marketplace exclusion, version sync, receipt shape, and Codex hook limitations.
- 2026-05-15: Updated Cursor context after physical-directory smoke succeeded and symlink install remained blocked.

## Context

This change is a distribution sub-item. It is not part of the stage-two trigger convergence, path migration, or long-term spec library work, and it must not block the acceptance of those stage-two items.

Local Cursor plugin testing showed that `/add-plugin /Users/lihuajun/WorkProject/superpowers` can create a symlink and validate the manifest, but the active Cursor Agent runtime still did not expose `t-superpowers` skills after a full Cursor restart. The team needs a production distribution path that does not depend on a local repository symlink or per-user manual copying.

The minimal Cursor physical-directory reproduction has now passed: after replacing the symlink with a real directory under `~/.cursor/plugins/local/t-superpowers`, Cursor listed `T Superpowers` as a local plugin with 15 skills and `/t-brainstorming` entered the expected workflow. This makes "copy a physical plugin directory" a required Cursor installer behavior, not just an implementation preference.

The internal package name is:

```text
@4399/tdata-t-superpowers
```

The design borrows the useful release discipline from `AiResoures`: internal npm registry usage, explicit release commands, changelog/version bumping, and publish scripts. It does not copy the `AiResoures` Gitea archive model because `t-superpowers` is a plugin bundle, not a project asset sync system.

## Goals

- Publish a production npm package named `@4399/tdata-t-superpowers`.
- Provide an explicit installer CLI for Cursor, Claude Code, and Codex.
- Support install, update, doctor, and uninstall flows for each target.
- Avoid relying on Cursor `/add-plugin <local-repo-path>` for normal team usage.
- Preserve `t-superpowers` namespace and existing `t-*` skills.
- Keep installation deterministic, diagnosable, and reversible.
- Protect user-owned files by only overwriting installer-managed targets unless the user passes an explicit force/adopt option.

## Non-Goals

- Do not add npm `postinstall` side effects.
- Do not implement a Cursor marketplace in this change.
- Do not assume Codex has a stable npm plugin marketplace until smoke evidence proves it.
- Do not change `t-*` skill behavior, trigger descriptions, or archive policy.
- Do not modify `vendor/superpowers/`.
- Do not integrate this package into `ai-assets` yet.
- Do not write new runtime artifacts under `docs/superpowers/` or `openspec/`.
- Do not archive this change until the installer is implemented, npm-based smoke is recorded, and the user explicitly requests archive.

## Package Shape

The repository build creates a clean npm package directory:

```text
dist/npm-package/
  package.json
  cli/tdata-t-superpowers.js
  lib/
  .cursor-plugin/plugin.json
  .claude-plugin/plugin.json
  .codex-plugin/plugin.json
  skills/
  agents/
  commands/
  hooks/
  assets/
  LICENSE
  README.md
  CHANGELOG.md
```

`dist/npm-package` is both the npm package root and the plugin root. This lets Claude Code consume the npm package as a plugin source while the CLI can also copy the same payload into Cursor and Codex-specific locations.

The npm `package.json` declares:

```json
{
  "name": "@4399/tdata-t-superpowers",
  "version": "<semver>",
  "type": "module",
  "bin": {
    "tdata-t-superpowers": "cli/tdata-t-superpowers.js"
  },
  "files": [
    "cli/",
    "lib/",
    ".cursor-plugin/",
    ".claude-plugin/plugin.json",
    ".codex-plugin/",
    "skills/",
    "agents/",
    "commands/",
    "hooks/",
    "assets/",
    "LICENSE",
    "README.md",
    "CHANGELOG.md"
  ]
}
```

The CLI path uses `cli/` rather than `bin/` so Claude Code does not treat the installer as a plugin executable directory.

The production npm package must not include `.claude-plugin/marketplace.json`. The repository's existing `.claude-plugin/marketplace.json` is a development marketplace with `name: "t-superpowers-dev"` and `source: "./"`. Packaging it into npm would create a misleading second marketplace on user machines. The build must copy `.claude-plugin/plugin.json` only.

## CLI Commands

Primary usage:

```bash
npx @4399/tdata-t-superpowers@latest install cursor
npx @4399/tdata-t-superpowers@latest install claude
npx @4399/tdata-t-superpowers@latest install codex
npx @4399/tdata-t-superpowers@latest install all

npx @4399/tdata-t-superpowers@latest update all
npx @4399/tdata-t-superpowers@latest doctor all
npx @4399/tdata-t-superpowers@latest uninstall cursor
```

Supported targets:

```text
cursor
claude
codex
all
```

Common options:

```text
--force          Replace an existing installer-managed target even when versions match.
--adopt          Allow replacing an existing t-superpowers target that lacks an install receipt.
--dry-run        Print planned writes and commands without mutating files.
--json           Emit machine-readable output.
```

Claude-only option:

```text
--scope user|project|local
```

The default Claude scope is `user`.

## Installation Receipt

File-copy targets write an install receipt so future updates know which files are managed:

```json
{
  "package": "@4399/tdata-t-superpowers",
  "version": "5.1.0",
  "target": "cursor",
  "installedAt": "2026-05-15T02:43:59Z",
  "source": "npm",
  "managedBy": "tdata-t-superpowers",
  "managedDirs": [
    "."
  ]
}
```

Cursor uses `managedDirs: ["."]` because the whole installed plugin directory is installer-managed. Codex uses `managedDirs` with each managed `t-*` skill directory, such as `["t-brainstorming", "t-using-superpowers"]`. The receipt must not expand every file into a large `managedFiles` list.

Targets without a receipt are treated as user-owned. If they still identify as `t-superpowers`, installation may continue only with `--adopt`. If they identify as another plugin, installation fails and does not mutate files.

## Cursor Install

Default target:

```text
~/.cursor/plugins/local/t-superpowers
```

`install cursor` copies the production plugin payload into that directory. It does not create a symlink to the development checkout.

Behavior:

- If the target does not exist, copy into a temporary sibling directory and rename into place.
- If the target is a symlink, remove only the symlink, not its destination, and require `--adopt` unless a receipt proves it was installer-managed.
- If the target has a receipt from `@4399/tdata-t-superpowers`, replace it with the current package payload.
- If the target has `.cursor-plugin/plugin.json` with `name: "t-superpowers"` but no receipt, require `--adopt`.
- If the target belongs to another plugin, fail.
- After installation, run the same checks as `doctor cursor`.

`doctor cursor` checks:

- `~/.cursor/plugins/local/t-superpowers/.cursor-plugin/plugin.json` exists and parses.
- Manifest `name` is `t-superpowers`.
- Manifest `displayName` is `T-Superpowers`.
- `skills/t-brainstorming/SKILL.md` exists.
- `skills/t-using-superpowers/SKILL.md` exists.
- `hooks/hooks-cursor.json` exists.
- `hooks/session-start` exists and is executable.
- The install receipt version matches the package version.

The doctor command cannot prove that the Cursor UI has loaded the plugin. It must report disk-level success and instruct the user to restart Cursor or open a new Agent session before running an app smoke prompt.

## Claude Code Install

Claude Code should use its native plugin system instead of direct cache writes.

`install claude` creates or updates a local generated marketplace directory, for example:

```text
~/.t-superpowers/claude-marketplace/
  .claude-plugin/marketplace.json
```

Marketplace content:

```json
{
  "name": "t-superpowers-internal",
  "owner": {
    "name": "4399"
  },
  "metadata": {
    "description": "Internal t-superpowers marketplace"
  },
  "plugins": [
    {
      "name": "t-superpowers",
      "source": {
        "source": "npm",
        "package": "@4399/tdata-t-superpowers",
        "registry": "https://registry-npm.gz4399.com/"
      },
      "description": "Internal t-superpowers fork for complex development workflows"
    }
  ]
}
```

Then the CLI runs:

```bash
claude plugin marketplace add ~/.t-superpowers/claude-marketplace --scope user
claude plugin install t-superpowers@t-superpowers-internal --scope user
```

If `--scope project` or `--scope local` is provided, the installer passes that scope through to both marketplace and plugin installation where Claude Code supports it.

`update claude` runs:

```bash
claude plugin marketplace update t-superpowers-internal
claude plugin update t-superpowers@t-superpowers-internal --scope <scope>
```

`doctor claude` checks:

- `claude` is available on `PATH`.
- `claude plugin marketplace list --json` includes `t-superpowers-internal`.
- `claude plugin list --json` includes `t-superpowers`.
- The installed version matches `.claude-plugin/plugin.json` from the npm package when the Claude CLI exposes version data.
- If version data is unavailable, the doctor reports `UNKNOWN` rather than guessing.

Claude Code supports npm plugin sources in marketplace entries and resolves updates using the plugin version. Therefore this package must bump `.claude-plugin/plugin.json` on every release.

## Codex Install

Codex support starts with a skills adapter because the stable local plugin marketplace path is not yet proven for Codex CLI, Codex IDE extension, or Codex App.

Default target:

```text
${CODEX_HOME:-~/.codex}/skills/
```

`install codex` copies:

```text
skills/t-* -> ${CODEX_HOME:-~/.codex}/skills/t-*
```

It also writes:

```text
${CODEX_HOME:-~/.codex}/skills/.t-superpowers-install.json
```

Behavior:

- Only directories listed in the receipt are updated or removed.
- Existing `t-*` skill directories without a matching receipt are treated as user-owned and require `--adopt`.
- If a skill directory belongs to another package or has unknown contents, installation fails unless `--adopt` is supplied.
- `CODEX_HOME` is respected for isolated smoke tests.

`doctor codex` checks:

- `${CODEX_HOME:-~/.codex}/skills/t-brainstorming/SKILL.md` exists.
- `${CODEX_HOME:-~/.codex}/skills/t-using-superpowers/SKILL.md` exists.
- Every installed `t-*` skill has valid YAML frontmatter with `name` and `description`.
- The receipt exists and matches the package version.

This path does not install Codex hooks or plugin metadata. The repository currently keeps `.codex-plugin/plugin.json` with `hooks: []`, and the stable user-level Codex hook installation path has not been proven for Codex CLI, Codex IDE extension, or Codex App. The skills adapter therefore guarantees skill availability only; it does not provide session-start injection.

`doctor codex` must report this limitation as `WARN` when the skills adapter is installed successfully. README guidance must say that Codex session-start injection requires a future verified Codex plugin path, not the current skills adapter.

A future `--experimental-plugin` mode may copy `.codex-plugin/plugin.json` and Codex hook metadata into a Codex plugin cache only after smoke evidence proves the runtime recognizes that form.

## Update Model

Team update command:

```bash
npx @4399/tdata-t-superpowers@latest update all
npx @4399/tdata-t-superpowers@latest doctor all
```

Update behavior:

- If no prior receipt exists, `update` behaves like `install` and applies the same safety checks.
- If the installed version equals the running package version, update is a no-op unless `--force` is passed.
- If the installed version differs, the installer replaces only managed files.
- Cursor and Codex file-copy updates create backups under:

```text
~/.t-superpowers/backups/cursor/<timestamp>-<old-version>/
~/.t-superpowers/backups/codex/<timestamp>-<old-version>/
```

Claude updates are delegated to `claude plugin update` because Claude Code manages its plugin cache and orphan cleanup.

## Build And Release

Build command:

```bash
npm run build
```

Expected build steps:

1. Remove `dist/npm-package/`.
2. Copy allowlisted plugin files into `dist/npm-package/`.
3. Generate npm `package.json` with package name `@4399/tdata-t-superpowers`.
4. Copy `.claude-plugin/plugin.json` only; do not copy the development `.claude-plugin/marketplace.json`.
5. Copy or generate `CHANGELOG.md` for internal package releases.
6. Validate that version fields are synchronized across:
   - root `package.json`
   - `.cursor-plugin/plugin.json`
   - `.claude-plugin/plugin.json`
   - `.codex-plugin/plugin.json`
   - `.claude-plugin/marketplace.json` when kept for local development
   - generated `dist/npm-package/package.json`
7. Run `npm pack --dry-run ./dist/npm-package`.

Version synchronization should be implemented by a single-purpose lightweight script, for example `tools/sync-versions.mjs`, and called from build or release workflows. The script may update version fields only. It must not change root `package.json` fields such as:

```json
{
  "name": "superpowers",
  "main": ".opencode/plugins/superpowers.js"
}
```

Those fields remain upstream-compatible live-surface exceptions and are covered by `tools/t-stage1-check.sh`.

Publish command:

```bash
npm publish ./dist/npm-package --access restricted --registry https://registry-npm.gz4399.com/
```

The repository should keep upstream `RELEASE-NOTES.md` separate from internal npm release notes. Internal releases should use a dedicated `CHANGELOG.md` in this fork.

## Requirements

### Requirement: Build Produces A Clean NPM Package

The build must produce a package root that can act as both npm package and plugin root.

#### Scenario: Build package layout

- Given the repository has synchronized manifest versions
- When `npm run build` runs
- Then `dist/npm-package/package.json` has `name: "@4399/tdata-t-superpowers"`
- And `.cursor-plugin/plugin.json`, `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`, `skills/`, `agents/`, `commands/`, `hooks/`, and `assets/` exist under `dist/npm-package/`
- And `dist/npm-package/.claude-plugin/marketplace.json` does not exist
- And `npm pack --dry-run ./dist/npm-package` succeeds

#### Scenario: Version sync preserves root package identity

- Given the root `package.json` has `name: "superpowers"` and `main: ".opencode/plugins/superpowers.js"`
- When the version synchronization script runs
- Then only version fields are changed
- And root `package.json` still has `name: "superpowers"`
- And root `package.json` still has `main: ".opencode/plugins/superpowers.js"`

### Requirement: Cursor Installs From NPM Payload

The installer must install Cursor from the npm payload, not from the development repository.

#### Scenario: Fresh Cursor install

- Given `~/.cursor/plugins/local/t-superpowers` does not exist
- When `npx @4399/tdata-t-superpowers@latest install cursor` runs
- Then `~/.cursor/plugins/local/t-superpowers/.cursor-plugin/plugin.json` exists
- And `skills/t-brainstorming/SKILL.md` exists under the installed plugin
- And `.t-superpowers-install.json` records the package version

#### Scenario: Cursor update replaces managed install

- Given `~/.cursor/plugins/local/t-superpowers/.t-superpowers-install.json` records an older package version
- When `npx @4399/tdata-t-superpowers@latest update cursor` runs
- Then the installed plugin version matches the running npm package version
- And the previous managed install is backed up under `~/.t-superpowers/backups/cursor/`

### Requirement: Claude Code Installs Through Native Plugin Commands

The installer must use Claude Code marketplace and plugin commands instead of writing directly to Claude's plugin cache.

#### Scenario: Claude install creates npm-source marketplace

- Given `claude` is available on `PATH`
- When `npx @4399/tdata-t-superpowers@latest install claude` runs
- Then the generated marketplace contains npm source package `@4399/tdata-t-superpowers`
- And the installer runs `claude plugin marketplace add`
- And the installer runs `claude plugin install t-superpowers@t-superpowers-internal`

#### Scenario: Claude update delegates to Claude Code

- Given `t-superpowers@t-superpowers-internal` is installed
- When `npx @4399/tdata-t-superpowers@latest update claude` runs
- Then the installer runs `claude plugin marketplace update t-superpowers-internal`
- And the installer runs `claude plugin update t-superpowers@t-superpowers-internal`

### Requirement: Codex Installs Skills Adapter

The installer must provide a Codex skills distribution path without assuming unverified plugin marketplace support.

#### Scenario: Fresh Codex skills install

- Given `${CODEX_HOME:-~/.codex}/skills/t-brainstorming` does not exist
- When `npx @4399/tdata-t-superpowers@latest install codex` runs
- Then `${CODEX_HOME:-~/.codex}/skills/t-brainstorming/SKILL.md` exists
- And `${CODEX_HOME:-~/.codex}/skills/t-using-superpowers/SKILL.md` exists
- And `${CODEX_HOME:-~/.codex}/skills/.t-superpowers-install.json` records the package version
- And `doctor codex` reports `WARN` that session-start hook injection is not installed by the skills adapter

#### Scenario: Codex update only touches managed skills

- Given the Codex install receipt lists installer-managed `t-*` skill directories in `managedDirs`
- When `npx @4399/tdata-t-superpowers@latest update codex` runs
- Then only receipt-managed skill directories are replaced
- And unrelated user skills are not changed

### Requirement: Doctor Commands Classify Install Health

Each doctor command must return a deterministic status for the target it checks.

#### Scenario: Doctor all summarizes targets

- Given Cursor, Claude Code, and Codex installs are present
- When `npx @4399/tdata-t-superpowers@latest doctor all --json` runs
- Then the output includes one result for each target
- And each result is one of `PASS`, `WARN`, `FAIL`, or `UNKNOWN`
- And `UNKNOWN` is used when a runtime does not expose enough data to prove registration

### Requirement: Installer Protects User-Owned Targets

The installer must not overwrite unknown existing plugin or skill directories by default.

#### Scenario: Cursor target without receipt requires adopt

- Given `~/.cursor/plugins/local/t-superpowers` exists without `.t-superpowers-install.json`
- When `npx @4399/tdata-t-superpowers@latest install cursor` runs without `--adopt`
- Then the command exits non-zero
- And the existing directory is not modified

#### Scenario: Codex skill without receipt requires adopt

- Given `${CODEX_HOME:-~/.codex}/skills/t-brainstorming` exists without a matching receipt
- When `npx @4399/tdata-t-superpowers@latest install codex` runs without `--adopt`
- Then the command exits non-zero
- And the existing skill directory is not modified

## Error Handling

- Missing npm registry configuration must produce a clear message that includes `@4399:registry=https://registry-npm.gz4399.com/`.
- Missing `claude` binary must mark Claude install as `FAIL` and must not affect Cursor or Codex install when target is `all`.
- File-copy installs must write to a temporary directory first, then rename into place.
- If rename fails, the installer must leave the previous install intact and report the temporary path for manual cleanup.
- `--dry-run` must not create, modify, or delete files.

## Validation

Implementation must include:

- A recorded Cursor physical-directory smoke result showing that a non-symlink local plugin directory exposes `t-*` skills in Cursor Agent.
- Unit tests for package layout validation.
- Unit tests for Cursor install/update/doctor against a temporary `HOME`.
- Unit tests for Codex install/update/doctor against a temporary `CODEX_HOME`.
- A Claude installer test using a stub `claude` binary that records invoked commands.
- `npm pack --dry-run ./dist/npm-package`.
- `bash tools/t-stage1-check.sh`.
- `git diff --check`.
- A manual Cursor smoke after installing from npm:
  - simple copy prompt does not enter `t-brainstorming`
  - explicit `t-superpowers` prompt enters `t-brainstorming` or equivalent `t-superpowers` behavior
- A Claude Code CLI smoke after installing from npm marketplace.
- A Codex skills smoke after installing through the skills adapter.

## Risks

- Cursor did not expose skills when installed through a symlink created by `/add-plugin /Users/lihuajun/WorkProject/superpowers`, but did expose skills after the same payload was copied into a physical local plugin directory. The installer must therefore copy payloads for Cursor rather than symlink them.
- Codex skills install does not provide session-start injection. It only makes `t-*` skills available through Codex skill discovery.
- Claude Code npm source behavior depends on the internal registry being reachable from the user's machine.
- Existing local symlink installs require `--adopt` or manual cleanup before the first production install.

## References

- Cursor plugin repository structure: https://github.com/cursor/plugins
- Claude Code plugin marketplace npm sources and update behavior: https://code.claude.com/docs/en/plugin-marketplaces
- Claude Code plugin command reference: https://code.claude.com/docs/en/plugins-reference
- Codex CLI and IDE overview: https://help.openai.com/en/articles/11369540/

## Archive Patch

### plugin-distribution

Target: docsDev/specs/plugin-distribution/spec.md
Action: create

#### ADDED Requirements

##### Requirement: T-Superpowers Has An Internal NPM Installer

The system must distribute `t-superpowers` through the internal npm package `@4399/tdata-t-superpowers` with explicit installer commands for Cursor, Claude Code, and Codex.

###### Scenario: Multi-target install command

- Given a user has access to the internal npm registry
- When the user runs `npx @4399/tdata-t-superpowers@latest install all`
- Then the installer attempts Cursor, Claude Code, and Codex installation using each target's supported mechanism

##### Requirement: Updates Are Explicit And Managed

The system must update previously installed targets through explicit `update` commands and must protect user-owned files by default.

###### Scenario: Managed update

- Given a target has a `t-superpowers` install receipt
- When the user runs `npx @4399/tdata-t-superpowers@latest update <target>`
- Then the installer replaces only receipt-managed directories or files and leaves unrelated user files unchanged

##### Requirement: Production Package Excludes Development Marketplace

The system must not ship the development Claude marketplace in the npm package.

###### Scenario: Dev marketplace stripped from package

- Given the repository has `.claude-plugin/marketplace.json` for local development
- When the npm package is built
- Then `dist/npm-package/.claude-plugin/plugin.json` exists
- And `dist/npm-package/.claude-plugin/marketplace.json` does not exist
