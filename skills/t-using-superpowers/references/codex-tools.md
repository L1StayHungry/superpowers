# Codex Tool Mapping

Use this reference only when a selected skill names harness-specific tools. Available tools vary by Codex surface; never invent a tool that is not exposed in the current session.

| Skill wording | Codex equivalent when available |
| --- | --- |
| Dispatch a subagent | `spawn_agent` |
| Send work or feedback | `send_message` / `followup_task` |
| Wait for subagent progress | `wait_agent` |
| Inspect active agents | `list_agents` |
| Track a multi-step implementation | `update_plan` |
| Read, edit, or search files | Native filesystem tools |
| Run commands | Native shell execution |
| Invoke a skill | Load and follow the current skill instructions |

If multi-agent tools are unavailable, do not pretend delegation occurred. Follow the selected skill's fallback or report the capability gap.

Before worktree or finishing operations, inspect Git state with read-only commands (`git rev-parse`, `git branch --show-current`, `git status`) and respect the current harness's branch and approval constraints.
