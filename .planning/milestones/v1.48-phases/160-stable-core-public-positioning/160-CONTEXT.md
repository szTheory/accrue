# Phase 160: Stable-Core Public Positioning - Context

**Gathered:** 2026-05-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Align public documentation, package documentation, support-boundary mirrors, release notes, and planning mirrors around Accrue's stable-core / demand-driven expansion posture. This phase is documentation positioning and drift-proofing only: no new billing primitives, processor capability expansion, admin or portal product surface, backlog cleanup, or pause-rule implementation beyond the public positioning needed for POS-01, POS-02, and POS-03.

</domain>

<decisions>
## Implementation Decisions

### Stable-Core Claim Strength
- **D-01:** Public docs should explicitly say Accrue is stable-core / done enough for its declared scope and expands demand-driven from concrete evidence. Do not rely on quiet maintenance hints or release notes alone.
- **D-02:** Use "stable-core / demand-driven expansion" language, not "feature freeze", "maintenance only", or "no new features ever". The desired signal is stable public trust plus clear reopen criteria, not abandonment.
- **D-03:** The public posture should include the core reopen triggers already locked in project posture: concrete adopter failure mode, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change.
- **D-04:** Public copy should be adopter-facing and concrete: the canonical SaaS billing loop is complete, the documented facade is the stability boundary, and future work is proof, docs truth, support-contract hardening, maintenance, or justified expansion.

### Adopter-Facing Documentation Spine
- **D-05:** Use a layered hub-and-spoke documentation spine rather than one giant canonical README. Each surface should own one job and link to the others.
- **D-06:** Root `README.md` owns first impression: project positioning, package map, proof posture summary, start-here links, and one concise stable-core statement.
- **D-07:** `accrue/README.md` owns the core package landing page: install contract, public API/support boundary summary, guide index, versioning expectations, and links to release notes / upgrade.
- **D-08:** `accrue/guides/first_hour.md` remains the canonical setup and evaluation spine: deps, install, runtime config, migrations, Oban, webhooks, admin, subscription proof, and bounded Braintree branch.
- **D-09:** `accrue/guides/jobs_to_be_done.md` owns the complete supported SaaS billing loop narrative: subscribe, change/cancel, recover failed payments, self-serve, gate access, operate with audit/proof.
- **D-10:** `accrue/guides/maturity-and-maintenance.md` owns the long-form stable-core / demand-driven expansion doctrine, evidence bar, stop rules, revisit triggers, and explicit non-goal posture.
- **D-11:** `accrue/guides/production-readiness.md` owns ship-readiness checklist and operational gates only; do not turn it into the posture SSOT.
- **D-12:** `accrue_admin/README.md` and `accrue_portal/README.md` should stay thin and package-specific: mount/config/ownership boundary plus links back to First Hour, Jobs to Be Done, and Maturity. They should not duplicate the full billing-loop narrative.
- **D-13:** `examples/accrue_host/README.md` and `examples/accrue_host/docs/adoption-proof-matrix.md` should remain proof vocabulary and evidence mirrors. They should point to canonical docs for semantics and policy instead of becoming their own support-boundary authorities.
- **D-14:** Public docs must carry all adopter-critical truth. `.planning/*` stays a maintainer mirror and should not be required reading for adopters.

### Support-Boundary Mirrors
- **D-15:** Keep one authoritative provider capability contract and thin mirrors. The existing `.planning/processor-support-matrix.md` remains the maintainer-facing capability SSOT unless downstream planning creates a generated/public excerpt; do not hand-maintain two full capability tables.
- **D-16:** Package READMEs own package-scope boundaries only: `accrue` owns billing engine/facades/docs, `accrue_admin` owns operator UI, `accrue_portal` owns mounted self-serve/local checkout UI, and host apps own Repo, migrations, Oban supervision, auth/session/runtime secrets, routing, and app-domain membership policy.
- **D-17:** Allowed mirrors are short: 3-6 lines in root/package READMEs and First Hour; proof-lane wording in host/adoption docs; release-note deltas for changed capabilities. Each mirror should link back to the canonical boundary source.
- **D-18:** Forbidden duplication: full row-by-row capability tables outside the canonical source; reworded support labels that introduce new synonyms; long planning-posture prose pasted into package docs; release notes pretending to be the static support contract.
- **D-19:** Provider labels must stay capability-explicit and provider-honest. Stripe remains the first-user production path, Fake remains deterministic merge-blocking proof, and Braintree remains the bounded gateway subscription core path. Any processor-surface change must update behavior, support matrix, docs, examples/verifiers, and release notes together.

### Verifier and Release-Note Contract
- **D-20:** Add a dedicated stable-core posture verifier rather than stuffing this concern into `verify_package_docs.sh`. The recommended contract is a new `scripts/ci/verify_stable_core_posture.sh` with its own failure prefix and triage section.
- **D-21:** Wire the posture verifier into `docs-contracts-shift-left` and document it in `scripts/ci/README.md` alongside the existing package-doc, support-matrix, adoption-proof, and release-note gates.
- **D-22:** The verifier should use the repo's established bash style: `require_fixed`, `require_regex`, `require_absent_regex`, explicit stderr prefix, and narrow intentional substrings rather than broad terms like `stable`.
- **D-23:** The posture verifier should assert stable-core anchors across the public/mirror surfaces required by POS-03: root README, `accrue/README.md`, `accrue/guides/maturity-and-maintenance.md`, `accrue/guides/jobs_to_be_done.md`, `accrue/guides/release-notes.md`, `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/processor-support-matrix.md`, and `examples/accrue_host/docs/adoption-proof-matrix.md`.
- **D-24:** Extend `scripts/ci/verify_release_notes_contract.sh` only lightly: require a release-note posture token such as "stable-core posture" plus a pointer back to maturity/support-boundary docs. Do not couple all posture checks to version headings or force unrelated PRs through release-note edits.
- **D-25:** Optional ExUnit coverage, if added, should shell out to the bash verifier instead of re-encoding all needles in Elixir. Avoid dual-contract drift between bash and tests.
- **D-26:** Add negative guards for retired or dangerous posture terms if they appear during implementation, especially "feature freeze", "no new features ever", or public wording that implies planning internals are required to understand support boundaries.

### the agent's Discretion
- Downstream agents may choose exact copy as long as it preserves the decisions above, keeps the docs layered by ownership, and keeps wording adopter-facing rather than planning-jargon-heavy.
- Downstream agents may decide whether to introduce a public "support boundaries" guide or generated excerpt only if it does not create a second hand-maintained capability SSOT. The conservative default is thin public mirrors plus canonical matrix pointers.
- Downstream agents may choose exact verifier needles, but must keep them narrow, explainable, and low-churn. Prefer a small set of load-bearing posture phrases over brittle paragraph-length literals.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Project Posture
- `.planning/ROADMAP.md` — Phase 160 goal, dependencies, success criteria, and one-plan boundary.
- `.planning/REQUIREMENTS.md` — POS-01, POS-02, POS-03 and v1.48 out-of-scope boundaries.
- `.planning/PROJECT.md` — stable-core / demand-driven expansion posture, package ownership boundaries, and future-work bar.
- `.planning/STATE.md` — current milestone state and Phase 159 carry-forward decisions.
- `.planning/phases/159-linked-release-readiness-publish-proof/159-CONTEXT.md` — prior phase boundary: release proof only; stable-core positioning belongs here.
- `prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md` — adopter-first "done enough" lens, subagent research preference, DX/least-surprise framing, and overbuilding guardrails.

### Public Documentation Spine
- `README.md` — root first impression, package map, proof posture, and stable-core summary.
- `accrue/README.md` — core package landing page, install contract, public API/support summary, and guide index.
- `accrue_admin/README.md` — admin package mount/setup boundary; should remain a thin package-specific mirror.
- `accrue_portal/README.md` — portal package mount/setup boundary; should remain a thin package-specific mirror.
- `accrue/guides/first_hour.md` — canonical setup/evaluation spine and host README parity anchor.
- `accrue/guides/jobs_to_be_done.md` — complete supported SaaS billing loop narrative and scope/maturity summary.
- `accrue/guides/maturity-and-maintenance.md` — stable-core / demand-driven expansion doctrine, stop rules, evidence bar, and revisit triggers.
- `accrue/guides/production-readiness.md` — ship-readiness checklist; should link to posture docs without becoming the posture SSOT.
- `accrue/guides/upgrade.md` — public stability boundary and deprecation expectations.
- `accrue/guides/release-notes.md` — plain-language release mirror and posture/delta token target.

### Support and Proof Mirrors
- `.planning/processor-support-matrix.md` — canonical provider capability/support-boundary contract.
- `examples/accrue_host/README.md` — checked-in host proof story and proof-lane vocabulary.
- `examples/accrue_host/docs/adoption-proof-matrix.md` — adoption proof matrix and public proof taxonomy.
- `scripts/ci/README.md` — CI gate map, support-contract bundle, triage conventions, and place to document the new stable-core verifier.

### Verification and CI Contracts
- `scripts/ci/verify_package_docs.sh` — existing package-doc and guide-link verifier; do not overload with posture as the primary concern.
- `scripts/ci/verify_processor_support_matrix.sh` — support-matrix drift gate.
- `scripts/ci/verify_adoption_proof_matrix.sh` — adoption-proof drift gate.
- `scripts/ci/verify_release_notes_contract.sh` — release-note freshness gate to extend lightly for posture token/pointer.
- `.github/workflows/ci.yml` — `docs-contracts-shift-left` CI home for the new posture verifier.

### External Research References
- `https://docs.stripe.com/billing/subscriptions/overview` — Stripe's task/lifecycle-oriented subscription docs and status truth-table style.
- `https://laravel.com/docs/10.x/billing` — Laravel Cashier's fluent subscription abstraction, explicit subscription scope, and footguns around provider/API specifics.
- `https://github.com/pay-rails/pay` — Rails Pay's provider list, fake processor, upgrade guide, and multi-provider billing-library precedent.
- `https://hexdocs.pm/ecto/` — Ecto's componentized public documentation model and stable API expectations in the Elixir ecosystem.
- `https://hexdocs.pm/oban/instrumentation.html` — Oban's focused guide structure and operational/documentation layering.
- `https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/` — explicit feature/stability labeling precedent for avoiding claim drift.
- `https://doc.rust-lang.org/rustdoc/documentation-tests.html` — executable documentation contract precedent.
- `https://hexdocs.pm/ex_unit/ExUnit.DocTest.html` — Elixir-native docs-test precedent if a thin shell-out harness is added.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/ci/verify_package_docs.sh`: established `require_fixed` / `require_regex` / `require_absent_regex` style, stderr prefixing, version parsing, and docs-contract idiom.
- `scripts/ci/verify_processor_support_matrix.sh`: existing support-boundary drift gate; planners should reuse its capability-explicit discipline.
- `scripts/ci/verify_adoption_proof_matrix.sh`: existing proof-taxonomy gate; stable-core mirrors should be pinned here only where adoption-proof language changes.
- `scripts/ci/verify_release_notes_contract.sh`: existing release-note freshness gate; extend lightly rather than making it the posture SSOT.
- `.github/workflows/ci.yml`: `docs-contracts-shift-left` is the correct CI integration point for a new stable-core posture verifier.

### Established Patterns
- Public docs are already split by job: root README for orientation, package README for package landing, First Hour for setup, JTBD for capability loop, maturity guide for stop rules, production-readiness for ship checklist.
- Existing support-contract work uses one canonical support matrix plus thin mirrors and bash drift gates.
- Existing docs contracts prefer grep-friendly literal needles over complex parsers, with contributor triage in `scripts/ci/README.md`.
- Accrue's package boundary is already explicit: `accrue` owns billing domain/facades, `accrue_admin` owns operator UI, `accrue_portal` owns customer self-serve/local portal UI, and host apps own app-specific edges.

### Integration Points
- New planning output should produce `160-01-PLAN.md` covering copy edits, verifier addition, CI wiring, scripts/ci README triage, release-note contract, and planning mirror alignment.
- Public docs touched by this phase should be updated in one coherent PR/slice so stable-core claim strength, doc spine, and support-boundary mirrors land atomically.
- Verifier work should be part of the same plan as doc copy changes so POS-03 is satisfied by executable drift proof, not reviewer memory.

</code_context>

<specifics>
## Specific Ideas

- User explicitly asked to discuss all four gray areas and use subagent-backed research with pros/cons/tradeoffs, Elixir/Phoenix ecosystem idioms, lessons from Pay/Rails, Laravel Cashier, Stripe, Oban, Ecto/Phoenix, strong DX, least surprise, and a cohesive one-shot recommendation.
- Four advisor researchers converged on the same recommendation set: explicit but non-abandonment stable-core language; layered hub-and-spoke docs; canonical support truth with thin mirrors; and a dedicated stable-core posture verifier.
- Cashier's lesson: developer-friendly abstractions are valuable, but over-broad implicit scope creates confusion around what the abstraction does and does not own. Accrue should name supported slices explicitly.
- Pay's lesson: multi-provider billing libraries need visible provider lists, upgrade guidance, and fake/test processors, but Accrue should avoid implying broad provider parity just because adapters exist.
- Stripe's lesson: lifecycle/status truth tables and task-oriented docs reduce adopter confusion. Accrue should keep Jobs to Be Done and First Hour as product/DX surfaces, not bury support truth in planning.
- Ecto/Phoenix/Oban lesson: Elixir ecosystem docs work best when package docs, focused guides, and operational references have clear ownership. Accrue should not force readers through monorepo planning docs to evaluate a Hex package.
- Verifier lesson: use small executable docs contracts for load-bearing posture claims; do not rely on reviewer memory for POS-03.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within Phase 160 stable-core public positioning scope.

</deferred>

---

*Phase: 160-Stable-Core Public Positioning*
*Context gathered: 2026-05-31*
