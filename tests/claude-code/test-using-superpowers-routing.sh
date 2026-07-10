#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

for command in claude python3; do
  if ! command -v "${command}" >/dev/null 2>&1; then
    echo "SKIP: missing required command: ${command}"
    exit 77
  fi
done

WORK_DIR=$(mktemp -d)
trap 'rm -rf "${WORK_DIR}"' EXIT
CASE_FILTER="${1:-all}"
case "${CASE_FILTER}" in
  all|simple|explicit|complex) ;;
  *)
    echo "usage: $0 [all|simple|explicit|complex]" >&2
    exit 2
    ;;
esac

run_case() {
  local name="$1"
  local expected_skill="$2"
  local prompt="$3"
  local tool_mode="$4"
  local allow_xfail="$5"
  local project_dir="${WORK_DIR}/${name}/project"
  local log_file="${WORK_DIR}/${name}/claude-output.jsonl"

  mkdir -p "${project_dir}"

  set +e
  python3 - "${project_dir}" "${log_file}" "${ROOT}" "${prompt}" "${tool_mode}" <<'PY'
import subprocess
import sys

project_dir, log_file, plugin_root, prompt, tool_mode = sys.argv[1:]
command = [
    "claude",
    "-p",
    prompt,
    "--plugin-dir",
    plugin_root,
    "--dangerously-skip-permissions",
    "--max-turns",
    "3" if tool_mode == "full" else "2",
    "--verbose",
    "--output-format",
    "stream-json",
]
if tool_mode == "skill-only":
    command.extend(["--tools", "Skill"])
with open(log_file, "w", encoding="utf-8") as output:
    try:
        result = subprocess.run(
            command,
            cwd=project_dir,
            stdout=output,
            stderr=subprocess.STDOUT,
            text=True,
            timeout=150,
            check=False,
        )
    except subprocess.TimeoutExpired:
        output.write("\nHARNESS TIMEOUT after 150 seconds\n")
        raise SystemExit(124)
raise SystemExit(result.returncode)
PY
  local exit_code=$?
  set -e

  if [ "${exit_code}" -ne 0 ]; then
    # A bounded run may exit 1 after producing a valid initialized session.
    # Only its routing assertion may XFAIL; timeouts, auth/startup failures,
    # and malformed CLI runs remain hard failures.
    if [ "${allow_xfail}" = "true" ] &&
       [ "${exit_code}" -eq 1 ] &&
       rg -q '"subtype"[[:space:]]*:[[:space:]]*"init"' "${log_file}"; then
      : # Continue to the structured routing assertion below.
    else
      echo "FAIL ${name}: claude exited ${exit_code}"
      sed -n '1,120p' "${log_file}"
      return 1
    fi
  fi

  if ! rg -q '"subtype"[[:space:]]*:[[:space:]]*"init"' "${log_file}"; then
    echo "FAIL ${name}: claude exited ${exit_code}"
    sed -n '1,120p' "${log_file}"
    return 1
  fi

  python3 - "${name}" "${expected_skill}" "${log_file}" "${allow_xfail}" <<'PY'
import json
from pathlib import Path
import sys

name, expected, log_path, allow_xfail = sys.argv[1:]
skills = []
tool_uses = []
assistant_text = []

for line in Path(log_path).read_text(encoding="utf-8").splitlines():
    try:
        event = json.loads(line)
    except json.JSONDecodeError:
        continue
    message = event.get("message") or {}
    for item in message.get("content") or []:
        if item.get("type") == "tool_use" and item.get("name") == "Skill":
            skill = (item.get("input") or {}).get("skill")
            tool_uses.append(("Skill", skill))
            if skill:
                skills.append(skill)
        elif item.get("type") == "tool_use":
            tool_uses.append((item.get("name"), None))
        elif item.get("type") == "text" and item.get("text"):
            assistant_text.append(item["text"].replace("\n", " ")[:240])

if expected == "NONE":
    unexpected = [
        skill
        for skill in skills
        if skill.startswith("t-") or skill.startswith("t-superpowers:t-")
    ]
    if unexpected:
        raise SystemExit(f"FAIL {name}: unexpected t-* skills {unexpected}")
elif expected not in skills and not any(skill.endswith(f":{expected}") for skill in skills):
    summary = assistant_text[-1] if assistant_text else "(no assistant text)"
    message = f"expected {expected}, observed {skills}; response={summary}"
    if allow_xfail == "true":
        print(f"XFAIL {name}: {message}")
        raise SystemExit(0)
    raise SystemExit(f"FAIL {name}: {message}")
elif not tool_uses or tool_uses[0][0] != "Skill":
    message = f"first tool must be Skill, observed {tool_uses}"
    if allow_xfail == "true":
        print(f"XFAIL {name}: {message}")
        raise SystemExit(0)
    raise SystemExit(f"FAIL {name}: {message}")

summary = assistant_text[-1] if assistant_text else "(no assistant text)"
print(
    f"PASS {name}: skills={skills or ['none']}; "
    f"first_tool={tool_uses[0] if tool_uses else 'none'}; response={summary}"
)
PY
}

if [ "${CASE_FILTER}" = "all" ] || [ "${CASE_FILTER}" = "simple" ]; then
  run_case \
    simple \
    NONE \
    '请直接把 README 里的一个错别字修正一下，这是单文件机械文案修改。' \
    skill-only \
    false
fi

if [ "${CASE_FILTER}" = "all" ] || [ "${CASE_FILTER}" = "explicit" ]; then
  run_case \
    explicit \
    t-test-driven-development \
    '请明确使用 t-test-driven-development，为现有 parseConfig 增加空输入错误处理；在实际实现前先按该 workflow 处理。' \
    skill-only \
    true
fi

if [ "${CASE_FILTER}" = "all" ] || [ "${CASE_FILTER}" = "complex" ]; then
  run_case \
    complex \
    t-brainstorming \
    '我要重构登录认证，涉及 API、token 轮换、数据库迁移和多个文件的用户可见行为变化，请开始实现。' \
    full \
    true
fi
