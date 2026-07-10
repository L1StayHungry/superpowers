---
change_id: 20260710-upstream-6-1-1-runtime
created_at: 2026-07-10T04:24:23Z
updated_at: 2026-07-10T05:00:19Z
owner: lihuajun
---

# Upstream v6.1.1 Runtime Baseline Implementation Plan

## Change History

- 2026-07-10: Initial implementation plan for the approved runtime baseline.
- 2026-07-10: Added quality-review fixes for offline vendor integrity, executable hook tests, package contract coverage, skill classification, and live routing evidence.

## Goal

Establish the v6.1.1 upstream reference baseline and adopt the approved runtime fixes without overwriting the internal fork's trigger and distribution contracts.

## Interfaces

- `.codex-plugin/plugin.json`: preserves fork identity/version/descriptions; exposes `hooks: {}` and `interface.category: "Developer Tools"`.
- `hooks/session-start`: stdout remains one JSON object using Cursor `additional_context`, Claude Code `hookSpecificOutput.additionalContext`, or SDK-standard `additionalContext`.
- `vendor/superpowers/UPSTREAM_COMMIT`: keeps `upstream`, `branch`, `commit`, `synced_at`, and `notes` fields.
- `vendor/superpowers/UPSTREAM_MANIFEST`: schema version 1, exact upstream commit/scope, and 62 path-sorted entries containing path, Git mode/type, blob ID, and symlink target where applicable.

## Implementation Steps

1. Add deterministic source and package assertions for the exact Codex manifest values; run them against the old implementation and record the expected RED output.
2. Refresh the existing vendor pathspec from upstream commit `d884ae04edebef577e82ff7c4e143debd0bbec99`, including additions and deletions inside the selected skill and hook trees; update metadata and upstream contribution docs. Mark only the vendor subtree as exempt from Git whitespace errors so exact upstream bytes and whole-tree `git diff --check` can coexist.
3. Update the fork Codex manifest and keep its internal identity and version unchanged.
4. Compact `t-using-superpowers`, delete obsolete local Copilot/Gemini mappings, and keep a truthful compact Codex mapping without `close_agent`.
5. Remove the legacy skills warning from `hooks/session-start` and pipe each of its three JSON `printf` outputs through `cat`.
6. Append a dated correction to the Stage 1 acceptance record and update current maintenance guidance that still permits the old Codex hook shapes.
7. Run focused GREEN, full installer tests, build, vendor equality checks, shell syntax checks, and `git diff --check`; stage only this change and create the focused commit.
8. Address review findings with an offline vendor manifest gate, real SessionStart subprocess checks, full packaged-Codex assertions, corrected planning/execution categories, and bounded live routing cases.

## TDD Evidence

- RED timestamp: 2026-07-10T04:24:23Z.
- `bash tools/t-stage1-check.sh` exited 1 because the old category was `Coding`.
- `node --test tests/npm-installer/build.test.mjs` exited 1 because the packaged hooks value was `[]`, not `{}`.
- Raw output: `transcripts/red-baseline.md`.
- Quality-review RED: the new planning marker failed, the vendor manifest was missing, vendor `text` remained set, and the natural Claude complex prompt explored files instead of loading `t-brainstorming`. See `transcripts/quality-review-red.md` and `transcripts/live-bootstrap.md`.

## Reproducible Vendor Manifest

Generate the manifest from the already-fetched approved upstream checkout and commit using the same pathspec:

```bash
UPSTREAM_CHECKOUT=/absolute/path/to/obra-superpowers
python3 - "$UPSTREAM_CHECKOUT" d884ae04edebef577e82ff7c4e143debd0bbec99 > vendor/superpowers/UPSTREAM_MANIFEST <<'PY'
import json, subprocess, sys
repo, commit = sys.argv[1:]
scope = [
    "skills", "hooks", "CLAUDE.md", "AGENTS.md", "GEMINI.md",
    ".claude-plugin/plugin.json", ".claude-plugin/marketplace.json",
    ".cursor-plugin/plugin.json", ".codex-plugin/plugin.json",
    "package.json", "gemini-extension.json", ".opencode/plugins/superpowers.js",
]
raw = subprocess.check_output(
    ["git", "-C", repo, "ls-tree", "-rz", "-r", "--full-tree", commit, "--", *scope]
)
entries = []
for record in raw.split(b"\0"):
    if not record:
        continue
    metadata, raw_path = record.split(b"\t", 1)
    mode, object_type, object_id = metadata.decode().split()
    if object_type != "blob":
        raise SystemExit(f"unexpected object type: {object_type}")
    entry = {
        "path": raw_path.decode(), "mode": mode,
        "type": "symlink" if mode == "120000" else "file",
        "git_blob": object_id,
    }
    if mode == "120000":
        entry["target"] = subprocess.check_output(
            ["git", "-C", repo, "cat-file", "-p", object_id]
        ).decode()
    entries.append(entry)
print(json.dumps({
    "schema_version": 1, "upstream_commit": commit,
    "scope": scope, "entries": entries,
}, indent=2, ensure_ascii=False))
PY
```

The sustainable offline validation command is:

```bash
bash tools/t-stage1-check.sh
```

## Validation

- `bash tools/t-stage1-check.sh`
- `node --test tests/npm-installer/build.test.mjs`
- `bash tests/claude-code/test-using-superpowers-routing.sh`
- `npm run test:npm-installer`
- `npm run build`
- `npm run pack:dry-run`
- `bash -n hooks/session-start tools/t-stage1-check.sh`
- `diff -q vendor/superpowers/CLAUDE.md docs/upstream-contrib.md`
- `git diff --check`

## Non-Goals

- Do not implement later visual companion, writing-plan, SDD, worktree, finishing, or skill-authoring stages.
- Do not change versions, publish, push, archive, or prepare an upstream PR.
- Do not modify historical archived specs.

## Risks

- The vendor refresh is intentionally large but must be mechanically attributable to the upstream commit.
- Concurrent later-stage work may touch vendor source for comparison; it must not customize the vendor tree.
- The live Claude complex case is a documented XFAIL, not a passing trigger claim; isolated subagent behavior passed and deterministic boundaries remain enforced.
- Systematic old/new and hook-probe comparisons locate that XFAIL in Claude Code `2.1.204`/`gpt-5.5` ignoring SessionStart `additionalContext`; the same prompts fail on pre-sync commit `5314938`, so this stage neither caused nor conceals a regression.
