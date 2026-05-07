# Phase 119: Braintree Bounded Plan-Swap Closeout - Context

**Gathered:** 2026-05-07
**Status:** Ready for planning
**Source:** Synthesized from active roadmap, requirements, current repo code, and completed Phase 118 artifacts

<domain>
## Phase Boundary

Finish `v1.37` by hardening the bounded Braintree plan-swap story and locking
every public mirror back to the same provider-honest subscription-change
contract.

This phase is a closeout pass, not another broad subscription-change feature
expansion. Stripe and Fake keep the richer active-subscription-change bundle
that Phase 118 promoted. Braintree stays intentionally narrower: first-party
plan swap only through `Accrue.Billing.swap_plan/3` when the host configures
`:plan_resolver`, with no first-party preview, quantity, or subscription-item
parity.

This phase does not reopen pause/resume, schedules, broader self-serve item
management, release automation, or new processor breadth.

</domain>

<decisions>
## Implementation Decisions

### Braintree support boundary
- **D-01:** Braintree's active-subscription-change story remains bounded to
  `Accrue.Billing.swap_plan/3` only.
- **D-02:** That bounded Braintree swap path is official only when the host
  configures `:plan_resolver` to translate app-facing `price_id`s into
  Braintree plan metadata.
- **D-03:** `preview_upcoming_invoice/2`, `update_quantity/3`, `add_item/3`,
  `remove_item/2`, and `update_item_quantity/3` remain explicitly unsupported
  on Braintree and should never be described as "coming soon", "temporarily
  unavailable", or implied parity.
- **D-04:** Unsupported Braintree quantity/item/preview branches must fail
  clearly in runtime, docs, and touched UI copy, with one actionable next step:
  keep the policy host-owned, configure `:plan_resolver` for bounded swap, or
  use a provider that supports the richer official lane.

### Public mirror discipline
- **D-05:** `.planning/processor-support-matrix.md` remains the canonical SSOT
  for the provider contract.
- **D-06:** Package-facing docs, lifecycle guidance, First Hour,
  production-readiness guidance, and example-host proof docs should mirror the
  support matrix thinly rather than each restating a different Braintree story.
- **D-07:** Touched docs should point readers back to the same support contract:
  shared facade, provider-honest behavior, bounded Braintree swap-only support,
  and explicit unsupported preview/quantity/item semantics.

### Touched UI posture
- **D-08:** Admin/operator wording may expose bounded Braintree swap support,
  but only through explicit `:plan_resolver` setup guidance and without
  presenting quantity/item actions as latent capabilities.
- **D-09:** Portal/customer wording should remain conservative: Braintree plan
  changes stay host-managed unless the product deliberately surfaces the bounded
  swap path elsewhere. This phase is hardening copy and guidance, not adding a
  second self-serve Braintree semantics layer.
- **D-10:** Shared copy seams stay authoritative for touched UI wording:
  `accrue_admin/lib/accrue_admin/copy/subscription.ex` and
  `accrue_portal/lib/accrue_portal/copy.ex`.

### Proof and drift gates
- **D-11:** Existing runtime and UI tests should pin the bounded Braintree
  story more explicitly where current wording or setup guidance is still loose.
- **D-12:** The support-contract verifier bundle must catch drift across:
  - `.planning/processor-support-matrix.md`
  - package-facing docs
  - host README
  - adoption-proof matrix
- **D-13:** Verifier wording should block both kinds of regressions:
  - Braintree parity creep
  - accidental erasure of the `:plan_resolver` setup contract

### Prior phase lessons to preserve
- **D-14:** Keep the Phase 117 and 118 rule that official support is a named,
  explicit bundle rather than a vague "subscription updates vary by provider"
  story.
- **D-15:** Keep the Phase 110 lifecycle wording discipline: no pause/resume,
  schedule, or reversible-cancel implications when Braintree does not support
  those semantics.
- **D-16:** Keep the support-contract co-update habit from Phases 109, 112,
  114, 117, and 118: runtime truth, public docs, example-host guidance, and
  merge-blocking verifier needles move together.

### the agent's Discretion
- Exact split between runtime-copy hardening and docs-only hardening, as long as
  the bounded Braintree story gets stricter rather than broader.
- Exact set of touched guides, as long as First Hour, lifecycle semantics,
  production-readiness, and example-host mirrors stop teaching overlapping but
  slightly different stories.
- Exact verifier needles and helper phrasing, as long as they preserve one clear
  provider-honest contract and fail loudly on drift.

</decisions>

<specifics>
## Specific Ideas

- Recommended plan shape:
  - Plan 01: harden runtime/touched-surface Braintree swap-only truth and proof
  - Plan 02: align support matrix, package docs, lifecycle docs, and
    example-host guidance
  - Plan 03: tighten support-contract verifier needles and contributor map
- Recommended Braintree top-line wording:
  - bounded first-party `swap_plan/3` only with `:plan_resolver`
  - no first-party preview, quantity, or subscription-item support
  - mounted local checkout/portal remain honest but separate from swap semantics
- Recommended anti-drift rule:
  - if Braintree support wording changes, update matrix, docs, host proof docs,
    and verifier needles in the same PR

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Active milestone truth
- `.planning/ROADMAP.md` — Phase 119 goal and success criteria
- `.planning/REQUIREMENTS.md` — `SCM-06`
- `.planning/STATE.md` — active milestone position and next-phase handoff
- `.planning/processor-support-matrix.md` — canonical processor support SSOT

### Adjacent phase context that still governs scope
- `.planning/milestones/v1.37-phases/118-admin-portal-change-flows/118-CONTEXT.md` — promoted active-subscription-change boundary and touched UI posture
- `.planning/milestones/v1.37-phases/118-admin-portal-change-flows/118-RESEARCH.md` — current runtime/UI seam inventory and Braintree bounded story
- `.planning/milestones/v1.35-phases/109-support-contract-truth/109-CONTEXT.md` — support-mirror discipline and same-PR doc alignment rules
- `.planning/milestones/v1.36-phases/113-cancellation-semantics-closure/113-CONTEXT.md` — provider-honest unsupported guidance across admin/portal surfaces

### Runtime and support-contract seams
- `accrue/lib/accrue/billing.ex` — public facade contract
- `accrue/lib/accrue/billing/subscription_actions.ex` — Braintree swap and unsupported quantity semantics
- `accrue/lib/accrue/processor/capabilities.ex` — runtime support-label map
- `accrue/test/accrue/billing/subscription_actions_test.exs` — bounded Braintree swap-only and unsupported quantity proof
- `accrue/test/accrue/processor/capabilities_test.exs` — support-label proof

### Touched UI and copy seams
- `accrue_admin/lib/accrue_admin/copy/subscription.ex` — operator-facing Braintree setup and unsupported wording
- `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` — operator contract proof
- `accrue_portal/lib/accrue_portal/copy.ex` — customer-facing Braintree wording seam
- `accrue_portal/test/accrue_portal/live/subscription_live_test.exs` — portal copy proof
- `examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs` — host-facing wording proof anchor

### Docs and guide mirrors
- `accrue/README.md` — package-facing support-contract summary
- `accrue/guides/first_hour.md` — onboarding mirror and early Braintree branch
- `accrue/guides/lifecycle_semantics.md` — active-change and cancellation semantics SSOT
- `accrue/guides/production-readiness.md` — ship-order Braintree checks
- `accrue/guides/braintree-local-portal.md` — mounted local portal/setup guide
- `examples/accrue_host/README.md` — host proof/reference mirror
- `examples/accrue_host/docs/adoption-proof-matrix.md` — proof taxonomy mirror

### Drift-gate seams
- `scripts/ci/README.md` — support-contract bundle and contributor co-update rules
- `scripts/ci/verify_processor_support_matrix.sh` — matrix wording gate
- `scripts/ci/verify_package_docs.sh` — package-doc and host README wording gate
- `scripts/ci/verify_verify01_readme_contract.sh` — host README proof wording gate
- `scripts/ci/verify_adoption_proof_matrix.sh` — adoption matrix wording gate

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Runtime already has the bounded Braintree swap-only path and explicit
  unsupported quantity semantics; the main gap is contract hardening and drift
  prevention.
- Admin and portal copy seams already centralize provider-honest wording, so
  this phase can tighten language without inventing new UI architecture.
- The repo already has a support-contract verifier bundle and contributor-map
  section specifically for provider-honest mirror discipline.

### Established Patterns
- Support truth starts in the processor support matrix, then gets mirrored into
  thin docs and proof surfaces.
- Braintree setup dependencies are expressed as explicit config contracts rather
  than soft warnings or hidden fallbacks.
- Example-host docs stay proof-oriented and should defer normative API truth
  back to package docs and the support matrix.

### Integration Points
- Any Braintree swap wording change likely needs synchronized edits across:
  - `.planning/processor-support-matrix.md`
  - `accrue/README.md`
  - `accrue/guides/first_hour.md`
  - `accrue/guides/lifecycle_semantics.md`
  - `accrue/guides/production-readiness.md`
  - `examples/accrue_host/README.md`
  - verifier scripts under `scripts/ci/`
- If touched UI wording changes, corresponding LiveView tests should change in
  the same slice.

</code_context>

<deferred>
## Deferred Ideas

- No reopening of Braintree preview parity or self-serve quantity/item edits
- No pause/resume, schedule, or broader cancellation-product modeling
- No new processor capabilities or release-readiness automation work

</deferred>

---

*Phase: 119-braintree-bounded-plan-swap-closeout*
*Context gathered: 2026-05-07*
