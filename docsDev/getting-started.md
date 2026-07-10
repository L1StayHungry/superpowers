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

## Selectively Adopted From Upstream v6.1.1

This internal release selectively absorbs the useful engineering changes from upstream v6.1.1 while retaining the `t-*` namespace, complex-only trigger boundary, `docsDev/` artifacts, explicit archive gate, and internal npm distribution.

- Runtime integration uses the current Codex `hooks: {}` schema and more robust session-start output handling.
- The local visual companion adds session authentication, path isolation, safe lifecycle management, reconnect recovery, and idle shutdown without remote branding or telemetry.
- `t-writing-plans` preserves exact project-wide values in `Global Constraints`, declares task interfaces, and sizes tasks around independently testable delivery boundaries.
- `t-subagent-driven-development` uses one implementer and a single consolidated reviewer per task, followed by a final whole-branch review; file handoffs and a progress ledger keep controller context small and resumable.
- Worktrees stay project-local, and finishing/review guidance no longer assumes one forge command.
- `t-writing-skills` now uses Skill Discovery Optimization, matches guidance form to the observed failure, and requires controlled wording micro-tests for behavior-shaping edits.

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

This is the verified local path used by the repository harnesses. For normal usage, prefer the internal npm installer shown above; it creates the local Claude marketplace and installs the plugin through Claude Code's native command. Keep official `superpowers` disabled for normal team work.

### Cursor

Use the internal installer so Cursor receives the required physical plugin directory:

```bash
npx @4399/tdata-t-superpowers@latest install cursor
npx @4399/tdata-t-superpowers@latest doctor cursor
```

After enabling it, restart Cursor and verify the displayed plugin name is `T-Superpowers`. Keep official `superpowers` disabled for normal team work.

### Codex CLI / Codex App

Install the `t-*` skill adapter into the active Codex home:

```bash
npx @4399/tdata-t-superpowers@latest install codex
npx @4399/tdata-t-superpowers@latest doctor codex
```

`CODEX_HOME` is honored when set. Codex does not use the Claude/Cursor session-start hook, so `doctor codex` may report the documented adapter warning while the installed skills themselves are valid.

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
