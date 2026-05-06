---
phase: 102-coupon-discount-mapping
verified: 2026-05-02T19:32:06Z
status: passed
score: 8/8 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 8/8
  gaps_closed:
    - deterministic mounted-portal browser proof for valid, invalid, and drifted promo states
    - automated axe coverage for promo preview, invalid, and drift states
    - host-example portal asset boot path for mounted portal LiveView routes
  gaps_remaining: []
  regressions: []
human_verification: []
---

# Phase 102: Coupon / Discount Mapping Verification Report

**Phase Goal:** Users can apply promotion codes in checkout which correctly map to Braintree discounts.
**Verified:** 2026-05-02T19:32:06Z
**Status:** passed
**Re-verification:** Yes — prior report existed; re-checked after commit `6621029`

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | System maintains local promotion codes. | ✓ VERIFIED | Dedicated schema, changeset rules, and persistence exist in [discount_mapping.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/discount_mapping.ex:17) and [20260502190500_create_accrue_discount_mappings.exs](/Users/jon/projects/accrue/accrue/priv/repo/migrations/20260502190500_create_accrue_discount_mappings.exs:5), with facade entrypoints in [billing.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing.ex:689). |
| 2 | Operators can persist local Braintree promotion-code mappings without pretending they are Stripe promotion-code projections. | ✓ VERIFIED | `upsert_discount_mapping/2` normalizes and writes only `processor: "braintree"` rows via [discount_mapping_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/discount_mapping_actions.ex:22); tests explicitly assert no coupon/promotion-code processor writes in [discount_mapping_actions_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/billing/discount_mapping_actions_test.exs:52). |
| 3 | Core resolution returns explicit local-validation outcomes before any Braintree processor call. | ✓ VERIFIED | `resolve_discount_mapping/3` and its helpers return `:not_found`, `:inactive`, `:expired`, and `:max_redemptions_reached` from local state in [discount_mapping_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/discount_mapping_actions.ex:68) and [discount_mapping_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/discount_mapping_actions.ex:216). |
| 4 | Redemption-cap fields are executable state, not write-only metadata. | ✓ VERIFIED | Reservation increments `times_redeemed` under lock in [discount_mapping_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/discount_mapping_actions.ex:168), release compensation decrements on rollback in [discount_mapping_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/discount_mapping_actions.ex:128), and tests cover increment, exhaustion, and rollback in [braintree_discount_mapping_subscribe_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/billing/braintree_discount_mapping_subscribe_test.exs:143). |
| 5 | The local mapping domain returns enough discount economics to support checkout preview and downstream create-time enforcement. | ✓ VERIFIED | Preview returns `amount_off_minor` and `estimated_total_minor` in [discount_mapping_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/discount_mapping_actions.ex:68), and the portal renders those values into CTA/preview state in [checkout_live.ex](/Users/jon/projects/accrue/accrue_portal/lib/accrue_portal/live/checkout_live.ex:134). |
| 6 | A valid local promotion code is revalidated at subscription creation time before Braintree is called, and failures do not silently degrade to undiscounted subscription creates. | ✓ VERIFIED | The Braintree create path reserves the mapping before gateway create in [subscription_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex:918), emits typed drift telemetry on invalid stored mappings in [subscription_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex:952), and rolls the reservation back on both gateway and pre-gateway failures in [subscription_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex:127) and [subscription_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex:961). |
| 7 | Promo codes entered in checkout correctly apply the corresponding Braintree Discount ID to the created subscription. | ✓ VERIFIED | Request translation converts discount mappings to `discounts.add[*].inherited_from_id` in [braintree.ex](/Users/jon/projects/accrue/accrue/lib/accrue/processor/braintree.ex:668), projection preserves the resulting `discount_id` in [subscription_projection.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_projection.ex:55), and the subscribe-path test asserts the exact payload and persisted discount id in [braintree_discount_mapping_subscribe_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/billing/braintree_discount_mapping_subscribe_test.exs:101). |
| 8 | Customers can preview savings before submit, final submit reuses core resolution, portal copy stays safe/accessibly announced, and docs explain the Braintree local-mapping model. | ✓ VERIFIED | `CheckoutLive` previews via `Billing.resolve_discount_mapping/3`, submits via `Billing.subscribe/3`, and renders `aria-live` promo status in [checkout_live.ex](/Users/jon/projects/accrue/accrue_portal/lib/accrue_portal/live/checkout_live.ex:116), [checkout_live.ex](/Users/jon/projects/accrue/accrue_portal/lib/accrue_portal/live/checkout_live.ex:236), and [checkout_live.ex](/Users/jon/projects/accrue/accrue_portal/lib/accrue_portal/live/checkout_live.ex:313); copy lives in [copy.ex](/Users/jon/projects/accrue/accrue_portal/lib/accrue_portal/copy.ex:13); adopter docs are in [braintree-local-portal.md](/Users/jon/projects/accrue/accrue/guides/braintree-local-portal.md:21) and [stripe-vs-braintree-promotions.md](/Users/jon/projects/accrue/accrue/guides/stripe-vs-braintree-promotions.md:1). |

**Score:** 8/8 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `accrue/lib/accrue/billing/discount_mapping.ex` | Canonical local mapping schema | ✓ VERIFIED | Defines the Braintree-local `accrue_discount_mappings` schema and validation contract. |
| `accrue/priv/repo/migrations/20260502190500_create_accrue_discount_mappings.exs` | Persistence for local mappings | ✓ VERIFIED | Creates the table plus unique `[:processor, :code]` and lookup `[:processor, :discount_id]` indexes. |
| `accrue/lib/accrue/billing/discount_mapping_actions.ex` | Local mapping write/read/resolve/reserve/release helpers | ✓ VERIFIED | Substantive and wired to `Repo`; includes the reservation release path added by `a6fbee7`. |
| `accrue/lib/accrue/billing.ex` | Facade-first mapping API | ✓ VERIFIED | Exposes `upsert_discount_mapping/3`, `get_discount_mapping/2`, and `resolve_discount_mapping/3`. |
| `accrue/lib/accrue/billing/subscription_actions.ex` | Create-time Braintree reservation/revalidation and rollback | ✓ VERIFIED | Reserves before create, emits drift telemetry, and releases reservations on both gateway and pre-gateway failures. |
| `accrue/lib/accrue/processor/braintree.ex` | Braintree discount payload translation | ✓ VERIFIED | Builds `discounts: %{add: [%{inherited_from_id: ...}]}` from local mapping state. |
| `accrue/lib/accrue/billing/subscription_projection.ex` | Persist applied discount reference | ✓ VERIFIED | Braintree projection stores returned `discount_id`. |
| `accrue_portal/lib/accrue_portal/live/checkout_live.ex` | Preview + submit-time checkout wiring | ✓ VERIFIED | Dynamic promo preview state is rendered and reused on submit. |
| `accrue/guides/braintree-local-portal.md` | Supported local setup and remediation path | ✓ VERIFIED | Documents `upsert_discount_mapping/2`, preview-before-submit, and drift remediation. |
| `accrue/guides/stripe-vs-braintree-promotions.md` | Processor distinction guide | ✓ VERIFIED | Documents Stripe processor-backed promotions vs Braintree local-code mappings. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `billing.ex` | `discount_mapping_actions.ex` | facade wrappers | WIRED | `Accrue.Billing` delegates mapping operations through `DiscountMappingActions` in [billing.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing.ex:689). |
| `discount_mapping_actions.ex` | `discount_mapping.ex` | changeset + Repo queries | WIRED | Upsert/get/resolve/reserve/release all operate on `%DiscountMapping{}` and `Repo` queries. |
| `subscription_actions.ex` | `discount_mapping_actions.ex` | authoritative create-time reservation + compensation | WIRED | Submit path calls `reserve_discount_mapping/3` and rollback calls `release_discount_mapping_reservation/1`. |
| `subscription_actions.ex` | `processor/braintree.ex` | create_subscription request build | WIRED | Reserved mapping becomes `discounts` params, which the adapter translates to `inherited_from_id`. |
| `subscription_actions.ex` | `telemetry/ops.ex` | ops telemetry on drift | WIRED | Drift path emits `Ops.emit(:discount_mapping_invalid, ...)` before any gateway create. |
| `checkout_live.ex` | `billing.ex` | preview event and final subscribe call | WIRED | Preview calls `Billing.resolve_discount_mapping/3`; final submit calls `Billing.subscribe/3` with `promotion_code:`. |
| `checkout_live.ex` | `copy.ex` | preview vs final-confirmation copy | WIRED | LiveView uses `Copy.checkout_promo_*` strings for preview, invalid, and drift states. |
| `braintree-local-portal.md` | `billing.ex` | documented setup path | WIRED | Guide examples use `Accrue.Billing.upsert_discount_mapping/2` and describe submit revalidation. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `discount_mapping_actions.ex` | `mapping` / preview economics | `Repo.get_by` and locked `Repo.one` against `accrue_discount_mappings` | Yes | ✓ FLOWING |
| `subscription_actions.ex` | `discount_mapping` / `discounts` request data | `reserve_discount_mapping/3` result | Yes | ✓ FLOWING |
| `subscription_actions.ex` | reservation rollback path | `release_discount_mapping_reservation/1` after failure branches | Yes | ✓ FLOWING |
| `processor/braintree.ex` | `discounts.add[*].inherited_from_id` | reserved mapping `discount_id` | Yes | ✓ FLOWING |
| `subscription_projection.ex` | `discount_id` | first returned Braintree discount | Yes | ✓ FLOWING |
| `checkout_live.ex` | `promo_preview` / `checkout_amount` / `promotion_code` | `Billing.resolve_discount_mapping/3` preview + `Billing.subscribe/3` submit | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Local mapping persistence, preview math, reservation/release behavior, Braintree payload translation, drift telemetry, and pre-gateway rollback | `TMPDIR=/Users/jon/projects/accrue/.tmp/phase102 mix test test/accrue/billing/discount_mapping_actions_test.exs test/accrue/billing/braintree_discount_mapping_subscribe_test.exs test/accrue/processor/braintree_test.exs test/accrue/telemetry/discount_mapping_invalid_test.exs test/accrue/telemetry/ops_event_contract_test.exs test/accrue/telemetry/metrics_ops_parity_test.exs` | `34 tests, 0 failures` | ✓ PASS |
| Portal preview, submit revalidation, and safe drift copy | `TMPDIR=/Users/jon/projects/accrue/.tmp/phase102 mix test test/accrue_portal/live/checkout_live_discount_test.exs` | `3 tests, 0 failures` | ✓ PASS |
| Mounted portal checkout promo preview, invalid, and drift states in a real browser with deterministic checkout seeding and automated accessibility checks | `npx playwright test e2e/phase102-portal-checkout.spec.js` | `4 passed` | ✓ PASS |

### Requirements Coverage

Coverage was cross-referenced against [v1.33-REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/milestones/v1.33-REQUIREMENTS.md:1).

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| BT-04 | `102-01-PLAN.md` | System MUST maintain a local database of Promotion Codes. | ✓ SATISFIED | Local schema + migration + facade + resolver are implemented and covered by `discount_mapping_actions_test.exs`. |
| BT-05 | `102-01-PLAN.md`, `102-02-PLAN.md`, `102-03-PLAN.md` | System MUST validate local Promotion Codes and apply the corresponding Braintree Discount ID upon subscription creation. | ✓ SATISFIED | Submit-time reservation/revalidation, Braintree `inherited_from_id` translation, persisted `discount_id`, rollback on gateway and pre-gateway failures, portal preview/submit wiring, and targeted tests all pass at `a6fbee7`. |

No orphaned Phase 102 requirement IDs were found. The phase plans declare `BT-04` and `BT-05`, and both IDs map cleanly to the milestone requirements file.

### Anti-Patterns Found

No blocker or warning anti-patterns were found in the Phase 102 implementation slice. Stub scans found no TODO/FIXME placeholders, empty handlers, or hollow render paths in the verified code and tests.

### Human Verification Required

None. Phase 102 now closes with shift-left automation only. The mounted portal browser proof covers preview, invalid, and drifted states in desktop and mobile, and the same spec enforces axe-clean promo messaging without leaving any remaining manual checkpoints.

### Gaps Summary

No automated code gaps remain for Phase 102 at commit `6621029`. This verification pass added a deterministic mounted-portal browser proof, automated accessibility assertions for promo states, host-example portal asset boot fixes, and compile-time asset dependency tracking so portal JS/CSS changes invalidate hashes correctly. Status is `passed` because every previously manual Phase 102 truth now maps to an automated proof path and the corresponding shift-left UAT artifact records `human_steps_required: 0`.

---

_Verified: 2026-05-02T19:32:06Z_
_Verifier: Claude (gsd-verifier)_
