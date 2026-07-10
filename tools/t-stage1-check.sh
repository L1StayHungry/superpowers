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
assert_eq(
    (codex.get("interface") or {}).get("category"),
    "Developer Tools",
    ".codex-plugin/plugin.json interface.category",
)
assert_eq(codex.get("hooks"), {}, ".codex-plugin/plugin.json hooks")

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

# The always-loaded bootstrap must stay compact and preserve the fork boundary.
bootstrap_skill="skills/t-using-superpowers/SKILL.md"
for marker in \
  '<SUBAGENT-STOP>' \
  '<TRIGGER-BOUNDARY>' \
  '<COMPLEX-WORK-GATE>' \
  'complex multi-file.*first action.*t-brainstorming.*before.*reading' \
  'User.*instructions.*precedence' \
  '^## Skill Priority' \
  'Planning skills turn.*executable steps' \
  'Execution skills guide.*TDD' \
  '^## Red Flags'; do
  if ! rg -n "${marker}" "${bootstrap_skill}" >/dev/null; then
    echo "FAIL: t-using-superpowers missing required marker: ${marker}"
    exit 1
  fi
done

if rg -n '```dot|references/(copilot|gemini)-tools\.md|In Claude Code:|In Copilot CLI:|In Gemini CLI:' "${bootstrap_skill}" >/dev/null; then
  echo "FAIL: t-using-superpowers retains removed platform or flowchart guidance"
  exit 1
fi

bootstrap_words=$(wc -w < "${bootstrap_skill}")
if [ "${bootstrap_words}" -gt 500 ]; then
  echo "FAIL: t-using-superpowers is too large (${bootstrap_words} words; maximum 500)"
  exit 1
fi

for removed_reference in \
  skills/t-using-superpowers/references/copilot-tools.md \
  skills/t-using-superpowers/references/gemini-tools.md; do
  if [ -e "${removed_reference}" ]; then
    echo "FAIL: obsolete platform reference remains: ${removed_reference}"
    exit 1
  fi
done

if rg -n '\bclose_agent\b' skills/t-using-superpowers/references/codex-tools.md >/dev/null; then
  echo "FAIL: Codex mapping references unavailable close_agent"
  exit 1
fi

# SessionStart no longer emits the legacy custom-skills warning and applies the
# accepted EPIPE workaround to all three JSON output branches.
if rg -n '~/.config/superpowers/skills|legacy_skills_dir|warning_message' hooks/session-start >/dev/null; then
  echo "FAIL: hooks/session-start retains obsolete legacy skills warning"
  exit 1
fi

printf_pipelines=$(rg -c 'printf .*"\$session_context" \| cat$' hooks/session-start || true)
if [ "${printf_pipelines}" -ne 3 ]; then
  echo "FAIL: hooks/session-start must pipe all three JSON printf outputs through cat"
  exit 1
fi

# Exercise each SessionStart output branch and validate its public JSON shape.
python3 - <<'PY'
import json
import os
import subprocess
import sys


def fail(message):
    print(f"FAIL hooks/session-start: {message}", file=sys.stderr)
    sys.exit(1)


cases = (
    ("cursor", {"CURSOR_PLUGIN_ROOT": "/tmp/t-superpowers"}, "additional_context"),
    ("claude", {"CLAUDE_PLUGIN_ROOT": "/tmp/t-superpowers"}, "hookSpecificOutput"),
    ("sdk", {}, "additionalContext"),
)

for name, additions, expected_key in cases:
    env = os.environ.copy()
    for variable in ("CURSOR_PLUGIN_ROOT", "CLAUDE_PLUGIN_ROOT", "COPILOT_CLI"):
        env.pop(variable, None)
    env.update(additions)

    result = subprocess.run(
        ["bash", "hooks/session-start"],
        env=env,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        fail(f"{name} exited {result.returncode}: {result.stderr.strip()}")

    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        fail(f"{name} emitted invalid JSON: {error}")

    if set(payload) != {expected_key}:
        fail(f"{name} expected only {expected_key!r}, got {sorted(payload)!r}")

    if name == "claude":
        nested = payload[expected_key]
        if set(nested) != {"hookEventName", "additionalContext"}:
            fail(f"claude nested keys invalid: {sorted(nested)!r}")
        if nested["hookEventName"] != "SessionStart":
            fail("claude hookEventName is not SessionStart")
        context = nested["additionalContext"]
    else:
        context = payload[expected_key]

    if "t-superpowers:t-using-superpowers" not in context:
        fail(f"{name} context missing t-superpowers identity")
    if "~/.config/superpowers/skills" in context or "legacy_skills_dir" in context:
        fail(f"{name} context retains legacy warning")
PY

# Offline integrity gate for the exact upstream vendor pathspec.
python3 - <<'PY'
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

EXPECTED_COMMIT = "d884ae04edebef577e82ff7c4e143debd0bbec99"
EXPECTED_SCOPE = [
    "skills",
    "hooks",
    "CLAUDE.md",
    "AGENTS.md",
    "GEMINI.md",
    ".claude-plugin/plugin.json",
    ".claude-plugin/marketplace.json",
    ".cursor-plugin/plugin.json",
    ".codex-plugin/plugin.json",
    "package.json",
    "gemini-extension.json",
    ".opencode/plugins/superpowers.js",
]
ROOT = Path("vendor/superpowers")
MANIFEST = ROOT / "UPSTREAM_MANIFEST"
METADATA_PATHS = {"UPSTREAM_COMMIT", "UPSTREAM_MANIFEST"}


def fail(message):
    print(f"FAIL vendor baseline: {message}", file=sys.stderr)
    sys.exit(1)


def git_blob_id(data):
    header = f"blob {len(data)}\0".encode()
    return hashlib.sha1(header + data).hexdigest()


if not MANIFEST.is_file():
    fail("vendor/superpowers/UPSTREAM_MANIFEST missing")

metadata = {}
metadata_file = ROOT / "UPSTREAM_COMMIT"
if not metadata_file.is_file():
    fail("vendor/superpowers/UPSTREAM_COMMIT missing")
for line in metadata_file.read_text(encoding="utf-8").splitlines():
    if ":" in line:
        key, value = line.split(":", 1)
        metadata[key.strip()] = value.strip()
if metadata.get("commit") != EXPECTED_COMMIT:
    fail(f"UPSTREAM_COMMIT must be {EXPECTED_COMMIT}, got {metadata.get('commit')!r}")

try:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
except (OSError, json.JSONDecodeError) as error:
    fail(f"cannot read UPSTREAM_MANIFEST: {error}")

if manifest.get("schema_version") != 1:
    fail("UPSTREAM_MANIFEST schema_version must be 1")
if manifest.get("upstream_commit") != EXPECTED_COMMIT:
    fail("UPSTREAM_MANIFEST upstream_commit mismatch")
if manifest.get("scope") != EXPECTED_SCOPE:
    fail("UPSTREAM_MANIFEST scope mismatch")

attributes = subprocess.check_output(
    [
        "git",
        "check-attr",
        "text",
        "whitespace",
        "--",
        "vendor/superpowers/CLAUDE.md",
    ],
    text=True,
)
if "text: unset" not in attributes or "whitespace: unset" not in attributes:
    fail("vendor subtree must set both -text and -whitespace in .gitattributes")

entries = manifest.get("entries")
if not isinstance(entries, list):
    fail("UPSTREAM_MANIFEST entries must be a list")
if len(entries) != 62:
    fail(f"UPSTREAM_MANIFEST must contain 62 entries, got {len(entries)}")

expected = {}
for entry in entries:
    path = entry.get("path")
    if not isinstance(path, str) or not path or path in METADATA_PATHS:
        fail(f"invalid manifest path: {path!r}")
    if path in expected:
        fail(f"duplicate manifest path: {path}")
    expected[path] = entry
if list(expected) != sorted(expected):
    fail("UPSTREAM_MANIFEST entries must be path-sorted")

actual = {}
for path in ROOT.rglob("*"):
    if path.is_dir() and not path.is_symlink():
        continue
    relative = path.relative_to(ROOT).as_posix()
    if relative in METADATA_PATHS:
        continue
    stat = path.lstat()
    if path.is_symlink():
        target = os.readlink(path)
        data = os.fsencode(target)
        actual[relative] = {
            "path": relative,
            "mode": "120000",
            "type": "symlink",
            "git_blob": git_blob_id(data),
            "target": target,
        }
    elif path.is_file():
        data = path.read_bytes()
        actual[relative] = {
            "path": relative,
            "mode": "100755" if stat.st_mode & 0o111 else "100644",
            "type": "file",
            "git_blob": git_blob_id(data),
        }
    else:
        fail(f"unsupported filesystem entry: {relative}")

if set(actual) != set(expected):
    missing = sorted(set(expected) - set(actual))
    unexpected = sorted(set(actual) - set(expected))
    fail(f"path set mismatch; missing={missing}, unexpected={unexpected}")
for path in sorted(expected):
    if actual[path] != expected[path]:
        fail(f"content/mode/type mismatch: {path}")
PY

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
