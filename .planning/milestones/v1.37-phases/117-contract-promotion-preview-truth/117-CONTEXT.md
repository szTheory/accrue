# Phase 117: Contract Promotion + Preview Truth - Context

**Gathered:** 2026-05-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Promote Accrue's active subscription-change bundle from scattered runtime and guide behavior into one explicit first-party support contract centered on `swap_plan/3` and `preview_upcoming_invoice/2`.

This phase clarifies and hardens the public contract that already exists in code. It does not widen scope into broader lifecycle expansion, fake Braintree parity, quantity/item-management promotion, schedule management, or new seat-domain abstractions.

</domain>

<decisions>
## Implementation Decisions

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

### the agent's Discretion
- Exact wording of the new provider labels, as long as the two-axis contract remains explicit and provider-honest.
- Exact capability-row naming in the support matrix and code, as long as `swap_plan` and preview stop being hidden under coarse generic buckets.
- Exact UI layout for preview-first flows, as long as Stripe/Fake become preview-led and Braintree stays explicit/direct.
- Exact CI/verifier needle placement, as long as the support-contract bundle keeps all touched mirrors aligned.

</decisions>

<specifics>
## Specific Ideas

- Recommended top-line contract wording:
  - “`swap_plan/3` and `preview_upcoming_invoice/2` are Accrue’s official active-subscription-change APIs. Provider behavior stays honest: Stripe supports preview-before-commit natively, Fake proves the flow shape locally, and Braintree supports only a bounded first-party plan-swap path with no first-party preview.”
- Recommended Braintree wording:
  - “Braintree plan swaps require `:plan_resolver`, matching currency, matching billing cycle, and a single-item subscription. Preview and quantity/item changes remain unsupported through Accrue.”
- Recommended preview wording:
  - “Preview is the canonical path where supported. Stripe and Fake can preview before commit; Braintree cannot.”
- Recommended UI posture:
  - Stripe/Fake: `Preview change` then `Confirm change`
  - Braintree: direct `Change plan` with explicit provider note and no preview CTA
- Recommended maintainer posture:
  - no new canonical doc
  - lifecycle guide owns meaning
  - processor matrix owns support truth
  - every other surface mirrors with links, not duplicate tables
- User preference captured explicitly:
  - one-shot, deeply researched, cohesive recommendations by default
  - shift low-impact discuss/planning choices left into synthesis
  - escalate only materially impactful boundary changes

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and contract truth
- `.planning/ROADMAP.md` — Phase 117 goal, boundary, and success criteria
- `.planning/REQUIREMENTS.md` — `SCM-01` and `SCM-02`
- `.planning/STATE.md` — active milestone position and sequencing
- `.planning/PROJECT.md` — milestone framing and strategic intent
- `.planning/STRATEGY.md` — bounded dual-provider philosophy and non-targets

### Canonical docs spine
- `.planning/processor-support-matrix.md` — capability/support SSOT that must be updated to reflect the active subscription-change contract
- `accrue/guides/lifecycle_semantics.md` — semantic SSOT for action meaning, provider labels, and preview/proration guidance

### Runtime contract seams
- `accrue/lib/accrue/billing.ex` — public billing facade
- `accrue/lib/accrue/billing/subscription_actions.ex` — `swap_plan/3`, preview, and current option/runtime behavior
- `accrue/lib/accrue/processor/capabilities.ex` — current support-label map that needs finer-grained contract rows
- `accrue/lib/accrue/processor/braintree.ex` — bounded Braintree truth, preview unsupported, proration subset
- `accrue/lib/accrue/plan_resolver.ex` — Braintree plan-resolution seam

### Public mirrors and onboarding surfaces
- `accrue/README.md` — package-facing summary mirror
- `accrue/guides/first_hour.md` — first-user onboarding mirror
- `accrue/guides/braintree-local-portal.md` — mounted Braintree path and provider-honest setup guidance
- `examples/accrue_host/README.md` — thin host proof mirror
- `examples/accrue_host/docs/adoption-proof-matrix.md` — thin proof taxonomy mirror

### Admin and UI surfaces
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` — current swap/proration flow and gating
- `accrue_admin/lib/accrue_admin/copy/subscription.ex` — current operator-facing wording and Braintree guidance

### Proof anchors
- `accrue/test/accrue/billing/proration_roundtrip_test.exs` — Fake proof shape for preview/swap/preview continuity
- `accrue/test/live_stripe/proration_fidelity_live_test.exs` — live Stripe preview-vs-commit fidelity proof
- `accrue/test/accrue/billing/upcoming_invoice_test.exs` — baseline preview contract proof
- `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` — current admin-copy/gating proof

### Drift-gate and contributor rules
- `scripts/ci/README.md` — support-contract bundle and same-PR co-update rules for docs/mirrors

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `swap_plan/3` already exists as a public intent-first facade and has bounded Braintree support.
- `preview_upcoming_invoice/2` already exists as a public facade and already embodies the separate preview-before-commit shape Accrue should promote.
- `PlanResolver` already provides the host-owned seam needed for app-facing Braintree plan translation.
- Existing Fake and live Stripe tests already provide the right proof-story split for preview behavior.
- `accrue_admin` already has subscription action UI and copy seams that can be tightened instead of rebuilt.

### Established Patterns
- Fake remains the deterministic local and merge-blocking proof lane.
- Provider-backed lanes are fidelity proof, not the primary dev loop.
- Accrue already prefers explicit unsupported errors over silent parity theater.
- The repo already uses package docs + host docs + matrix + CI verifiers as a co-updated contract bundle.
- Intent-first context functions with typed errors are the established library DX style.

### Integration Points
- Phase 117 needs runtime contract truth, support-matrix truth, lifecycle-doc truth, onboarding truth, admin copy, and CI contract needles to move together.
- The processor capability map must stop hiding `swap_plan` and preview semantics behind coarse generic rows.
- Admin/UI changes in later phases should consume the contract decisions from this file instead of reopening provider-boundary debates.

</code_context>

<deferred>
## Deferred Ideas

- Broad quantity/item-management promotion across all providers
- First-party Braintree preview or pseudo-preview implementation
- New seat-domain abstractions
- Pause/resume/schedule-management expansion
- Provider-specific public facade verbs for subscription changes
- A new standalone canonical subscription-change design doc

</deferred>

---

*Phase: 117-contract-promotion-preview-truth*
*Context gathered: 2026-05-07*
