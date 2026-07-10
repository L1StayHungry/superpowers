**Implementer dispatch prompt contract:** When a task brief already exists on disk, the prompt contains only:
1. Role/instruction to implement the task
2. Brief path to read: `/tmp/sdd/task-03-brief.md`
3. Required report path: `/tmp/sdd/task-03-report.md`
4. Invocation/command to run, if any

Do not copy or summarize the brief, plan, spec, or context into the dispatch prompt. The implementer reads the file.
