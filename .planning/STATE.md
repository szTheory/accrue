---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
stopped_at: Completed 03-06-PLAN.md
last_updated: "2026-04-14T17:48:59.937Z"
last_activity: 2026-04-14
progress:
  total_phases: 9
  completed_phases: 2
  total_plans: 20
  completed_plans: 18
  percent: 90
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-11)

**Core value:** A Phoenix developer can install Accrue + accrue_admin and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic, with tamper-evident audit and zero breaking-change pain through v1.x.
**Current focus:** Phase 03 — core-subscription-lifecycle

## Current Position

Phase: 03 (core-subscription-lifecycle) — EXECUTING
Plan: 7 of 8
Status: Ready to execute
Last activity: 2026-04-14

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**

- Total plans completed: 6
- Average duration: N/A
- Total execution time: 0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01 | 6 | - | - |

**Recent Trend:**

- Last 5 plans: none
- Trend: N/A

*Updated after each plan completion*
| Phase 03-core-subscription-lifecycle P01 | 9m | 4 tasks | 18 files |
| Phase 03 P02 | 10m | 3 tasks | 18 files |
| Phase 03 P03 | 25m | 3 tasks | 7 files |
| Phase 03-core-subscription-lifecycle P04 | 35m | 3 tasks | 12 files |
| Phase 03 P05 | 12m | 2 tasks | 5 files |
| Phase 03 P06 | 25m | 3 tasks | 10 files |

## Accumulated Context

### Decisions

Full decision log lives in PROJECT.md Key Decisions table. Recent decisions affecting current work:

- [Roadmap]: 9-phase topological structure; topological execution 1→9
- [Roadmap]: Fake Processor is primary test surface from Phase 1, not a test-layer afterthought
- [Roadmap]: Money value type lands in Phase 1 so no schema is built with bare-integer amounts
- [Roadmap]: Gift cards (BILL-086, MAIL-gift) deferred to v2, not in v1 scope
- [Roadmap]: DLQ retention default 90 days (WH-11); installer idempotent from day one (INST-07)
- [Phase 03-core-subscription-lifecycle]: defdelegate is compile-checked in modern Elixir — action modules need declarative stubs, not empty bodies
- [Phase 03-core-subscription-lifecycle]: NoRawStatusAccess Credo check scoped to Subscription-shaped code (stripe status atoms) to avoid false positives on WebhookEvent.status
- [Phase 03]: Invoice.changeset/2 @required_fields is empty — state-machine changeset operates on bare structs; processor enforcement lives at Customer level
- [Phase 03]: Accrue.Billing.Query exempt from NoRawStatusAccess: canonical query wrapper, same role as Subscription module for predicates
- [Phase 03]: Invoice rollup columns use bigint not integer: annual enterprise totals and multi-year Subscription Schedule previews can exceed 2^31
- [Phase 03]: advance/2 vs advance_subscription/2 split preserves Phase 1 clock-only API while adding subscription-aware trial crossing
- [Phase 03]: Fake new resources use atom-keyed Stripe-shape maps consistent with Phase 1 + LatticeStripe struct translation pattern
- [Phase 03]: create_charge routes through PaymentIntent.create because lattice_stripe 1.0 removes direct Charge.create per Stripe 2026-03-25.dahlia
- [Phase 03-core-subscription-lifecycle]: NimbleOptions nil defaults require {:or, [:type, nil]} union — bare :string/:pos_integer types fail validate with default: nil
- [Phase 03-core-subscription-lifecycle]: Accrue.Billing.subscribe/3 accepts both billable struct AND %Customer{} directly — tests need manual customer seeding; host-app callers use lazy fetch
- [Phase 03-core-subscription-lifecycle]: Fake gains build_subscription_item/apply_subscription_update/merge_item helpers so flat item patches round-trip through Stripe-shape items.data nesting
- [Phase 03]: InvoiceProjection emits :processor_id (not :stripe_id) for parent invoice; only InvoiceItem uses :stripe_id (D3-15)
- [Phase 03]: InvoiceProjection delegates field lookup to SubscriptionProjection.get/2 for dual-key (atom/string) support — no duplication
- [Phase 03]: run_action/4 is the single D3-18 workflow shape for all 5 invoice actions; only pay_invoice wraps via IntentResult
- [Phase 03]: charge/3 calls Processor.create_charge OUTSIDE Repo.transact so SCA 3DS responses never persist a half-baked Charge row — IntentResult.wrap branches before any DB insert
- [Phase 03]: Fingerprint dedup uses application-level SELECT then rescue Ecto.ConstraintError for concurrent race via partial unique index backstop
- [Phase 03]: set_default_payment_method asserts pm.customer_id==customer.id BEFORE any processor call; raises Accrue.Error.NotAttached — not a tuple return
- [Phase 03]: create_refund returns uniform {:ok, %Refund{}} — fee settlement state is a property (fees_settled?) not a tagged-return branch (D3-47)
- [Phase 03]: Accrue.Repo facade gains get/get_by/get_by!/delete/aggregate delegations for Plan 06 — D-10 host-owns-Repo preserved as pure pass-throughs

### Pending Todos

None yet.

### Blockers/Concerns

- **Release Please v4 monorepo output naming:** verify via dry-run before Phase 9 release work.
- **ChromicPDF on minimal Alpine containers:** needs real-world container testing in Phase 6; PDF.Null adapter is the escape hatch.
- **lattice_stripe 1.1 (BillingMeter/MeterEvent/BillingPortal.Session):** Required for Phase 4 requirements BILL-11 (metered billing) and CHKT-02 (Customer Portal). Upstream work is in-flight in a parallel session targeting 1.1 release. Does NOT block Phase 3 or the rest of Phase 4.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260413-jri | Bump lattice_stripe to ~> 1.0 and unblock Phase 3 | 2026-04-13 | 52bec8e | [260413-jri-bump-lattice-stripe-to-1-0-and-unblock-p](./quick/260413-jri-bump-lattice-stripe-to-1-0-and-unblock-p/) |

## Session Continuity

Last session: 2026-04-14T17:48:47.030Z
Stopped at: Completed 03-06-PLAN.md
Resume file: None
