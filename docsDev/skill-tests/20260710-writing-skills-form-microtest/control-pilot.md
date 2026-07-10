## Implementer Dispatch Prompts

Do **not** restate on-disk briefs, plans, specs, or context in implementer prompts—not in prose, bullets, or code blocks. If the implementer can read a file, cite the path only.

Prompt must include:
- task brief path
- exact invocation/command
- required report path
- any task-specific constraints not already in the brief

Example: read `/tmp/sdd/task-03-brief.md`; write `/tmp/sdd/task-03-report.md`.
