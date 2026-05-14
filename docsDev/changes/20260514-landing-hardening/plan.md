---
change_id: 20260514-landing-hardening
created_at: 2026-05-14T11:05:00Z
updated_at: 2026-05-14T11:05:00Z
owner: lihuajun
---

# Landing Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use t-superpowers:t-subagent-driven-development (recommended) or t-superpowers:t-executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the current `t-superpowers` fork understandable and safe to enable for team users by hardening metadata, onboarding docs, bootstrap wording, and lightweight CI guardrails.

**Architecture:** This is a documentation and metadata slice. Runtime behavior stays in the existing skills and hooks; the implementation changes only string metadata, one onboarding guide, one README notice, one hook wrapper string, and one GitHub Actions guardrail. Validation is static and deterministic, with app-level smoke left as an explicit follow-up.

**Tech Stack:** JSON plugin manifests, Bash session hook, Markdown documentation, GitHub Actions YAML, `rg`, `python3`, `bash`.

---

## File Structure

- `.codex-plugin/plugin.json`: Codex plugin marketplace metadata and default prompts.
- `.cursor-plugin/plugin.json`: Cursor plugin metadata.
- `.claude-plugin/plugin.json`: Claude Code plugin metadata.
- `.claude-plugin/marketplace.json`: local Claude marketplace metadata.
- `hooks/session-start`: session bootstrap wrapper text; platform output routing must stay unchanged.
- `README.md`: first-screen fork notice and link to the team guide.
- `docsDev/getting-started.md`: team guide for enablement, trigger boundaries, and artifact paths.
- `.github/workflows/t-superpowers-guardrails.yml`: lightweight PR/push guardrails.
- `docsDev/changes/20260514-landing-hardening/plan.md`: this implementation plan and verification log.

## Task 1: Update Plugin Metadata

**Files:**
- Modify: `.codex-plugin/plugin.json`
- Modify: `.cursor-plugin/plugin.json`
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Inspect current manifest fields**

Run:

```bash
python3 - <<'PY'
import json
for path in [
    ".codex-plugin/plugin.json",
    ".cursor-plugin/plugin.json",
    ".claude-plugin/plugin.json",
    ".claude-plugin/marketplace.json",
]:
    data = json.load(open(path, encoding="utf-8"))
    print(f"\n--- {path} ---")
    if path == ".codex-plugin/plugin.json":
        interface = data["interface"]
        print("description:", data["description"])
        print("shortDescription:", interface["shortDescription"])
        print("longDescription:", interface["longDescription"])
        print("defaultPrompt:", interface["defaultPrompt"])
    elif path == ".claude-plugin/marketplace.json":
        print("description:", data["description"])
        print("plugin description:", data["plugins"][0]["description"])
    else:
        print("description:", data["description"])
PY
```

Expected: output still contains upstream-style broad wording, including the Codex prompts `"I've got an idea for something I'd like to build."` and `"Let's add a feature to this project."`.

- [ ] **Step 2: Replace metadata strings with scoped t-superpowers wording**

Edit the four JSON files so these exact values are present:

`.codex-plugin/plugin.json`:

```json
{
  "description": "Internal t-superpowers fork for complex development workflows: planning, TDD, debugging, review, and archive discipline while simple edits stay in normal agent mode.",
  "interface": {
    "shortDescription": "Complex-change planning, TDD, debugging, review, and archive workflows",
    "longDescription": "T-Superpowers is an internal fork of Superpowers for complex development work. Use it when a change needs t-* planning, TDD, systematic debugging, subagent execution, review, or archive discipline. Simple copy/style/config edits, Q&A, and pure code reading should stay in the default agent flow.",
    "defaultPrompt": [
      "Plan a complex change with t-superpowers.",
      "Use t-superpowers for a multi-file behavior change."
    ]
  }
}
```

Keep every existing field not shown above unchanged.

`.cursor-plugin/plugin.json`:

```json
{
  "description": "Internal t-superpowers fork for complex development workflows; use t-* skills for planning, TDD, debugging, review, and archive work while simple edits stay direct."
}
```

`.claude-plugin/plugin.json`:

```json
{
  "description": "Internal t-superpowers fork for Claude Code complex development workflows: planning, TDD, debugging, review, and archive discipline while simple edits stay direct."
}
```

`.claude-plugin/marketplace.json`:

```json
{
  "description": "Development marketplace for the internal t-superpowers fork.",
  "plugins": [
    {
      "description": "Internal t-superpowers fork for complex development workflows: planning, TDD, debugging, review, and archive discipline while simple edits stay direct."
    }
  ]
}
```

- [ ] **Step 3: Validate JSON and metadata assertions**

Run:

```bash
python3 -m json.tool .codex-plugin/plugin.json >/dev/null
python3 -m json.tool .cursor-plugin/plugin.json >/dev/null
python3 -m json.tool .claude-plugin/plugin.json >/dev/null
python3 -m json.tool .claude-plugin/marketplace.json >/dev/null
python3 - <<'PY'
import json
codex = json.load(open(".codex-plugin/plugin.json", encoding="utf-8"))
cursor = json.load(open(".cursor-plugin/plugin.json", encoding="utf-8"))
claude = json.load(open(".claude-plugin/plugin.json", encoding="utf-8"))
market = json.load(open(".claude-plugin/marketplace.json", encoding="utf-8"))
prompts = codex["interface"]["defaultPrompt"]
old = {
    "I've got an idea for something I'd like to build.",
    "Let's add a feature to this project.",
}
assert not (old & set(prompts)), prompts
for text in [
    codex["description"],
    codex["interface"]["shortDescription"],
    codex["interface"]["longDescription"],
    cursor["description"],
    claude["description"],
    market["description"],
    market["plugins"][0]["description"],
]:
    lowered = text.lower()
    assert (
        "t-superpowers" in text
        or "T-Superpowers" in text
        or "complex" in lowered
        or "planning" in lowered
    ), text
print("OK: plugin metadata is scoped")
PY
```

Expected: all commands exit `0`, and the final line is `OK: plugin metadata is scoped`.

- [ ] **Step 4: Commit metadata update**

Run:

```bash
git add .codex-plugin/plugin.json .cursor-plugin/plugin.json .claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "docs: scope t-superpowers plugin metadata"
```

Expected: commit succeeds.

## Task 2: Add Team Onboarding Guide And README Fork Notice

**Files:**
- Create: `docsDev/getting-started.md`
- Modify: `README.md`

- [ ] **Step 1: Add the team guide**

Create `docsDev/getting-started.md` with this content:

```markdown
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
```

- [ ] **Step 2: Add README fork notice above the upstream README body**

Insert this block at the very top of `README.md`, before the existing `# Superpowers` heading:

```markdown
# t-superpowers

`t-superpowers` is an internal fork of [`obra/superpowers`](https://github.com/obra/superpowers) for team development workflows.

Start with the team guide: [docsDev/getting-started.md](docsDev/getting-started.md).

For normal team work, enable either official `superpowers` or internal `t-superpowers`, not both. Simple edits, Q&A, and code reading should stay in ordinary agent mode. Use `t-superpowers` for complex multi-file features, behavior changes, root-cause-unknown bugs, and changes that need specs, plans, verification, or archive records.

## Upstream README Reference

The remainder of this README is upstream-oriented reference text retained during the fork rollout.

```

Do not rewrite the rest of the upstream README in this task.

- [ ] **Step 3: Validate guide and README content**

Run:

```bash
rg -n "t-superpowers|docsDev/getting-started.md|docsDev/changes/<change-id>|docsDev/specs/<capability>/spec.md|docsDev/archive/<change-id>" README.md docsDev/getting-started.md
rg -n 'official `superpowers` or internal `t-superpowers`, not both|Do not enable both|Do Not Enable Both' README.md docsDev/getting-started.md
```

Expected: both commands exit `0` and print matches in both files where applicable.

- [ ] **Step 4: Commit onboarding docs**

Run:

```bash
git add README.md docsDev/getting-started.md
git commit -m "docs: add t-superpowers onboarding guide"
```

Expected: commit succeeds.

## Task 3: Scope Session-Start Wrapper Branding

**Files:**
- Modify: `hooks/session-start`

- [ ] **Step 1: Inspect current wrapper text**

Run:

```bash
sed -n '1,60p' hooks/session-start
```

Expected: line containing `session_context=` still starts with `You have superpowers.` and references `t-superpowers:t-using-superpowers`.

- [ ] **Step 2: Replace only the wrapper string**

Edit `hooks/session-start` so the `session_context=` assignment becomes:

```bash
session_context="<EXTREMELY_IMPORTANT>\nYou have t-superpowers, the internal Superpowers fork for complex development workflows.\n\n**Below is the full content of your 't-superpowers:t-using-superpowers' skill - it defines when to use t-* workflows and when simple requests should stay in the default agent flow. For all other skills, use the 'Skill' tool:**\n\n${using_superpowers_escaped}\n\n${warning_escaped}\n</EXTREMELY_IMPORTANT>"
```

Do not change the `if [ -n "${CURSOR_PLUGIN_ROOT:-}" ]` / `elif [ -n "${CLAUDE_PLUGIN_ROOT:-}" ]` / `else` routing or output JSON fields.

- [ ] **Step 3: Validate hook syntax and output routing**

Run:

```bash
bash -n hooks/session-start
CURSOR_PLUGIN_ROOT=/tmp/plugin-root hooks/session-start >/tmp/t-superpowers-cursor-hook.json
CLAUDE_PLUGIN_ROOT=/tmp/plugin-root hooks/session-start >/tmp/t-superpowers-claude-hook.json
python3 - <<'PY'
import json
cursor = json.load(open("/tmp/t-superpowers-cursor-hook.json", encoding="utf-8"))
claude = json.load(open("/tmp/t-superpowers-claude-hook.json", encoding="utf-8"))
assert "additional_context" in cursor
assert "hookSpecificOutput" in claude
assert "t-superpowers" in cursor["additional_context"]
assert "t-superpowers:t-using-superpowers" in claude["hookSpecificOutput"]["additionalContext"]
print("OK: session-start wrapper and routing validated")
PY
```

Expected: all commands exit `0`, and the final line is `OK: session-start wrapper and routing validated`.

- [ ] **Step 4: Commit hook wording**

Run:

```bash
git add hooks/session-start
git commit -m "docs: brand session bootstrap as t-superpowers"
```

Expected: commit succeeds.

## Task 4: Add Lightweight CI Guardrails

**Files:**
- Create: `.github/workflows/t-superpowers-guardrails.yml`

- [ ] **Step 1: Create guardrail workflow**

Create `.github/workflows/t-superpowers-guardrails.yml` with this content:

```yaml
name: t-superpowers guardrails

on:
  pull_request:
  push:
    branches:
      - t-dev
      - main

jobs:
  guardrails:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Stage 1 namespace check
        run: bash tools/t-stage1-check.sh

      - name: Stage 2 live surface guardrails
        shell: bash
        run: |
          set -euo pipefail

          live_paths=(
            skills
            hooks
            .claude-plugin
            .cursor-plugin
            .codex-plugin
            README.md
            docsDev/getting-started.md
          )

          if rg -n 'docs/superpowers/(specs|plans)' "${live_paths[@]}"; then
            echo "FAIL: live surfaces must not instruct new runtime artifacts under docs/superpowers/specs or docs/superpowers/plans"
            exit 1
          fi

          if rg -n '(^|[^t-])superpowers:(brainstorming|dispatching-parallel-agents|executing-plans|finishing-a-development-branch|receiving-code-review|requesting-code-review|subagent-driven-development|systematic-debugging|test-driven-development|using-git-worktrees|using-superpowers|verification-before-completion|writing-plans|writing-skills|archive)' "${live_paths[@]}"; then
            echo "FAIL: live surfaces must use t-superpowers:t-* runtime references"
            exit 1
          fi
```

- [ ] **Step 2: Validate workflow syntax locally**

Run:

```bash
ruby -e 'require "yaml"; YAML.load_file(ARGV[0]); puts "OK: yaml parsed"' .github/workflows/t-superpowers-guardrails.yml
```

Expected: exits `0` and prints `OK: yaml parsed`.

- [ ] **Step 3: Run guardrail commands locally**

Run:

```bash
bash tools/t-stage1-check.sh
live_paths=(skills hooks .claude-plugin .cursor-plugin .codex-plugin README.md docsDev/getting-started.md)
if rg -n 'docs/superpowers/(specs|plans)' "${live_paths[@]}"; then
  echo "FAIL docs/superpowers live path leak"
  exit 1
fi
if rg -n '(^|[^t-])superpowers:(brainstorming|dispatching-parallel-agents|executing-plans|finishing-a-development-branch|receiving-code-review|requesting-code-review|subagent-driven-development|systematic-debugging|test-driven-development|using-git-worktrees|using-superpowers|verification-before-completion|writing-plans|writing-skills|archive)' "${live_paths[@]}"; then
  echo "FAIL upstream runtime namespace leak"
  exit 1
fi
echo "OK: guardrails pass locally"
```

Expected: `tools/t-stage1-check.sh` prints `OK: Stage 1 migration self-check passed`, and final output prints `OK: guardrails pass locally`.

- [ ] **Step 4: Commit CI guardrail**

Run:

```bash
git add .github/workflows/t-superpowers-guardrails.yml
git commit -m "ci: add t-superpowers guardrails"
```

Expected: commit succeeds.

## Task 5: Final Verification And Plan Evidence

**Files:**
- Modify: `docsDev/changes/20260514-landing-hardening/plan.md`

- [ ] **Step 1: Run full scoped verification**

Run:

```bash
git diff --check -- .codex-plugin/plugin.json .cursor-plugin/plugin.json .claude-plugin/plugin.json .claude-plugin/marketplace.json hooks/session-start README.md docsDev/getting-started.md .github/workflows/t-superpowers-guardrails.yml docsDev/changes/20260514-landing-hardening/plan.md
bash tools/t-stage1-check.sh
python3 -m json.tool .codex-plugin/plugin.json >/dev/null
python3 -m json.tool .cursor-plugin/plugin.json >/dev/null
python3 -m json.tool .claude-plugin/plugin.json >/dev/null
python3 -m json.tool .claude-plugin/marketplace.json >/dev/null
bash -n hooks/session-start
ruby -e 'require "yaml"; YAML.load_file(ARGV[0]); puts "OK: yaml parsed"' .github/workflows/t-superpowers-guardrails.yml
python3 - <<'PY'
import json
codex = json.load(open(".codex-plugin/plugin.json", encoding="utf-8"))
prompts = codex["interface"]["defaultPrompt"]
assert "I've got an idea for something I'd like to build." not in prompts
assert "Let's add a feature to this project." not in prompts
assert all(len(prompt) <= 128 for prompt in prompts)
print("OK: codex default prompts scoped and short")
PY
rg -n "docsDev/changes/<change-id>/spec.md|docsDev/changes/<change-id>/plan.md|docsDev/specs/<capability>/spec.md|docsDev/archive/<change-id>" docsDev/getting-started.md
if rg -n "^[[:space:]]*allow_implicit_invocation:[[:space:]]*false" . --glob "!vendor/**"; then
  echo "FAIL: allow_implicit_invocation false was introduced"
  exit 1
fi
if find . -path './vendor' -prune -o -path './tools/t-validate' -print -o -path './tools/t-state' -print | rg .; then
  echo "FAIL: forbidden validation/state tool exists"
  exit 1
fi
```

Expected: all commands exit `0`. The `rg` command prints the expected artifact path lines from `docsDev/getting-started.md`.

- [ ] **Step 2: Append verification log to this plan**

Append a `## Verification Log` section to this file with the UTC timestamp, command list, exit codes, and conclusions from Step 1. Generate the timestamp with:

```bash
date -u +%Y-%m-%dT%H:%M:%SZ
```

The log must contain one bullet for each verification group in Step 1:

- `git diff --check` result for the changed files.
- `bash tools/t-stage1-check.sh` result.
- JSON manifest validation result.
- `bash -n hooks/session-start` result.
- workflow YAML parse result.
- Codex default prompt assertion result.
- onboarding artifact path scan result.
- forbidden design scan result.

Each bullet must state the command or command group, the exit code, and the conclusion in plain language.

- [ ] **Step 3: Commit verification log**

Run:

```bash
git add docsDev/changes/20260514-landing-hardening/plan.md
git commit -m "docs: record landing hardening verification"
```

Expected: commit succeeds.

- [ ] **Step 4: Confirm final clean state**

Run:

```bash
git status --short
```

Expected: no output.

## Self-Review

- Spec coverage: Task 1 covers plugin metadata and Codex default prompts. Task 2 covers README and `docsDev/getting-started.md`. Task 3 covers session-start branding without changing routing. Task 4 covers CI guardrails. Task 5 covers deterministic validation and evidence.
- Scope control: Cursor.app and Codex App manual smoke remain follow-up validation after landing surfaces are fixed. Historical tests with upstream paths are not migrated in this patch.
- Forbidden design check: The plan does not add state fields, `acceptance_evidence`, conversation hashes, PR online checks, transaction backups, `tools/t-validate`, or `tools/t-state`.
- Type and path consistency: All changed file paths match the approved spec. Runtime artifacts remain under `docsDev/changes/20260514-landing-hardening/`.
