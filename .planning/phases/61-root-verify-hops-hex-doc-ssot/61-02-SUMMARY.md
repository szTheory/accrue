---
phase: 61-root-verify-hops-hex-doc-ssot
plan: "02"
subsystem: docs
tags: [INT-09, Hex, planning, CONTRIBUTING]

requires:
  - phase: 61-01
    provides: INT-08 contributor map + verify_package_docs ownership baseline
provides:
  - v1.16 MILESTONES Hex + maintainer next pointers
  - PROJECT Current State dual-authority lines + Hex links
  - INT-09 contributor map row; CONTRIBUTING pre-publish deps edge

key-files:
  created: []
  modified:
    - .planning/MILESTONES.md
    - .planning/PROJECT.md
    - scripts/ci/README.md
    - CONTRIBUTING.md

requirements-completed: [INT-09]

duration: 12min
completed: 2026-04-23
---

# Phase 61 plan 02 summary

Aligned **INT-09** planning and contributor docs: **MILESTONES** v1.16 header, **PROJECT** § Current State dual-track (**`@version`** vs **public Hex**), **INT-09** CI README row, and **CONTRIBUTING** sharp edge for **Hex-only** `mix deps.get` after **`@version`** bumps.

## Task commits

Single docs commit (bundled 61-02 file set).

## Verification

- `bash scripts/ci/verify_package_docs.sh` — pass
- `bash scripts/ci/verify_verify01_readme_contract.sh` — pass
- `accrue/guides/first_hour.md` Hex banner — present (no prose change)

## Self-Check: PASSED
