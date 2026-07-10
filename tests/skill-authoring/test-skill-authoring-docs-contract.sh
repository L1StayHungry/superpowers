#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GETTING_STARTED="$ROOT_DIR/docsDev/getting-started.md"
INSTALLER="$ROOT_DIR/docsDev/t-superpowers-installer.md"
CHANGELOG="$ROOT_DIR/CHANGELOG.md"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

for contract in \
  '## Selectively Adopted From Upstream v6.1.1' \
  'Global Constraints' \
  'single consolidated reviewer' \
  'Skill Discovery Optimization'; do
  grep -Fq "$contract" "$GETTING_STARTED" ||
    fail "$GETTING_STARTED is missing release guidance: $contract"
done

grep -Fq 'npx @4399/tdata-t-superpowers@latest install codex' "$GETTING_STARTED" ||
  fail "$GETTING_STARTED still treats the Codex package as unavailable"
grep -Fq '5+ fresh-context repetitions per wording variant' "$INSTALLER" ||
  fail "$INSTALLER does not document the strengthened skill-authoring evidence"
grep -Fq 'one consolidated reviewer per task' "$INSTALLER" ||
  fail "$INSTALLER does not document the strengthened SDD review boundary"

for entry in \
  'Selective upstream v6.1.1 runtime and visual-companion hardening' \
  'Planning, SDD, worktree, and finishing workflow upgrades' \
  'Skill Discovery Optimization, failure-matched guidance'; do
  grep -Fq "$entry" "$CHANGELOG" ||
    fail "$CHANGELOG is missing Unreleased entry: $entry"
done

if rg -n 'Kimi|Antigravity|Pi harness|Codex portal|official Codex plugin marketplace' \
  "$GETTING_STARTED" "$INSTALLER" "$CHANGELOG" >/dev/null; then
  fail 'internal documentation added an unsupported distribution channel'
fi

printf 'PASS: onboarding, installer, and Unreleased notes document only the supported selective v6.1.1 workflow\n'
