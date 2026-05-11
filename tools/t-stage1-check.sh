#!/usr/bin/env bash
set -euo pipefail

upstream_skills_regex='superpowers:(brainstorming|dispatching-parallel-agents|executing-plans|finishing-a-development-branch|receiving-code-review|requesting-code-review|subagent-driven-development|systematic-debugging|test-driven-development|using-git-worktrees|using-superpowers|verification-before-completion|writing-plans|writing-skills|archive)'

for cmd in rg python3 git; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "FAIL: missing required command: ${cmd}"
    exit 1
  fi
done

# skills/ should expose only migrated t-* skill directories.
non_t_dir=$(find skills -mindepth 1 -maxdepth 1 -type d ! -name 't-*' | sort | head -1)
if [ -n "${non_t_dir}" ]; then
  echo "FAIL: non-t- skill dirs remain: ${non_t_dir}"
  exit 1
fi

# Runtime-visible references must use t-superpowers:t-* after Stage 1.
residual_refs=$(rg -n --glob '!vendor/**' \
  --glob '!package.json' \
  --glob '!gemini-extension.json' \
  --glob '!.opencode/**' \
  "${upstream_skills_regex}" \
  skills hooks .claude-plugin .cursor-plugin .codex-plugin tests || true)
if [ -n "${residual_refs}" ]; then
  echo "FAIL: superpowers:<skill> references remain in migrated runtime/test scope"
  printf '%s\n' "${residual_refs}"
  exit 1
fi

# Template/path references in migrated skills must not point at removed upstream skill directories.
stale_skill_paths=$(rg -n --glob '!vendor/**' \
  '(^|[^t-])requesting-code-review/code-reviewer\.md|skills/requesting-code-review/' \
  skills hooks .claude-plugin .cursor-plugin .codex-plugin tests || true)
if [ -n "${stale_skill_paths}" ]; then
  echo "FAIL: stale requesting-code-review template paths remain"
  printf '%s\n' "${stale_skill_paths}"
  exit 1
fi

# Plugin manifests must use the t-superpowers package identity and skill roots.
python3 - <<'PY'
import json
import sys


def load(path):
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)


def assert_eq(actual, expected, label):
    if actual != expected:
        print(f"FAIL {label}: expected {expected!r}, got {actual!r}", file=sys.stderr)
        sys.exit(1)


claude = load(".claude-plugin/plugin.json")
assert_eq(claude.get("name"), "t-superpowers", ".claude-plugin/plugin.json name")

cursor = load(".cursor-plugin/plugin.json")
assert_eq(cursor.get("name"), "t-superpowers", ".cursor-plugin/plugin.json name")
assert_eq(cursor.get("displayName"), "T-Superpowers", ".cursor-plugin/plugin.json displayName")
assert_eq(cursor.get("skills"), "./skills/", ".cursor-plugin/plugin.json skills")

codex = load(".codex-plugin/plugin.json")
assert_eq(codex.get("name"), "t-superpowers", ".codex-plugin/plugin.json name")
assert_eq(codex.get("skills"), "./skills/", ".codex-plugin/plugin.json skills")
assert_eq(
    (codex.get("interface") or {}).get("displayName"),
    "T-Superpowers",
    ".codex-plugin/plugin.json interface.displayName",
)

marketplace = load(".claude-plugin/marketplace.json")
assert_eq(marketplace.get("name"), "t-superpowers-dev", ".claude-plugin/marketplace.json name")
plugins = marketplace.get("plugins") or []
if not plugins:
    print("FAIL .claude-plugin/marketplace.json plugins array is empty", file=sys.stderr)
    sys.exit(1)
assert_eq(
    plugins[0].get("name"),
    "t-superpowers",
    ".claude-plugin/marketplace.json plugins[0].name",
)
PY

# The session bootstrap must read and advertise the migrated using-superpowers skill.
if rg -n 'skills/using-superpowers/SKILL\.md|superpowers:using-superpowers' hooks/session-start >/dev/null; then
  echo "FAIL: hooks/session-start still references upstream using-superpowers path or runtime id"
  exit 1
fi

for skill in \
  brainstorming \
  dispatching-parallel-agents \
  executing-plans \
  finishing-a-development-branch \
  receiving-code-review \
  requesting-code-review \
  subagent-driven-development \
  systematic-debugging \
  test-driven-development \
  using-git-worktrees \
  using-superpowers \
  verification-before-completion \
  writing-plans \
  writing-skills; do
  skill_file="skills/t-${skill}/SKILL.md"
  if [ ! -f "${skill_file}" ]; then
    echo "FAIL: missing ${skill_file}"
    exit 1
  fi
  if ! rg -n "^name:[[:space:]]+t-${skill}[[:space:]]*$" "${skill_file}" >/dev/null; then
    echo "FAIL: frontmatter name is not t-${skill} in ${skill_file}"
    exit 1
  fi
done

# The upstream vendor baseline must remain complete enough for future rebases.
if [ ! -f vendor/superpowers/UPSTREAM_COMMIT ]; then
  echo "FAIL: vendor/superpowers/UPSTREAM_COMMIT missing"
  exit 1
fi
if ! rg -n '^commit:[[:space:]]+[0-9a-f]{7,40}[[:space:]]*$' vendor/superpowers/UPSTREAM_COMMIT >/dev/null; then
  echo "FAIL: vendor/superpowers/UPSTREAM_COMMIT commit field invalid"
  exit 1
fi
for path in \
  vendor/superpowers/CLAUDE.md \
  vendor/superpowers/AGENTS.md \
  vendor/superpowers/GEMINI.md \
  vendor/superpowers/package.json \
  vendor/superpowers/gemini-extension.json \
  vendor/superpowers/.opencode/plugins/superpowers.js \
  vendor/superpowers/.claude-plugin/plugin.json \
  vendor/superpowers/.claude-plugin/marketplace.json \
  vendor/superpowers/.cursor-plugin/plugin.json \
  vendor/superpowers/.codex-plugin/plugin.json \
  vendor/superpowers/hooks/session-start \
  vendor/superpowers/hooks/hooks.json \
  vendor/superpowers/hooks/hooks-cursor.json \
  vendor/superpowers/hooks/run-hook.cmd; do
  if [ ! -f "${path}" ]; then
    echo "FAIL: vendor baseline missing ${path}"
    exit 1
  fi
done

for skill in \
  brainstorming \
  dispatching-parallel-agents \
  executing-plans \
  finishing-a-development-branch \
  receiving-code-review \
  requesting-code-review \
  subagent-driven-development \
  systematic-debugging \
  test-driven-development \
  using-git-worktrees \
  using-superpowers \
  verification-before-completion \
  writing-plans \
  writing-skills; do
  path="vendor/superpowers/skills/${skill}/SKILL.md"
  if [ ! -f "${path}" ]; then
    echo "FAIL: vendor baseline missing ${path}"
    exit 1
  fi
done

if ! diff -q vendor/superpowers/CLAUDE.md docs/upstream-contrib.md >/dev/null; then
  echo "FAIL: docs/upstream-contrib.md must equal vendor/superpowers/CLAUDE.md"
  exit 1
fi

# Cursor declares these roots, so the directories must exist even if empty.
for dir in agents commands; do
  if [ ! -d "${dir}" ]; then
    echo "FAIL: missing Cursor ${dir}/ directory"
    exit 1
  fi
done

# Codex must explicitly choose one Stage 1 hook mode.
python3 - <<'PY'
import json
import os
import sys

with open(".codex-plugin/plugin.json", encoding="utf-8") as handle:
    manifest = json.load(handle)

if "hooks" not in manifest:
    print("FAIL .codex-plugin/plugin.json hooks field must be explicitly set", file=sys.stderr)
    sys.exit(1)

hooks = manifest["hooks"]
codex_hooks_path = "hooks/hooks-codex.json"
if hooks == []:
    pass
elif hooks == "./hooks/hooks-codex.json":
    if not os.path.isfile(codex_hooks_path):
        print("FAIL: hooks/hooks-codex.json missing", file=sys.stderr)
        sys.exit(1)
else:
    print(
        "FAIL .codex-plugin/plugin.json hooks must be [] or './hooks/hooks-codex.json'; "
        f"got {hooks!r}",
        file=sys.stderr,
    )
    sys.exit(1)

if os.path.isfile(codex_hooks_path):
    with open(codex_hooks_path, encoding="utf-8") as handle:
        body = handle.read()
    if "CLAUDE_PLUGIN_ROOT" in body:
        print("FAIL: hooks/hooks-codex.json must not contain CLAUDE_PLUGIN_ROOT", file=sys.stderr)
        sys.exit(1)
PY

# Excluded JSON entry points remain outside Stage 1 migration.
python3 - <<'PY'
import json
import sys

for path in ("package.json", "gemini-extension.json"):
    with open(path, encoding="utf-8") as handle:
        name = json.load(handle).get("name")
    if name != "superpowers":
        print(f"FAIL {path} name: expected 'superpowers', got {name!r}", file=sys.stderr)
        sys.exit(1)
PY

if [ ! -L AGENTS.md ] || [ "$(readlink AGENTS.md)" != "CLAUDE.md" ]; then
  echo "FAIL: AGENTS.md must remain a symlink to CLAUDE.md"
  exit 1
fi

# These six files are deliberately outside Stage 1 migration and must stay untouched.
git diff --exit-code HEAD -- \
  package.json \
  gemini-extension.json \
  .opencode/plugins/superpowers.js \
  CLAUDE.md \
  AGENTS.md \
  GEMINI.md >/dev/null || {
    echo "FAIL: excluded entry/instruction files have uncommitted changes"
    exit 1
  }

echo "OK: Stage 1 migration self-check passed"
