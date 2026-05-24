---
phase: 121-linked-publish-proof-sweep
plan: 03
subsystem: docs-and-proof
tags: [docs, verification, host-integration, release-truth]

# Dependency graph
requires:
  - phase: 121-linked-publish-proof-sweep
    provides: superseding linked release proof for PR `#23`, version `1.1.1`, run `25554198977`
provides:
  - Post-publish docs aligned to the shipped trio
  - Green smoke and full verifier reruns against the released line
  - Closed Phase 121 ledger keyed to the actual shipped identifiers
affects: [phase-121, docs-contracts-shift-left, host-integration]

# Tech tracking
tech-stack:
  added: []
  patterns: [post-publish-doc-sweep, verifier-ledger, host-mount-separation]

key-files:
  created:
    - .planning/phases/121-linked-publish-proof-sweep/121-03-SUMMARY.md
  modified:
    - .planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md
    - README.md
    - accrue/guides/first_hour.md
    - examples/accrue_host/README.md
    - examples/accrue_host/docs/adoption-proof-matrix.md
    - scripts/ci/verify_package_docs.sh
    - scripts/ci/verify_adoption_proof_matrix.sh
    - scripts/ci/verify_verify01_readme_contract.sh
    - examples/accrue_host/config/config.exs
    - examples/accrue_host/lib/accrue_host_web/router.ex
    - examples/accrue_host/test/accrue_host_web/portal_cold_start_test.exs
    - examples/accrue_host/test/install_boundary_test.exs
    - scripts/ci/accrue_host_seed_e2e.exs
    - accrue_admin/lib/accrue_admin/router.ex

key-decisions:
  - "Normalize the Phase 121 ledger to the superseding shipped line (`#23`, `1.1.1`, `25554198977`) while preserving the failed `1.1.0` attempt as historical evidence."
  - "Keep `/billing` as the canonical mounted admin proof path and move the mounted customer portal onto a separate host path so host-integration stops testing two incompatible contracts on the same prefix."
  - "Treat host-integration regressions discovered during the docs sweep as part of the release-proof surface rather than downgrading the wrapper gate."

requirements-completed: [PPX-13, PPX-14]

# Metrics
duration: ~2h
completed: 2026-05-08
---

# Phase 121 Plan 03: Post-publish mirrors and verifier bundle aligned to the shipped trio

**Plan 03 completed against the superseding linked release line: PR `#23`, version `1.1.1`, workflow run `25554198977`.**

## Accomplishments
- Updated the known pair-only public mirrors so they now describe the shipped trio:
  - `README.md`
  - `accrue/guides/first_hour.md`
  - `examples/accrue_host/README.md`
  - `examples/accrue_host/docs/adoption-proof-matrix.md`
- Tightened the post-publish shell verifiers to match the released three-package truth and `1.1.1` line.
- Repaired the host proof surface uncovered by the full bundle:
  - separated mounted portal and admin routes in the example host
  - kept admin proof on `/billing`
  - moved portal proof to its own host path and updated seeded checkout fixtures accordingly
  - made dual admin mounts compile cleanly by deriving mount-specific admin pipeline names
- Wrote the final Phase 121 ledger entries for public registry proof, post-publish mirror notes, smoke reruns, and full verifier reruns.

## Verification
- `bash scripts/ci/verify_package_docs.sh`
- `bash scripts/ci/verify_adoption_proof_matrix.sh`
- `bash scripts/ci/verify_release_manifest_alignment.sh`
- `bash scripts/ci/verify_release_contract.sh`
- `bash scripts/ci/verify_verify01_readme_contract.sh`
- `bash scripts/ci/verify_production_readiness_discoverability.sh`
- `bash scripts/ci/verify_core_admin_invoice_verify_ids.sh`
- `bash scripts/ci/accrue_host_uat.sh`

## Outcome
- Public docs and proof mirrors now reflect the actual shipped three-package line.
- The merge-blocking docs-contracts bundle and the host-integration wrapper pass against that released state.
- Phase 121 is now closed on evidence instead of the earlier partial `1.1.0` release attempt.

## Self-Check: PASSED

---
*Phase: 121-linked-publish-proof-sweep*
*Completed: 2026-05-08*
