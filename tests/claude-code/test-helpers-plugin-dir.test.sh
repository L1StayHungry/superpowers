#!/usr/bin/env bash
# Tests that run_claude loads the local plugin under test.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

fakebin="$TMP_DIR/bin"
mkdir -p "$fakebin"

cat > "$fakebin/claude" <<'CLAUDE'
#!/usr/bin/env bash
printf '%s\n' "$*" > "$CLAUDE_ARGS_LOG"
echo "fake claude output"
CLAUDE
chmod +x "$fakebin/claude"

cat > "$fakebin/python3" <<'PYTHON'
#!/usr/bin/env bash
shift 3
exec "$@"
PYTHON
chmod +x "$fakebin/python3"

source "$SCRIPT_DIR/test-helpers.sh"

PATH="$fakebin:/usr/bin:/bin" \
  CLAUDE_ARGS_LOG="$TMP_DIR/claude.args" \
  run_claude "hello" 42 >/dev/null

args="$(cat "$TMP_DIR/claude.args")"

if ! printf '%s\n' "$args" | grep -q -- "--plugin-dir $PLUGIN_DIR"; then
  echo "FAIL: run_claude should pass --plugin-dir for the local plugin"
  echo "  args: $args"
  exit 1
fi

echo "PASS: run_claude passes local --plugin-dir"
