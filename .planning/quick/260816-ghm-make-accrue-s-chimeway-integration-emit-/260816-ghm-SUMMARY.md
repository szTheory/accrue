---
quick_id: 260816-ghm
status: complete
subsystem: accrue-chimeway-dunning
tags: [chimeway, dunning, privacy, integration]
requires: []
provides:
  - Stable opaque Chimeway recipient correlation for Accrue dunning campaigns
  - Matching invoice.paid cancellation signal actor
affects: [accrue, chimeway]
key_files:
  created: []
  modified:
    - accrue/config/test.exs
    - accrue/lib/accrue/integrations/chimeway.ex
    - accrue/test/accrue/integrations/chimeway_test.exs
    - accrue/guides/dunning.md
    - accrue/CHANGELOG.md
decisions:
  - Use cw_accrue_customer_<customer UUID> as the durable Chimeway recipient reference.
  - Preserve email only as transient user:<email> delivery identity.
---

# Quick Task 260816-ghm: Chimeway Phase 98 opaque-recipient compatibility Summary

Accrue dunning now persists a deterministic opaque customer reference in Chimeway and uses that same reference to terminate waiting workflows with `invoice.paid`.

## Completed Work

- Added `customer_recipient_ref/1`, shared by notifier output and cancellation signals.
- Updated recipient maps to send durable `recipient_ref` plus transient `user:<email>` delivery identity.
- Added Phase 98 regression coverage for atom/string params, opaque-reference privacy, notification persistence, and signal equality.
- Updated the adopter guide and Unreleased changelog contract.

## Verification

- `CHIMEWAY_PATH=/Users/jon/projects/chimeway mix test test/accrue/integrations/chimeway_test.exs --warnings-as-errors` — passed (4 tests).
- `mix format --check-formatted lib/accrue/integrations/chimeway.ex test/accrue/integrations/chimeway_test.exs` — passed.
- `bash scripts/ci/verify_dunning_chimeway_isolation.sh` — passed.
- `bash scripts/ci/verify_release_notes_contract.sh` — passed.
- `git diff --check` — passed.

## Commits

- `f8ded962` — `test(260816-ghm): cover opaque Chimeway recipient routing`
- `be9ec462` — `feat(260816-ghm): use opaque Chimeway customer refs`
- `6484dee0` — `docs(260816-ghm): document opaque Chimeway routing`

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 3 - Blocking] Configured Chimeway's required test schema prefix.
   - **Found during:** Task 1 RED verification.
   - **Issue:** The local Phase 98 checkout requires `config :chimeway, prefix: "chimeway"` before its application can start; the existing cross-repo test setup only configured its repo.
   - **Fix:** Added the test-only schema prefix configuration alongside the existing Chimeway repo configuration.
   - **Files modified:** `accrue/config/test.exs`
   - **Commit:** `f8ded962`

## Self-Check: PASSED

- All five implementation and documentation files exist.
- All three task commits are present in git history.
