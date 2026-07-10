---
change_id: 20260710-upstream-6-1-1-runtime
created_at: 2026-07-10T04:24:23Z
updated_at: 2026-07-10T05:00:19Z
owner: lihuajun
---

# Upstream v6.1.1 Runtime Baseline Spec

## Change History

- 2026-07-10: Initial approved design for the v6.1.1 runtime-baseline sync.
- 2026-07-10: Quality-review hardening added an offline vendor integrity manifest, executable SessionStart branch tests, complete packaging assertions, accurate planning/execution wording, and live routing evidence.

## Context

This repository forked upstream Superpowers v5.1.0 and now needs a trustworthy v6.1.1 reference baseline plus a small set of runtime fixes. The sync must preserve the internal `t-superpowers` namespace, narrow complex-work trigger boundary, `docsDev/` artifact policy, internal installer, and explicit archive discipline.

The upstream source for this change is commit `d884ae04edebef577e82ff7c4e143debd0bbec99` (tag v6.1.1). Upstream source is copied only into the established `vendor/superpowers/` scope; fork runtime files are reconciled intentionally instead of being overwritten wholesale.

## Goals

- Refresh the existing upstream vendor scope to the exact v6.1.1 source and record its commit and sync time.
- Make future vendor drift detectable offline through a small manifest of the approved path set, Git modes/types, blob IDs, and symlink targets.
- Keep `docs/upstream-contrib.md` byte-identical to the refreshed upstream `CLAUDE.md`.
- Make the Codex manifest use exact `hooks: {}` and category `Developer Tools`, including the built npm payload.
- Remove the obsolete legacy-skill warning from the session bootstrap and retain the three harness-specific JSON response shapes.
- Append `| cat` to all three bootstrap `printf` pipelines to avoid the Windows EPIPE regression.
- Reduce the always-loaded `t-using-superpowers` token footprint while retaining the local trigger boundary, subagent stop guard, user-instruction priority, `t-*` namespace, skill priority, and red flags.
- Keep only an accurate, compact Codex tool reference; remove obsolete Copilot and Gemini references from this local skill.

## Non-Goals

- No direct merge or rebase of upstream into the fork runtime.
- No version bump, npm publish, push, upstream PR, or archive.
- No Kimi, Pi, Antigravity, Codex portal, or marketplace support.
- No widening to upstream's "1% chance" skill trigger rule.
- No changes to `t-archive`, state-machine metadata, archive transactions, or historical archived specs.
- No adoption of visual companion, planning, SDD, worktree, finishing, or skill-authoring changes in this runtime-only change.
- No local customization inside `vendor/superpowers/`; it remains upstream source plus the two baseline metadata files.

## Requirements

### Requirement: Exact Upstream Vendor Baseline

The existing vendor scope must be fully replaced from upstream v6.1.1. Selected root files, the complete `hooks/` tree, and the complete existing fourteen skill trees must reflect upstream additions, removals, file modes, and symlinks. Unsupported new harness roots and unrelated upstream repository files must remain outside the vendor snapshot.

`vendor/superpowers/UPSTREAM_MANIFEST` must pin the same 62-file path set using Git mode/type and blob ID, including the `AGENTS.md` symlink target. `tools/t-stage1-check.sh` must validate that manifest without network or access to the upstream checkout and require `UPSTREAM_COMMIT` to equal the full approved commit.

Because vendor files are byte-for-byte upstream source, `.gitattributes` must apply both `-text` and `-whitespace` to `vendor/superpowers/**`; fork-owned files remain subject to normal text and whitespace checks.

#### Scenario: Vendor provenance

- Given the runtime baseline sync has completed
- When `vendor/superpowers/UPSTREAM_COMMIT` is read
- Then `commit` equals `d884ae04edebef577e82ff7c4e143debd0bbec99`
- And `synced_at` records this sync
- And `UPSTREAM_MANIFEST` matches every non-metadata vendor path, byte, mode/type, and symlink target offline
- And `docs/upstream-contrib.md` equals `vendor/superpowers/CLAUDE.md` byte-for-byte

### Requirement: Codex Hook Schema Remains Stable Through Packaging

The root and npm-packaged Codex manifests must retain exact empty-object hooks and the Developer Tools category.

#### Scenario: Source manifest

- Given `.codex-plugin/plugin.json`
- When its JSON is parsed
- Then `hooks` is exactly `{}`
- And `interface.category` is exactly `Developer Tools`
- And `name` is `t-superpowers` and `version` is `5.1.1`
- And `description` and `interface.defaultPrompt` retain the internal complex-work wording
- And the name, version, and internal trigger descriptions remain the existing fork values

#### Scenario: Built npm payload

- Given `npm run build` succeeds
- When `dist/npm-package/.codex-plugin/plugin.json` is parsed
- Then `hooks` is exactly `{}`
- And `interface.category` is exactly `Developer Tools`

### Requirement: Compact Trigger Bootstrap

The always-loaded skill must keep the fork's narrow triggering contract without platform-specific access tutorials or an oversized flowchart.

#### Scenario: Trigger boundary is preserved

- Given an agent reads `t-using-superpowers`
- When the request is a simple copy, style, config, Q&A, or code-reading task
- Then the skill does not force a heavyweight `t-*` workflow
- And explicit `t-*` requests or clearly complex work still enter the relevant workflow

#### Scenario: Subagent guard is preserved

- Given an agent was dispatched as a subagent for a bounded task
- When it reads the skill
- Then `SUBAGENT-STOP` tells it to skip the bootstrap skill

### Requirement: Portable Session Bootstrap Output

The session hook must inject the existing `t-superpowers:t-using-superpowers` content in the appropriate Cursor, Claude Code, or SDK-standard JSON shape without emitting the obsolete `~/.config/superpowers/skills` warning.

#### Scenario: JSON output pipeline

- Given any of the three platform branches is selected
- When the hook prints its JSON response
- Then its `printf` output is piped through `cat`
- And the output parses as JSON containing only that branch's public field shape
- And the injected skill path and runtime identifier use `t-*` naming

## Validation

- Focused RED/GREEN: `bash tools/t-stage1-check.sh` and `node --test tests/npm-installer/build.test.mjs`.
- Full deterministic checks: `bash tools/t-stage1-check.sh`, `npm run test:npm-installer`, `npm run build`, and `git diff --check`.
- Verify vendor commit metadata and `diff -q vendor/superpowers/CLAUDE.md docs/upstream-contrib.md`.
- Verify deleted local references and compact skill wording with scoped `rg` checks.
- Run `bash tests/claude-code/test-using-superpowers-routing.sh` for simple, explicit, and complex routing; record any model-specific XFAIL instead of hiding it.

## Risks

- Vendor scope drift could accidentally import unsupported harness roots; the sync must use the previously established archive pathspec rather than the entire upstream tree.
- Upstream v6.1.1 contains a trailing space in a vendored skill. `.gitattributes` must suppress whitespace errors only for the vendor subtree so `git diff --check` can remain a whole-tree gate without altering upstream bytes.
- A future packaging refactor could coerce `{}` back to `[]`; the build regression test must inspect the emitted manifest.
- Over-compressing `t-using-superpowers` could remove a local trigger or priority guard; deterministic scans plus review must confirm each retained contract.
- Claude Code 2.1.204 / gpt-5.5 still explored before loading `t-brainstorming` in the implicit complex live case despite the injected narrow complex-work gate. Explicit TDD routing passed repeatedly but also had one non-invoking sample. The harness records non-deterministic explicit/complex misses as XFAIL; three isolated subagent route checks passed. Do not claim universal trigger compliance from static prompt wording or a single model sample.
- `| cat` intentionally changes pipeline failure behavior to match the accepted upstream EPIPE workaround; shell syntax and harness tests remain required.

## Archive Patch

### runtime

Target: docsDev/specs/runtime/spec.md
Action: create

#### ADDED Requirements

##### Requirement: Upstream Runtime Baselines Are Selectively Synchronized

The system must keep an exact upstream source snapshot in the established vendor scope while reconciling fork runtime behavior intentionally.

###### Scenario: Refreshing an upstream baseline

- Given a reviewed upstream release is selected
- When the vendor baseline is refreshed
- Then the existing vendor root files, hooks tree, and tracked skill trees reflect the selected upstream commit
- And unsupported harness roots are not imported
- And `UPSTREAM_COMMIT` records the exact commit and sync time

##### Requirement: Codex Empty Hooks Use Object Shape

The source and packaged Codex plugin manifests must represent intentionally disabled hooks as `{}` and classify the plugin as `Developer Tools`.

###### Scenario: Building the internal npm payload

- Given the source Codex manifest contains `hooks: {}`
- When the npm payload is built
- Then the packaged manifest also contains exact `hooks: {}`
- And its interface category is `Developer Tools`

##### Requirement: Session Bootstrap Avoids Windows EPIPE

Each session-start JSON response must pipe its `printf` output through `cat` while preserving the platform-specific response schema and internal `t-*` injection identity.

###### Scenario: Emitting session context

- Given Cursor, Claude Code, or the SDK-standard branch is active
- When the session hook emits JSON
- Then the selected `printf` command is followed by `| cat`
- And no obsolete legacy custom-skills warning is injected
