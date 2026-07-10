### Implementer Dispatch Prompts

Treat on-disk briefs as the payload. Do **not** restate the plan, spec, context, or acceptance criteria in the dispatch prompt, including inside code blocks. Provide only:

- task brief path to read
- exact command/invocation to run, if any
- required report path to write
- any truly missing runtime detail not present in the brief

Example: “Read `/tmp/sdd/task-03-brief.md`. Execute it. Write report to `/tmp/sdd/task-03-report.md`.”
