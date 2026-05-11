#!/usr/bin/env bash
# Tests timeout handling in the Claude Code skill test runner.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

fakebin="$TMP_DIR/bin"
work="$TMP_DIR/claude-code"
mkdir -p "$fakebin" "$work"

cp "$SCRIPT_DIR/run-skill-tests.sh" "$work/"

cat > "$work/test-subagent-driven-development-integration.sh" <<'TEST'
#!/usr/bin/env bash
exit 0
TEST
chmod +x "$work/test-subagent-driven-development-integration.sh"

cat > "$fakebin/claude" <<'CLAUDE'
#!/usr/bin/env bash
if [ "${1:-}" = "--version" ]; then
  echo "fake claude"
  exit 0
fi
exit 0
CLAUDE
chmod +x "$fakebin/claude"

cat > "$fakebin/timeout" <<'TIMEOUT'
#!/usr/bin/env bash
printf '%s\n' "$1" >> "$TIMEOUT_LOG"
shift
exec "$@"
TIMEOUT
chmod +x "$fakebin/timeout"

run_case() {
  local name="$1"
  local expected="$2"
  shift 2

  : > "$TMP_DIR/timeout.log"

  PATH="$fakebin:/usr/bin:/bin" \
    TIMEOUT_LOG="$TMP_DIR/timeout.log" \
    bash "$work/run-skill-tests.sh" "$@" >/dev/null

  local actual
  actual="$(tail -1 "$TMP_DIR/timeout.log")"

  if [ "$actual" != "$expected" ]; then
    echo "FAIL: $name"
    echo "  expected timeout $expected, got $actual"
    exit 1
  fi

  echo "PASS: $name"
}

run_python_fallback_case() {
  rm -f "$fakebin/timeout"

  cat > "$fakebin/python3" <<'PYTHON'
#!/usr/bin/env bash
printf 'python:%s\n' "$3" >> "$TIMEOUT_LOG"
shift 3
exec "$@"
PYTHON
  chmod +x "$fakebin/python3"

  : > "$TMP_DIR/timeout.log"

  PATH="$fakebin:/usr/bin:/bin" \
    TIMEOUT_LOG="$TMP_DIR/timeout.log" \
    bash "$work/run-skill-tests.sh" --test test-subagent-driven-development-integration.sh --timeout 42 >/dev/null

  local actual
  actual="$(tail -1 "$TMP_DIR/timeout.log")"

  if [ "$actual" != "python:42" ]; then
    echo "FAIL: python fallback is used when timeout is unavailable"
    echo "  expected python:42, got $actual"
    exit 1
  fi

  echo "PASS: python fallback is used when timeout is unavailable"
}

run_case \
  "integration test defaults to 1800 seconds" \
  "1800" \
  --integration --test test-subagent-driven-development-integration.sh

run_case \
  "explicit timeout is preserved" \
  "42" \
  --integration --test test-subagent-driven-development-integration.sh --timeout 42

run_python_fallback_case
