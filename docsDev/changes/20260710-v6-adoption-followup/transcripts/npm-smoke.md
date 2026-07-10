# npm smoke — v6.0.0

Date: 2026-07-10 (UTC+8)
Package: `@4399/tdata-t-superpowers@6.0.0`
Registry: `https://registry-npm.gz4399.com/`

## Local gates

| Check | Result |
|---|---|
| `npm run test:npm-installer` | PASS 67/67 (after unhardcoding Codex version assert to `rootPkg.version`) |
| `npm run build` | PASS |
| `npm run pack:dry-run` | PASS — name `@4399/tdata-t-superpowers`, version `6.0.0`, 72 files; includes `.claude-plugin/plugin.json`; excludes marketplace and `.agents/skills/` |
| `git diff --check` | PASS |
| `bash tools/t-stage1-check.sh` | Expected FAIL while `package.json` version bump is uncommitted (excluded-entry guard). Re-run after release commit. |

## Local tarball install smoke

Tarball: `4399-tdata-t-superpowers-6.0.0.tgz`
Temp project: `/tmp/tdata-tsp-release.clz39H`

| Target | Result |
|---|---|
| Cursor `install` / `doctor` | PASS — physical dir `~/.cursor/plugins/local/t-superpowers`, 15 `t-*` skills |
| Codex `install` / `doctor` | Expected WARN — session-start hook not installed by skills adapter; 15 managed `t-*` skills |
| Claude `install --dry-run` | PASS — would generate marketplace only; no real user config written |

## Registry precheck

| Check | Result |
|---|---|
| `npm publish ./dist/npm-package --dry-run` | PASS — `+ @4399/tdata-t-superpowers@6.0.0` |
| `npm view @4399/tdata-t-superpowers@6.0.0` | E404 (version not yet published) |
| `npm dist-tag ls` before publish | `latest: 5.1.2` |

## Notes

- Root `package.json` retains `name: "superpowers"` and `main: ".opencode/plugins/superpowers.js"`.
- Real `npm publish` awaits explicit user confirmation (“发布”).
