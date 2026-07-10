**Implementer dispatch prompt contract:** When a task brief exists on disk, do not paste or summarize it. The prompt must contain only:
1. Read: `/tmp/sdd/task-03-brief.md`
2. Do the task described there.
3. Write report: `/tmp/sdd/task-03-report.md`
4. Include the exact invocation/command to run.

Do not add plan/spec/context restatements, even in code blocks.
