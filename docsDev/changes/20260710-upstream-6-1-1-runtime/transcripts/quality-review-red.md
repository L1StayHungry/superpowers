# Quality Review RED Evidence — 2026-07-10

## Planning classification

```text
$ bash tools/t-stage1-check.sh
exit 1
FAIL: t-using-superpowers missing required marker: Planning skills turn.*executable steps
```

## Missing offline vendor contract

```text
$ bash tools/t-stage1-check.sh
exit 1
FAIL vendor baseline: vendor/superpowers/UPSTREAM_MANIFEST missing
```

## Vendor text normalization still enabled

```text
$ bash tools/t-stage1-check.sh
exit 1
FAIL vendor baseline: vendor subtree must set both -text and -whitespace in .gitattributes
```

## Complex route not explicit enough

```text
$ bash tools/t-stage1-check.sh
exit 1
FAIL: t-using-superpowers missing required marker: complex multi-file.*first action.*t-brainstorming.*before.*reading
```

The associated live Claude failure is recorded separately in `live-bootstrap.md`.
