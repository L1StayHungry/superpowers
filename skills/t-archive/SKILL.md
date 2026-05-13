---
name: t-archive
description: Use ONLY when the user explicitly asks to archive a specific change-id into docsDev/specs/ (e.g. "archive 20260508-add-billing-export", "走 t-archive", "把 20260508-add-billing-export 沉淀到 specs"). Do NOT auto-trigger after verification succeeds. Do NOT infer archive intent from phrases like "looks good" / "ok" / "可以了". The user must provide explicit archive intent and a change-id.
---

# Archive Completed Changes

## Overview

Archive an accepted `docsDev/changes/<change-id>/` change into the long-term `docsDev/specs/` library and move the full change snapshot to `docsDev/archive/`.

**Announce at start:** "I'm using the t-archive skill to archive this change."

This skill is a light wrapper around:

1. `tools/t-archive-precheck <change-id>`
2. Archive Patch merge into `docsDev/specs/<capability>/spec.md`
3. `git mv docsDev/changes/<change-id> docsDev/archive/<change-id>`
4. `git add docsDev/specs docsDev/archive`
5. `git commit -m "archive <change-id>: <summary>"`

## Hard Gates

Do not run this skill unless the current user request has both:

- Explicit archive intent, such as `archive`, `归档`, `走 t-archive`, or `沉淀到 specs`.
- A concrete change-id matching `YYYYMMDD-<slug>`.

If the user says `可以了`, `ok`, `looks good`, or verification has passed, do not infer archive intent. Report that archive requires an explicit request naming the change-id.

If the user asks for archive intent without a concrete change-id, ask for the change-id and stop. Do not run precheck.

## Exit Code Meanings

| Code | Meaning |
| --- | --- |
| `1` | Argument, change directory, or spec is missing or invalid |
| `2` | Archive Patch fields or format are invalid |
| `3` | Archive Patch Target escapes `docsDev/specs/` |
| `4` | `docsDev/archive/<change-id>/` already exists |
| `5` | Working tree is not clean |

## Process

### Step 1: Extract The Change-Id

Extract one change-id from the current user request:

```regex
\b\d{8}-[a-z0-9-]{3,40}\b
```

If none is present, ask for the change-id and stop. If more than one is present, ask which one to archive and stop.

### Step 2: Run Precheck Before Any Mutation

Run:

```bash
precheck_json="$(mktemp)"
precheck_err="$(mktemp)"
tools/t-archive-precheck "<change-id>" >"${precheck_json}" 2>"${precheck_err}"
precheck_code=$?
if [ "${precheck_code}" -ne 0 ]; then
  printf 'precheck exit %s\n' "${precheck_code}"
  cat "${precheck_err}"
fi
```

If `precheck_code` is non-zero:

- Report the exit code meaning from the table above.
- Include the stderr message.
- Do not edit, stage, stash, reset, clean, or modify files.
- Stop.

### Step 3: Read Validated Metadata

Parse the precheck JSON. Treat it as authoritative for `change_id`, `capability`, `target`, and `action`.

```bash
python3 - "${precheck_json}" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)

if not data.get("change_id"):
    raise SystemExit("precheck JSON missing change_id")
for patch in data.get("archive_patches", []):
    for key in ("capability", "target", "action"):
        if not patch.get(key):
            raise SystemExit(f"precheck JSON patch missing {key}")
    print(f"{patch['capability']} {patch['action']} {patch['target']}")
PY
```

### Step 4: Derive Summary And Date

Use UTC for Change History dates:

```bash
archive_date="$(date -u +%Y-%m-%d)"
```

Derive `<summary>` from the first H1 in `docsDev/changes/<change-id>/spec.md`. Strip one trailing ` Spec`; if no H1 exists, use the change-id.

```bash
summary="$(
python3 - "docsDev/changes/<change-id>/spec.md" "<change-id>" <<'PY'
import re
import sys

text = open(sys.argv[1], encoding="utf-8").read()
fallback = sys.argv[2]
match = re.search(r"(?m)^#\s+(.+?)\s*$", text)
if not match:
    print(fallback)
else:
    title = re.sub(r"\s+Spec$", "", match.group(1).strip())
    print(title or fallback)
PY
)"
```

### Step 5: Validate Target Existence Before Writes

Before editing any file, check all targets from precheck JSON:

- `Action: create` requires the target file to be missing.
- `Action: update` requires the target file to exist.

```bash
python3 - "${precheck_json}" <<'PY'
from pathlib import Path
import json
import sys

data = json.load(open(sys.argv[1], encoding="utf-8"))
failed = False
for patch in data["archive_patches"]:
    target = Path(patch["target"])
    exists = target.exists()
    if patch["action"] == "create" and exists:
        print(f"target exists for Action=create: {target}", file=sys.stderr)
        failed = True
    if patch["action"] == "update" and not exists:
        print(f"target missing for Action=update: {target}", file=sys.stderr)
        failed = True
if failed:
    raise SystemExit(1)
PY
```

If this fails, stop without rollback because no mutation has happened.

### Step 6: Apply Archive Patch

Read `docsDev/changes/<change-id>/spec.md` and apply each `## Archive Patch` section named in the precheck JSON.

Markdown section rules:

- Archive Patch starts at `## Archive Patch` and must be terminal.
- Capability section starts at `### <capability>` and ends before the next `### ` capability heading or end of file.
- Long-term spec Requirement block starts at exact `### Requirement: <name>`.
- A long-term spec Requirement block ends before the next heading at level 1, 2, or 3. If no such heading exists, the block ends at EOF.
- Archive Patch Requirement headings are normalized when copied:
  - `##### Requirement:` becomes `### Requirement:`
  - `###### Scenario:` becomes `#### Scenario:`

Action rules:

- `ADDED Requirements`: append normalized Requirement blocks at the end of the `## Requirements` section, before the next `## ` heading or EOF.
- `MODIFIED Requirements`: find the exact existing `### Requirement: <name>` block and replace it with the normalized body after `Replace with:`. Do not copy the `Replace with:` line into the long-term spec.
- `REMOVED Requirements`: delete the exact existing `### Requirement: <name>` block named by `- Requirement: <name>`. Ignore `- Reason:` lines; they are Archive Patch rationale only.
- `RENAMED Requirements`: parse `- From: <old>` and `- To: <new>` from the same renamed item, then rename only the exact `### Requirement: <old>` heading line to `### Requirement: <new>`. Keep the block body and scenarios unchanged. Ignore `- Reason:` lines.

Change History rule:

- Insert `- <UTC date>: archived from docsDev/changes/<change-id>/ (<summary>)` as the first bullet under `## Change History`.
- Do not append duplicate Change History entries for the same change-id if the step is re-run during manual correction before commit.

For `Action: create`, create the target with:

```markdown
---
capability: <capability>
owner: <owner from change spec frontmatter>
updated_at: <ISO-8601 UTC timestamp>
source: t-superpowers
---

# <Capability Title> Spec

## Change History

- <UTC date>: archived from docsDev/changes/<change-id>/ (<summary>)

## Overview

Archived long-term requirements for <capability>.

## Requirements

<normalized ADDED Requirements>

## Notes
```

### Step 7: Validate The Pre-Move Diff

Run:

```bash
git diff --check -- docsDev/specs "docsDev/changes/<change-id>"
```

Expected: exit `0`.

If this fails, run rollback:

```bash
git reset --hard HEAD
git clean -fd
```

Report the failed step and stop.

### Step 8: Move, Stage, And Commit

Run:

```bash
git mv "docsDev/changes/<change-id>" "docsDev/archive/<change-id>"
git add docsDev/specs docsDev/archive
git diff --cached --name-only -- docsDev/specs "docsDev/archive/<change-id>"
```

Confirm the staged list includes:

- Every touched `docsDev/specs/<capability>/spec.md` target.
- At least one path under `docsDev/archive/<change-id>/`.

Then commit:

```bash
git commit -m "archive <change-id>: <summary>"
```

Report:

```bash
git log --oneline -1
```

### Step 9: Failure Handling

If any step after a successful precheck mutates files and then fails before commit, run:

```bash
git reset --hard HEAD
git clean -fd
```

Report the failed step and stop. Do not retry automatically.

If the archive commit succeeds and a problem is found after commit, do not reset or retry automatically. Ask the user whether to use `git revert <archive-commit>` or make a corrective commit.
