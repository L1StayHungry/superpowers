#!/usr/bin/env bash
# Tests for stop-server.sh PID-ownership safety.
#
# A stale server.pid (e.g. after a reboot, when the kernel has recycled the PID)
# can point at an unrelated, live process. stop-server.sh must verify the PID is
# actually our brainstorm server before signalling it.

set -u
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STOP="$SCRIPT_DIR/../../skills/t-brainstorming/scripts/stop-server.sh"
SERVER="$SCRIPT_DIR/../../skills/t-brainstorming/scripts/server.cjs"

PASS=0; FAIL=0
PIDS=()
DIRS=()

cleanup() {
  for pid in "${PIDS[@]}"; do
    kill -9 "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  done
  for dir in "${DIRS[@]}"; do
    rm -rf "$dir"
  done
}
trap cleanup EXIT

track_dir() { DIRS+=("$1"); }
track_pid() { PIDS+=("$1"); }
untrack_pid() {
  local remove="$1"
  local kept=()
  local pid
  for pid in "${PIDS[@]}"; do
    [[ "$pid" == "$remove" ]] || kept+=("$pid")
  done
  PIDS=("${kept[@]}")
}
new_server_id() {
  printf 'testid%026d\n' "$RANDOM"
}

ok() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
bad() { echo "  FAIL: $1"; echo "    $2"; FAIL=$((FAIL + 1)); }

# --- Test 1: an unrelated, reused PID must NOT be killed ---
SESS="$(mktemp -d)"; track_dir "$SESS"; mkdir -p "$SESS/state"
sleep 600 &
UNRELATED=$!
track_pid "$UNRELATED"
disown "$UNRELATED" 2>/dev/null || true
echo "$UNRELATED" > "$SESS/state/server.pid"
OUT="$("$STOP" "$SESS")"
if kill -0 "$UNRELATED" 2>/dev/null; then
  case "$OUT" in
    *stale_pid*) ok "unrelated reused PID is left alone (stale_pid)" ;;
    *) bad "unrelated PID survived but status was not stale_pid" "$OUT" ;;
  esac
else
  bad "unrelated reused PID was KILLED" "$OUT"
fi

# --- Test 2: a marked brainstorm session under the stable temp root is stopped and cleaned ---
TEMP_ROOT="${TMPDIR:-/tmp}"
TEMP_ROOT="${TEMP_ROOT%/}"
mkdir -p "$TEMP_ROOT/t-superpowers-brainstorm"
SESS="$(mktemp -d "$TEMP_ROOT/t-superpowers-brainstorm/session.XXXXXX")"; track_dir "$SESS"; mkdir -p "$SESS/content" "$SESS/state"
printf '%s\n' 't-superpowers-brainstorm-cleanup-v1' > "$SESS/state/cleanup-marker"
chmod 600 "$SESS/state/cleanup-marker"
SERVER_ID="$(new_server_id)"
printf '%s\n' "$SERVER_ID" > "$SESS/state/server-instance-id"
BRAINSTORM_DIR="$SESS" BRAINSTORM_PORT=3399 node "$SERVER" "--brainstorm-server-id=$SERVER_ID" > /dev/null 2>&1 &
SRV=$!
track_pid "$SRV"
disown "$SRV" 2>/dev/null || true
for _ in $(seq 1 40); do kill -0 "$SRV" 2>/dev/null && break; sleep 0.1; done
sleep 0.4
echo "$SRV" > "$SESS/state/server.pid"
OUT="$("$STOP" "$SESS")"
sleep 0.3
if kill -0 "$SRV" 2>/dev/null; then
  bad "real brainstorm server still running after stop" "$OUT"
else
  wait "$SRV" 2>/dev/null || true
  untrack_pid "$SRV"
  if [[ -d "$SESS" ]]; then
    bad "temporary brainstorm session is removed after stop" "$SESS still exists"
  else
    case "$OUT" in
      *stopped*) ok "real brainstorm server is stopped and its temporary session is removed" ;;
      *) bad "server stopped but status was not 'stopped'" "$OUT" ;;
    esac
  fi
fi

# --- Test 2a: an unmarked directory in the temp root is never deleted ---
SESS="$(mktemp -d "$TEMP_ROOT/t-superpowers-brainstorm/unmarked.XXXXXX")"; track_dir "$SESS"; mkdir -p "$SESS/content" "$SESS/state"
SERVER_ID="$(new_server_id)"
printf '%s\n' "$SERVER_ID" > "$SESS/state/server-instance-id"
BRAINSTORM_DIR="$SESS" BRAINSTORM_PORT=0 node "$SERVER" "--brainstorm-server-id=$SERVER_ID" > /dev/null 2>&1 &
SRV=$!; track_pid "$SRV"; disown "$SRV" 2>/dev/null || true
for _ in $(seq 1 40); do [[ -f "$SESS/state/server-info" ]] && break; sleep 0.1; done
echo "$SRV" > "$SESS/state/server.pid"
OUT="$("$STOP" "$SESS")"
wait "$SRV" 2>/dev/null || true; untrack_pid "$SRV"
if [[ -d "$SESS" ]]; then
  ok "unmarked temporary directories are preserved"
else
  bad "unmarked temporary directories are preserved" "$OUT"
fi

# --- Test 2b: an explicit project path under /tmp is preserved even with a marker ---
EXPLICIT_ROOT="$TEMP_ROOT/repo/docsDev"
mkdir -p "$EXPLICIT_ROOT"
SESS="$(mktemp -d "$EXPLICIT_ROOT/session.XXXXXX")"; track_dir "$SESS"; mkdir -p "$SESS/content" "$SESS/state"
printf '%s\n' 't-superpowers-brainstorm-cleanup-v1' > "$SESS/state/cleanup-marker"
chmod 600 "$SESS/state/cleanup-marker"
SERVER_ID="$(new_server_id)"
printf '%s\n' "$SERVER_ID" > "$SESS/state/server-instance-id"
BRAINSTORM_DIR="$SESS" BRAINSTORM_PORT=0 node "$SERVER" "--brainstorm-server-id=$SERVER_ID" > /dev/null 2>&1 &
SRV=$!; track_pid "$SRV"; disown "$SRV" 2>/dev/null || true
for _ in $(seq 1 40); do [[ -f "$SESS/state/server-info" ]] && break; sleep 0.1; done
echo "$SRV" > "$SESS/state/server.pid"
OUT="$("$STOP" "$SESS")"
wait "$SRV" 2>/dev/null || true; untrack_pid "$SRV"
if [[ -d "$SESS" ]]; then
  ok "explicit /tmp project directories are preserved despite a marker"
else
  bad "explicit /tmp project directories are preserved despite a marker" "$OUT"
fi

# --- Test 2c: canonicalization prevents a .. path from escaping the allowed root ---
OUTSIDE_ROOT="$TEMP_ROOT/escaped-project"
mkdir -p "$OUTSIDE_ROOT"
SESS="$(mktemp -d "$OUTSIDE_ROOT/session.XXXXXX")"; track_dir "$SESS"; mkdir -p "$SESS/content" "$SESS/state"
printf '%s\n' 't-superpowers-brainstorm-cleanup-v1' > "$SESS/state/cleanup-marker"
chmod 600 "$SESS/state/cleanup-marker"
SERVER_ID="$(new_server_id)"
printf '%s\n' "$SERVER_ID" > "$SESS/state/server-instance-id"
BRAINSTORM_DIR="$SESS" BRAINSTORM_PORT=0 node "$SERVER" "--brainstorm-server-id=$SERVER_ID" > /dev/null 2>&1 &
SRV=$!; track_pid "$SRV"; disown "$SRV" 2>/dev/null || true
for _ in $(seq 1 40); do [[ -f "$SESS/state/server-info" ]] && break; sleep 0.1; done
echo "$SRV" > "$SESS/state/server.pid"
ESCAPING_PATH="$TEMP_ROOT/t-superpowers-brainstorm/../escaped-project/$(basename "$SESS")"
OUT="$("$STOP" "$ESCAPING_PATH")"
wait "$SRV" 2>/dev/null || true; untrack_pid "$SRV"
if [[ -d "$SESS" ]]; then
  ok "canonical .. paths cannot escape the allowed cleanup root"
else
  bad "canonical .. paths cannot escape the allowed cleanup root" "$OUT"
fi

# --- Test 2d: persistent sessions stop with explicit stopped metadata ---
SESS="$(mktemp -d "$SCRIPT_DIR/.stop-persistent.XXXXXX")"; track_dir "$SESS"; mkdir -p "$SESS/content" "$SESS/state"
SERVER_ID="$(new_server_id)"
printf '%s\n' "$SERVER_ID" > "$SESS/state/server-instance-id"
BRAINSTORM_DIR="$SESS" BRAINSTORM_PORT=0 node "$SERVER" "--brainstorm-server-id=$SERVER_ID" > /dev/null 2>&1 &
SRV=$!
track_pid "$SRV"
disown "$SRV" 2>/dev/null || true
for _ in $(seq 1 40); do
  [[ -f "$SESS/state/server-info" ]] && break
  sleep 0.1
done
echo "$SRV" > "$SESS/state/server.pid"
OUT="$("$STOP" "$SESS")"
sleep 0.3
if kill -0 "$SRV" 2>/dev/null; then
  bad "persistent brainstorm server still running after stop" "$OUT"
else
  wait "$SRV" 2>/dev/null || true
  untrack_pid "$SRV"
  if [[ -f "$SESS/state/server-info" ]]; then
    bad "persistent stop clears server-info" "server-info still exists after: $OUT"
  elif [[ ! -f "$SESS/state/server-stopped" ]]; then
    bad "persistent stop writes server-stopped" "server-stopped missing after: $OUT"
  elif grep -q '"reason":"stop-server.sh"' "$SESS/state/server-stopped"; then
    ok "persistent stop clears alive metadata and writes server-stopped"
  else
    bad "persistent stop writes stop reason" "$(cat "$SESS/state/server-stopped" 2>/dev/null || true)"
  fi
fi

# --- Test 3: no pid file ---
SESS="$(mktemp -d)"; track_dir "$SESS"; mkdir -p "$SESS/state"
OUT="$("$STOP" "$SESS")"
case "$OUT" in
  *not_running*) ok "missing pid file reports not_running" ;;
  *) bad "missing pid file: unexpected status" "$OUT" ;;
esac

# --- Test 4: a node server.cjs impostor with missing instance id is spared ---
SESS="$(mktemp -d)"; track_dir "$SESS"; mkdir -p "$SESS/state"
( exec -a "node server.cjs" sleep 600 ) &
IMPOSTOR=$!
track_pid "$IMPOSTOR"
disown "$IMPOSTOR" 2>/dev/null || true
echo "$IMPOSTOR" > "$SESS/state/server.pid"
OUT="$("$STOP" "$SESS")"
if kill -0 "$IMPOSTOR" 2>/dev/null; then
  case "$OUT" in
    *stale_pid*) ok "missing instance id leaves node server.cjs impostor alone" ;;
    *) bad "impostor survived but status was not stale_pid" "$OUT" ;;
  esac
else
  bad "killed a node server.cjs impostor with missing instance id" "$OUT"
fi

# --- Test 5: a node server.cjs impostor with wrong instance id is spared ---
SESS="$(mktemp -d)"; track_dir "$SESS"; mkdir -p "$SESS/state"
EXPECTED_ID="$(new_server_id)"
WRONG_ID="$(new_server_id)"
printf '%s\n' "$EXPECTED_ID" > "$SESS/state/server-instance-id"
( exec -a "node server.cjs --brainstorm-server-id=$WRONG_ID" sleep 600 ) &
IMPOSTOR=$!
track_pid "$IMPOSTOR"
disown "$IMPOSTOR" 2>/dev/null || true
echo "$IMPOSTOR" > "$SESS/state/server.pid"
OUT="$("$STOP" "$SESS")"
if kill -0 "$IMPOSTOR" 2>/dev/null; then
  case "$OUT" in
    *stale_pid*) ok "wrong instance id leaves node server.cjs impostor alone" ;;
    *) bad "wrong-id impostor survived but status was not stale_pid" "$OUT" ;;
  esac
else
  bad "killed a node server.cjs impostor with wrong instance id" "$OUT"
fi

# --- Test 6: malformed instance id is fail-closed ---
SESS="$(mktemp -d)"; track_dir "$SESS"; mkdir -p "$SESS/state"
printf '%s\n' 'bad id with spaces' > "$SESS/state/server-instance-id"
( exec -a "node server.cjs --brainstorm-server-id=bad-id-with-spaces" sleep 600 ) &
IMPOSTOR=$!
track_pid "$IMPOSTOR"
disown "$IMPOSTOR" 2>/dev/null || true
echo "$IMPOSTOR" > "$SESS/state/server.pid"
OUT="$("$STOP" "$SESS")"
if kill -0 "$IMPOSTOR" 2>/dev/null; then
  case "$OUT" in
    *stale_pid*) ok "malformed instance id is fail-closed" ;;
    *) bad "malformed-id impostor survived but status was not stale_pid" "$OUT" ;;
  esac
else
  bad "killed process despite malformed instance id" "$OUT"
fi

echo "--- Results: $PASS passed, $FAIL failed ---"
[ "$FAIL" -eq 0 ] || exit 1
