# Verification — 2026-07-10T04:31:53Z

## Focused GREEN

- `bash tools/t-stage1-check.sh` — exit `0`; output: `OK: Stage 1 migration self-check passed`.
- `node --test tests/npm-installer/build.test.mjs` — exit `0`; 1 test passed, 0 failed.

## Vendor and Session Hook

- Extracted the approved v6.1.1 pathspec to a temporary directory and compared relative paths, bytes, symlink targets, and executable bits with `vendor/superpowers/` — exit `0`; 62 upstream files/symlinks matched.
- `diff -q vendor/superpowers/CLAUDE.md docs/upstream-contrib.md` — exit `0`.
- Parsed `hooks/session-start` output as JSON for Cursor, Claude Code, and SDK-standard environment branches — exit `0`; all three shapes contained `t-superpowers:t-using-superpowers` and no legacy warning.
- `bash -n hooks/session-start tools/t-stage1-check.sh` — exit `0`.

## Full Regression

- `npm run test:npm-installer` — exit `0`; 67 tests passed, 0 failed.
- `npm run build` — exit `0`.
- `npm run pack:dry-run` — exit `0`; 70 files listed, version remained `5.1.1`, and no tarball was created.
- `git diff --check` — initially identified one trailing space copied exactly from upstream `skills/writing-skills/SKILL.md`; after adding the vendor-only `.gitattributes` exemption, exit `0` without altering vendor bytes.

The final pre-commit verification is rerun after this evidence file is added; commit status and final command results are reported in the task handoff.

## Quality-Review Hardening

- Offline generation command: the exact `git ls-tree` / `git cat-file` command is recorded in `plan.md` under “Reproducible Vendor Manifest”.
- Offline validation command: `bash tools/t-stage1-check.sh`; it requires commit `d884ae04edebef577e82ff7c4e143debd0bbec99`, exact 62-path set, Git blobs, executable modes, entry types, and symlink target.
- `git check-attr text whitespace -- vendor/superpowers/CLAUDE.md` reports `text: unset` and `whitespace: unset`.
- SessionStart validation now runs all three environment branches as subprocesses, parses JSON, checks exact public keys and internal identity, and rejects the legacy warning.
- Packaged manifest focused test now locks name, version, internal description/default prompts, hooks, and category.
- Live Claude routing: simple PASS; explicit produced both PASS (Skill first) and a later XFAIL; complex consistently XFAIL without timeout. Full evidence is in `live-bootstrap.md`.
