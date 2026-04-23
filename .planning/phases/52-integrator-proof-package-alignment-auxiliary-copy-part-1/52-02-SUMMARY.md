---
phase: 52-integrator-proof-package-alignment-auxiliary-copy-part-1
plan: "02"
subsystem: testing
tags: [hex, semver, verify_package_docs, readme]

requires: []
provides:
  - Consumer install snippets aligned to mix.exs @version (0.3.1)
  - Hex vs main callouts on GitHub-facing READMEs and First Hour
  - verify_package_docs needles for new literals
affects: []

tech-stack:
  added: []
  patterns:
    - "Single @version SSOT with verify_package_docs require_fixed needles for banners"

key-files:
  created: []
  modified:
    - scripts/ci/verify_package_docs.sh
    - accrue/README.md
    - accrue_admin/README.md
    - accrue/guides/first_hour.md
    - README.md

key-decisions:
  - "Short Hex vs main blockquote near install snippets per 52-CONTEXT D-11"

patterns-established: []

requirements-completed: [INT-05]

duration: 20min
completed: 2026-04-22
---

# Phase 52 Plan 02 Summary

**Install-facing markdown and the root proof blurb now match `accrue` / `accrue_admin` `@version` (0.3.1), with explicit Hex vs `main` callouts and extended `verify_package_docs.sh` needles so Release Please bumps surface doc drift.**

## Task Commits

1. **Docs + banners** — `ae4e986`
2. **verify_package_docs extension** — `84e9b29`

## Follow-up

- Host README **Capsule R** was tightened in commit `b21b0f8` so the text before **Seeded history** does not embed the `mix verify.full` literal, restoring `Accrue.Docs.CanonicalDemoContractTest` parity (discovered via full `accrue` test run during phase execution).

## Self-Check: PASSED

- `bash scripts/ci/verify_package_docs.sh`
- Dynamic `{:accrue, "~> $version"` grep against `accrue/README.md`

---
*Phase: 52-integrator-proof-package-alignment-auxiliary-copy-part-1*
