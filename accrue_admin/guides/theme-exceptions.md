# Accrue Admin — theme & layout exceptions

This register tracks **intentional** deviations from Accrue Admin’s token-first styling (see **UX-04** in planning) so reviewers can spot drift and plan future tokenization. Introduced as part of **Phase 50** (v1.12 admin hygiene).

## Register

| slug | location | deviation | rationale | future_token | status | phase_ref |
|------|------------|-----------|-----------|--------------|--------|-----------|

## Phase 53 reviewer note (auxiliary Connect / events)

**v1.13 Phase 53:** `ConnectAccountsLive`, `ConnectAccountLive`, and `EventsLive` were audited for hard-coded hex colors, inline `style=`, and non-`ax-*` layout classes on touched auxiliary rows. **No token bypasses** were introduced; `default_brand/0` helper maps remain the only accent literals outside HEEx.
