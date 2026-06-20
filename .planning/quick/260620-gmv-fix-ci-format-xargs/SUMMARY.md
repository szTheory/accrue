---
quick_id: 260620-gmv
slug: fix-ci-format-xargs
date: 2026-06-20
type: quick
status: complete
commit: 0ce75413
---

# Summary — fix(ci): green main (format + CMP-05 xargs portability)

## What changed

- **`accrue/test/accrue/docs/package_docs_verifier_test.exs`** — ran `mix format`;
  the multi-line `String.replace(..., global: false)` calls now match the formatter.
- **`scripts/ci/verify_package_docs.sh`** — appended `|| true` to both CMP-05
  command substitutions (`primitive_override_hit`, `inline_style_hit`) and added
  comments. The no-hit path no longer aborts under `set -euo pipefail` when GNU
  xargs (CI Linux) returns 123 on empty/no-match grep input.

## Root cause

Both failures **predate** the v1.53 milestone close — main CI was already red at
`0195b09d` (pre-push HEAD). Introduced by Phase 188/189 commits (`dd2f0a69` format,
`156861c1` CMP-05 block). The verify_package_docs.sh bug only manifested on CI
because BSD xargs (macOS) exits 0 on empty input while GNU xargs (Linux) runs the
command and propagates grep's exit 1 as 123 — invisible to local runs.

## Verification

- `cd accrue && mix format --check-formatted` → exit 0
- `bash -n` + `bash -e scripts/ci/verify_package_docs.sh` → exit 0
- 123-pipeline absorbed by `|| true` under `set -euo pipefail` → exit 0
- Real `.ax-button {…}` override still detected → guard not neutered

## Result

Committed `0ce75413`, pushed `0d697e89..0ce75413`. CI run 27876388415 watching.
