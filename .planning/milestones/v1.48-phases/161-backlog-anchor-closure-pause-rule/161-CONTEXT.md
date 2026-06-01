# Phase 161: Backlog Anchor Closure + Pause Rule - Context

**Gathered:** 2026-06-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Retire stale roadmap pressure, classify remaining seeds and deferred ideas with explicit revisit triggers, and record the post-v1.48 pause rule for broad feature work. This phase is planning hygiene and maintainer posture only: no new billing primitives, processor breadth, admin/portal feature work, ecosystem integration implementation, or public API changes.

</domain>

<decisions>
## Implementation Decisions

### Anchor and Seed Disposition
- **D-01:** Use a split-registry model for stale planning pressure. Historical friction anchors stay traceability-only; deferred seeds/ideas live in a separate trigger-bound bucket.
- **D-02:** Classify v1.17 FRG anchors as **Historical Anchors** unless a fresh sourced friction row reopens them. They should remain linked for audit history, but must not appear as active milestone pressure.
- **D-03:** Classify `SEED-001` as resolved historical context, not a live seed. Its linked-release purpose has already been superseded by later linked publish work and Phase 159 release-readiness context.
- **D-04:** Classify `SEED-002` and deferred feature ideas as dormant future-roadmap material with concrete reopen triggers. They are not v1.48 closeout blockers and do not create default next-milestone scope.
- **D-05:** Every deferred row that survives Phase 161 should carry: status, reason, future owner or category, and `revisit_trigger`. The trigger must match the stable-core evidence bar: concrete adopter failure, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change.
- **D-06:** Do not hard-delete historical anchors. The footgun is institutional memory loss and repeated re-triage; the cleaner approach is to mark them non-active and prove that active roadmap surfaces no longer imply broad feature work.

### Planning Hygiene Proof
- **D-07:** Adopt a hybrid hygiene proof: a human-readable planning hygiene ledger plus a fast Bash verifier wired into the existing docs-contract pattern.
- **D-08:** Do not introduce a separate machine-readable manifest for this phase. A manifest would add dual-SSOT drift for a small planning-hygiene closeout.
- **D-09:** Add or extend a verifier in the repo's existing style (`require_fixed`, `require_regex`, `require_absent_regex`, clear failure prefix) to prove:
  - broad-feature pointers are explicitly historical, deferred, or dormant;
  - no active roadmap pointer suggests broad feature work is currently open;
  - deferred seeds/ideas have concrete reopen triggers;
  - the pause rule is mirrored across `PROJECT.md`, `ROADMAP.md`, and `STATE.md`.
- **D-10:** The verifier should live with the current docs-contract scripts and be included in the existing `docs-contracts-shift-left` lane, not as a new heavyweight CI job.
- **D-11:** The hygiene proof should optimize for maintainer DX: fast local failure, grep-friendly diagnostics, and one obvious place to fix wording drift.

### Pause Rule
- **D-12:** Use a doctrine-plus-mirrors placement model. `PROJECT.md` owns the canonical pause doctrine; `ROADMAP.md` and `STATE.md` carry concise mirrors for milestone closeout and session continuity.
- **D-13:** The pause rule should be strong but not a feature freeze. Preferred wording: after v1.48, broad feature milestones remain closed by default unless reopened by concrete adopter failure, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change.
- **D-14:** Reopen decisions should be recorded in `PROJECT.md` or a future strategy artifact, then reflected in `ROADMAP.md`/`STATE.md`. Do not allow a deferred idea or stale seed alone to create milestone scope.
- **D-15:** Preserve the public stable-core / demand-driven expansion language from Phase 160. The pause rule is a maintainer decision about planning defaults, not public abandonment language.

### Cohesive Recommendation
- **D-16:** Phase 161 should land as one coherent maintenance-posture slice: split stale anchors from deferred seeds, add the hygiene ledger, add the verifier, mirror the pause rule, and update state. Splitting these into independent partial edits risks a contradictory planning surface.
- **D-17:** The planner should prefer small, auditable text changes plus one focused verifier over broad rewrites of historical planning docs.

### the agent's Discretion
- Downstream agents may choose exact section names, but should preserve the active/non-active distinction. Recommended labels are **Historical Anchors**, **Deferred Seeds and Ideas**, and **Pause Rule**.
- Downstream agents may choose whether to extend `verify_v1_17_friction_research_contract.sh` or create a separate `verify_roadmap_hygiene.sh`; the default recommendation is a separate small hygiene verifier to avoid overloading the v1.17-specific contract.
- Downstream agents may decide whether the hygiene ledger lives primarily in `ROADMAP.md` or `PROJECT.md`, as long as `PROJECT.md` remains the canonical doctrine home and the verifier proves the mirrors.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Project Posture
- `.planning/ROADMAP.md` — Phase 161 goal, success criteria, historical backlog anchors, and active roadmap status.
- `.planning/REQUIREMENTS.md` — BAK-01, BAK-02, PAU-01 and v1.48 out-of-scope boundaries.
- `.planning/PROJECT.md` — stable-core / demand-driven expansion doctrine, future-work bar, non-goals, and recommended pause posture.
- `.planning/STATE.md` — current milestone cursor, existing deferred items, and session continuity.
- `.planning/phases/159-linked-release-readiness-publish-proof/159-CONTEXT.md` — release-readiness boundary and Phase 159 proof posture.
- `.planning/phases/160-stable-core-public-positioning/160-CONTEXT.md` — stable-core public-positioning decisions, verifier style, and support-boundary mirror policy.
- `prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md` — adopter-first done-enough lens, subagent research preference, DX/least-surprise framing, and overbuilding guardrails.

### Historical Anchors and Seeds
- `.planning/research/v1.17-FRICTION-INVENTORY.md` — durable friction inventory, historical FRG anchors, maintainer passes, and existing revisit-trigger vocabulary.
- `.planning/research/v1.17-north-star.md` — stop rules S1/S5, P0 intake gate, defer/revisit requirements, and no-scope-creep doctrine.
- `.planning/seeds/SEED-001-post-v1-36-linked-release-window.md` — resolved linked-release seed; should become historical context only.
- `.planning/seeds/SEED-002-ecosystem-integrations.md` — dormant future-roadmap seed; should remain trigger-bound, not active scope.

### Public and Maintainer Posture Mirrors
- `README.md` — public stable-core / demand-driven expansion summary.
- `accrue/README.md` — core package stability boundary and reopen criteria.
- `accrue/guides/maturity-and-maintenance.md` — public doctrine for done-enough, evidence bar, and revisit triggers.
- `accrue/guides/jobs_to_be_done.md` — scoped SaaS billing loop narrative and non-goal framing.
- `.planning/processor-support-matrix.md` — support-boundary SSOT; useful precedent for capability-explicit labels and thin mirrors.

### Verification and CI Contracts
- `scripts/ci/verify_v1_17_friction_research_contract.sh` — existing friction-inventory contract; do not break its five-row invariant without deliberate decision.
- `scripts/ci/verify_stable_core_posture.sh` — Phase 160 posture verifier style and mirror coverage pattern.
- `scripts/ci/README.md` — docs-contract triage conventions and place to document any new hygiene verifier.
- `.github/workflows/ci.yml` — `docs-contracts-shift-left` integration point for the hygiene proof.

### External Research References
- `https://github.com/pay-rails/pay` — multi-provider billing-library precedent: explicit provider/support boundaries and fake/test processor lessons.
- `https://laravel.com/docs/cashier` — scoped billing abstraction precedent and Stripe-first DX lessons.
- `https://docs.stripe.com/changelog` — explicit version/change communication precedent.
- `https://docs.stripe.com/libraries/set-version` — API versioning and upgrade-boundary precedent.
- `https://guides.rubyonrails.org/maintenance_policy.html` — explicit maintenance-policy framing precedent.
- `https://docs.djangoproject.com/en/4.2/internals/release-process/` — release/deprecation policy precedent.
- `https://kubernetes.io/docs/reference/using-api/deprecation-policy/` — lifecycle/deprecation policy precedent.
- `https://hexdocs.pm/phoenix/changelog.html` — Elixir ecosystem precedent for explicit changelog and upgrade signaling.
- `https://hexdocs.pm/ecto/changelog.html` — Elixir ecosystem precedent for explicit changelog and upgrade signaling.
- `https://hexdocs.pm/elixir/1.18.4/compatibility-and-deprecations.html` — compatibility/deprecation discipline precedent.
- `https://hexdocs.pm/oban/changelog.html` — Oban release/upgrade signaling precedent.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/ci/verify_stable_core_posture.sh`: established Phase 160 style for checking doctrine mirrors with narrow fixed/regex needles and absent-danger-word guards.
- `scripts/ci/verify_v1_17_friction_research_contract.sh`: existing invariant checker for the v1.17 friction inventory and roadmap anchor links.
- `scripts/ci/README.md`: existing home for docs-contract triage notes and local command guidance.
- `.github/workflows/ci.yml`: existing `docs-contracts-shift-left` CI lane for planning/docs hygiene gates.

### Established Patterns
- Accrue uses canonical doctrine plus thin mirrors, not duplicated long-form policy across every surface.
- Existing planning contracts favor explicit evidence rows, stop rules, and revisit triggers over aspirational backlog prose.
- Verifiers are intentionally lightweight Bash scripts that fail with actionable messages before expensive BEAM/Postgres lanes run.
- Stable-core posture is already public-facing; Phase 161 should strengthen maintainer planning defaults without rewriting public docs into abandonment copy.

### Integration Points
- `PROJECT.md` should receive the canonical pause-rule doctrine or closeout text.
- `ROADMAP.md` should make historical anchors visibly non-active and should not keep broad-feature pressure in the active phase table after Phase 161.
- `STATE.md` should record the pause rule and classify deferred items for session continuity.
- A new or extended CI verifier should be documented in `scripts/ci/README.md` and wired into `.github/workflows/ci.yml`.

</code_context>

<specifics>
## Specific Ideas

- User asked to discuss all three gray areas and use subagent-backed research with pros/cons/tradeoffs, ecosystem lessons, Elixir/Phoenix idioms, DX, least surprise, and one cohesive recommendation.
- Three advisor researchers converged on compatible recommendations:
  - split historical anchors from deferred seeds/ideas;
  - use a hybrid human-readable ledger plus grep-backed verifier;
  - use doctrine-plus-mirrors for the pause rule.
- Main footgun: leaving historical links in `ROADMAP.md` without explicit non-active language. That undermines BAK-02 because future agents may treat them as active scope.
- Second footgun: introducing a manifest for a small hygiene problem. It would create dual-SSOT drift and more contributor ceremony than the phase needs.
- Third footgun: using "feature freeze" or "maintenance only" language. That would conflict with Phase 160's stable-core / demand-driven expansion posture and could send the wrong public signal.
- The architecture should feel like mature Phoenix/Ecto/Oban-style maintenance discipline: explicit changelog/upgrade/policy signals, fast diagnostics, and no surprise scope expansion from stale backlog prose.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within Phase 161 backlog-anchor closure and pause-rule scope.

</deferred>

---

*Phase: 161-Backlog Anchor Closure + Pause Rule*
*Context gathered: 2026-06-01*
