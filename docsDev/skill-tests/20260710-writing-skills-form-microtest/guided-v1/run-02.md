**Implementer dispatch prompt contract:** When a task brief exists on disk, the prompt contains only:
1. Read the brief: `/tmp/sdd/task-03-brief.md`
2. Execute the task exactly as specified there.
3. Write the report to: `/tmp/sdd/task-03-report.md`
4. Include the invocation/command needed to run or verify the work.

Do not copy brief contents into the prompt; reference the path.
