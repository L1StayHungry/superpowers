#!/usr/bin/env bash
# Scaffold the Svelte Todo test project
# Usage: ./scaffold.sh /path/to/target/directory

set -e

TARGET_DIR="${1:?Usage: $0 <target-directory>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Create target directory
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

# Initialize git repo
git init

# Copy design and plan
cp "$SCRIPT_DIR/design.md" .
cp "$SCRIPT_DIR/plan.md" .

cat > CLAUDE.md << 'EOF'
# Test Harness Notes

Do not use the Read tool in this harness. Use shell read-only commands such as `sed -n`, `grep`, or `python3 -c` to inspect files.

If the Read tool is available despite this instruction, omit the `pages` parameter entirely on ordinary text files. Only use `pages` for paginated documents, and never pass an empty `pages` value.

This is a disposable test repository. Work may happen in Claude Code worktrees, but completed task work must be committed and merged or cherry-picked back into this repository before reporting DONE.

For Vite/Svelte dev-server verification, use bounded checks only. Prefer `npm run build` plus static source or dev module checks. If you start `npm run dev`, stop it yourself and do not loop indefinitely debugging HTTP fetches.
EOF

# Create .claude settings to allow reads/writes in this directory
mkdir -p .claude
cat > .claude/settings.local.json << 'SETTINGS'
{
  "permissions": {
    "allow": [
      "Edit(**)",
      "Write(**)",
      "Bash(npm:*)",
      "Bash(npx:*)",
      "Bash(mkdir:*)",
      "Bash(git:*)"
    ]
  }
}
SETTINGS

# Create initial commit
git add .
git commit -m "Initial project setup with design and plan"

echo "Scaffolded Svelte Todo project at: $TARGET_DIR"
echo ""
echo "To run the test:"
echo "  claude -p \"Execute this plan using t-superpowers:t-subagent-driven-development. Plan: $TARGET_DIR/plan.md\" --plugin-dir /path/to/superpowers"
