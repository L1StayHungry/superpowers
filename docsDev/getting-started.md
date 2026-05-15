# t-superpowers Getting Started

`t-superpowers` is the internal fork of `obra/superpowers` for team development workflows. It keeps the engineering discipline from Superpowers, but narrows usage so simple work stays lightweight and complex work gets specs, plans, verification, and archive records.

## Choose The Right Mode

Use normal agent mode for:

- small copy, style, config, spelling, or formatting edits
- Q&A, explanations, and code reading
- single-file mechanical changes with low risk

Use `t-superpowers` for:

- multi-file features
- user-visible behavior changes
- root-cause-unknown bugs or failing tests
- changes involving interfaces, data, permissions, auth, concurrency, migrations, payments, or similar high-risk areas
- work where you explicitly want `t-brainstorming`, `t-writing-plans`, TDD, verification, subagents, review, or archive records

For ambiguous work, ask for `t-superpowers` explicitly if you want the full workflow.

## Do Not Enable Both For Normal Work

Official `superpowers` and internal `t-superpowers` can coexist for namespace testing, but normal team usage should enable one family at a time. Enabling both can inject two bootstrap contexts and make trigger behavior noisy.

## Recommended Internal NPM Install

For normal team usage, install the internal package instead of using Cursor `/add-plugin` against the repository checkout:

```bash
npm config set @4399:registry https://registry-npm.gz4399.com/
npx @4399/tdata-t-superpowers@latest install all
npx @4399/tdata-t-superpowers@latest doctor all
```

Cursor must receive a physical plugin directory. Local smoke showed Cursor did not reliably expose skills from the symlink created by `/add-plugin /Users/lihuajun/WorkProject/superpowers`, while the same payload worked after copying into `~/.cursor/plugins/local/t-superpowers`.

Codex installation currently uses a skills adapter. It installs `t-*` skills but does not install session-start hooks, so `doctor codex` reports `WARN` for that limitation.

## Local Enablement

Use your clone path in place of `/Users/lihuajun/WorkProject/superpowers`.

### Claude Code

For local development and smoke testing, pass the plugin directory:

```bash
claude -p "用 t-superpowers，规划一个复杂变更" --plugin-dir /Users/lihuajun/WorkProject/superpowers
```

This is the verified local path used by the repository harnesses. If the team publishes an internal Claude marketplace, install `t-superpowers` from that marketplace and disable official `superpowers` for normal team work.

### Cursor

Use Cursor's plugin UI or command flow to add the local plugin from the repository root when local plugins are enabled:

```text
/add-plugin /Users/lihuajun/WorkProject/superpowers
```

After enabling it, verify the displayed plugin name is `T-Superpowers`. If your Cursor build only supports marketplace plugins, use the team's published internal `t-superpowers` package and keep official `superpowers` disabled.

### Codex CLI / Codex App

Codex local harness validation currently uses an isolated `CODEX_HOME` with the local plugin copied into the Codex plugin cache. The stable team path is to install the published internal `t-superpowers` plugin once it is available in the team's Codex plugin source.

Until that package exists, treat Codex local enablement as a harness task rather than a normal user install. The verified checks are recorded under `docsDev/archive/20260512-trigger-convergence/transcripts/`.

## Artifact Paths

Complex change artifacts use:

```text
docsDev/changes/<change-id>/spec.md
docsDev/changes/<change-id>/plan.md
docsDev/changes/<change-id>/transcripts/
```

Long-term specs use:

```text
docsDev/specs/<capability>/spec.md
```

Archived change snapshots use:

```text
docsDev/archive/<change-id>/
```

Do not create new runtime artifacts under `docs/superpowers/` or `openspec/`.

## Archive Boundary

Archive is explicit. `t-archive` should run only when a user says to archive a concrete change-id, such as:

```text
归档 20260514-example-change
```

Do not infer archive intent from `可以了`, `ok`, `looks good`, or successful verification.
