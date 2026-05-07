# Phase 118: Admin + Portal Change Flows - Context

**Gathered:** 2026-05-07
**Status:** Ready for planning
**Source:** Synthesized from active roadmap, requirements, current repo code, and adjacent phase artifacts

<domain>
## Phase Boundary

Expose Accrue's supported active-subscription-change bundle coherently across the
public billing facade, admin/operator flows, and customer self-serve portal
surfaces.

This phase builds on the already-promoted `swap_plan/3` and
`preview_upcoming_invoice/2` contract by extending the official
active-subscription-change story to quantity and subscription-item mutations
where processor truth supports them, then reflecting that contract in touched
admin and portal flows.

This phase does not widen Accrue into pause/unpause, resume, schedule
management, coupon/promotion workflows, or a faux-uniform Braintree parity
layer.

</domain>

<decisions>
## Implementation Decisions

### Official active-subscription-change boundary
- **D-01:** Phase 118 should promote only the active-subscription-change APIs
  that current runtime truth can defend:
  - `Accrue.Billing.swap_plan/3`
  - `Accrue.Billing.preview_upcoming_invoice/2`
  - `Accrue.Billing.update_quantity/3`
  - `Accrue.Billing.add_item/3`
  - `Accrue.Billing.remove_item/2`
  - `Accrue.Billing.update_item_quantity/3`
- **D-02:** Stripe and Fake are the official providers for quantity and
  subscription-item mutation semantics in this phase.
- **D-03:** Braintree remains bounded to plan-swap support through
  `swap_plan/3` when the host configures `:plan_resolver`; it does **not**
  gain first-party quantity, item, or preview parity in this phase.
- **D-04:** Unsupported Braintree quantity, item, and preview branches must
  fail clearly and surface one concrete next step rather than implying missing
  setup or future parity.
- **D-05:** The support contract must stay explicit at the facade boundary
  rather than forcing callers to infer supported change operations from lower
  level processor adapters or generic `subscription.update` capability labels.

### Preview-before-commit posture
- **D-06:** Preview-before-commit remains the default posture for plan-change
  flows wherever preview is supported.
- **D-07:** Admin and portal flows should present preview state before commit
  when the touched flow performs a plan swap or other invoice-affecting change
  on Stripe/Fake.
- **D-08:** Braintree flows must not imply preview support. They should explain
  that the provider contract is bounded to direct commit for supported plan
  swaps and explicit unsupported errors elsewhere.
- **D-09:** Preview UX should stay provider-honest and bounded. It is not a
  full invoice workspace or a generic "what if anything changes" simulator.

### Admin/operator surface scope
- **D-10:** Admin is the primary touched UI surface for operator-managed
  quantity and subscription-item mutations in this phase.
- **D-11:** Admin should expose supported subscription-change actions,
  preview state, and provider/setup gates in one coherent flow rather than a
  scattered set of unguided forms.
- **D-12:** Existing lifecycle and cancellation guidance in admin must remain
  explicit and provider-honest; this phase adds change-flow depth without
  reopening pause/resume scope.
- **D-13:** Admin must distinguish:
  - supported Stripe/Fake quantity/item change paths
  - bounded Braintree swap-only path
  - unsupported branches with actionable guidance
- **D-14:** If Braintree `:plan_resolver` is missing, admin should present
  actionable setup guidance instead of a generic failed mutation path.

### Portal/self-serve surface scope
- **D-15:** Portal work in this phase is limited to bounded, Accrue-owned
  self-serve plan-change flows with provider-honest wording.
- **D-16:** Portal should expose supported plan-change preview + commit flows
  without implying pause/resume, schedule management, or broad item-management
  self-serve semantics.
- **D-17:** Customer-facing wording should stay least-surprise and explicit:
  what changes now, what changes at renewal, and whether preview is available.
- **D-18:** Portal flows must not teach raw processor jargon or ask end users
  to reason about unsupported Braintree parity. Unsupported branches should
  point to host-owned or operator-driven next steps.
- **D-19:** The mounted/local portal path remains a first-party Accrue surface;
  any wording added here must still avoid pretending it is identical to Stripe's
  upstream hosted portal.

### Host-owned seams
- **D-20:** Host apps should continue owning plan catalog presentation,
  authorization, and any softer Braintree product policy above Accrue's bounded
  processor contract.
- **D-21:** If portal or example-host flows need a thin helper for previewing or
  committing supported changes, that helper should live in the host billing
  facade rather than teaching UI code to reach directly into Accrue schemas.
- **D-22:** Host seams must remain provider-neutral wherever the shared contract
  is provider-neutral, and explicitly bounded where Braintree remains special.

### Proof shape
- **D-23:** Fake remains the deterministic merge-blocking proof lane for the
  promoted active-subscription-change bundle.
- **D-24:** Core library proof must pin the promoted quantity/item APIs and the
  typed unsupported Braintree branches.
- **D-25:** Admin and portal tests should prove the touched UX contracts:
  preview wording, supported actions, setup gates, and unsupported-branch copy.
- **D-26:** Example-host or installer-template proof should stay thin and
  adoption-facing rather than becoming a second implementation of billing
  semantics.

### Ecosystem and strategy lessons to preserve
- **D-27:** Keep the bounded multi-provider lesson from prior phases: explicit
  first-party slices are better than implied parity.
- **D-28:** Keep the lifecycle wording posture from Phase 110: avoid schedule,
  resume, or "reactivation" implications when the current change flow does not
  promise those semantics.
- **D-29:** Keep the support-contract co-update discipline from Phases 109, 112,
  and 113: runtime truth, support matrix, touched docs, and touched UI must
  move together.

### the agent's Discretion
- Exact UI composition for preview panels, staged actions, and confirmation
  layout, as long as provider-honest guidance remains explicit.
- Exact support-label taxonomy for quantity/item rows, as long as the public
  contract becomes clearer rather than more generic.
- Exact host helper names for bounded preview/commit seams, as long as they stay
  thin, explicit, and adjacent to the existing host billing facade patterns.

</decisions>

<specifics>
## Specific Ideas

- Recommended plan shape:
  - Plan 01: promote official quantity/item support truth and core proof
  - Plan 02: deepen admin subscription change flows with preview and gates
  - Plan 03: add bounded portal self-serve change flow plus thin host seams and proof
- Recommended provider story:
  - Stripe/Fake: plan swap + preview + quantity/item changes
  - Braintree: plan swap only, and only with `:plan_resolver`; no preview,
    quantity, or subscription-item parity
- Recommended customer-facing posture:
  - preview before commit where supported
  - explicit provider-honest wording
  - no pause/resume or schedule implication creep

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and active contract truth
- `.planning/ROADMAP.md` — Phase 118 goal and success criteria
- `.planning/REQUIREMENTS.md` — `SCM-03`, `SCM-04`, `SCM-05`
- `.planning/PROJECT.md` — bounded product posture
- `.planning/STATE.md` — active milestone position
- `.planning/processor-support-matrix.md` — current active-subscription-change
  support SSOT and current out-of-slice quantity/item wording

### Prior locked context that still applies
- `.planning/milestones/v1.35-phases/110-lifecycle-semantics-self-serve-clarity/110-CONTEXT.md` — provider-honest lifecycle wording posture for touched UI
- `.planning/milestones/v1.36-phases/112-customer-update-contract-closure/112-CONTEXT.md` — support-contract closure discipline, Fake-first proof, and host-helper posture
- `.planning/milestones/v1.36-phases/113-cancellation-semantics-closure/113-CONTEXT.md` — provider-honest unsupported guidance across admin/portal surfaces

### Runtime change-flow seams
- `accrue/lib/accrue/billing.ex` — public active-subscription-change facade
- `accrue/lib/accrue/billing/subscription_actions.ex` — swap, preview, and
  quantity semantics
- `accrue/lib/accrue/billing/subscription_items.ex` — add/remove/update item
  semantics
- `accrue/lib/accrue/processor/capabilities.ex` — runtime support-label map
- `accrue/lib/accrue/processor/braintree.ex` — explicit unsupported quantity and
  item semantics
- `accrue/lib/accrue/processor/fake.ex` — deterministic proof lane
- `accrue/lib/accrue/processor/stripe.ex` — native plan/preview support path

### Touched admin and portal seams
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` — current operator
  actions surface
- `accrue_admin/lib/accrue_admin/copy/subscription.ex` — current operator copy
- `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` — existing
  operator proof anchor
- `accrue_portal/lib/accrue_portal/live/subscription_live.ex` — current portal
  detail surface
- `accrue_portal/lib/accrue_portal/live/subscriptions_live.ex` — current portal
  list surface
- `accrue_portal/lib/accrue_portal/copy.ex` — customer-facing copy seam
- `accrue_portal/test/accrue_portal/live/subscription_live_test.exs` — portal
  detail proof anchor
- `accrue_portal/test/accrue_portal/live/subscriptions_live_test.exs` — portal
  list proof anchor

### Host and install seams
- `examples/accrue_host/lib/accrue_host/billing.ex` — host-owned billing facade
- `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` —
  example-host billing surface
- `examples/accrue_host/test/accrue_host/billing_facade_test.exs` — host helper
  proof anchor
- `examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs` —
  example-host UI proof anchor
- `accrue/priv/accrue/templates/install/billing.ex.eex` — generated host facade
  template

### Core proof anchors
- `accrue/test/accrue/processor/capabilities_test.exs` — support-label proof
- `accrue/test/accrue/billing/subscription_actions_test.exs` — swap and
  Braintree bounded semantics
- `accrue/test/accrue/billing/subscription_items_test.exs` — quantity/item proof
- `accrue/test/accrue/billing/upcoming_invoice_test.exs` — preview proof
- `accrue/test/accrue/billing/proration_roundtrip_test.exs` — preview/commit
  coherence proof

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Accrue.Billing` already exposes the full mutation bundle needed for this
  phase; most of the gap is support promotion and UI reflection, not raw new
  runtime invention.
- `AccrueAdmin.Live.SubscriptionLive` already has an action-staging pattern and
  provider-aware guidance seam that can absorb more supported change actions.
- `AccruePortal.Copy` already centralizes lifecycle-safe wording and can absorb
  bounded plan-change copy without scattering strings through LiveViews.
- `AccrueHost.Billing` and the installer template already provide the thin
  host-facade seam for exposing additional preview/commit helpers cleanly.

### Established Patterns
- Support truth is maintained by co-updating runtime labels, the processor
  support matrix, package docs, and tests.
- Fake is the merge-blocking semantic SSOT, while provider-backed checks stay
  bounded and explicit.
- Touched portal and admin flows prefer shared copy helpers and explicit
  provider-aware guidance over generic "semantics vary" wording.
- Host apps own billable resolution and product policy, while Accrue owns the
  bounded processor contract.

### Integration Points
- Quantity/item promotion must align:
  - runtime support labels
  - `.planning/processor-support-matrix.md`
  - `accrue/README.md` and any touched guides
  - core tests
  - touched admin/portal/example-host flows
- Preview and plan-change UX must respect the current provider split:
  - Stripe/Fake preview supported
  - Braintree preview unsupported
  - Braintree swap depends on `:plan_resolver`

</code_context>

<deferred>
## Deferred Ideas

- Pause/unpause, resume, and schedule-management promotion
- Broad customer self-serve quantity/item management if it requires a larger
  product model than this bounded phase
- Coupon, promotion code, or payment-method expansion
- Any attempt to fabricate Braintree preview parity or subscription-item parity

</deferred>

---

*Phase: 118-admin-portal-change-flows*
*Context gathered: 2026-05-07*
