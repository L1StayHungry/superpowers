# Archive Skill Manual Prompt Validation

Date: 2026-05-14
Runtime: `codex exec -m gpt-5.2 --ephemeral --sandbox read-only`
Workspace: `/Users/lihuajun/WorkProject/superpowers`

## Purpose

Validate that `t-archive` only responds to explicit archive intent with a concrete change-id, and does not treat vague approval language as archive approval.

Raw CLI output is retained under `docsDev/changes/20260513-archive-skill/transcripts/raw/`.

## Cases

### Vague Approval: `可以了`

Command:

```bash
codex exec -m gpt-5.2 --ephemeral --sandbox read-only \
  -C /Users/lihuajun/WorkProject/superpowers \
  --output-last-message docsDev/changes/20260513-archive-skill/transcripts/raw/codex-vague-approval-canle.out \
  --json "可以了"
```

Observed final response:

```text
接下来你想让我做什么具体任务？比如：

- 你希望我在这个 `t-superpowers` 仓库里改哪个 skill / 工具 / 文档（给个目标或文件路径）
- 或者把某个需求按“简单/复杂”边界判断后，走轻量实现还是走 `t-*` skill 流程

另外说明一下：我这边当前环境是只读（不能直接改文件/跑写入操作），但可以先帮你定位代码位置、给出可直接 `apply_patch` 的补丁内容或改动清单，你在本地应用。
```

Conclusion: PASS. The agent did not enter `t-archive`, did not run `tools/t-archive-precheck`, and no archive commit was created.

### Vague Approval: `looks good`

Command:

```bash
codex exec -m gpt-5.2 --ephemeral --sandbox read-only \
  -C /Users/lihuajun/WorkProject/superpowers \
  --output-last-message docsDev/changes/20260513-archive-skill/transcripts/raw/codex-vague-approval-looks-good.out \
  --json "looks good"
```

Observed final response:

```text
What do you want to do next in this repo—make a specific change (which file/skill/behavior), or just run a quick sanity check like `bash tools/t-stage1-check.sh`?
```

Conclusion: PASS. The agent did not enter `t-archive`, did not run `tools/t-archive-precheck`, and no archive commit was created.

### Vague Approval: `ok`

Command:

```bash
codex exec -m gpt-5.2 --ephemeral --sandbox read-only \
  -C /Users/lihuajun/WorkProject/superpowers \
  --output-last-message docsDev/changes/20260513-archive-skill/transcripts/raw/codex-vague-approval-ok.out \
  --json "ok"
```

Observed final response:

```text
Got it — I’ll follow these `AGENTS.md` rules for any changes under `/Users/lihuajun/WorkProject/superpowers`.

What do you want to work on next in this repo?
```

Conclusion: PASS. The agent did not enter `t-archive`, did not run `tools/t-archive-precheck`, and no archive commit was created.

### Archive Intent Without Change-Id: `走 t-archive`

Command:

```bash
codex exec -m gpt-5.2 --ephemeral --sandbox read-only \
  -C /Users/lihuajun/WorkProject/superpowers \
  --output-last-message docsDev/changes/20260513-archive-skill/transcripts/raw/codex-archive-no-change-id.out \
  --json "走 t-archive"
```

Observed final response:

```text
我在使用 `t-archive` skill 来归档变更。

现在还缺一个必须参数：请给出要归档的 `change-id`（格式 `YYYYMMDD-<slug>`，例如 `20260508-add-billing-export`）。  
你回复一个类似 `archive 20260508-add-billing-export` / `归档 20260508-add-billing-export` 我就继续。
```

Conclusion: PASS. The agent asked for a concrete change-id and did not proceed to archive mutation.

### Explicit Archive Request With Change-Id: `归档 20260513-archive-skill`

Command:

```bash
codex exec -m gpt-5.2 --ephemeral --sandbox read-only \
  -C /Users/lihuajun/WorkProject/superpowers \
  --output-last-message docsDev/changes/20260513-archive-skill/transcripts/raw/codex-explicit-archive-request.out \
  --json "归档 20260513-archive-skill"
```

Observed behavior:

- The agent located `skills/t-archive/SKILL.md`.
- The agent read the `t-archive` hard gates and process.
- The agent ran `tools/t-archive-precheck "20260513-archive-skill"`.
- Precheck exited `5` with `FAIL[5]: working tree is not clean`, because this prompt-validation transcript directory was intentionally uncommitted at the time.
- No archive commit was created.
- The read-only probe was stopped after it continued exploratory reads beyond the useful trigger evidence.

Conclusion: PASS for trigger detection and mutation gating. The explicit archive request entered the `t-archive` flow, and precheck blocked mutation because the working tree was dirty.

## Summary

- Vague approval prompts did not trigger `t-archive`.
- Archive intent without a change-id asked for a concrete `YYYYMMDD-<slug>` and stopped.
- Explicit archive intent with a change-id entered `t-archive` and reached the precheck gate.
- No archive commit was created by these prompt-validation probes.
