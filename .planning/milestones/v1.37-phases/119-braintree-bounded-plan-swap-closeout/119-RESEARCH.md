# Phase 119: Braintree Bounded Plan-Swap Closeout - Research

**Researched:** 2026-05-07  
**Domain:** Braintree bounded plan-swap contract hardening across runtime, docs, touched UI, and support-contract verifiers  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01..D-04:** Braintree remains bounded to `swap_plan/3` with
  `:plan_resolver`; preview, quantity, and subscription-item semantics stay
  explicitly unsupported.
- **D-05..D-07:** The processor support matrix is the SSOT and docs should
  mirror it thinly instead of retelling different Braintree stories.
- **D-08..D-10:** Touched UI surfaces may harden wording and setup guidance, but
  should not invent a new Braintree self-serve semantics layer.
- **D-11..D-13:** Tests and verifier scripts need to block both parity creep and
  accidental loss of the `:plan_resolver` contract.

### Deferred Ideas (OUT OF SCOPE)
- Braintree preview parity
- Braintree quantity or subscription-item parity
- pause/resume or schedule management reopening
- broad new portal/admin feature work beyond contract hardening

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| `SCM-06` | The processor support matrix, lifecycle/First Hour/production-readiness docs, example-host guidance, and merge-blocking verifiers repeat one coherent subscription-change contract and catch future drift automatically. | The repo already has the necessary mirror surfaces and shift-left verifier bundle; the remaining work is to tighten the Braintree swap-only story and make those needles more explicit about `:plan_resolver` and unsupported preview/quantity/item semantics. |

</phase_requirements>

## Summary

Most of the runtime and UI boundary this phase needs already exists. The public
support matrix, package README, First Hour guide, lifecycle semantics guide,
production-readiness checklist, admin copy, portal copy, and host README all
already describe Braintree as narrower than Stripe/Fake on active subscription
changes. The gap is not missing infrastructure; it is closeout-level tightening
so every mirror says the same bounded thing with the same setup contract and the
same unsupported branches. [VERIFIED: `.planning/processor-support-matrix.md`,
`accrue/README.md`, `accrue/guides/first_hour.md`,
`accrue/guides/lifecycle_semantics.md`, `accrue/guides/production-readiness.md`,
`examples/accrue_host/README.md`]

The core runtime boundary is already strong. `swap_plan/3` is the bounded
Braintree first-party path when a host supplies `:plan_resolver`, while
`update_quantity/3` is explicitly unsupported and preview remains unsupported
for Braintree in the public contract. That means the main runtime work for
Phase 119 is likely proof or error-shape hardening rather than new billing
behavior. [VERIFIED: `accrue/lib/accrue/billing/subscription_actions.ex`,
`accrue/test/accrue/billing/subscription_actions_test.exs`,
`accrue/lib/accrue/processor/capabilities.ex`,
`accrue/test/accrue/processor/capabilities_test.exs`]

The admin surface already exposes the right Braintree story for operators:
bounded first-party swap support only with `:plan_resolver`, preview
unavailable, and quantity/item changes unsupported. The portal surface is even
more conservative, explicitly keeping Braintree plan changes host-managed and
out of self-serve preview/swap UI. Those are good closeout defaults because
Phase 119's goal is to harden the contract, not broaden Braintree UI support.
[VERIFIED: `accrue_admin/lib/accrue_admin/copy/subscription.ex`,
`accrue_admin/test/accrue_admin/live/subscription_live_test.exs`,
`accrue_portal/lib/accrue_portal/copy.ex`,
`accrue_portal/test/accrue_portal/live/subscription_live_test.exs`]

The highest-leverage remaining work is docs and drift gates. The repo already
has a support-contract bundle spanning `verify_processor_support_matrix.sh`,
`verify_package_docs.sh`, `verify_verify01_readme_contract.sh`, and
`verify_adoption_proof_matrix.sh`, plus contributor-map guidance in
`scripts/ci/README.md`. Phase 119 should turn that into a stricter Braintree
closeout gate by pinning `:plan_resolver` setup language and the explicit
unsupported preview/quantity/item boundary where needed. [VERIFIED:
`scripts/ci/README.md`, `scripts/ci/verify_processor_support_matrix.sh`,
`scripts/ci/verify_package_docs.sh`,
`scripts/ci/verify_verify01_readme_contract.sh`,
`scripts/ci/verify_adoption_proof_matrix.sh`]

**Primary recommendation:** split Phase 119 into three plans:

1. harden the bounded Braintree runtime/touched-surface contract and proof
2. align support-matrix and package/example-host guidance around one exact
   swap-only-with-`:plan_resolver` story
3. tighten the support-contract verifier bundle and contributor-map rules so
   future wording drift is merge-blocking

That sequencing keeps the work narrow and defensible: confirm the runtime/UI
truth, mirror it precisely in docs, then pin it in automated drift gates.

## Current-State Findings

### The canonical support matrix already encodes the closeout target

- The capability table already lists:
  - `subscription.swap_plan` as `bounded first-party` on Braintree
  - `subscription.update_quantity` as `unsupported` on Braintree
  - subscription-item rows as `unsupported` on Braintree
  - `invoice.preview_upcoming_invoice` as `unsupported` on Braintree
  [VERIFIED: `.planning/processor-support-matrix.md`]
- The public API mapping already says `swap_plan/3` is bounded on Braintree
  only when the host provides `:plan_resolver`. [VERIFIED:
  `.planning/processor-support-matrix.md`]
- The matrix already frames unsupported Braintree quantity/item semantics as
  typed unsupported behavior instead of implied parity. [VERIFIED:
  `.planning/processor-support-matrix.md`]

### Runtime semantics are mostly already complete

- `Accrue.Billing.swap_plan/3` remains the official public swap verb.
  [VERIFIED: `accrue/lib/accrue/billing.ex`]
- `SubscriptionActions` and related tests already pin the bounded Braintree
  swap path and explicit unsupported quantity semantics. [VERIFIED:
  `accrue/lib/accrue/billing/subscription_actions.ex`,
  `accrue/test/accrue/billing/subscription_actions_test.exs`]
- `Capabilities` and its tests already express the promoted active-change
  support map, so the likely runtime gap is wording granularity, not missing
  capability rows. [VERIFIED:
  `accrue/lib/accrue/processor/capabilities.ex`,
  `accrue/test/accrue/processor/capabilities_test.exs`]

### Touched UI surfaces already lean in the right direction

- Admin copy currently says:
  - Stripe/Fake support preview-backed swap and quantity/item changes
  - Braintree supports bounded swap only with `:plan_resolver`
  - Braintree quantity/item mutations remain unsupported
  [VERIFIED: `accrue_admin/lib/accrue_admin/copy/subscription.ex`]
- Admin LiveView tests already assert setup guidance and unsupported branch
  wording, making them good merge-blocking anchors for any closeout tightening.
  [VERIFIED: `accrue_admin/test/accrue_admin/live/subscription_live_test.exs`]
- Portal copy currently keeps Braintree plan changes host-managed and says the
  mounted portal does not preview invoices or offer direct self-serve swaps on
  Braintree. That conservative wording matches the phase goal well. [VERIFIED:
  `accrue_portal/lib/accrue_portal/copy.ex`,
  `accrue_portal/test/accrue_portal/live/subscription_live_test.exs`]

### Docs are broad but not yet obviously locked to one phrasing discipline

- `accrue/README.md`, `first_hour.md`, and `production-readiness.md` all carry
  the Braintree bounded-swap story, but they do so with slightly different
  emphasis: support-bundle summary, onboarding branch, and ship checklist.
  [VERIFIED: `accrue/README.md`, `accrue/guides/first_hour.md`,
  `accrue/guides/production-readiness.md`]
- `lifecycle_semantics.md` is the natural semantic SSOT for active subscription
  changes and likely needs to be part of the closeout alignment pass so First
  Hour and production-readiness point back to one place. [VERIFIED:
  `accrue/guides/lifecycle_semantics.md`]
- `braintree-local-portal.md` already documents `:plan_resolver`, but its role
  in the official bounded plan-swap contract should stay synchronized with the
  other mirrors. [VERIFIED: `accrue/guides/braintree-local-portal.md`]

### The verifier bundle exists but only partially pins the closeout nuance

- `verify_processor_support_matrix.sh` already pins the canonical matrix rows
  for swap, preview, and provider-honest hosted/local wording. [VERIFIED:
  `scripts/ci/verify_processor_support_matrix.sh`]
- `verify_package_docs.sh`, `verify_verify01_readme_contract.sh`, and
  `verify_adoption_proof_matrix.sh` already require Braintree mentions plus
  `swap_plan/3` and `preview_upcoming_invoice/2`, but they do not appear to
  assert the full `:plan_resolver` setup nuance everywhere Phase 119 cares
  about it. [VERIFIED: `scripts/ci/verify_package_docs.sh`,
  `scripts/ci/verify_verify01_readme_contract.sh`,
  `scripts/ci/verify_adoption_proof_matrix.sh`]
- `scripts/ci/README.md` already has a support-contract bundle section from
  Phase 117. Phase 119 can extend that guidance specifically for the bounded
  Braintree swap-only closeout so contributors know which mirrors and needles
  must move together. [VERIFIED: `scripts/ci/README.md`]

## Risks

### Risk 1: docs teach the right boundary but with inconsistent emphasis

If First Hour, lifecycle semantics, production-readiness, and the host README
keep describing Braintree from different angles without one clear phrasing
discipline, future contributors will update one mirror and miss the others.

### Risk 2: verifier needles may miss the `:plan_resolver` contract

If CI only checks for generic mentions of `swap_plan/3` and Braintree, a future
edit could preserve those words while weakening the critical "only with
`:plan_resolver`" setup boundary.

### Risk 3: over-correcting UI wording could reopen scope

If this phase starts introducing new Braintree self-serve actions instead of
hardening copy and tests, it will become another feature slice instead of the
intended closeout pass.

## Recommended Plan Shape

### Plan 01: Braintree runtime and touched-surface boundary hardening

Scope:
- tighten any remaining runtime/copy wording around Braintree swap-only support
- ensure operator/customer surfaces and tests clearly express the
  `:plan_resolver` contract and unsupported preview/quantity/item branches
- keep the phase focused on hardening, not new UX breadth

Why first:
- docs and verifier updates need one exact runtime/UI truth to point at

### Plan 02: Support-mirror and guide alignment

Scope:
- align processor support matrix, package docs, lifecycle semantics, First Hour,
  production-readiness, Braintree local portal guide, host README, and adoption
  proof matrix around the same bounded Braintree story

Why second:
- this is the direct closure path for `SCM-06`

### Plan 03: Shift-left drift gate hardening

Scope:
- tighten verifier scripts and contributor-map guidance so bounded Braintree
  swap-only wording is merge-blocking

Why third:
- once the final wording exists, CI can pin it with less churn

## Verification Posture

- Core runtime proof should stay targeted and deterministic:
  - `cd accrue && mix test test/accrue/billing/subscription_actions_test.exs test/accrue/processor/capabilities_test.exs`
- Touched UI proof should stay bounded:
  - `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs`
  - `cd accrue_portal && mix test test/accrue_portal/live/subscription_live_test.exs`
  - `cd examples/accrue_host && mix test test/accrue_host_web/live/subscription_live_test.exs`
- Drift-gate proof should run the support-contract bundle from repo root:
  - `bash scripts/ci/verify_processor_support_matrix.sh`
  - `bash scripts/ci/verify_package_docs.sh`
  - `bash scripts/ci/verify_verify01_readme_contract.sh`
  - `bash scripts/ci/verify_adoption_proof_matrix.sh`
