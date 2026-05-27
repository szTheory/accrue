# Phase 136-02 Summary: Adopter Confidence - Recovery Wiring Visibility

Updated the host UI and documentation to provide visibility into the active recovery jobs, satisfying PROOF-06.

## Deliverables

- **UI Update:**
  - Added "Recovery Wiring Demo (PROOF-06)" section to `SubscriptionLive`.
  - Explains the purpose of `DetectExpiringCards` and `MeterEventsReconciler` jobs.

- **Documentation Update:**
  - Updated `examples/accrue_host/README.md` to include recovery and maintenance jobs in the Observability and "What this app proves" sections.
  - Updated `examples/accrue_host/docs/adoption-proof-matrix.md` to include a row for Recovery Wiring (PROOF-06).

## Verification Results

- Verified UI changes via `grep`.
- Verified documentation changes via `grep`.
- The `recovery_wiring_test.exs` from 136-01 remains the functional proof.

## Traceability
- **PROOF-06**: Recovery crons wired and documented in `examples/accrue_host`.
