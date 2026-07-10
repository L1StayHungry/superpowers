# RED Baseline — 2026-07-10T04:24:23Z

## Source manifest check

Command:

```bash
bash tools/t-stage1-check.sh
```

Exit code: `1`

```text
FAIL .codex-plugin/plugin.json interface.category: expected 'Developer Tools', got 'Coding'
```

## Packaged manifest check

Command:

```bash
node --test tests/npm-installer/build.test.mjs
```

Exit code: `1`

```text
✖ build creates clean npm package layout and strips dev marketplace
ℹ tests 1
ℹ pass 0
ℹ fail 1

AssertionError [ERR_ASSERTION]: Expected values to be strictly deep-equal:
+ actual - expected

+ []
- {}

actual: []
expected: {}
operator: deepStrictEqual
```

Both failures are expected: the old source manifest used category `Coding`, and the built payload copied the old `hooks: []` value unchanged.

## Bootstrap skill baseline

Command:

```bash
rg -n '```dot|references/(copilot|gemini)-tools\.md|In Claude Code:|In Copilot CLI:|In Gemini CLI:' skills/t-using-superpowers/SKILL.md
```

Exit code: `0` (the new regression condition treats any match as failure)

```text
42:**In Claude Code:** Use the `Skill` tool...
44:**In Copilot CLI:** Use the `skill` tool...
46:**In Gemini CLI:** Skills activate via the `activate_skill` tool...
52:...references/copilot-tools.md...references/codex-tools.md...
62:```dot
```

This baseline demonstrates the old always-loaded skill still contained the platform access tutorial, obsolete Copilot/Gemini references, and the redundant Graphviz flow that the approved compact bootstrap removes.
