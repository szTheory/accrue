# Phase 246 TABLE-01 Identity Gap Summary

Resolved the five omitted collection identity renderers so exact identifiers remain distinct, readable, and copyable through the existing clipboard component.

The coupon, event, payment, Connect account, and webhook rows now use the shared `DataTable.identity_cell/1` layout and `IdBadge` copy action. Human-readable identity leads when available. Events preserve the exact stored event type key as copyable evidence, labeled “Copy event type” to distinguish it from the event record UUID. Connect accounts use email as the primary identity when available and keep the Stripe account ID in the secondary copy action.

## Verification

- RED: the five focused LiveView files produced **60 tests, 5 failures**, each on the newly added exact-ID clipboard assertion.
- GREEN: reran the same five files with warnings as errors and seed 0: **60 tests, 0 failures**.
- Shared contracts: `data_table_test.exs` and `id_badge_test.exs`, warnings as errors and seed 0: **35 tests, 0 failures**.
- `git diff --check` passed before the implementation commit.

## Commits

- `eb3c4944` — `test(246-identity): expose missing collection ID copy actions` (RED regression assertions)
- `d1840677` — `fix(246-identity): add copyable exact IDs to collections` (GREEN implementation)

The validation artifact now records all five gaps as resolved using `gsd_run query verification.append-audit`; Nyquist compliance remains false because the phase-wide rendered-evidence sign-off is outside this identity-gap correction.
