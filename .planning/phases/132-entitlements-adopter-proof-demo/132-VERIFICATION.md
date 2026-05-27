# Phase 132: Entitlements Adopter-Proof Demo Verification

This file provides the goal-backward verification steps to ensure Phase 132 meets its acceptance criteria.

## Phase Goal
The canonical `examples/accrue_host` demonstrates the v1.39 headline JTBD — gate access on what a customer has paid for — end-to-end, so the flagship entitlements capability is provable in the demo, not just unit-tested in core.

## Required Truths

For the phase to be considered complete, the following statements MUST be observable truths:

### 1. Entitlements mapped to correct entity
The configuration for `config :accrue, :entitlements` natively retrieves the organization from `current_scope`, ensuring B2B apps gate based on the org rather than the user.
**How to verify:** Inspect `examples/accrue_host/config/config.exs` and ensure `container.assigns.current_scope.organization` is resolved in the `billable` function.

### 2. Gated Route is active
The router uses the `Accrue.Live.Entitlements` gate in `examples/accrue_host/lib/accrue_host_web/router.ex` to protect a route (e.g. `/app/reports/advanced`).
**How to verify:** Run `cd examples/accrue_host && mix phx.routes` and confirm the route exists.

### 3. Gating rules operate correctly (Allow & Deny)
An entitled billable can access the route, and a non-entitled billable is denied.
**How to verify:** Run `cd examples/accrue_host && mix test test/accrue_host_web/live/entitlements_guard_test.exs` and confirm the integration tests pass, proving the allow/deny logic natively works.

### 4. Adopter-Proof Contract is enforced
The `examples/accrue_host/docs/adoption-proof-matrix.md` contains a specific contract proving the demo exists, and CI enforces this contract.
**How to verify:** Run `bash scripts/ci/verify_adoption_proof_matrix.sh` and ensure it succeeds, showing the Entitlement gating row exists.

## Final Sign-off

Run the following command to execute all verifications automatically:

```bash
# 1. Test Entitlements Route behaves correctly
cd examples/accrue_host && mix test test/accrue_host_web/live/entitlements_guard_test.exs

# 2. Check Adopter-Proof matrix checks out
cd ../../ && bash scripts/ci/verify_adoption_proof_matrix.sh
```

If both commands return 0 (success), the phase is complete and ready for milestone inclusion.
