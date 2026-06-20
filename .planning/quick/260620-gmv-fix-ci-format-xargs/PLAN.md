---
quick_id: 260620-gmv
slug: fix-ci-format-xargs
date: 2026-06-20
type: quick
status: in-progress
---

# Fix two pre-existing main CI failures (format + verify_package_docs portability)

## Context

Main CI was red **before** the v1.53 milestone-close push (commit `0195b09d` already
showed failing CI runs). Two independent, pre-existing failures from Phase 188/189 commits:

1. **`mix format --check-formatted`** fails on
   `accrue/test/accrue/docs/package_docs_verifier_test.exs` (introduced by `dd2f0a69`,
   feat 188-08). A multi-line `String.replace(..., global: false)` call was never run
   through `mix format`. Cosmetic.

2. **`scripts/ci/verify_package_docs.sh` exits 123** (introduced by `156861c1`,
   feat 189-07, the CMP-05 guard block). The two `find … -print0 | xargs -0 grep … | head`
   pipelines abort under `set -euo pipefail` on the **no-hit path**: with no matches (or no
   input files), grep exits 1 and **GNU xargs (CI Linux)** propagates 123. **BSD xargs
   (macOS)** exits 0 on empty input, so it passed locally and only failed on CI — a classic
   portability trap. An empty result is the *passing* case for these guards.

## Tasks

- [x] Run `mix format` on `accrue/test/accrue/docs/package_docs_verifier_test.exs`
- [x] Append `|| true` to both CMP-05 command substitutions in
      `scripts/ci/verify_package_docs.sh` so the no-hit path doesn't abort under
      `pipefail` + GNU xargs; add explanatory comments
- [x] Verify: `mix format --check-formatted` clean; `bash -e verify_package_docs.sh` exits 0;
      guard still *detects* a real `.ax-button {…}` override (not a no-op)
- [ ] Commit `fix(ci):` and push to main

## Verification

- `cd accrue && mix format --check-formatted` → exit 0 ✓
- `bash -n` + `bash -e scripts/ci/verify_package_docs.sh` → exit 0 ✓
- Simulated 123 pipeline absorbed by `|| true` under `set -euo pipefail` → exit 0 ✓
- Real override still detected → guard not neutered ✓
