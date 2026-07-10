#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export SDD_RESUME_FROM_TASK1=1
exec bash "$SCRIPT_DIR/test-subagent-driven-development-integration.sh"
