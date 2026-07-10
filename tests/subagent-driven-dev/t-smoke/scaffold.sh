#!/usr/bin/env bash
# Scaffold the t-smoke subagent-driven-development test project
# Usage: ./scaffold.sh TARGET_DIRECTORY

set -e

TARGET_DIR="${1:?Usage: $0 TARGET_DIRECTORY}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

git init

mkdir -p docsDev/changes/t-smoke
cp "$SCRIPT_DIR/design.md" docsDev/changes/t-smoke/spec.md
cp "$SCRIPT_DIR/plan.md" docsDev/changes/t-smoke/plan.md

cat > CLAUDE.md << 'EOF'
# Test Harness Notes

Do not use the Read tool in this harness. Use shell read-only commands such as `sed -n`, `grep`, or `python3 -c` to inspect files.

If the Read tool is available despite this instruction, omit the `pages` parameter entirely on ordinary text files. Only use `pages` for paginated documents, and never pass an empty `pages` value.

This is a disposable smoke-test repository. Work may happen in Claude Code worktrees, but completed task work must be committed and merged or cherry-picked back into this repository before reporting DONE.

Keep the implementation small. The goal is to verify `t-superpowers:t-subagent-driven-development` harness behavior, not to build a product.
EOF

mkdir -p .claude
cat > .claude/settings.local.json << 'SETTINGS'
{
  "permissions": {
    "allow": [
      "Edit(**)",
      "Write(**)",
      "Bash(npm:*)",
      "Bash(node:*)",
      "Bash(mkdir:*)",
      "Bash(git:*)",
      "Bash(test:*)"
    ]
  }
}
SETTINGS

git add .
git commit -m "Initial t-smoke project setup"

echo "Scaffolded t-smoke project at: $TARGET_DIR"
echo ""
echo "To run the test:"
echo "  claude -p \"Execute this plan using t-superpowers:t-subagent-driven-development. Plan: $TARGET_DIR/docsDev/changes/t-smoke/plan.md\" --plugin-dir /path/to/superpowers"
