# T-Superpowers Installer

Install the internal package from the 4399 npm registry:

```bash
npm config set @4399:registry https://registry-npm.gz4399.com/
npx @4399/tdata-t-superpowers@latest install all
npx @4399/tdata-t-superpowers@latest doctor all
```

## Cursor

Cursor installation copies a physical plugin directory to:

```text
~/.cursor/plugins/local/t-superpowers
```

Do not use a symlink for Cursor. Local smoke showed Cursor recognized the physical directory and did not reliably activate the symlink created by `/add-plugin`.

## Claude Code

Claude Code installation creates a local marketplace named `t-superpowers-internal` that points to the npm package, then uses `claude plugin install`.

## Codex

Codex installation copies `t-*` skills into `${CODEX_HOME:-~/.codex}/skills/`. This skills adapter does not install session-start hooks. `doctor codex` reports this as a warning.
