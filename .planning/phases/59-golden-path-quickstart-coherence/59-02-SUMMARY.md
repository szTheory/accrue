---
phase: 59-golden-path-quickstart-coherence
plan: "02"
subsystem: testing
tags: [ci, verify_package_docs, quickstart, INT-06]

requires:
  - plan: "01"
    provides: quickstart and First Hour content needles reference in script
provides:
  - Merge-blocking quickstart hub + capsule structure checks in verify_package_docs.sh
  - ExUnit fixtures for quickstart in tmp_dir runs; negative test for missing auth_adapters anchor
affects: []

key-files:
  created: []
  modified:
    - scripts/ci/verify_package_docs.sh
    - accrue/test/accrue/docs/package_docs_verifier_test.exs

requirements-completed: [INT-06]

duration: —
completed: 2026-04-23
---

# Phase 59 plan 02 summary

**INT-06 automation slice:** Extended `verify_package_docs.sh` for quickstart + capsule literals; tests copy `quickstart.md` into fixtures and assert stdout mentions quickstart; negative drift on `auth_adapters.md`.

## Task commits

Single commit: `47b17ea` — `test(ci): extend package docs verifier for quickstart hub (59-02)`

## Self-Check: PASSED

- `mix test accrue/test/accrue/docs/package_docs_verifier_test.exs` — 7 tests, 0 failures.
- Doc-contract bash trio exited 0.
