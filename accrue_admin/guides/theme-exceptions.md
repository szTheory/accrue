# Accrue Admin — theme & layout exceptions

This register tracks **intentional** deviations from Accrue Admin’s token-first styling (see **UX-04** in planning) so reviewers can spot drift and plan future tokenization. Introduced as part of **Phase 50** (v1.12 admin hygiene).

## Register

| slug | location | deviation | rationale | future_token | status | phase_ref |
|------|------------|-----------|-----------|--------------|--------|-----------|

## Phase 53 reviewer note (auxiliary Connect / events)

**v1.13 Phase 53:** `ConnectAccountsLive`, `ConnectAccountLive`, and `EventsLive` were audited for hard-coded hex colors, inline `style=`, and non-`ax-*` layout classes on touched auxiliary rows. **No token bypasses** were introduced; `default_brand/0` helper maps remain the only accent literals outside HEEx.

## Phase 55 reviewer note (invoice VERIFY wiring)

**v1.14 Phase 55:** `InvoicesLive` / `InvoiceLive` were reviewed for VERIFY-01 merge-blocking Playwright coverage (`core-admin-invoices-index`, `core-admin-invoices-detail`). **No new token exceptions** were required for invoice index/detail wiring; invoice chrome remains on `AccrueAdmin.Copy` / `AccrueAdmin.Copy.Invoice` with existing `ax-*` shell tokens.
