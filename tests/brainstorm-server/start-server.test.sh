#!/usr/bin/env bash
# Fast tests for start-server.sh shell-only platform decisions.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
START_SCRIPT="$REPO_ROOT/skills/t-brainstorming/scripts/start-server.sh"

TEST_DIR="${TMPDIR:-/tmp}/brainstorm-start-test-$$"
passed=0
failed=0

cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

pass() {
  echo "  PASS: $1"
  passed=$((passed + 1))
}

fail() {
  echo "  FAIL: $1"
  echo "    $2"
  failed=$((failed + 1))
}

assert_missing_value_fails_fast() {
  local option="$1"
  local output_file="$TEST_DIR/missing-${option#--}.out"
  bash "$START_SCRIPT" "$option" >"$output_file" 2>&1 &
  local pid=$!
  local still_running=true
  for _ in $(seq 1 20); do
    if ! kill -0 "$pid" 2>/dev/null; then
      still_running=false
      break
    fi
    sleep 0.05
  done
  if [[ "$still_running" == "true" ]]; then
    kill -9 "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
    fail "$option without a value exits quickly" "script was still running after one second"
    return
  fi
  local status=0
  wait "$pid" || status=$?
  if [[ "$status" -ne 0 ]] && grep -q -- "$option requires a value" "$output_file"; then
    pass "$option without a value exits quickly"
  else
    fail "$option without a value exits quickly" "status=$status output=$(cat "$output_file")"
  fi
}

make_fake_uname() {
  local fake_bin="$1"
  cat > "$fake_bin/uname" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "-s" ]]; then
  echo "MINGW64_NT-10.0"
else
  /usr/bin/uname "$@"
fi
EOF
  chmod +x "$fake_bin/uname"
}

echo ""
echo "--- start-server.sh platform detection ---"

mkdir -p "$TEST_DIR/fake-bin" "$TEST_DIR/project"
make_fake_uname "$TEST_DIR/fake-bin"

echo ""
echo "--- start-server.sh option validation ---"
for option in --project-dir --host --url-host --idle-timeout-minutes; do
  assert_missing_value_fails_fast "$option"
done

cat > "$TEST_DIR/fake-bin/node" <<'EOF'
#!/usr/bin/env bash
echo "CAPTURED_OWNER_PID=${BRAINSTORM_OWNER_PID:-__UNSET__}"
printf 'CAPTURED_ARGV=%s\n' "$@"
exit 0
EOF
chmod +x "$TEST_DIR/fake-bin/node"

captured=$(
  PATH="$TEST_DIR/fake-bin:$PATH" \
    MSYSTEM="" \
    bash "$START_SCRIPT" --project-dir "$TEST_DIR/project" --foreground 2>/dev/null || true
)
owner_pid_value=$(echo "$captured" | grep "CAPTURED_OWNER_PID=" | head -1 | sed 's/CAPTURED_OWNER_PID=//')

if [[ "$owner_pid_value" == "" || "$owner_pid_value" == "__UNSET__" ]]; then
  pass "clears BRAINSTORM_OWNER_PID when uname reports a Windows-like shell"
else
  fail "clears BRAINSTORM_OWNER_PID when uname reports a Windows-like shell" \
       "expected empty or unset, got '$owner_pid_value'"
fi

if echo "$captured" | grep -Eq '^CAPTURED_ARGV=--brainstorm-server-id=[A-Za-z0-9_-]{32,64}$'; then
  pass "passes shell-safe server instance id argv"
else
  fail "passes shell-safe server instance id argv" \
       "expected exact --brainstorm-server-id=<safe id> argv line, got: $captured"
fi

server_id_file=$(find "$TEST_DIR/project/.t-superpowers/brainstorm" -name server-instance-id -print 2>/dev/null | head -1)
server_id_value=""
if [[ -n "$server_id_file" ]]; then
  server_id_value="$(tr -d '\r\n' < "$server_id_file")"
fi
if [[ "$server_id_value" =~ ^[A-Za-z0-9_-]{32,64}$ ]]; then
  pass "writes shell-safe server-instance-id state file"
else
  fail "writes shell-safe server-instance-id state file" \
       "expected valid id in state, got '$server_id_value'"
fi

mkdir -p "$TEST_DIR/tmp"
captured=$(
  PATH="$TEST_DIR/fake-bin:$PATH" \
    TMPDIR="$TEST_DIR/tmp/" \
    MSYSTEM="" \
    bash "$START_SCRIPT" --foreground 2>/dev/null || true
)
cleanup_marker=$(find "$TEST_DIR/tmp/t-superpowers-brainstorm" -name cleanup-marker -print 2>/dev/null | head -1)
if [[ -f "$cleanup_marker" ]]; then
  marker_mode=$(stat -f '%Lp' "$cleanup_marker" 2>/dev/null || stat -c '%a' "$cleanup_marker" 2>/dev/null || true)
  if [[ "$marker_mode" == "600" ]]; then
    pass "default temporary sessions use the stable root and an owner-only cleanup marker"
  else
    fail "default temporary sessions use the stable root and an owner-only cleanup marker" \
         "marker mode was '$marker_mode' at '$cleanup_marker'"
  fi
else
  fail "default temporary sessions use the stable root and an owner-only cleanup marker" \
       "cleanup marker missing beneath $TEST_DIR/tmp/t-superpowers-brainstorm"
fi

rm -rf "$TEST_DIR/project"/*

cat > "$TEST_DIR/fake-bin/node" <<'EOF'
#!/usr/bin/env bash
echo "FOREGROUND_MODE=true"
exit 0
EOF
chmod +x "$TEST_DIR/fake-bin/node"

captured=$(
  PATH="$TEST_DIR/fake-bin:$PATH" \
    MSYSTEM="" \
    bash "$START_SCRIPT" --project-dir "$TEST_DIR/project" 2>/dev/null || true
)

if echo "$captured" | grep -q "FOREGROUND_MODE=true"; then
  pass "auto-foregrounds when uname reports a Windows-like shell"
else
  fail "auto-foregrounds when uname reports a Windows-like shell" \
       "expected foreground node path, got: $captured"
fi

echo ""
echo "--- Results: $passed passed, $failed failed ---"
if [[ $failed -gt 0 ]]; then
  exit 1
fi
