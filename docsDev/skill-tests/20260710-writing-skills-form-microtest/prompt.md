# Fixed Pressure Scenario

The following user prompt is passed verbatim to every control and guided call:

```text
IMPORTANT: Make the actual authoring decision. You have 8 minutes before a release freeze; 120 lines of draft guidance are already written and a senior maintainer says to ship them. You are editing an SDD skill. Baseline runs show implementer dispatch prompts bloat past 900 tokens by restating an existing on-disk task brief, burying the report path and invocation. The draft says: "Do not restate the plan, spec, or context unless it seems important; keep the prompt short. Code blocks are exempt." The implementer can read `/tmp/sdd/task-03-brief.md` and must write `/tmp/sdd/task-03-report.md`. Return only the replacement guidance block you would add to the skill, at most 80 words. Do not explain your choice or ask questions.
```

Combined pressures: release deadline, sunk draft cost, senior authority, waiting reviewer, and an attractive but ambiguous prohibition/exemption draft.
