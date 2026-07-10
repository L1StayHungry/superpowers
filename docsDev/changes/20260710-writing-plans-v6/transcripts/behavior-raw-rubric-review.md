<!-- provenance
agent: /root/writing_plans_v6/raw_rubric_reviewer
assigned inputs: verbatim behavior-control-output.md and behavior-guided-strict-output.md
captured: verbatim final payload after rereading updated strict raw
status: superseded by behavior-boundary-review.md because this rubric did not enforce non-empty same-line interface values
-->

| Raw | A | B | C | 总分 | 判定 |
|---|---:|---:|---:|---:|---|
| control | 1 | 1 | 0 | 2 | RED |
| strict | 2 | 2 | 2 | 6 | GREEN |
control：约束与签名散落，且机械拆为 DB/API/UI/配置文档四个 Task。
strict：五条约束集中逐字；字面 `**Interfaces:**` 下含 `- Consumes:` / `- Produces:`，三条精确签名齐全；单一端到端纵向 Task。
最终 RED/GREEN 成立。
