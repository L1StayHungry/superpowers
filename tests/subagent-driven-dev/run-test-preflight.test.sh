#!/usr/bin/env bash
# Tests prerequisite checks for subagent-driven-development fixtures.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUN_TEST="$SCRIPT_DIR/run-test.sh"
TMP_DIR="$(mktemp -d)"
DYNAMIC_FIXTURE_DIR=""

cleanup() {
  rm -rf "$TMP_DIR"
  if [ -n "$DYNAMIC_FIXTURE_DIR" ]; then
    rm -rf "$DYNAMIC_FIXTURE_DIR"
  fi
}
trap cleanup EXIT

pass=0
fail=0

assert_prereq_exit() {
  local name="$1"
  local expected="$2"
  shift 2

  set +e
  "$@" >"$TMP_DIR/out" 2>"$TMP_DIR/err"
  local status=$?
  set -e

  local output
  output="$(cat "$TMP_DIR/out" "$TMP_DIR/err")"

  if [ "$status" -ne 78 ]; then
    echo "FAIL: $name"
    echo "  expected exit 78, got $status"
    echo "$output" | sed 's/^/  /'
    fail=$((fail + 1))
    return
  fi

  if ! printf '%s\n' "$output" | grep -q "$expected"; then
    echo "FAIL: $name"
    echo "  expected output containing: $expected"
    echo "$output" | sed 's/^/  /'
    fail=$((fail + 1))
    return
  fi

  echo "PASS: $name"
  pass=$((pass + 1))
}

fakebin="$TMP_DIR/fakebin"
mkdir -p "$fakebin"

cat > "$fakebin/node" <<'NODE'
#!/usr/bin/env bash
if [ "$1" = "-p" ]; then
  echo "20.9.0"
else
  echo "fake node only supports -p" >&2
  exit 1
fi
NODE
chmod +x "$fakebin/node"

assert_prereq_exit \
  "svelte-todo rejects Node versions too old for create-vite" \
  "SKIP: prerequisite missing or unsupported: node >= 20.19.0 or >= 22.12.0 required" \
  env PATH="$fakebin:/usr/bin:/bin" "$RUN_TEST" svelte-todo --plugin-dir "$SCRIPT_DIR/../.."

assert_prereq_exit \
  "go-fractals rejects missing go before invoking Claude" \
  "SKIP: prerequisite missing or unsupported: go command not found" \
  env PATH="/usr/bin:/bin" "$RUN_TEST" go-fractals --plugin-dir "$SCRIPT_DIR/../.."

assert_scaffold_tool_note() {
  local name="$1"
  local dir="$TMP_DIR/$name-project"

  "$SCRIPT_DIR/$name/scaffold.sh" "$dir" >/dev/null

  if [ ! -f "$dir/CLAUDE.md" ]; then
    echo "FAIL: $name scaffold writes Claude tool compatibility note"
    echo "  missing $dir/CLAUDE.md"
    fail=$((fail + 1))
    return
  fi

  if ! grep -q 'never pass an empty `pages` value' "$dir/CLAUDE.md"; then
    echo "FAIL: $name scaffold writes Claude tool compatibility note"
    echo "  CLAUDE.md did not contain Read pages guidance"
    fail=$((fail + 1))
    return
  fi

  if ! grep -q 'Do not use the Read tool' "$dir/CLAUDE.md"; then
    echo "FAIL: $name scaffold writes Claude tool compatibility note"
    echo "  CLAUDE.md did not tell Claude to avoid the Read tool"
    fail=$((fail + 1))
    return
  fi

  if ! grep -q 'merged or cherry-picked back into this repository before reporting DONE' "$dir/CLAUDE.md"; then
    echo "FAIL: $name scaffold writes worktree completion note"
    echo "  CLAUDE.md did not require worktree results to return to the main repo"
    fail=$((fail + 1))
    return
  fi

  if grep -q 'Read(\*\*)' "$dir/.claude/settings.local.json"; then
    echo "FAIL: $name scaffold does not allow Read in local settings"
    echo "  settings.local.json still allows Read(**)"
    fail=$((fail + 1))
    return
  fi

  echo "PASS: $name scaffold writes Claude tool compatibility note"
  pass=$((pass + 1))
}

assert_scaffold_tool_note svelte-todo
assert_scaffold_tool_note go-fractals

assert_verifier_failure_propagates() {
  local name="run-test propagates fixture verifier failures"
  local fixture_name
  fixture_name="$(basename "$(mktemp -d "$SCRIPT_DIR/preflight-verifier-fail.XXXXXX")")"
  DYNAMIC_FIXTURE_DIR="$SCRIPT_DIR/$fixture_name"

  cat > "$DYNAMIC_FIXTURE_DIR/scaffold.sh" <<'SCAFFOLD'
#!/usr/bin/env bash
set -e

target_dir="${1:?Usage: $0 TARGET_DIRECTORY}"
mkdir -p "$target_dir"
cd "$target_dir"

git init
printf '%s\n' "# Preflight verifier failure fixture" > README.md
git add README.md
git -c user.name="Preflight Test" -c user.email="preflight@example.com" commit -m "Initial fixture project"
SCAFFOLD
  chmod +x "$DYNAMIC_FIXTURE_DIR/scaffold.sh"

cat > "$DYNAMIC_FIXTURE_DIR/verify.sh" <<'VERIFY'
#!/usr/bin/env bash
echo "PREFLIGHT_VERIFIER_MARKER"
exit 7
VERIFY
  chmod +x "$DYNAMIC_FIXTURE_DIR/verify.sh"

  local fake_claude_dir="$TMP_DIR/fake-claude-bin"
  mkdir -p "$fake_claude_dir"
  cat > "$fake_claude_dir/claude" <<'CLAUDE'
#!/usr/bin/env bash
echo '{"type":"result","usage":{"input_tokens":0,"output_tokens":0}}'
exit 0
CLAUDE
  chmod +x "$fake_claude_dir/claude"

  set +e
  env PATH="$fake_claude_dir:/usr/bin:/bin" "$RUN_TEST" "$fixture_name" --plugin-dir "$SCRIPT_DIR/../.." --timeout 5 >"$TMP_DIR/verifier-out" 2>"$TMP_DIR/verifier-err"
  local status=$?
  set -e

  local output
  output="$(cat "$TMP_DIR/verifier-out" "$TMP_DIR/verifier-err")"

  if [ "$status" -ne 7 ]; then
    echo "FAIL: $name"
    echo "  expected exit 7, got $status"
    echo "$output" | sed 's/^/  /'
    fail=$((fail + 1))
    return
  fi

  if ! printf '%s\n' "$output" | grep -q 'Fixture verifier failed'; then
    echo "FAIL: $name"
    echo "  expected output containing: Fixture verifier failed"
    echo "$output" | sed 's/^/  /'
    fail=$((fail + 1))
    return
  fi

  if ! printf '%s\n' "$output" | grep -q 'PREFLIGHT_VERIFIER_MARKER'; then
    echo "FAIL: $name"
    echo "  expected output containing verifier marker"
    echo "$output" | sed 's/^/  /'
    fail=$((fail + 1))
    return
  fi

  echo "PASS: $name"
  pass=$((pass + 1))
}

assert_verifier_failure_propagates

if grep -q -- "--disallowed-tools Read" "$RUN_TEST"; then
  echo "PASS: run-test disables Read in Claude Code harness runs"
  pass=$((pass + 1))
else
  echo "FAIL: run-test disables Read in Claude Code harness runs"
  echo "  missing --disallowed-tools Read"
  fail=$((fail + 1))
fi

if grep -q 'run_with_timeout "$TIMEOUT_SECONDS" claude' "$RUN_TEST"; then
  echo "PASS: run-test wraps Claude with a portable timeout"
  pass=$((pass + 1))
else
  echo "FAIL: run-test wraps Claude with a portable timeout"
  fail=$((fail + 1))
fi

if grep -q 'CLAUDE_STATUS=$?' "$RUN_TEST" && grep -q 'exit "$CLAUDE_STATUS"' "$RUN_TEST"; then
  echo "PASS: run-test propagates Claude exit status"
  pass=$((pass + 1))
else
  echo "FAIL: run-test propagates Claude exit status"
  fail=$((fail + 1))
fi

if grep -q 'merge or cherry-pick every subagent commit back into the current repository' "$RUN_TEST"; then
  echo "PASS: run-test prompt requires worktree results to be merged back"
  pass=$((pass + 1))
else
  echo "FAIL: run-test prompt requires worktree results to be merged back"
  fail=$((fail + 1))
fi

if grep -q 'do not loop indefinitely debugging browser fetches' "$RUN_TEST"; then
  echo "PASS: run-test prompt limits Svelte dev-server verification loops"
  pass=$((pass + 1))
else
  echo "FAIL: run-test prompt limits Svelte dev-server verification loops"
  fail=$((fail + 1))
fi

if grep -q 'run_fixture_verifier "$TEST_DIR" "$OUTPUT_DIR/project" "$LOG_FILE"' "$RUN_TEST"; then
  echo "PASS: run-test runs fixture verifier after successful Claude runs"
  pass=$((pass + 1))
else
  echo "FAIL: run-test runs fixture verifier after successful Claude runs"
  echo '  missing run_fixture_verifier "$TEST_DIR" "$OUTPUT_DIR/project" "$LOG_FILE"'
  fail=$((fail + 1))
fi

if awk '
  /t-smoke\)/ { in_t_smoke = 1 }
  in_t_smoke && /cd \$OUTPUT_DIR\/project && npm test/ { found = 1 }
  in_t_smoke && /;;/ { in_t_smoke = 0 }
  END { exit found ? 0 : 1 }
' "$RUN_TEST"; then
  echo "PASS: run-test prints t-smoke npm test next steps"
  pass=$((pass + 1))
else
  echo "FAIL: run-test prints t-smoke npm test next steps"
  echo '  missing t-smoke) case with cd $OUTPUT_DIR/project && npm test'
  fail=$((fail + 1))
fi

echo "Results: $pass passed, $fail failed"
if [ "$fail" -gt 0 ]; then
  exit 1
fi
