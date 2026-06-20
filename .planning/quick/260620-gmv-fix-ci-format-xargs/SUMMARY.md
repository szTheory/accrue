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

## Round 2 — planning-doc contract fallout from the v1.53 close

Watching CI on `0ce75413` revealed the "Docs and bash contracts" job still red, now on a
**different** step: **Stable-core posture contract** (`verify_stable_core_posture.sh`). Root
cause: the GSD complete-milestone workflow **deletes `.planning/REQUIREMENTS.md`**, but this
repo treats it as a *permanent public-anchor file* — three merge-blocking contracts depend on
standing literals in the planning docs (the documented "planning-doc contract invariants"
gotcha). The close also reworded two standing needles.

Fixes:

- **Restored `.planning/REQUIREMENTS.md`** as a "fresh" file retaining standing
  `POS-01..03` + collapsed shipped-milestone one-liners (now incl. v1.53 shipped 33/33,
  archived) + Out of Scope. The full v1.53 functional reqs stay archived in
  `milestones/v1.53-REQUIREMENTS.md`. (Matches the v1.47/v1.50 clear-then-recreate precedent.)
- **`.planning/ROADMAP.md`** — re-added the literal `No broad feature milestone is currently
  open.` (roadmap-hygiene needle dropped by the close's `<details>` splice).
- **`.planning/PROJECT.md`** — re-hyphenated `stable-core / demand-driven expansion` (close had
  reworded it to "stable core", breaking the stable-core-posture needle).

Verified: **all 14 bash contracts** in the Docs/bash CI job pass locally (exit 0).

## Result

Round 1: `0ce75413` (format + xargs), pushed `0d697e89..0ce75413`.
Round 2: planning-doc contract restore (REQUIREMENTS.md + ROADMAP/PROJECT needles).
CI watched to green.
