---
phase: 32-adoption-discoverability-doc-graph
plan: 03
subsystem: docs
tags: [guides, ssot, testing, stripe]

requires:
  - phase: 32-01
  - phase: 32-02
provides:
  - Package/repo guides aligned to host Proof SSOT with enforced one-liner
affects: []

tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified:
    - accrue/guides/testing.md
    - accrue/guides/first_hour.md
    - guides/testing-live-stripe.md
    - scripts/ci/verify_package_docs.sh

key-decisions:
  - "Live-Stripe guide explicitly not PR merge-blocking; links to host Proof"

patterns-established: []

requirements-completed: [ADOPT-03]

duration: 15min
completed: 2026-04-21
---

# Phase 32 — Plan 03 summary

**Testing and first-hour guides repeat the approved merge-blocking one-liner with deep links; live-Stripe guide names the non-blocking lane.**

## Self-check: PASSED

- `bash scripts/ci/verify_package_docs.sh` — OK
