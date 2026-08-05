# Deferred Items

- `cd examples/accrue_host && mix format --check-formatted` is currently blocked by formatting violations in the unrelated, tracked files `lib/accrue_host_web/components/layouts.ex`, `priv/repo/migrations/20260803031000_create_accrue_apple_reconciliation_checkpoints.exs`, and `priv/repo/migrations/20260803013000_create_accrue_entitlement_compatibility_evidence.exs`. Phase 221-02's four scoped files pass the targeted formatter check.
