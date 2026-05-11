#!/usr/bin/env bash
# Tests timeout fallback used by shared Claude Code test helpers.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

fakebin="$TMP_DIR/bin"
mkdir -p "$fakebin"

cat > "$fakebin/claude" <<'CLAUDE'
#!/usr/bin/env bash
echo "fake claude output"
CLAUDE
chmod +x "$fakebin/claude"

cat > "$fakebin/python3" <<'PYTHON'
#!/usr/bin/env bash
printf 'python:%s\n' "$3" >> "$TIMEOUT_LOG"
shift 3
exec "$@"
PYTHON
chmod +x "$fakebin/python3"

source "$SCRIPT_DIR/test-helpers.sh"

: > "$TMP_DIR/timeout.log"

output="$(
  PATH="$fakebin:/usr/bin:/bin" \
    TIMEOUT_LOG="$TMP_DIR/timeout.log" \
    run_claude "hello" 42
)"

if [ "$output" != "fake claude output" ]; then
  echo "FAIL: run_claude should return claude output"
  echo "  got: $output"
  exit 1
fi

if [ "$(cat "$TMP_DIR/timeout.log")" != "python:42" ]; then
  echo "FAIL: run_claude should use python fallback when timeout is unavailable"
  cat "$TMP_DIR/timeout.log"
  exit 1
fi

echo "PASS: run_claude uses python timeout fallback"

real_python="$(command -v python3)"
real_bash="$(command -v bash)"
rm -f "$fakebin/python3"
ln -s "$real_python" "$fakebin/python3"
ln -s "$real_bash" "$fakebin/bash"

cat > "$TMP_DIR/stdin-check.sh" <<'SCRIPT'
#!/usr/bin/env bash
if IFS= read -r line; then
  echo "unexpected stdin: $line"
  exit 1
fi
echo "stdin closed"
SCRIPT
chmod +x "$TMP_DIR/stdin-check.sh"

stdin_output="$(
  PATH="$fakebin" run_with_timeout 5 bash "$TMP_DIR/stdin-check.sh"
)"

if [ "$stdin_output" != "stdin closed" ]; then
  echo "FAIL: run_with_timeout should not leak its Python heredoc to child stdin"
  echo "$stdin_output"
  exit 1
fi

echo "PASS: run_with_timeout closes child stdin in python fallback"
