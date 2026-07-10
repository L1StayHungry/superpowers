**Implementer dispatch prompt contract:** When a task brief exists on disk, the prompt consists of:
1. Read brief: `/tmp/sdd/task-03-brief.md`
2. Execute exactly that task.
3. Write report: `/tmp/sdd/task-03-report.md`
4. Include the required invocation/command.

Do not copy or summarize the brief, plan, spec, or surrounding context into the dispatch prompt. The file path is the context.
