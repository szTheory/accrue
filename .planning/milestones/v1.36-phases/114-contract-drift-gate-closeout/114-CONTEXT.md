# Phase 114: Contract Drift Gate Closeout - Context

**Gathered:** 2026-05-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Close `PROC-24` by making the finalized dual-provider core contract read the same way across the processor support matrix, package-facing docs, example-host proof artifacts, and merge-blocking drift gates.

This is a contract-closeout phase, not a new product-surface phase. It does not reopen lifecycle breadth, broaden the example host into a second specification, or turn planning mirrors into another contract SSOT.

</domain>

<decisions>
## Implementation Decisions

### Docs coverage
- **D-01:** `.planning/processor-support-matrix.md` remains the single canonical wording spine for the finalized dual-provider core contract.
- **D-02:** Package docs, host docs, and proof docs should mirror only the durable contract needles their audience needs, not restate the full matrix.
- **D-03:** The mirrored needles should stay focused on:
  - the supported slice name (`gateway subscription core`)
  - Fake-first merge-blocking proof posture
  - advisory provider-backed fidelity lanes
  - Stripe-hosted versus Braintree-mounted-local honesty
  - immediate cancel versus scheduled-end split
  - bounded `update_customer/2` semantics where that API is surfaced
- **D-04:** Do not optimize for every single doc page being self-contained if that requires restating the same support contract in multiple voices.
- **D-05:** Phase 114 should prefer layered documentation over duplicate documentation: one canonical contract source, then audience-specific teaching surfaces that link back to it.

### Example-host proof depth
- **D-06:** `examples/accrue_host` remains a thin adoption-facing proof surface, not a second authoritative contract mirror.
- **D-07:** The example host should prove installed-host ergonomics, host-owned seams, and realistic usage flows without re-explaining the entire provider contract inline.
- **D-08:** Host proof docs should repeat only the minimum semantics needed to prevent misuse:
  - `update_customer/2` is bounded and provider-neutral
  - `cancel/2` is the shared immediate path
  - `cancel_at_period_end/2` is not a Braintree first-party path
  - Fake is merge-blocking; provider-backed lanes are advisory where stated
- **D-09:** Host code and tests should stay thin and delegating. The canonical semantics still live in runtime code, the support matrix, and package guides.
- **D-10:** Avoid turning the example host README or adoption-proof matrix into a quasi-spec, because that creates a high-trust but fast-drifting second contract voice.

### Drift-gate shape
- **D-11:** Keep the drift gate as a named support-contract bundle composed of existing targeted verifiers, not a new mega-verifier.
- **D-12:** The core Phase 114 bundle should center on:
  - `scripts/ci/verify_processor_support_matrix.sh`
  - `scripts/ci/verify_package_docs.sh`
  - `scripts/ci/verify_verify01_readme_contract.sh`
  - `scripts/ci/verify_adoption_proof_matrix.sh`
- **D-13:** Runtime capability truth and adapter semantics remain proven in ExUnit; exact public contract wording remains proven by targeted bash/string-literal gates.
- **D-14:** Do not collapse docs, proof, and matrix drift into one broad owner script. Surface-local failures are easier to understand, maintain, and trust.
- **D-15:** The support-contract bundle should be documented clearly in `scripts/ci/README.md` and kept stable as a contributor-facing ritual.
- **D-16:** Extend or tighten the targeted verifiers only where Phase 114 surfaces actually move; do not widen the gate bundle into unrelated doc territory.

### Planning mirror hygiene
- **D-17:** `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` should behave as concise closeout mirrors, not second copies of the support contract.
- **D-18:** `REQUIREMENTS.md` should close `PROC-24` and update traceability, but not restate the detailed contract semantics already captured elsewhere.
- **D-19:** `ROADMAP.md` should mark Phase 114 and milestone `v1.36` complete with a short outcome summary and links/pointers, not another full contract narrative.
- **D-20:** `STATE.md` should be corrected to current live facts and remain the operational position mirror, not a second milestone brief.
- **D-21:** If a planning mirror needs to reference contract truth, it should point to the support matrix, docs, or context file rather than paraphrasing all semantics again.

### Architecture and DX posture
- **D-22:** Phase 114 should optimize for least surprise: the place where maintainers expect contract truth should actually be the place that owns it.
- **D-23:** Provider-honest semantics stay more important than local page convenience or documentation symmetry.
- **D-24:** Strong DX here means:
  - a single canonical contract spine
  - thin but trustworthy adoption-facing proof
  - fast, localizable CI failures
  - low-maintenance mirrors
  - explicit links between artifacts instead of hidden duplication
- **D-25:** This phase should preserve the repo’s existing “bounded first-party slice, no parity theater” philosophy rather than inventing a broader documentation architecture.

### Lessons to preserve from other ecosystems
- **D-26:** Copy Stripe’s layering model, not its breadth: canonical technical contract plus audience-specific guides.
- **D-27:** Preserve the Pay/Cashier lesson that processor divergence must be named honestly instead of flattened into a fake uniform story.
- **D-28:** Preserve the Phoenix/Rails example-app lesson that sample hosts should demonstrate usage and integration seams, not become the authoritative API spec.
- **D-29:** Preserve the ActiveMerchant warning already captured in strategy: broad abstraction and broad mirror surfaces create long-tail DX erosion and drift burden.

### GSD shift-left preference
- **D-30:** For low-impact implementation forks inside an already approved boundary, future GSD discuss/planning passes should default to researched synthesis and one cohesive recommendation package instead of reopening the fork interactively.
- **D-31:** Reopen decisions interactively only when the choice materially changes:
  - product boundary
  - first-party support promise
  - public API shape
  - verifier philosophy
  - support/operator obligations
- **D-32:** Existing config posture already points in this direction (`research_before_questions`, `discuss_auto_resolve_low_impact`, `discuss_high_impact_confirm`). Future phases should continue to honor that preference without inventing unnecessary new toggles.

### the agent's Discretion
- Exact wording of the short mirrored needles in package docs and example-host docs, as long as they stay faithful to the canonical matrix.
- Exact naming and presentation of the “support-contract bundle” in `scripts/ci/README.md`, as long as the underlying targeted-script posture remains unchanged.
- Exact terseness of the Phase 114 closeout edits in `REQUIREMENTS.md`, `ROADMAP.md`, and `STATE.md`, as long as those files stay concise mirrors instead of semantic duplicates.

</decisions>

<specifics>
## Specific Ideas

- Recommended docs shape:
  - matrix is the full contract spine
  - package docs mirror only first-user needles
  - example-host docs mirror only adoption/proof needles
  - all surfaces cross-link explicitly
- Recommended host-proof shape:
  - one realistic host-owned seam
  - thin delegation examples
  - no second contract table in the host docs
- Recommended drift-gate shape:
  - reuse the existing `docs-contracts-shift-left` culture
  - keep one targeted verifier per surface
  - document the bundle clearly, but do not centralize all literals in one god-script
- Recommended planning-mirror shape:
  - close statuses cleanly
  - add one short outcome summary
  - point back to canonical artifacts for semantics
- Recommended future GSD preference:
  - research and synthesize low-impact forks by default
  - escalate only truly high-impact boundary choices

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Active milestone and strategic contract truth
- `.planning/ROADMAP.md` — Phase 114 goal, milestone scope, and success criteria
- `.planning/REQUIREMENTS.md` — `PROC-24`
- `.planning/STATE.md` — active execution position and current mirror drift
- `.planning/PROJECT.md` — milestone posture and bounded dual-provider philosophy
- `.planning/STRATEGY.md` — strategic parent for the official dual-provider core
- `.planning/research/ARCHITECTURE.md` — v1.36 integration points and build order
- `.planning/research/PITFALLS.md` — contract-drift and proof-lane risks
- `.planning/research/SUMMARY.md` — milestone thesis and closeout direction

### Prior locked context
- `.planning/phases/112-customer-update-contract-closure/112-CONTEXT.md` — customer-update contract closure and prior shift-left preference
- `.planning/phases/113-cancellation-semantics-closure/113-CONTEXT.md` — cancellation split, provider-honest semantics, and prior shift-left preference
- `.planning/phases/112-customer-update-contract-closure/112-RESEARCH.md` — prior drift-gate and mirror-alignment lessons for customer update
- `.planning/phases/113-cancellation-semantics-closure/113-03-SUMMARY.md` — targeted cancellation drift-gate precedent

### Canonical contract and public mirrors
- `.planning/processor-support-matrix.md` — canonical support contract spine for the dual-provider core
- `accrue/README.md` — package-facing contract mirror
- `accrue/guides/first_hour.md` — first-user install and proof mirror
- `accrue/guides/testing.md` — proof-lane posture and host/doc contract mirror
- `guides/testing-live-stripe.md` — advisory live-provider lane framing
- `examples/accrue_host/README.md` — host-facing proof mirror
- `examples/accrue_host/docs/adoption-proof-matrix.md` — proof-scope matrix for adopters/evaluators

### Verifier and CI surfaces
- `scripts/ci/verify_processor_support_matrix.sh` — support-matrix drift gate
- `scripts/ci/verify_package_docs.sh` — package-doc and host-doc fixed-needle gate
- `scripts/ci/verify_verify01_readme_contract.sh` — host README VERIFY-01 gate
- `scripts/ci/verify_adoption_proof_matrix.sh` — adoption-proof matrix gate
- `scripts/ci/README.md` — contributor-facing co-update rules and support-contract bundle home
- `.github/workflows/ci.yml` — `docs-contracts-shift-left` and `host-integration` CI wiring

### Runtime and proof anchors
- `accrue/test/accrue/processor/capabilities_test.exs` — runtime capability truth anchor
- `examples/accrue_host/lib/accrue_host/billing.ex` — host-owned seam pattern
- `examples/accrue_host/test/accrue_host/billing_facade_test.exs` — thin host delegation proof

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.planning/processor-support-matrix.md` already provides the right canonical-contract shape for this phase.
- `verify_processor_support_matrix.sh`, `verify_package_docs.sh`, `verify_verify01_readme_contract.sh`, and `verify_adoption_proof_matrix.sh` already form most of the needed support-contract bundle.
- `scripts/ci/README.md` already contains co-update rules and bundle-style contributor guidance that can be extended instead of reinvented.
- `examples/accrue_host/lib/accrue_host/billing.ex` already models the correct thin host-owned seam pattern.

### Established Patterns
- The repo already prefers one canonical support matrix plus targeted mirror needles rather than full duplicate contract tables.
- The repo already uses bash verifiers for exact docs/proof wording and ExUnit for runtime semantics.
- The repo already treats Fake as merge-blocking and provider-backed lanes as advisory fidelity checks.
- Prior phases already established that support labels, docs, example-host proof, and gates should move together in one truth pass.

### Integration Points
- Phase 114 must align:
  - support-matrix wording
  - package docs
  - example-host proof docs
  - targeted CI verifiers
  - planning mirrors
- If host-facing or package-facing wording changes, the matching verifier needles and contributor-map prose must move in the same phase.
- `STATE.md` currently contains operational drift and should be reconciled as part of the closeout-mirror work.

</code_context>

<deferred>
## Deferred Ideas

- Turning the example host into a second full contract mirror or quasi-spec
- Creating one broad mega-verifier that centrally owns every support-contract literal
- Rewriting planning mirrors into long-form semantic docs
- Reopening broader lifecycle, scheduling, preview/proration, or processor-expansion scope in this phase
- Adding new GSD config toggles unless a real behavior gap appears beyond the existing low-impact/high-impact defaults

</deferred>

---

*Phase: 114-contract-drift-gate-closeout*
*Context gathered: 2026-05-07*
