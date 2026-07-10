## Implementer Dispatch Prompts

Do **not** restate on-disk briefs, plans, specs, or context in implementer prompts. No “important excerpts.” No code-block exemption. If the implementer can read a file, point to it.

Required prompt contents:
- Task brief path to read
- Exact command/invocation if applicable
- Required report path to write
- Any hard constraints not present in the brief

Example: “Read `/tmp/sdd/task-03-brief.md`. Execute task 03. Write report to `/tmp/sdd/task-03-report.md`.”
