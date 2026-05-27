<user_constraints>
## User Constraints (from Phase 132 Requirements)

### Locked Decisions
- The canonical `examples/accrue_host` MUST demonstrate the v1.39 headline JTBD (gating access on what a customer has paid for) end-to-end.
- `examples/accrue_host` MUST gate at least one route or page on an entitlement using the v1.39 gate API (`Accrue.Live.Entitlements` / `Accrue.Plug.RequireEntitlement` / `Accrue.entitled?`).
- An entitled billable MUST reach the gated surface, and a non-entitled billable MUST be denied.
- `examples/accrue_host/docs/adoption-proof-matrix.md` MUST gain a matching row proving the entitlement-gating demo is part of the proof-posture contract.
- Updating the matrix REQUIRES co-updating `scripts/ci/verify_adoption_proof_matrix.sh` in the same change set.

### the agent's Discretion
- The name of the gated route (e.g., `/app/advanced-reports`, `/app/premium-feature`).
- The specific feature name to gate on (e.g., `:advanced_reports`, `:premium_access`).
- Which file to place the test/seed data in (e.g., `seed_e2e_cleanup_test.exs`, `priv/repo/seeds.exs`, or a new `entitlements_test.exs` within the host).

### Deferred Ideas (OUT OF SCOPE)
- Custom/external entitlement resolvers (stick to `LocalMap` and static config).
- Complex quota/limits gating (focus on a boolean feature gate for the primary demo).
</user_constraints>
