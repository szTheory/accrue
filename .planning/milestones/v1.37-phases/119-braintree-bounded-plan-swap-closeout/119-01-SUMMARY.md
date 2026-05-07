---
phase: 119-braintree-bounded-plan-swap-closeout
plan: 01
subsystem: payments
tags: [braintree, subscriptions, admin, portal, host, testing]
requires:
  - phase: 118-admin-portal-change-flows
    provides: active-subscription-change UI and runtime seams
provides:
  - bounded Braintree swap-plan runtime contract with explicit resolver requirements
  - provider-honest admin and portal copy for unsupported preview and quantity semantics
  - merge-blocking tests for bounded Braintree wording across core and touched UI seams
affects: [119-02, 119-03, SCM-06]
tech-stack:
  added: []
  patterns: [bounded braintree swap-only contract, shared copy seam proof, Fake-first verification]
key-files:
  created:
    - .planning/milestones/v1.37-phases/119-braintree-bounded-plan-swap-closeout/119-01-SUMMARY.md
  modified:
    - accrue/lib/accrue/billing/subscription_actions.ex
    - accrue/lib/accrue/processor/capabilities.ex
    - accrue/test/accrue/billing/subscription_actions_test.exs
    - accrue/test/accrue/processor/capabilities_test.exs
    - accrue_admin/lib/accrue_admin/copy/subscription.ex
    - accrue_admin/test/accrue_admin/live/subscription_live_test.exs
    - accrue_portal/lib/accrue_portal/copy.ex
    - accrue_portal/test/accrue_portal/live/subscription_live_test.exs
    - examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs
key-decisions:
  - "Braintree swap support remains first-party only through swap_plan/3 with host-supplied :plan_resolver metadata."
  - "Preview, quantity, and subscription-item semantics remain explicitly unsupported on Braintree across runtime and touched UI surfaces."
  - "Touched admin and portal copy stays conservative rather than implying latent self-serve parity."
patterns-established:
  - "Braintree support is hardened by pairing runtime checks with shared copy seams and adjacent LiveView tests."
  - "Unsupported provider semantics are phrased as explicit boundaries plus one actionable host-owned next step."
requirements-completed: [SCM-06]
duration: 2 min
completed: 2026-05-07
---

# Phase 119 Plan 01 Summary

**Braintree plan swaps now stay explicitly bounded to `swap_plan/3` plus `:plan_resolver`, while runtime and touched UI seams reject preview and quantity parity clearly under test.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-07T21:04:44Z
- **Completed:** 2026-05-07T21:05:47Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- Verified the bounded Braintree runtime path now resolves host-owned plan metadata before swap and fails clearly when the resolver contract is missing or invalid.
- Locked admin, portal, and host-facing wording to the same provider-honest boundary: swap-only support with no preview, quantity, or item parity.
- Confirmed the targeted core and touched-surface tests pass on the current worktree.

## Verification

- `cd accrue && mix test test/accrue/billing/subscription_actions_test.exs test/accrue/processor/capabilities_test.exs`
  - PASS, 16 tests, 0 failures
- `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs`
  - PASS, 8 tests, 0 failures
- `cd accrue_portal && mix test test/accrue_portal/live/subscription_live_test.exs`
  - PASS, 4 tests, 0 failures
- `cd examples/accrue_host && mix test test/accrue_host_web/live/subscription_live_test.exs`
  - PASS, 5 tests, 0 failures

## Task Commits

No new phase-local commits were created in this execution run. The phase was verified in place on a pre-existing dirty worktree so unrelated user changes were preserved.

## Files Created/Modified

- `accrue/lib/accrue/billing/subscription_actions.ex` - Bounded Braintree swap execution now depends on resolved host plan metadata and explicit mismatch checks.
- `accrue/lib/accrue/processor/capabilities.ex` - Provider support labels continue to advertise swap-only Braintree support and explicit unsupported branches elsewhere.
- `accrue/test/accrue/billing/subscription_actions_test.exs` - Added resolver-backed positive proof and explicit failure cases for missing resolver, billing-cycle drift, and currency drift.
- `accrue/test/accrue/processor/capabilities_test.exs` - Pinned the bounded support labels that back the public matrix.
- `accrue_admin/lib/accrue_admin/copy/subscription.ex` - Hardened operator-facing Braintree guidance around `:plan_resolver` and unsupported quantity/item semantics.
- `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` - Pinned the same operator wording under LiveView proof.
- `accrue_portal/lib/accrue_portal/copy.ex` - Kept customer-facing Braintree plan changes explicitly host-managed and preview-free.
- `accrue_portal/test/accrue_portal/live/subscription_live_test.exs` - Pinned the bounded portal wording.
- `examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs` - Preserved host-facing proof for the provider-honest cancellation and plan-change split.

## Decisions Made

- Kept the Braintree portal posture conservative: copy hardening only, not a new self-serve swap surface.
- Treated the plan-resolver contract as the only supported bridge from app-facing `price_id` to Braintree mutation metadata.

## Deviations from Plan

None - plan behavior matched the planned bounded-support hardening work already present in the worktree.

## Issues Encountered

None.

## Next Phase Readiness

- Public docs can now mirror one precise runtime/UI contract without inventing a second Braintree story.
- The verifier bundle can safely pin the final wording because the runtime and touched UI seams are already aligned.

## Self-Check: PASSED

- Summary file exists at `.planning/milestones/v1.37-phases/119-braintree-bounded-plan-swap-closeout/119-01-SUMMARY.md`
- All targeted Wave 1 verification commands passed on the current worktree

---
*Phase: 119-braintree-bounded-plan-swap-closeout*
*Completed: 2026-05-07*
