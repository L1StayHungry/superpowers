#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
WORKTREE_SKILL="${WORKTREE_SKILL:-$ROOT_DIR/skills/t-using-git-worktrees/SKILL.md}"
FINISHING_SKILL="${FINISHING_SKILL:-$ROOT_DIR/skills/t-finishing-a-development-branch/SKILL.md}"

failures=0

pass() {
  echo "PASS: $1"
}

fail() {
  echo "FAIL: $1" >&2
  failures=$((failures + 1))
}

require_fixed() {
  local file="$1"
  local literal="$2"
  local description="$3"
  if rg -q --fixed-strings -- "$literal" "$file"; then
    pass "$description"
  else
    fail "$description (missing: $literal)"
  fi
}

require_regex() {
  local file="$1"
  local pattern="$2"
  local description="$3"
  if rg -q -- "$pattern" "$file"; then
    pass "$description"
  else
    fail "$description (missing pattern: $pattern)"
  fi
}

forbid_fixed() {
  local file="$1"
  local literal="$2"
  local description="$3"
  if rg -q --fixed-strings -- "$literal" "$file"; then
    fail "$description (found: $literal)"
  else
    pass "$description"
  fi
}

require_order() {
  local file="$1"
  local first="$2"
  local second="$3"
  local description="$4"
  local first_line second_line
  first_line="$(rg -n -m 1 -- "$first" "$file" | cut -d: -f1 || true)"
  second_line="$(rg -n -m 1 -- "$second" "$file" | cut -d: -f1 || true)"
  if [ -n "$first_line" ] && [ -n "$second_line" ] && [ "$first_line" -lt "$second_line" ]; then
    pass "$description"
  else
    fail "$description"
  fi
}

verify_absent_location_ignore_behavior() {
  local repo location probe_command
  repo="$(mktemp -d "${TMPDIR:-/tmp}/t-worktree-ignore.XXXXXX")"
  git -C "$repo" init -q
  printf '%s\n' '.worktrees/' > "$repo/.gitignore"
  probe_command="$(rg -m 1 '^git check-ignore -q ' "$WORKTREE_SKILL" || true)"

  if [ -z "$probe_command" ]; then
    fail "worktree skill exposes a gitignore safety probe"
    rm -rf "$repo"
    return
  fi
  pass "worktree skill exposes a gitignore safety probe"

  if [ -e "$repo/.worktrees" ] || [ -e "$repo/worktrees" ]; then
    fail "ignore behavior fixture starts with both worktree directories absent"
    rm -rf "$repo"
    return
  fi
  pass "ignore behavior fixture starts with both worktree directories absent"

  location=".worktrees"
  if (cd "$repo" && LOCATION="$location" bash -c "$probe_command"); then
    pass "the skill probe matches an absent directory with a trailing-slash gitignore rule"
  else
    fail "the skill probe matches an absent directory with a trailing-slash gitignore rule"
  fi

  location="worktrees"
  if (cd "$repo" && LOCATION="$location" bash -c "$probe_command"); then
    fail "the skill probe rejects an absent unignored directory"
  else
    pass "the skill probe rejects an absent unignored directory"
  fi

  rm -rf "$repo"
}

echo "=== Worktree location contract ==="
forbid_fixed "$WORKTREE_SKILL" '~/.config/superpowers/worktrees/' "legacy global worktree fallback is absent"
require_regex "$WORKTREE_SKILL" 'declared worktree directory preference|explicit.*worktree.*preference' "explicit user preference is honored"
require_fixed "$WORKTREE_SKILL" 'ls -d .worktrees' "existing hidden project directory is detected"
require_fixed "$WORKTREE_SKILL" 'ls -d worktrees' "existing visible project directory is detected"
require_regex "$WORKTREE_SKILL" 'default.*`.worktrees/`|Default.*`.worktrees/`' "project-local .worktrees is the default"
require_order "$WORKTREE_SKILL" 'declared worktree directory preference|explicit.*worktree.*preference' 'existing project-local worktree directory' "explicit preference precedes existing-directory detection"
require_order "$WORKTREE_SKILL" 'existing project-local worktree directory' 'default.*`.worktrees/`|Default.*`.worktrees/`' "existing-directory detection precedes the default"
require_fixed "$WORKTREE_SKILL" 'git check-ignore -q "${LOCATION%/}/"' "the exact project-local worktree directory is probed with directory semantics"
require_regex "$WORKTREE_SKILL" 'absolute location outside the repository.*user-owned|outside the repository is user-owned' "explicit external locations are not treated as project-owned"
require_regex "$WORKTREE_SKILL" 'Add.*\.gitignore.*commit|add.*\.gitignore.*commit' "missing ignore rule is committed before worktree creation"
verify_absent_location_ignore_behavior

echo "=== Finishing safety contract ==="
require_fixed "$FINISHING_SKILL" 'INTEGRATION_BRANCH' "local integration branch is tracked separately"
require_fixed "$FINISHING_SKILL" 'FORK_BASE_REF' "fork base reference is tracked separately"
require_fixed "$FINISHING_SKILL" 'FORK_POINT' "fork point is explicit"
require_fixed "$FINISHING_SKILL" 'git merge-base HEAD "$FORK_BASE_REF"' "fork point is computed conservatively"
require_fixed "$FINISHING_SKILL" 'git fetch --all --prune' "remote refs are refreshed before reorganization"
require_fixed "$FINISHING_SKILL" 'git branch -r --contains "$sha"' "shared commits are detected"
require_regex "$FINISHING_SKILL" 'explicit.*confirm|explicit.*option 1 confirmation' "soft reset requires explicit confirmation"
require_order "$FINISHING_SKILL" 'explicit.*confirm|explicit.*option 1 confirmation' 'git reset --soft' "confirmation appears before the soft reset instruction"
require_fixed "$FINISHING_SKILL" 'You may use git add and git commit only.' "t-git-commit is limited to add and commit"
require_fixed "$FINISHING_SKILL" 'Do not run reset, rebase, checkout, clean, stash, or force-push.' "t-git-commit cannot rewrite history"
require_fixed "$FINISHING_SKILL" 'ORIG_TREE=$(git rev-parse HEAD^{tree})' "pre-reorganization tree is recorded"
require_fixed "$FINISHING_SKILL" 'test "$(git rev-parse HEAD^{tree})" = "$ORIG_TREE"' "tree equivalence is verified"

echo "=== Forge-neutral completion contract ==="
forbid_fixed "$FINISHING_SKILL" '~/.config/superpowers/worktrees/' "legacy global worktree cleanup ownership is absent"
forbid_fixed "$FINISHING_SKILL" 'gh pr create' "GitHub CLI PR creation is not hardcoded"
require_regex "$FINISHING_SKILL" 'forge.*(tool|integration)|available.*forge' "change request creation uses an available forge tool"
require_regex "$FINISHING_SKILL" 'pull request.*merge request|PR/MR|change request' "provider-neutral change request terminology is present"
require_regex "$FINISHING_SKILL" 'standard-menu Option 2' "named-branch push is gated by the user's finishing choice"
require_regex "$FINISHING_SKILL" 'detached-HEAD-menu Option 1' "detached-HEAD push is gated by the user's finishing choice"
require_regex "$FINISHING_SKILL" 'equivalent direct push/change-request instruction' "an equivalent direct instruction counts as explicit authorization"
require_fixed "$FINISHING_SKILL" 'git push -u origin <feature-branch>' "named branches use a non-force upstream push"
require_fixed "$FINISHING_SKILL" 'git push -u origin HEAD:refs/heads/<new-branch>' "detached HEAD uses a non-force explicit branch push"
require_regex "$FINISHING_SKILL" 'Do NOT clean up worktree|Do not clean up the worktree' "review workspace is preserved after push"

if [ "$failures" -ne 0 ]; then
  echo "FAILED: $failures contract assertion(s)" >&2
  exit 1
fi

echo "PASSED: worktree and finishing contracts"
