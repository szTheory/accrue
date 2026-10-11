# Phase 244: Operator Language and Evidence - Context

**Gathered:** 2026-10-10
**Status:** Ready for planning
**Provenance:** The maintainer selected all three discussion areas and explicitly requested parallel consideration, coherent synthesis, and automatic adoption of recommendations. Decisions below are delegated recommendations, not invented answers to individual questions. Three bounded read-only advisor reviews completed. Source observations and external guidance informed decisions; no fresh rendered acceptance or implementation is claimed.

<domain>
## Phase Boundary

Deliver LANG-01, STATE-01, EVID-01, and CONS-01 on selected existing Admin screens: understandable primary labels, evidence-true outcomes and supported next steps, retained exact investigation evidence, and consistent names for actual destinations/effects. Start from the shipped v1.64 baseline and confirm remaining defects against current mounted output before edits.

No new billing behavior, diagnosis capability, authorization semantics, Portal work, rooms, redesign, rebrand, dependency migration, test framework, or CI lane. SEED-004 contributes content hierarchy and operator clarity only. Do not repeat v1.64's broad surface cleanup or reopen its completed acceptance.
</domain>

<decisions>
## Implementation Decisions

### Activity wording
- **D-01:** Use explicit, meaning-backed operator labels for known event/state types through the incumbent Copy owner. Read the event producer and outcome contract before choosing a label: a locally recorded update, requested processor operation, received delivery, and completed operation have different meanings. Do not infer semantics by replacing punctuation or title-casing arbitrary keys.
- **D-02:** Retain the exact key independently from its display label. For unrecognized types, use a neutral fallback such as “Billing event” with the exact key available; do not classify an unfamiliar type as failure, lost history, or a completed action. Nil/malformed values receive honest missing-data treatment without fabricated identifiers. Exact final strings and mapping membership are planner discretion after source and rendered confirmation.
- **D-03:** Reuse the same label meaning across the targeted Home, event list/detail, and related activity consumers that actually share the underlying event. Avoid divergent page-local translations or a mapping of every possible provider event without evidence. Primary scanning language serves billing/support operators; established billing terms remain where they affect decisions. Historical activity must not imply current customer/provider state.

### Technical evidence and hierarchy
- **D-04:** Keep affected object, observed outcome, material uncertainty, and supported next action visible. Put secondary technical evidence in existing native disclosure or detail fields when it crowds primary scanning. Retain visible identity/context needed to distinguish records. Choose by the surface's task; no universal collapsed-fields policy or new inspector.
- **D-05:** Exact event key, relevant record identifiers, and timestamps remain discoverable at the investigation point. Preserve full available timestamp precision and timezone in an accessible evidence location; minute/relative summaries alone do not satisfy exact evidence. Home may use compact time while the existing detail/disclosure carries the complete value. Do not label absent time as current or invent freshness.
- **D-06:** Evidence must work with keyboard and touch and remain selectable; reuse incumbent copy controls where appropriate. Never make tooltip/hover the only access path. Disclosure names identify their contents, preserve native activation/focus behavior, and handle long identifiers on narrow screens. Do not add controls to every row just for uniformity.
- **D-07:** Preserve fresh owner scope and existing authorized projection. Humanizing a label does not approve adding raw payloads, sensitive fields, new reads, new links, logging, or mutation. Keep raw payload in its existing authorized detail context; do not duplicate it on Home. Missing or inaccessible relationships stay explicit and do not produce unrelated plausible links.

### Outcomes, recovery, and destination names
- **D-08:** Prefer concise observed outcome plus a supported next step, with technical limitation in contextual evidence where needed. Distinguish completed, requested/queued, failed, blocked, and unable-to-confirm using actual available evidence. Do not invent a cause, blame filters/configuration for service failures, or soften uncertainty into success.
- **D-09:** If observation fails after a mutation request, preserve uncertainty and direct the operator to an existing supported reread/investigation path before suggesting another mutation. A read retry and replay/resend are different actions. Do not offer a generic retry that could duplicate billing work. This phase changes presentation only; if correct wording needs new domain behavior, document the gap for separate scope.
- **D-10:** Repeated navigation/page/breadcrumb/action names agree with their existing destination/effect. Maintain a small vocabulary/destination table in the phase's focused planning inventory, not a new global taxonomy. Preserve payment versus exact Charge evidence, event versus webhook delivery, and requested versus completed. Keep Copy.Locked and legal/audit/provider meaning intact. Redundant implementation narration can be shortened without losing consequential limitations.

### Focused delivery, automation, and stopping rules
- **D-11:** Home recent activity and inline Home wording are initial source-confirmed candidates; event detail and webhook related activity are likely same-meaning consumers. They are not a blanket fix list. Planning first confirms current mounted route/state output, records each candidate as change/adequate/unobserved with owning source and test, then selects coherent slices. STATE-01 requires real targeted outcome coverage, not just static label edits. Do not add a new broad research phase or all-route audit.
- **D-12:** Attach each recurring claim to its cheapest faithful existing owner: Copy tests for mapping/fallback and parity; owning LiveView tests for rendered labels, identity, exact evidence and supported branches; existing browser tests for real disclosure/navigation, focus, long-ID layout, narrow/wide and effective light/dark where affected. Include unknown keys, missing facts, sub-minute timestamps, stale/unavailable observations, and destination/effect assertions. Avoid tests that merely freeze paragraphs, blanket banned-word lint, broad AI detectors, relaxed exclusions, and duplicate matrices.
- **D-13:** Preserve state/job/dispatch/audit evidence for mutation/outcome claims. A clicked button, screenshot inventory, or displayed success sentence alone does not prove the operation. Bind each passing result to its tested revision, route/state/fixture, viewport/theme and served assets when relevant. Record initial failures honestly. Use the current build/parity and acceptance owners; plan exact commands rather than inheriting historical green results.
- **D-14:** Use one batched rendered review, one corrective batch, and one confirmation round per coherent slice. Reopen only for a named defect or evidence that invalidates the decision. Subjective comprehension informs agent review; do not invent a mandatory owner acceptance loop for mechanically decidable claims. Stop research at diminishing returns; no further fanout is needed unless new evidence exposes a genuine decision.
- **D-15:** Prefer a small local helper or modest explicit duplication over a new dependency/abstraction when it keeps ownership clear. Consolidate semantics that must agree at an existing owner. No new dependency is justified by this discussion; copy-paste preference does not authorize duplicating billing, money, scope, or authorization logic.

### Agent Discretion
The maintainer delegated all three areas: exact wording, small mapping/helper shape, confirmed consumer selection, detail placement within existing components, focused test selection, and implementation decomposition. Recommendations above are adopted under that delegation. Ask only if new evidence reveals a real product fork or an external action beyond existing authorization. This discussion does not authorize implementation by itself; the next workflow is phase planning.
</decisions>

<canonical_refs>
## Canonical References

Downstream agents must read the relevant sections before planning/implementation. Current source and approved requirements outrank dated prose. No separate Phase 244 SPEC.md exists.

### Scope and product
- `.planning/ROADMAP.md` — Phase 244 goal and four success criteria.
- `.planning/REQUIREMENTS.md` — all four approved requirements and guardrails.
- `.planning/PROJECT.md` — v1.65 scope, stable-core and shift-left policy.
- `PRODUCT.md` — equal operator/engineering audience, evidence boundaries and plain operator voice.
- `brandbook/voice.md` — calm, exact voice; apply vocabulary according to audience, without developer implementation narration in routine tasks.
- `CLAUDE.md` — project constraints and acceptance conventions.
- `.planning/seeds/SEED-004-admin-ui-blueprint-redesign.md` — background hierarchy/clarity only; M2/M3 remain deferred.

### Completed baseline
- `.planning/milestones/v1.64-phases/242-investigations-and-remaining-admin-surfaces/242-CONTEXT.md` — disclosure, navigation, copy, locked wording, evidence owners and review budget.
- `.planning/milestones/v1.64-phases/243-integrated-evidence-and-feedback-preview/243-CONTEXT.md` — isolated preview/proof custody, asset identity and revision evidence.
- `examples/accrue_host/README.md` — supported preview/startup; preserve feedback instance during proof.

### Current candidate and recurring owners
- `accrue/lib/accrue/events.ex` — event recording semantics; read relevant actual producers when mapping keys.
- `accrue_admin/lib/accrue_admin/copy.ex` — shared Copy delegates and state vocabulary.
- `accrue_admin/lib/accrue_admin/copy/billing_event.ex` — event-facing Copy owner.
- `accrue_admin/lib/accrue_admin/copy/locked.ex` — verbatim protected copy.
- `accrue_admin/lib/accrue_admin/live/dashboard_live.ex` — initial Home candidates.
- `accrue_admin/lib/accrue_admin/live/events_live.ex` — event collection consumer.
- `accrue_admin/lib/accrue_admin/live/event_live.ex` — event title/evidence and scoped relationships.
- `accrue_admin/lib/accrue_admin/live/webhook_live.ex` — related event activity, observation/replay outcomes.
- `accrue_admin/lib/accrue_admin/components/timeline.ex` — incumbent native disclosure and timeline rendering.
- `accrue_admin/test/accrue_admin/copy_test.exs` — Copy parity and limited existing voice guard; inline LiveView strings need owning rendered assertions.
- `accrue_admin/test/accrue_admin/copy/billing_event_test.exs` — event Copy owner.
- `accrue_admin/test/accrue_admin/live/dashboard_live_test.exs` — Home rendered owner.
- `accrue_admin/test/accrue_admin/live/event_live_test.exs` — exact event evidence owner.
- `accrue_admin/test/accrue_admin/live/events_live_test.exs` — collection owner.
- `accrue_admin/test/accrue_admin/live/webhook_live_test.exs` — webhook detail owner.
- `accrue_admin/test/accrue_admin/live/webhook_replay_test.exs` — requested/replay outcome contracts.

### Primary external guidance checked for this discussion
- https://www.gov.uk/service-manual/design/writing-for-user-interfaces — concise task-based interface wording, clarity around unsuccessful completion; guidance, not a new design authority.
- https://design-system.service.gov.uk/components/error-message/ — user-correctable validation versus service/permission problems and supported recovery.
- https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/ — keyboard disclosure behavior; preserve native semantics.
- https://design.education.gov.uk/content-design/plain-language — necessary technical terms explained for the audience.
</canonical_refs>

<code_context>
## Existing Code Insights
- Home currently uses `event.type` as its timeline title and contains inline “scoped billing record” / “Open event ledger” wording. Existing detail and related webhook activity also show raw event types. These are source observations requiring current mounted confirmation.
- Dashboard and event detail format recorded timestamps to minutes; investigation acceptance must preserve complete available precision somewhere accessible, rather than claiming the current compact output is exact.
- Shared Timeline already supports per-item native `<details>`, supporting metadata and detail links. Event detail has existing fields/raw-data disclosures. Reuse those seams without introducing a new inspector or duplicating payloads.
- Copy has an existing BillingEvent owner and a locked copy module. Existing generic/voice guards scan Copy modules; they do not establish clarity of inline LiveView strings or state truth.
- Existing scoped reads and validated relationships remain authoritative. Display labels must not change query values, persisted event types, filter identity, or authorization.
</code_context>

<specifics>
## Specific Ideas
- Illustrative known event label: `customer.updated` → “Customer updated,” only after confirming the producer's meaning. Preserve `customer.updated` as evidence. Unknown keys get neutral activity wording rather than guessed actions.
- The maintainer's Mailglass report emphasizes truthful uncertainty/recovery, plain scanning language and exact evidence; Scrypath emphasizes actual destination names and observation failure distinct from operation failure. Their recorded results are historical guidance, not current Accrue acceptance.
- User preference: “another copy and paste is better than another dep”; apply D-15 within existing semantic/security ownership boundaries.
- Parallel consideration covered operator/product, engineering/distributed outcomes, accessibility/narrow rendering, scope/security and delivery provenance. No irrelevant framework/graphics exploration was added.
</specifics>

<deferred>
## Deferred Ideas
None newly proposed. Previously excluded diagnosis/new rooms, Portal work, redesign and broad tooling remain outside this phase. Any domain correctness gap discovered during wording work requires explicit separate disposition.
</deferred>

---
*Phase: 244-operator-language-and-evidence*
*Context gathered: 2026-10-10*
