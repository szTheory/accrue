---
phase: 32-adoption-discoverability-doc-graph
plan: 01
subsystem: docs
tags: [readme, ci, verify-01, host-integration]

requires: []
provides:
  - Single host H2 `## Proof and verification` with canonical merge-blocking lede
  - Doc contracts for new headings and VERIFY-01 awk depth
affects: [32-02, 32-03]

tech-stack:
  added: []
  patterns:
    - "Host README: Proof section SSOT; VERIFY-01 nested as H3 with #### children"

key-files:
  created: []
  modified:
    - examples/accrue_host/README.md
    - scripts/ci/verify_package_docs.sh
    - scripts/ci/verify_verify01_readme_contract.sh
    - accrue/README.md
    - accrue_admin/README.md

key-decisions:
  - "Visual walkthrough explicitly labeled non-merge-blocking vs VERIFY-01"
  - "README Hex install lines aligned to mix.exs 0.3.0 so verify_package_docs passes"

patterns-established:
  - "Approved one-liner lives under host ## Proof and verification lede"

requirements-completed: [ADOPT-02]

duration: 25min
completed: 2026-04-21
---

# Phase 32 — Plan 01 summary

**Host demo README now has one Proof and verification section as runnable SSOT, with CI scripts locking headings and VERIFY-01 depth.**

## Performance

- **Tasks:** 1
- **Files modified:** 5 (including version pin drift fix for doc gate)

## Accomplishments

- Introduced `## Proof and verification` with verbatim merge-blocking one-liner; demoted Verification modes and VERIFY-01 with valid heading hierarchy.
- Clarified Visual walkthrough as trust/demo lane only.
- Updated `verify_package_docs.sh` / `verify_verify01_readme_contract.sh`; awk accepts `### VERIFY-01`.
- Synced `accrue` / `accrue_admin` README `~>` pins with `@version` so `verify_package_docs.sh` succeeds.

## Task commits

1. **32-01-01** — `2cb742f` (docs)

## Self-check: PASSED

- `bash scripts/ci/verify_package_docs.sh` — OK
- `bash scripts/ci/verify_verify01_readme_contract.sh` — OK

## Deviations

- **Hex README version pins:** `accrue/README.md` and `accrue_admin/README.md` still said `~> 0.2.0` while `mix.exs` is `0.3.0`, causing `verify_package_docs` to fail before any phase-32 README work. Bumped install snippets to `~> 0.3.0` so the doc contract passes.
