<!-- provenance
agent: /root/writing_plans_v6/boundary_both_reviewer
assigned inputs: raw control, old strict, new exact, and split payloads
captured: verbatim final payload
-->

| Raw | A | B | C | D |
|---|---:|---:|---:|---:|
| control | 1 | 1 | 0 | — |
| 旧 strict | 2 | 1 | 2 | — |
| 新 exact | 2 | 2 | 2 | — |
| split | — | — | — | 2 |
证据：control 五约束和三签名均散落，且按 DB/API/UI/配置机械拆成 4 Task。
证据：旧 strict 集中逐字列五约束且为单一纵向 Task；但 `Consumes:`/`Produces:` 同行为空、内容 nested，故 B=1。
证据：新 exact 五约束集中、单一 Task；Interfaces 两项均同行非空，Produces 同行含三签名。
证据：split 恰好两 Task；虽共享 registry，各有独立 test、同行非空 Interfaces、RED/GREEN/Review，故 D=2。
