# Phase 117: Contract Promotion + Preview Truth - Research

**Researched:** 2026-05-07
**Domain:** Active subscription-change contract promotion across Accrue's billing facade, support matrix, lifecycle docs, and shift-left proof bundle
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Public contract labeling
- **D-01:** `Accrue.Billing.swap_plan/3` and `Accrue.Billing.preview_upcoming_invoice/2` should both be promoted as **official active-subscription-change APIs**.
- **D-02:** The public contract must use **two-axis labeling**, not one coarse support label:
  - top-level: these APIs are part of Accrue's official active-subscription-change contract
  - provider-level: each processor gets explicit capability labels that state what is native, bounded, unsupported, or testing-only
- **D-03:** `swap_plan/3` provider labels should be:
  - Stripe: `native`
  - Braintree: `bounded first-party` / `host-owned metadata + native mutation`
  - Fake: `testing/local-only`
- **D-04:** `preview_upcoming_invoice/2` provider labels should be:
  - Stripe: `native`
  - Braintree: `unsupported`
  - Fake: `testing/local-only`
- **D-05:** Do **not** label either API `all first-party` in the coarse existing sense. That would hide the Braintree preview gap and overstate parity.
- **D-06:** Add finer-grained capability rows for these APIs instead of overloading broad labels like `subscription.update`.

### Braintree contract boundary
- **D-07:** Keep Braintree on the shared public facade, but only as a **bounded first-party plan-swap path**.
- **D-08:** The Braintree `swap_plan/3` contract is:
  - single-item subscription only
  - `:plan_resolver` required
  - current and target plans must both resolve
  - resolved target must be `processor: "braintree"`
  - current and target plans must share currency
  - current and target plans must share billing cycle
  - supported proration values are only `:create_prorations` and `:none`
- **D-09:** `preview_upcoming_invoice/2` remains explicitly unsupported on Braintree. Accrue should not invent pseudo-preview or parity theater here.
- **D-10:** If a host wants Braintree pre-commit pricing copy, that must stay **host-owned** and be presented as an estimate, not as an Accrue invoice preview.
- **D-11:** `:plan_resolver` should be documented as a **Braintree swap enabler**, not as a generic abstraction layer. The required metadata contract should be spelled out explicitly: `processor_plan_id`, `unit_amount_minor`, `currency`, `billing_cycle`, and `processor: "braintree"`.
- **D-12:** Unsupported Braintree quantity and multi-item semantics should fail clearly at the facade boundary with typed unsupported guidance. Do not silently accept or ignore incompatible options.
- **D-13:** The public option story for Braintree must not imply that `:quantity`, `:proration_date`, `:billing_cycle_anchor`, `:payment_behavior`, or `:metadata` are meaningful if they are not honored on that path.

### Preview-before-commit posture
- **D-14:** Adopt **canonical-when-supported** as the official preview posture.
- **D-15:** On Stripe and Fake, `preview_upcoming_invoice/2` is the **default documented and first-party UI path** before `swap_plan/3`.
- **D-16:** On Braintree, there is **no first-party preview step**. The contract is direct bounded swap only, with explicit provider-honest wording.
- **D-17:** Do **not** make preview a hard runtime precondition for the raw API. `swap_plan/3` should remain directly callable for host code and operator flows.
- **D-18:** Docs and UI should consistently state that preview is the canonical path **where Accrue supports it**, while Braintree intentionally does not participate in that preview flow.
- **D-19:** Preview wording should acknowledge exactness honestly:
  - Stripe preview is the closest fidelity path and has live proof
  - Fake preview preserves flow shape and deterministic proof, but is `testing/local-only`
  - final committed amounts can still differ slightly due to timing/tax/provider details where applicable

### Docs and SSOT architecture
- **D-20:** Keep a **two-part canonical spine** rather than creating a new dedicated subscription-change contract doc.
- **D-21:** `accrue/guides/lifecycle_semantics.md` is the **semantic SSOT** for:
  - action meaning
  - preview-before-commit posture
  - proration expectations
  - provider labels
  - UI/copy guidance
- **D-22:** `.planning/processor-support-matrix.md` is the **capability/support SSOT** for:
  - which providers support `swap_plan/3`
  - which providers support preview
  - which quantity/item semantics are official
  - where Braintree support ends
- **D-23:** API docs should stay thin and reference the two canonical docs above for semantics and support boundaries.
- **D-24:** `accrue/README.md`, `accrue/guides/first_hour.md`, `examples/accrue_host/README.md`, and `examples/accrue_host/docs/adoption-proof-matrix.md` should act as **thin mirrors**, not competing truth sources.
- **D-25:** Do not create a third “subscription_change_contract.md” style canonical artifact. That would add drift burden with no real payoff.

### Admin and portal UX posture
- **D-26:** Stripe/Fake UI flows should be **preview-first**:
  - primary CTA: preview the change
  - secondary CTA: confirm the change after preview
- **D-27:** Braintree UI flows should not expose a fake preview affordance. They should instead present a direct bounded swap path plus explicit setup/support constraints.
- **D-28:** Do not expose raw option enums like `create_prorations` directly to end users where outcome-oriented copy is possible.
- **D-29:** Braintree UI should hide unsupported options such as `Always invoice`, and it should gate swap availability on more than resolver presence alone.
- **D-30:** Admin/operator copy should describe Braintree constraints concretely:
  - missing resolver
  - unresolved target price
  - billing-cycle mismatch
  - currency mismatch
  - no preview support
  - no quantity or multi-item support through Accrue
- **D-31:** Customer-facing wording should say “preview unavailable for this provider” rather than implying the feature is broken or incomplete.

### Architecture and DX principles
- **D-32:** Preserve the existing intent-first public API design (`swap_plan/3`, `preview_upcoming_invoice/2`) rather than introducing provider-specific facade verbs.
- **D-33:** Preserve provider-honest behavior over façade uniformity. One function name is good DX; fake sameness is not.
- **D-34:** Explicit runtime failures and explicit docs are preferred over hidden fallback behavior.
- **D-35:** The repo should continue to learn from:
  - Stripe: keep preview and commit separate, proration explicit
  - Laravel Cashier / Pay: intent-first verbs and bounded shared facade work well when divergence is named honestly
  - ActiveMerchant: avoid broad lowest-common-denominator gateway sameness
- **D-36:** This phase should improve least surprise for both adopters and maintainers by aligning runtime truth, matrix truth, docs truth, and UI truth around one coherent provider-honest contract.

### Shift-left discussion preference
- **D-37:** For future GSD discuss/planning passes in this processor-support track, default to:
  - research-first synthesis
  - cohesive recommendation packages
  - auto-resolution of low-impact forks
  - interactive escalation only for materially high-impact boundary decisions
- **D-38:** High-impact escalation should be reserved for decisions that would materially change:
  - public API shape
  - milestone scope
  - first-party support promise
  - release-gate philosophy
  - processor strategy
- **D-39:** Current config already points this way (`research_before_questions`, `discuss_auto_resolve_low_impact`, `discuss_high_impact_confirm`); future GSD behavior in this repo should keep leaning into that preference instead of reopening routine contract-shaping choices.

### Claude's Discretion
- Exact wording of the new provider labels, as long as the two-axis contract remains explicit and provider-honest.
- Exact capability-row naming in the support matrix and code, as long as `swap_plan` and preview stop being hidden under coarse generic buckets.
- Exact UI layout for preview-first flows, as long as Stripe/Fake become preview-led and Braintree stays explicit/direct.
- Exact CI/verifier needle placement, as long as the support-contract bundle keeps all touched mirrors aligned.

### Deferred Ideas (OUT OF SCOPE)

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SCM-01 | Host code can treat `Accrue.Billing.swap_plan/3` as an official first-party active-subscription-change API with one documented support contract across Fake, Stripe, and bounded Braintree. | Promote `swap_plan/3` through `Accrue.Billing`, `SubscriptionActions`, `PlanResolver`, `lifecycle_semantics.md`, `.planning/processor-support-matrix.md`, and the support-contract verifier bundle instead of widening runtime scope. [VERIFIED: accrue/lib/accrue/billing.ex][VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex][VERIFIED: accrue/lib/accrue/plan_resolver.ex][VERIFIED: accrue/guides/lifecycle_semantics.md][VERIFIED: .planning/processor-support-matrix.md][VERIFIED: scripts/ci/README.md] |
| SCM-02 | Host code and first-party UI surfaces can preview supported subscription changes through `Accrue.Billing.preview_upcoming_invoice/2` before commit, with proration and preview semantics documented as the canonical path. | Keep preview canonical on Stripe/Fake, explicitly unsupported on Braintree, and prove that stance with `upcoming_invoice`, Fake round-trip, live Stripe fidelity, and mirror/verifier updates. [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex][VERIFIED: accrue/test/accrue/billing/upcoming_invoice_test.exs][VERIFIED: accrue/test/accrue/billing/proration_roundtrip_test.exs][VERIFIED: accrue/test/live_stripe/proration_fidelity_live_test.exs][VERIFIED: scripts/ci/README.md] |
</phase_requirements>

## Summary

Phase 117 should be planned as a **contract-promotion and drift-closure phase**, not as a net-new billing-engine phase. `Accrue.Billing.swap_plan/3` already exists on the public facade, `SubscriptionActions.swap_plan/3` already branches into a bounded Braintree path, `preview_upcoming_invoice/2` already exists as a public preview helper, and `PlanResolver` already defines the host-owned metadata seam Braintree needs. The biggest gap is not missing runtime primitives; it is that the support SSOT, docs mirrors, capability labels, and admin wording do not yet tell one coherent “active subscription change” story. [VERIFIED: accrue/lib/accrue/billing.ex][VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex][VERIFIED: accrue/lib/accrue/plan_resolver.ex][VERIFIED: .planning/processor-support-matrix.md][VERIFIED: accrue_admin/lib/accrue_admin/live/subscription_live.ex][VERIFIED: accrue_admin/lib/accrue_admin/copy/subscription.ex]

The hardest boundary is Braintree honesty. Stripe has a first-party invoice-preview API for subscription changes, including `proration_behavior` and `proration_date`, so Accrue can safely document preview-before-commit there. Braintree still requires direct subscription updates with explicit `price` plus `plan_id`, restricts swaps to the same billing cycle, and does not offer an equivalent upcoming-invoice preview surface. Planning should therefore **promote a two-axis contract**: official active-subscription-change APIs at the top level, then explicit provider labels underneath. [CITED: https://docs.stripe.com/api/invoices/create_preview][CITED: https://docs.stripe.com/billing/subscriptions/prorations?locale=en-GB][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/][VERIFIED: .planning/phases/117-contract-promotion-preview-truth/117-CONTEXT.md]

The planner should decompose this phase into three tightly coupled slices: `capability/code truth`, `canonical docs + thin mirrors`, and `shift-left proof`. That keeps Phase 117 focused on SCM-01 and SCM-02 while leaving the heavier preview-first UI mechanics for Phase 118. The one nuance is that any already-misleading UI or copy touched by Phase 117 should be corrected enough to stop contradicting the new contract, even if the full preview UX ships later. [VERIFIED: .planning/ROADMAP.md][VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: .planning/phases/117-contract-promotion-preview-truth/117-CONTEXT.md][ASSUMED]

**Primary recommendation:** Promote `swap_plan/3` and `preview_upcoming_invoice/2` by updating the capability map, semantic SSOT, support matrix, thin mirrors, and verifier bundle in one same-PR contract bundle; do not spend Phase 117 budget inventing Braintree preview semantics or redesigning the full admin/portal flow. [VERIFIED: scripts/ci/README.md][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Official `swap_plan/3` contract | API / Backend | Database / Storage | The facade, option validation, processor branching, and typed failures live in `Accrue.Billing` and `SubscriptionActions`, while local subscription rows and events are updated transactionally after mutation. [VERIFIED: accrue/lib/accrue/billing.ex][VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex] |
| Official `preview_upcoming_invoice/2` contract | API / Backend | Frontend Server (SSR) | Preview generation is a backend processor call plus decomposition into `UpcomingInvoice`; UI surfaces should consume that backend truth rather than recalculate locally. [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex][VERIFIED: accrue/lib/accrue/billing/upcoming_invoice.ex] |
| Braintree bounded swap gating | API / Backend | Frontend Server (SSR) | Currency/billing-cycle/resolver checks belong at the facade boundary; LiveView should only expose affordances that match those backend limits. [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex][VERIFIED: accrue/lib/accrue/processor/braintree.ex][VERIFIED: accrue_admin/lib/accrue_admin/live/subscription_live.ex] |
| Provider-honest preview-first wording | Frontend Server (SSR) | API / Backend | Admin and later portal flows should present preview-first only where the backend actually supports preview; the backend remains the source of capability truth. [VERIFIED: accrue_admin/lib/accrue_admin/live/subscription_live.ex][VERIFIED: accrue_admin/lib/accrue_admin/copy/subscription.ex][VERIFIED: .planning/phases/117-contract-promotion-preview-truth/117-CONTEXT.md] |
| Contract drift prevention | API / Backend | CDN / Static | Capability labels originate in code and canonical markdown, while bash verifiers and mirror docs keep static contract copies from drifting. [VERIFIED: accrue/lib/accrue/processor/capabilities.ex][VERIFIED: .planning/processor-support-matrix.md][VERIFIED: scripts/ci/README.md] |

## Project Constraints (from CLAUDE.md)

- Use Elixir `~> 1.17`, OTP `27+`, Phoenix `1.8+`, Ecto `3.12+`, and PostgreSQL `14+`; Phase 117 should not recommend version backports or legacy compatibility work. [VERIFIED: CLAUDE.md]
- Keep `lattice_stripe`, `oban`, `swoosh`, `ecto_sql`, `postgrex`, `nimble_options`, `telemetry`, and `chromic_pdf`/PDF adapter patterns consistent with the repo stack; this phase should not introduce alternate billing-stack dependencies. [VERIFIED: CLAUDE.md]
- Webhook verification remains mandatory and sensitive Stripe fields must never be logged; any new preview/swap docs or tests should preserve the existing security posture. [VERIFIED: CLAUDE.md]
- All public entry points emit telemetry and the Fake lane remains deterministic and merge-blocking; provider-backed runs are fidelity checks, not the primary development loop. [VERIFIED: CLAUDE.md][VERIFIED: .planning/STRATEGY.md]
- `accrue/` and `accrue_admin/` are sibling mix projects in one monorepo with shared `.github/workflows/`, shared `guides/`, and per-package `mix.exs`; planning should expect cross-package doc and test updates. [VERIFIED: CLAUDE.md]

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `accrue` | `1.0.0` | Public billing facade and subscription-change runtime | The phase is explicitly about promoting existing facade truth, not replacing it. `swap_plan/3` and `preview_upcoming_invoice/2` already live here. [VERIFIED: accrue/mix.exs][VERIFIED: accrue/lib/accrue/billing.ex] |
| `phoenix_live_view` | `~> 1.1` | Admin/operator surface contract consumer | `accrue_admin` already renders subscription actions through LiveView and is the established seam for operator wording/gating. [VERIFIED: accrue_admin/mix.exs][VERIFIED: accrue_admin/lib/accrue_admin/live/subscription_live.ex] |
| `nimble_options` | `~> 1.1` | Swap option validation | `swap_plan/3` already depends on `NimbleOptions` to enforce explicit proration and typed option validation. [VERIFIED: accrue/mix.exs][VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex] |
| `lattice_stripe` | `~> 1.1` | Stripe-backed preview/commit fidelity lane | The live Stripe proof uses `LatticeStripe.Invoice.list/3` to compare preview and committed invoices, which matches the repo’s Stripe integration posture. [VERIFIED: accrue/mix.exs][VERIFIED: accrue/test/live_stripe/proration_fidelity_live_test.exs] |
| `braintree` | `~> 0.16` | Braintree bounded mutation adapter | The bounded swap path is already implemented on the official Braintree adapter and should be clarified, not re-platformed. [VERIFIED: accrue/mix.exs][VERIFIED: accrue/lib/accrue/processor/braintree.ex] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `ExUnit` | bundled with Elixir | Contract, docs, and LiveView proof harness | Use for focused facade, docs verifier, and admin regression tests during this phase. [VERIFIED: accrue/test/test_helper.exs][VERIFIED: accrue_admin/test/test_helper.exs] |
| Bash verifier scripts | repo-local | Merge-blocking support-contract drift gates | Use whenever matrix or mirror wording changes. The repo already treats these as the support-contract bundle. [VERIFIED: scripts/ci/README.md][VERIFIED: scripts/ci/verify_processor_support_matrix.sh][VERIFIED: scripts/ci/verify_package_docs.sh][VERIFIED: scripts/ci/verify_verify01_readme_contract.sh][VERIFIED: scripts/ci/verify_adoption_proof_matrix.sh] |
| `PlanResolver` behaviour seam | repo-local | Host-owned Braintree plan metadata translation | Use only for the bounded Braintree swap path; do not generalize it into a cross-provider abstraction in this phase. [VERIFIED: accrue/lib/accrue/plan_resolver.ex][VERIFIED: .planning/phases/117-contract-promotion-preview-truth/117-CONTEXT.md] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Canonical lifecycle guide + support matrix spine | A new dedicated “subscription change contract” guide | Reject it. The context explicitly locks a two-doc canonical spine and warns that a third canonical artifact would add drift burden. [VERIFIED: .planning/phases/117-contract-promotion-preview-truth/117-CONTEXT.md] |
| Explicit Braintree unsupported preview | A hand-rolled pseudo-preview/proration engine | Reject it. Braintree does not expose a Stripe-like upcoming-invoice preview contract, and Phase 117 is about provider-honest promotion, not synthetic parity. [CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/][VERIFIED: .planning/phases/117-contract-promotion-preview-truth/117-CONTEXT.md] |
| Intent-first facade verbs (`swap_plan/3`, `preview_upcoming_invoice/2`) | Provider-specific public verbs | Reject it. The context locks intent-first public API shape and only wants provider-specific truth in labels and docs. [VERIFIED: .planning/phases/117-contract-promotion-preview-truth/117-CONTEXT.md] |

**Installation:** No new packages are recommended for Phase 117; reuse the repo-pinned stack and spend the phase budget on contract truth, docs, and proof. [VERIFIED: accrue/mix.exs][VERIFIED: accrue_admin/mix.exs]

**Version verification:** N/A for new-package selection; this phase should use the versions already pinned in `accrue/mix.exs` and `accrue_admin/mix.exs`, not introduce dependency churn. [VERIFIED: accrue/mix.exs][VERIFIED: accrue_admin/mix.exs]

## Architecture Patterns

### System Architecture Diagram

```text
Host code / LiveView action
  -> Accrue.Billing.swap_plan/3 or preview_upcoming_invoice/2
    -> SubscriptionActions
      -> validate options (NimbleOptions / explicit guards)
      -> branch by processor
         -> Stripe/Fake preview path
            -> processor create_invoice_preview
            -> decompose UpcomingInvoice
            -> UI/docs describe preview-before-commit as canonical
         -> Stripe/Fake/Braintree swap path
            -> build processor update request
            -> Braintree: resolve target metadata via PlanResolver
            -> processor update_subscription
            -> decompose subscription projection
            -> update local subscription + items + event inside Repo.transact
  -> Canonical docs + mirror docs
    -> lifecycle_semantics.md owns semantics
    -> processor-support-matrix.md owns support boundaries
    -> README / First Hour / host README / adoption-proof-matrix mirror the same contract
  -> Shift-left proof
    -> ExUnit facade tests
    -> docs verifier scripts
    -> advisory live Stripe fidelity test
```

The planner should treat the runtime flow and the docs/verifier flow as one contract bundle. Shipping only one half leaves the repo in a contradictory state. [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex][VERIFIED: accrue/guides/lifecycle_semantics.md][VERIFIED: .planning/processor-support-matrix.md][VERIFIED: scripts/ci/README.md]

### Recommended Project Structure
```text
accrue/
├── lib/accrue/billing/                 # Facade and subscription-change runtime
├── lib/accrue/processor/               # Capability map and provider adapters
├── lib/accrue/plan_resolver.ex         # Braintree metadata seam
├── guides/                             # Semantic SSOT + package-facing mirrors
└── test/accrue/                        # Facade/docs regressions + advisory live Stripe lane

accrue_admin/
├── lib/accrue_admin/live/              # Operator flows that consume the contract
├── lib/accrue_admin/copy/              # Provider-honest operator wording
└── test/accrue_admin/live/             # LiveView contract regressions

.planning/
├── processor-support-matrix.md         # Capability/support SSOT
└── phases/117-contract-promotion-preview-truth/

scripts/ci/
└── verify_*                           # Support-contract bundle verifiers
```

### Pattern 1: Promote Existing Runtime Truth Before Adding UX Depth
**What:** Treat `swap_plan/3` and `preview_upcoming_invoice/2` as already-real APIs whose contract needs to be made explicit everywhere. [VERIFIED: accrue/lib/accrue/billing.ex][VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex]

**When to use:** Use this pattern when the code path exists, the tests exist, and the main risk is fragmented truth across docs, labels, and UI wording. [VERIFIED: accrue/test/accrue/billing/swap_plan_test.exs][VERIFIED: accrue/test/accrue/billing/upcoming_invoice_test.exs][VERIFIED: .planning/processor-support-matrix.md]

**Example:**
```elixir
# Source: /Users/jon/projects/accrue/accrue/lib/accrue/billing.ex
def swap_plan(sub, new_price_id, opts) do
  span_billing(:subscription, :swap_plan, sub, opts, fn ->
    SubscriptionActions.swap_plan(sub, new_price_id, opts)
  end)
end

def preview_upcoming_invoice(sub_or_customer, opts \\ []) do
  span_billing(:invoice, :preview_upcoming, sub_or_customer, opts, fn ->
    SubscriptionActions.preview_upcoming_invoice(sub_or_customer, opts)
  end)
end
```

### Pattern 2: Keep Braintree Support Bounded at the Facade Boundary
**What:** Resolve Braintree target metadata, validate same-currency and same-billing-cycle constraints, and reject unsupported semantics before the provider call. [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex][VERIFIED: accrue/lib/accrue/processor/braintree.ex]

**When to use:** Use this pattern whenever a shared public verb exists but only a narrower provider subset is supportable honestly. [VERIFIED: .planning/phases/117-contract-promotion-preview-truth/117-CONTEXT.md]

**Example:**
```elixir
# Source: /Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex
with {:ok, current_plan} <- resolve_braintree_plan(existing_item.price_id),
     {:ok, target_plan} <- resolve_braintree_plan(new_price_id),
     :ok <- ensure_braintree_plan_processor(target_plan),
     :ok <- ensure_braintree_swap_currency_match(current_plan, target_plan),
     :ok <- ensure_braintree_swap_billing_cycle_match(current_plan, target_plan) do
  {:ok,
   %{
     items: [%{id: existing_item.processor_id, price: new_price_id}],
     braintree_plan_ref: target_plan,
     proration_behavior: validated[:proration]
   }}
end
```

### Pattern 3: Use Canonical Docs + Thin Mirrors + Scripted Drift Gates
**What:** Put semantics in `lifecycle_semantics.md`, support boundaries in `processor-support-matrix.md`, keep mirrors thin, and update verifier needles in the same PR. [VERIFIED: accrue/guides/lifecycle_semantics.md][VERIFIED: .planning/processor-support-matrix.md][VERIFIED: scripts/ci/README.md]

**When to use:** Use this pattern whenever public contract wording changes touch package docs, example-host docs, or planning SSOT. [VERIFIED: scripts/ci/README.md]

### Anti-Patterns to Avoid

- **Shipping preview promotion without updating the matrix:** The matrix still labels `preview_upcoming_invoice/2` as `out of slice`, so docs-only promotion would create an immediate SSOT contradiction. [VERIFIED: .planning/processor-support-matrix.md]
- **Inventing Braintree preview parity:** Braintree exposes direct subscription updates, not Stripe-style preview semantics, so a synthetic preview would be parity theater. [CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/]
- **Leaking raw proration enums into end-user UX:** Admin currently exposes `Create prorations`, `No proration`, and `Always invoice` directly; the context explicitly says outcome-oriented copy should replace raw enum leakage. [VERIFIED: accrue_admin/lib/accrue_admin/live/subscription_live.ex][VERIFIED: accrue_admin/lib/accrue_admin/copy/subscription.ex][VERIFIED: .planning/phases/117-contract-promotion-preview-truth/117-CONTEXT.md]
- **Treating Fake fidelity as production exactness:** Fake proves flow shape and deterministic CI behavior, but the numerical preview-vs-commit truth lives in the advisory live Stripe test. [VERIFIED: accrue/test/accrue/billing/proration_roundtrip_test.exs][VERIFIED: accrue/test/live_stripe/proration_fidelity_live_test.exs]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Braintree pre-commit invoice preview | A custom proration calculator or fake invoice-preview engine | Explicit unsupported error plus host-owned estimate wording | Braintree’s documented update flow requires direct mutation inputs and does not give Accrue a canonical invoice-preview contract to mirror. [CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/][VERIFIED: accrue/lib/accrue/processor/braintree.ex] |
| Contract truth distribution | A third canonical “subscription change contract” doc | `lifecycle_semantics.md` + `.planning/processor-support-matrix.md` | The context explicitly locks this two-doc spine to reduce drift. [VERIFIED: .planning/phases/117-contract-promotion-preview-truth/117-CONTEXT.md] |
| Provider-specific API surface | New verbs like `swap_braintree_plan/3` or `preview_stripe_invoice/2` | Keep `swap_plan/3` and `preview_upcoming_invoice/2`, then label provider behavior honestly | Intent-first verbs are already the established DX and the context locks them. [VERIFIED: accrue/lib/accrue/billing.ex][VERIFIED: .planning/phases/117-contract-promotion-preview-truth/117-CONTEXT.md] |
| Ad hoc docs review | Manual spot-checking only | Existing `verify_processor_support_matrix.sh`, `verify_package_docs.sh`, `verify_verify01_readme_contract.sh`, and `verify_adoption_proof_matrix.sh` bundle | The repo already codifies support-contract drift prevention there, and Phase 117 should extend that bundle rather than bypass it. [VERIFIED: scripts/ci/README.md] |

**Key insight:** The expensive part of this phase is not processor code. It is keeping one truthful contract across runtime, docs, mirrors, and gates. The repo already has the right primitives; planning should spend effort on same-PR synchronization. [VERIFIED: scripts/ci/README.md][VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex]

## Common Pitfalls

### Pitfall 1: Promoting `swap_plan/3` while leaving capability labels coarse
**What goes wrong:** Host docs say plan swap is an official contract, but code and matrix labels still hide it under broad `subscription.update` or `out of slice` buckets. [VERIFIED: accrue/lib/accrue/processor/capabilities.ex][VERIFIED: .planning/processor-support-matrix.md]

**Why it happens:** The current support map predates the active-subscription-change milestone and still reflects the narrower `gateway subscription core` slice. [VERIFIED: .planning/processor-support-matrix.md][VERIFIED: .planning/ROADMAP.md]

**How to avoid:** Add explicit capability rows and support labels for `swap_plan` and preview instead of overloading generic mutation rows. [VERIFIED: .planning/phases/117-contract-promotion-preview-truth/117-CONTEXT.md]

**Warning signs:** `Capabilities.support_label/1` still returns only generic `subscription.update`, or the matrix still marks preview `out of slice`. [VERIFIED: accrue/lib/accrue/processor/capabilities.ex][VERIFIED: .planning/processor-support-matrix.md]

### Pitfall 2: Documenting preview-first globally instead of canonical-when-supported
**What goes wrong:** Docs or UI imply every processor follows preview-before-commit, which is false for Braintree. [VERIFIED: .planning/phases/117-contract-promotion-preview-truth/117-CONTEXT.md][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/]

**Why it happens:** Stripe’s preview surface is real and easy to generalize mentally, while Braintree’s bounded path uses direct mutation inputs only. [CITED: https://docs.stripe.com/api/invoices/create_preview][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/]

**How to avoid:** Phrase preview as canonical **where supported** and pair it with an explicit Braintree “preview unavailable” path. [VERIFIED: .planning/phases/117-contract-promotion-preview-truth/117-CONTEXT.md]

**Warning signs:** Braintree UI or docs mention preview, proration-date exactness, or “confirm after preview” without a provider qualifier. [VERIFIED: .planning/phases/117-contract-promotion-preview-truth/117-CONTEXT.md]

### Pitfall 3: Treating `:plan_resolver` as sufficient gating by itself
**What goes wrong:** UI or docs imply Braintree swap is available whenever `:plan_resolver` exists, even if the target plan cannot resolve, currency mismatches, or billing cycles differ. [VERIFIED: accrue_admin/lib/accrue_admin/live/subscription_live.ex][VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex]

**Why it happens:** The current admin gate checks `PlanResolver.configured?/0`, but runtime enforcement is stricter. [VERIFIED: accrue_admin/lib/accrue_admin/live/subscription_live.ex][VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex]

**How to avoid:** Plan Phase 117 so the contract wording names the full bounded conditions, and leave richer preflight UI gating to Phase 118. [VERIFIED: .planning/phases/117-contract-promotion-preview-truth/117-CONTEXT.md][ASSUMED]

**Warning signs:** Copy says “configure `:plan_resolver`” but omits current/target resolution, currency, billing-cycle, or single-item constraints. [VERIFIED: accrue_admin/lib/accrue_admin/copy/subscription.ex][VERIFIED: accrue/lib/accrue/plan_resolver.ex][VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex]

### Pitfall 4: Over-claiming Fake proof
**What goes wrong:** Tests or docs imply Fake proves numerical preview fidelity, when it only proves pipeline shape. [VERIFIED: accrue/test/accrue/billing/proration_roundtrip_test.exs]

**Why it happens:** Fake’s preview API returns typed previews, which can look more authoritative than they are. [VERIFIED: accrue/test/accrue/billing/upcoming_invoice_test.exs][VERIFIED: accrue/test/accrue/billing/proration_roundtrip_test.exs]

**How to avoid:** Keep Fake as merge-blocking shape proof and cite the advisory live Stripe lane for numerical fidelity. [VERIFIED: accrue/test/live_stripe/proration_fidelity_live_test.exs][VERIFIED: .planning/STRATEGY.md]

**Warning signs:** Package or host docs describe Fake preview as exact, production-like, or parity-complete. [VERIFIED: examples/accrue_host/docs/adoption-proof-matrix.md]

## Code Examples

Verified patterns from official sources and the local codebase:

### Stripe/Fake preview path stays separate from commit
```elixir
# Source: /Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex
def preview_upcoming_invoice(%Subscription{} = sub, opts) do
  sub = Repo.preload(sub, [:subscription_items, :customer])
  new_price_id = Keyword.get(opts, :new_price_id)
  proration = Keyword.get(opts, :proration, :create_prorations)

  items =
    case new_price_id do
      nil -> Enum.map(sub.subscription_items, fn si -> %{id: si.processor_id, price: si.price_id} end)
      pid -> [item | _] = sub.subscription_items; [%{id: item.processor_id, price: pid}]
    end

  stripe_params = %{
    customer: sub.customer.processor_id,
    subscription: sub.processor_id,
    subscription_details: %{items: items, proration_behavior: Atom.to_string(proration)}
  }

  with {:ok, preview} <- Processor.__impl__().create_invoice_preview(stripe_params, sanitize_opts(opts)),
       {:ok, upcoming} <- decompose_upcoming(preview, sub) do
    {:ok, upcoming}
  end
end
```

### Braintree bounded proration translation
```elixir
# Source: /Users/jon/projects/accrue/accrue/lib/accrue/processor/braintree.ex
defp translate_proration_behavior(:create_prorations), do: {:ok, %{prorate_charges: true}}
defp translate_proration_behavior(:none), do: {:ok, %{prorate_charges: false}}

defp translate_proration_behavior(:always_invoice) do
  {:error,
   %APIError{
     code: "processor_operation_unsupported",
     http_status: 422,
     message:
       "Braintree swap_plan/3 does not support proration: :always_invoice. Use :create_prorations or :none."
   }}
end
```

### Live Stripe fidelity proof should stay advisory
```elixir
# Source: /Users/jon/projects/accrue/accrue/test/live_stripe/proration_fidelity_live_test.exs
assert {:ok, %UpcomingInvoice{} = preview} =
         Billing.preview_upcoming_invoice(sub,
           new_price_id: pro_price,
           proration: :create_prorations
         )

assert {:ok, committed_sub} =
         Billing.swap_plan(sub, pro_price, proration: :create_prorations)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `swap_plan/3` and preview exist in code but are not framed as one official contract | Promote them as the official active-subscription-change bundle with provider-specific labels | `v1.37` opened on 2026-05-07. [VERIFIED: .planning/ROADMAP.md][VERIFIED: .planning/STATE.md] | Phase 117 should plan around alignment work, not new public API invention. [VERIFIED: accrue/lib/accrue/billing.ex] |
| Coarse support labels such as `all first-party` and `out of slice` dominate the matrix | Two-axis contract: official API at the top level, then provider-honest labels for native/bounded/unsupported/testing-only paths | Locked by Phase 117 context on 2026-05-07. [VERIFIED: .planning/phases/117-contract-promotion-preview-truth/117-CONTEXT.md] | Planner should update capability rows and verifiers together. [VERIFIED: scripts/ci/README.md] |
| Braintree plan swap was mainly “runtime truth + guide mention” | Braintree should stay a bounded first-party plan-swap path with no preview semantics | The bounded swap runtime landed before `v1.37`; the promotion decision is now explicit. [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex][VERIFIED: accrue/guides/braintree-local-portal.md][VERIFIED: .planning/phases/117-contract-promotion-preview-truth/117-CONTEXT.md] | Planner should avoid widening to quantity/item/schedule/pause scope in this phase. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: .planning/ROADMAP.md] |

**Deprecated/outdated:**

- Treating `preview_upcoming_invoice/2` as `out of slice` in the support matrix is outdated for `v1.37` planning, because SCM-02 and the Phase 117 context now promote preview truth as part of the official active-subscription-change contract. [VERIFIED: .planning/processor-support-matrix.md][VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: .planning/phases/117-contract-promotion-preview-truth/117-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Phase 117 should correct any immediately contradictory UI/copy, but the full preview-first admin/portal implementation still belongs mainly to Phase 118. [ASSUMED] | Summary / Common Pitfalls / Validation | Planner could either under-scope SCM-02 or accidentally pull Phase 118 UI work forward. |

## Open Questions (RESOLVED)

1. **How much UI adjustment belongs in Phase 117 versus Phase 118?**
   - Resolved direction: Phase 117 owns only the minimum admin/operator contradiction cleanup needed so touched surfaces stop implying unsupported Braintree preview or parity. Full preview-first admin and portal UX, richer affordances, and deeper customer flow work remain in Phase 118. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: .planning/ROADMAP.md][VERIFIED: .planning/phases/117-contract-promotion-preview-truth/117-CONTEXT.md]
   - Planning consequence: Phase 117 may edit existing admin copy or gating where the new contract would otherwise be contradicted, but it must not add new routes, redesign the full flow, or absorb the broader UI scope already assigned to Phase 118. [RESOLVED]

2. **Where should thin API docs live for the promoted contract?**
   - Resolved direction: Use short function-level `@doc` updates on the public `Accrue.Billing` entry points and point those docs back to `accrue/guides/lifecycle_semantics.md` and `.planning/processor-support-matrix.md` for semantics and support boundaries. Do not create large provider tables or a new standalone ExDoc guide for this phase. [VERIFIED: .planning/phases/117-contract-promotion-preview-truth/117-CONTEXT.md]
   - Planning consequence: runtime/API-plan tasks should treat public function docs as thin contract signposts, while the lifecycle guide and support matrix remain the canonical source of detailed provider behavior. [RESOLVED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | `accrue` and `accrue_admin` tests | ✓ | `1.19.5` | — [VERIFIED: local shell `elixir --version`] |
| Erlang/OTP | Elixir runtime | ✓ | `28` | — [VERIFIED: local shell `elixir --version`] |
| PostgreSQL | ExUnit repos for both packages | ✓ | `14.17`; local server accepting on `localhost:5432` | — [VERIFIED: accrue/config/test.exs][VERIFIED: accrue_admin/config/test.exs][VERIFIED: local shell `psql --version`][VERIFIED: local shell `pg_isready`] |
| Node.js | Example-host/browser lanes and admin assets | ✓ | `22.14.0` | — [VERIFIED: local shell `node --version`] |
| npm | Browser lanes and admin assets | ✓ | `11.1.0` | — [VERIFIED: local shell `npm --version`] |
| Bash | Shift-left verifier scripts | ✓ | `5.2.37` | — [VERIFIED: local shell `bash --version`] |
| GitHub CLI (`gh`) | Optional `watch_ci.sh` helper only | ✓ | `2.89.0` | Skip `watch_ci.sh`; run local scripts directly. [VERIFIED: local shell `gh --version`][VERIFIED: scripts/ci/README.md] |

**Missing dependencies with no fallback:** None found for Phase 117’s code/docs/test work. [VERIFIED: local environment probes]

**Missing dependencies with fallback:** None. [VERIFIED: local environment probes]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit across both mix projects. [VERIFIED: accrue/test/test_helper.exs][VERIFIED: accrue_admin/test/test_helper.exs] |
| Config file | `accrue/test/test_helper.exs`, `accrue_admin/test/test_helper.exs`. [VERIFIED: accrue/test/test_helper.exs][VERIFIED: accrue_admin/test/test_helper.exs] |
| Quick run command | `cd accrue && mix test test/accrue/billing/swap_plan_test.exs test/accrue/billing/upcoming_invoice_test.exs test/accrue/billing/proration_roundtrip_test.exs test/accrue/processor/capabilities_test.exs test/accrue/docs/processor_support_matrix_test.exs --warnings-as-errors` [VERIFIED: test file paths][VERIFIED: accrue/mix.exs] |
| Full suite command | `cd accrue && mix test.all && cd ../accrue_admin && mix test --warnings-as-errors` [VERIFIED: accrue/mix.exs][VERIFIED: accrue_admin/mix.exs] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SCM-01 | `swap_plan/3` is an official active-subscription-change contract with bounded Braintree rules and explicit capability labeling. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex] | unit + docs-contract | `cd accrue && mix test test/accrue/billing/swap_plan_test.exs test/accrue/processor/capabilities_test.exs test/accrue/docs/processor_support_matrix_test.exs --warnings-as-errors` | ✅ [VERIFIED: file paths] |
| SCM-02 | `preview_upcoming_invoice/2` is the canonical preview-before-commit path where supported, with Fake shape proof and Stripe fidelity evidence. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex] | unit + advisory live | `cd accrue && mix test test/accrue/billing/upcoming_invoice_test.exs test/accrue/billing/proration_roundtrip_test.exs --warnings-as-errors` and advisory `cd accrue && STRIPE_TEST_SECRET_KEY=... ACCRUE_LIVE_BASIC_PRICE=... ACCRUE_LIVE_PRO_PRICE=... mix test test/live_stripe/proration_fidelity_live_test.exs --only live_stripe --warnings-as-errors` | ✅ [VERIFIED: file paths][VERIFIED: accrue/test/live_stripe/proration_fidelity_live_test.exs] |

### Sampling Rate

- **Per task commit:** Run the focused `accrue` facade/docs contract slice plus any touched verifier script directly from repo root. [VERIFIED: scripts/ci/README.md]
- **Per wave merge:** Run the support-contract bundle from repo root: `bash scripts/ci/verify_processor_support_matrix.sh && bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_verify01_readme_contract.sh && bash scripts/ci/verify_adoption_proof_matrix.sh`. [VERIFIED: scripts/ci/README.md]
- **Phase gate:** Run the focused `accrue` suite, the support-contract bundle, and any touched `accrue_admin` LiveView regression file before `/gsd-verify-work`. [VERIFIED: scripts/ci/README.md][VERIFIED: accrue_admin/test/accrue_admin/live/subscription_live_test.exs]

### Wave 0 Gaps

- [ ] Update `scripts/ci/verify_processor_support_matrix.sh` for the new explicit `swap_plan` / preview rows once the matrix changes. The current script has no needles for either API. [VERIFIED: scripts/ci/verify_processor_support_matrix.sh]
- [ ] Extend package/host mirror verifier needles if new contract wording lands in `accrue/README.md`, `accrue/guides/first_hour.md`, `examples/accrue_host/README.md`, or `examples/accrue_host/docs/adoption-proof-matrix.md`. [VERIFIED: scripts/ci/verify_package_docs.sh][VERIFIED: scripts/ci/verify_verify01_readme_contract.sh][VERIFIED: scripts/ci/verify_adoption_proof_matrix.sh]
- [ ] Add or update a focused admin regression if Phase 117 changes any subscription action copy or gating, because the current admin test file does not cover preview-first swap UX. [VERIFIED: accrue_admin/test/accrue_admin/live/subscription_live_test.exs][ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 117 does not introduce new end-user authentication flows. Existing auth adapters remain unchanged. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: accrue_admin/test/accrue_admin/live/subscription_live_test.exs] |
| V3 Session Management | no | No new session protocol is in scope; any admin flow changes still sit behind existing LiveView session/auth setup. [VERIFIED: accrue_admin/test/test_helper.exs] |
| V4 Access Control | yes | If admin copy or affordances change, keep them behind existing `Accrue.Auth` + `StepUp` guarded admin actions. [VERIFIED: accrue_admin/lib/accrue_admin/live/subscription_live.ex][VERIFIED: accrue_admin/test/accrue_admin/live/subscription_live_test.exs] |
| V5 Input Validation | yes | `NimbleOptions`, explicit `ArgumentError`, typed `APIError`, and `PlanResolver` schema checks are the standard controls for swap/preview inputs. [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex][VERIFIED: accrue/lib/accrue/plan_resolver.ex] |
| V6 Cryptography | no | This phase does not add cryptographic operations. Existing webhook-signature controls remain unchanged. [VERIFIED: CLAUDE.md] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unsupported provider semantics presented as supported | Tampering | Fail early with typed unsupported errors at the facade boundary and keep docs/mirrors aligned via verifier scripts. [VERIFIED: accrue/lib/accrue/processor/braintree.ex][VERIFIED: scripts/ci/README.md] |
| Admin action misuse from misleading copy | Elevation of privilege | Keep operator actions behind existing step-up checks and avoid exposing unsupported Braintree affordances. [VERIFIED: accrue_admin/lib/accrue_admin/live/subscription_live.ex][VERIFIED: .planning/phases/117-contract-promotion-preview-truth/117-CONTEXT.md] |
| Host assumes Fake preview equals production invoice exactness | Repudiation | Document Fake as deterministic local proof only and point to advisory live Stripe fidelity for exactness. [VERIFIED: accrue/test/accrue/billing/proration_roundtrip_test.exs][VERIFIED: accrue/test/live_stripe/proration_fidelity_live_test.exs] |

## Sources

### Primary (HIGH confidence)
- `accrue/lib/accrue/billing.ex` - public facade delegates for `swap_plan/3` and `preview_upcoming_invoice/2`. [VERIFIED: accrue/lib/accrue/billing.ex]
- `accrue/lib/accrue/billing/subscription_actions.ex` - swap, preview, Braintree gating, option validation, and projection flow. [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex]
- `accrue/lib/accrue/processor/capabilities.ex` - current support-label model and current drift point. [VERIFIED: accrue/lib/accrue/processor/capabilities.ex]
- `accrue/lib/accrue/processor/braintree.ex` - bounded Braintree update translation and unsupported-preview truth. [VERIFIED: accrue/lib/accrue/processor/braintree.ex]
- `accrue/lib/accrue/plan_resolver.ex` - required metadata contract for Braintree plan swap. [VERIFIED: accrue/lib/accrue/plan_resolver.ex]
- `accrue/guides/lifecycle_semantics.md` - current lifecycle semantic SSOT. [VERIFIED: accrue/guides/lifecycle_semantics.md]
- `.planning/processor-support-matrix.md` - current support SSOT and current preview drift. [VERIFIED: .planning/processor-support-matrix.md]
- `scripts/ci/README.md` and `scripts/ci/verify_*.sh` - support-contract bundle and current verifier coverage. [VERIFIED: scripts/ci/README.md][VERIFIED: scripts/ci/verify_processor_support_matrix.sh][VERIFIED: scripts/ci/verify_package_docs.sh][VERIFIED: scripts/ci/verify_verify01_readme_contract.sh][VERIFIED: scripts/ci/verify_adoption_proof_matrix.sh]
- `accrue/test/accrue/billing/*.exs`, `accrue/test/live_stripe/proration_fidelity_live_test.exs`, and `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` - current proof lanes. [VERIFIED: accrue/test/accrue/billing/swap_plan_test.exs][VERIFIED: accrue/test/accrue/billing/upcoming_invoice_test.exs][VERIFIED: accrue/test/accrue/billing/proration_roundtrip_test.exs][VERIFIED: accrue/test/live_stripe/proration_fidelity_live_test.exs][VERIFIED: accrue_admin/test/accrue_admin/live/subscription_live_test.exs]
- `accrue/mix.exs` and `accrue_admin/mix.exs` - repo-pinned stack versions. [VERIFIED: accrue/mix.exs][VERIFIED: accrue_admin/mix.exs]

### Secondary (MEDIUM confidence)
- Stripe API docs: `create_preview` invoice preview endpoint and proration guidance. [CITED: https://docs.stripe.com/api/invoices/create_preview][CITED: https://docs.stripe.com/billing/subscriptions/prorations?locale=en-GB]
- Braintree subscription update docs: explicit `price`, same-billing-cycle restriction, and direct update posture. [CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/]

### Tertiary (LOW confidence)
- None. Every material recommendation in this research is backed by the codebase, official docs, or both.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Phase 117 should reuse the repo-pinned stack and existing proof harness; no dependency-selection uncertainty remains. [VERIFIED: accrue/mix.exs][VERIFIED: accrue_admin/mix.exs]
- Architecture: MEDIUM - The runtime and docs seams are clear, but there is still some planning ambiguity around how much UI correction Phase 117 should absorb versus defer to Phase 118. [VERIFIED: .planning/ROADMAP.md][ASSUMED]
- Pitfalls: HIGH - The biggest failure modes are already visible in current repo drift: preview marked `out of slice`, coarse capability labels, and raw admin proration UI. [VERIFIED: .planning/processor-support-matrix.md][VERIFIED: accrue_admin/lib/accrue_admin/live/subscription_live.ex]

**Research date:** 2026-05-07
**Valid until:** 2026-06-06
