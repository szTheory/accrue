# Phase 242: Investigations and Remaining Admin Surfaces - Context

**Gathered:** 2026-10-10
**Status:** Ready for planning
**Decision authority:** Compiled from the maintainer-approved v1.64 scope, requirements and bounded upstream review, Phase 240's explicit authorization to carry settled answers forward, and the standing instruction to follow coherent recommendations until a genuine product decision is needed. No new product fork emerged. No new approval or simulated interview is inferred.
**Continuation:** `$gsd-plan-phase 242`. This context and current STATE focus/session fields supersede older handoffs that name discussion of 241 or 242. Phases 240 and 241 are complete; do not repeat them. The milestone remains 2/4 phases complete.

<domain>
## Phase Boundary

Refine the existing events/webhook investigation routes, coupon/promotion-code relationships, Connect facts and supported local fee action, and Home/navigation/search. Operators must reach the correct scoped record, retain bounded supported list context, discover exact evidence, review existing replay/action consequences and encounter coherent domain language. Cover JRN-05, JRN-06, JRN-07 and UXC-01.

Propagate the accepted Phase 240 system and Phase 241 destination/review contracts to every changed consumer. Each owning change includes acceptance, mounted inspection and current package asset proof. Phase 243 owns final reviewed Linux goldens and the stable Fake-backed feedback preview, rather than first acceptance of these surfaces.

This is existing Admin refinement. Preserve current Home and route families, host-owned scope/auth, billing/provider boundaries and the closed v1.63 archive. No new capability, room, diagnosis engine, search resource family or rebrand is approved.
</domain>

<decisions>
## Implementation Decisions

### Investigation hierarchy, evidence and replay

- **D-01:** Serve engineers and support/billing operators equally through identity/current scope → observed facts and material failures/uncertainty → supported next action → related evidence. Keep routine filters, selected lens and actionable facts visible. Use existing lists, detail fields, related links and disclosures according to their jobs; no universal columns, cards or tables.
- **D-02:** Distinguish the append-only local billing **event** from a received webhook **delivery** and its processing attempts/derived events. Use deliveries for webhook selection and result counts; source event types, actor/subject types, processor identifiers and diagnostic fields retain their exact meaning. A delivery, queued replay and resulting billing event are distinct observations.
- **D-03:** Retain familiar lazy activity/raw-data disclosure. Exact IDs, source relationships, timestamps, live/test mode, processing failures, payloads and available attempt evidence remain discoverable. Material failure, unsupported/ambiguous scope, uncertainty and replay consequence cannot depend on expanding raw JSON. Do not invent activity, causal links or a healthy state from absent evidence.
- **D-04:** Preserve the existing inline single/bulk replay review rather than introducing another wizard or universal action framework. A review identifies the exact delivery or selected set, current owner/eligibility, supported consequence and locked audit/replay wording. Selection changes or fresh scope/eligibility/material-state changes must not silently replay a different set. Dismissal cannot dispatch; step-up, fresh authorization and duplicate protections stay with their existing owners.
- **D-05:** Replay results distinguish queued/accepted, skipped/ineligible, denied, failed and unknown according to actual evidence. Enqueue acknowledgement does not imply successful processing or money movement. Reread failure after acceptance is not a failed replay that invites a blind retry. Initial/partial list failure, unavailable detail, no match and no records keep their separate supported recovery actions.

### Bounded list returns and existing relationships

- **D-06:** Extend the accepted validated destination/label contract to the named event, webhook, coupon, promotion-code and Connect list→detail jobs. The explicit return names its actual family; direct/invalid entry uses that family's safe scoped list fallback. Structural breadcrumbs remain distinct from a contextual filtered return.
- **D-07:** Preserve only meanings supported by the destination's current decoder and list behavior: current owner, supported search/filter/lens and relevant relationship constraint. Inventory exact decoder/allowlist/encoder parity during planning. Do not preserve ignored keys or infer behavior from URL equality alone. Sorting is included only where an existing destination supports it. Pagination, accumulated rows and scroll restoration are not new acceptance promises.
- **D-08:** Reuse `ScopedPath` and freshly resolved owner scope. Reject external/scheme-relative, malformed/ambiguous, other-mount and unauthorized destinations; caller-supplied owner data cannot choose the return scope. Preserve Phase 241's validated label/path agreement and malformed-percent boundary. Do not add nested return stacks, a navigation session service or routing dependency.
- **D-09:** Existing event→source delivery/subject and coupon→promotion-code→parent links preserve authorized resource and relationship identity. Provide accurate reciprocal/source links, bounded list context and ordinary Browser Back where appropriate. Do not expand the helper to arbitrary detail origins merely to recreate a full multi-hop stack. A missing, inaccessible or unavailable relationship remains truthful and does not produce a plausible link to an unrelated record.

### Catalog and Connect facts

- **D-10:** Keep coupon/discount terms and promotion-code identity, parent relationship, validity/activity, expiry, redemption limits and provider-defined restrictions clear. Preserve the approved resource vocabulary and distinguish a discount definition from a code that refers to it. Exact internal `Coupon`, API/model names and provider keys remain available in diagnostics; routine operator wording comes through existing Copy owners. Do not claim a missing parent or unknown limit is unrestricted, or add catalog creation/edit capabilities.
- **D-11:** Connect readiness, capabilities and requirements are stored provider observations. Keep the existing statement that the page does not track when Stripe last reported them; no invented freshness timestamp or live readiness claim. The supported platform-fee override is local policy and cannot imply remote capability/readiness changes.
- **D-12:** Apply the accepted self-contained review arrangement to the existing Connect fee form/drawer: exact account/owner, current local policy, proposed override/default consequence, supported validation and observation limits. Preserve fresh target/policy/actor authorization, step-up, exact monetary/percentage semantics, duplicate protection, associated errors and logical focus return. Do not copy billing rules into presentation or generalize a new action engine.

### Home, navigation, search and coherent copy

- **D-13:** Retain familiar static navigation and current Home. Make current route, owner and existing scoped destinations agree across Home, sidebar, breadcrumbs and search. Search remains bounded to its existing customers/invoices/subscriptions groups; do not add a new resource index, ranking system, command family or Home metrics rebuild.
- **D-14:** Search has one authoritative active result for pointer and keyboard use. Visible highlight, accessible semantics and Enter activation agree after pointer movement, Arrow navigation, query completion, LiveView replacement and scope changes. Keep real result links, bounded groups, clear identity and existing focus containment/restoration; choose semantics appropriate to the actual widget rather than adding `aria-selected` to arbitrary links.
- **D-15:** Preserve actual asynchronous search states: empty query/list shortcuts, loading, populated results, no match, partial/unavailable group and retry of unavailable lookups. An older query or owner result must not supersede current input/scope. Retain successful groups when another fails. Search-query persistence after opening a record is not an established contract; safe scoped destination and Browser Back remain sufficient.
- **D-16:** Use consistent resource, collection-method and action vocabulary through incumbent Copy modules across lists, details, filters/chips and reviews, including earlier billing copy where needed for UXC-01. Use **payment/Payments** for routine operator work and **Charge** where exact model/API evidence requires it; distinguish events from deliveries and human labels from raw collection enums. Review dismissal describes returning to the record, distinct from a domain cancellation. Preserve `Copy.Locked` verbatim and legal/audit/provider meaning; shorten procedural narration only when factual meaning remains intact.

### Shared system, automation and stopping rules

- **D-17:** Use Impeccable Operate and incumbent Cobalt, Geist/Geist Mono and package `--ax-*` roles. Carry approved typography/spacing, deliberate 2px dense and 1px structural exceptions, theme precedence, coarse-pointer geometry, keyboard/focus and state distinctions. Repeated keyboard search stays immediate; reduced motion and inactive overlays cannot delay task access or intercept input. No decorative motion or new font/UI dependency. The maintainer chose to keep the current Impeccable version during this session; no update is part of this phase.
- **D-18:** Each changed consumer receives faithful recurring proof at its existing ExUnit/query/contract, package browser or mounted host owner. Include real filter result membership, scoped returns/labels, relationship identity, replay/fee review target and consequence, fresh safety checks, selection/input transitions and distinct error outcomes. Browser tests exercise pointer→keyboard→Enter, disclosure, validation/correction/dismissal, focus, busy/reconnect and responsive/effective-theme behavior where claimed. Use authoritative state/job/dispatch/audit assertions for no-mutation claims; a page non-GET HTTP count proves only its narrower transport claim.
- **D-19:** Shift left into existing merge-blocking CI lanes when there is recurring value. Prefer the cheapest precise check and focused failure controls over duplicate fixtures/full matrices. A small faithful local helper is preferable to another dependency; retain shared money/scope/auth owners. No paid AI evaluator, fixed sleeps, blanket retries, hidden exclusions or relaxed snapshot tolerances. Canonical SUMMARY coverage and generator-owned automated UAT accompany completion; required human UAT remains zero whenever repeatable evidence can decide the claim.
- **D-20:** Source candidates require current mounted confirmation before cosmetic correction. Record source/fixture/built/compiled/served asset provenance separately from exercised behavior; explicitly build package assets and confirm current mounted bytes. Keep mutation/reset proof in disposable fixtures separate from feedback-preview custody. Update existing route/state coverage rather than creating a parallel registry. Final Linux golden/mask closure remains Phase 243.
- **D-21:** Preserve the milestone's bounded inspection budget across captures/scans/edits/rebuilds: one complete build/check and batched desktop/narrow/effective-theme inspection, one corrective batch, at most one confirming inspection per agreed delivery batch. Close a candidate as adequate/unobserved when evidence warrants. Reopen only for a named defect, safety/behavior failure, changed requirement or explicit owner feedback. Preserve honest actual-browser-zoom, physical-device, screen-reader-speech, provider and local/remote evidence limits without introducing confirmation-only UAT.

### Agent Discretion

Exact task decomposition, routine faithful copy, reuse of existing components, small helpers, appropriate accessible search mechanics, representative fixtures and precise assertions are delegated within the approved boundary. Focused implementation/command research and the phase UI contract are next; broad milestone/sibling-project research, brand setup and approval interviews are complete. No genuine product fork is currently unresolved. If new evidence exposes one, identify that concrete fork rather than reopening the whole discussion.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents must read relevant sections before planning or implementation.** Current scope and executable package owners outrank older aspirational prompts and dated handoff prose.

### Scope, product and accepted design

- `.planning/ROADMAP.md` — Phase 242 goal, JRN-05..07/UXC-01 success criteria and propagation; completion table establishes 240–241 complete.
- `.planning/REQUIREMENTS.md` — approved requirements and acceptance constraints; checkboxes/traceability outrank historical status prose.
- `.planning/PROJECT.md` — stable-core posture, explicit Admin-only milestone reopening, shift-left policy and completed upstream decisions.
- `PRODUCT.md` — equal operator audiences, ownership, product/provider truth; verify historical capability observations against delivered code.
- `.planning/research/v1.64/SUMMARY.md` — completed alternatives/dispositions, scope and stopping rules.
- `.planning/research/v1.64/OPERATOR-EXPERIENCE.md` — investigation/catalog/Connect returns, reciprocal relationships, diagnostics, search and language decisions.
- `.planning/research/v1.64/VISUAL-SYSTEM.md` — incumbent roles, density/input/theme/motion and mounted-confirmation constraints.
- `.planning/research/v1.64/AUTOMATION-AND-SEAMS.md` — existing evidence owners, fixture/asset seams and evidence limits.
- `.planning/milestones/v1.63-phases/233-shared-direction-portal-contract/DESIGN.md` — incumbent Admin visual direction; missing root DESIGN is not a redesign trigger.
- `accrue_admin/assets/css/theme.css` — executable token authority.
- `brandbook/voice.md` — measured, exact operator voice.
- `accrue_admin/lib/accrue_admin/copy/locked.ex` — verbatim legal/audit/replay contract.

### Completed phases and proof continuity

- `.planning/phases/240-shared-system-and-real-billing-exemplar/240-CONTEXT.md` — approved shared rules and delegated preparatory work.
- `.planning/phases/240-shared-system-and-real-billing-exemplar/240-UI-SPEC.md` — shared/exemplar composition and interaction contract.
- `.planning/phases/240-shared-system-and-real-billing-exemplar/240-COVERAGE.md` — route/registry/provenance baseline and incumbent owners.
- `.planning/phases/241-billing-operator-journeys/241-CONTEXT.md` — accepted validated destination/label and review safety contracts.
- `.planning/phases/241-billing-operator-journeys/241-HANDOFF.md` — completed delivery, current evidence, bookkeeping precedence and limits.
- `.planning/phases/241-billing-operator-journeys/241-EXECUTION-GATES.md` — honest failures/corrections and current owner commands; no claim that every broad browser attempt passed.
- `.planning/phases/241-billing-operator-journeys/241-CI-CONTRACT.md` — canonical automated UAT serialization and project-wide CI contract; avoid another metadata reconciliation loop.
- `.planning/milestones/v1.63-phases/238-admin-events-webhooks-remaining-billing-surfaces/238-VERIFICATION.md` — historical safety baseline only; current consumer acceptance belongs to Phase 242.

### Requested prompt continuity, subordinate to current scope

- `prompts/accrue_admin_operator_ui_journey_blueprint.md` — existing job/detail/review concepts; proposed new rooms/universal wizards are not approved.
- `prompts/accrue-library-summary-for-admin-ux-deep-research.md` — domain/projection/provider distinctions; verify older observations against current code.

### Focused primary guidance checked 2026-10-10

- [W3C disclosure pattern](https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/) — keyboard-operable show/hide and truthful expanded state; apply to existing disclosure semantics, no component library migration.
- [W3C link purpose](https://www.w3.org/WAI/WCAG22/Understanding/link-purpose-in-context.html) — understandable destinations and consistent identification; exact return labels are project decisions.
- [OWASP return destinations](https://cheatsheetseries.owasp.org/cheatsheets/Unvalidated_Redirects_and_Forwards_Cheat_Sheet.html) — constrain/authorize destinations through the existing local boundary.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `accrue_admin/lib/accrue_admin/scoped_path.ex` returns a validated path/label pair with fresh scope. Its current list allowlist covers billing/Recovery, not `/events`, `/webhooks`, `/coupons`, `/promotion-codes` or `/connect`. Extend only enumerated supported meanings; preserve completed billing behavior.
- `accrue_admin/lib/accrue_admin/components/detail.ex`, `related_resources.ex`, `json_viewer.ex`, `timeline.ex`, `detail_drawer.ex`, `step_up_auth_modal.ex` and `data_table.ex` provide incumbent summary/evidence/review/list composition. Their existence is reuse context, not current mounted proof.
- `accrue_admin/lib/accrue_admin/components/global_search.ex` plus `accrue_admin/assets/js/hooks/command_palette.js` own existing grouped scoped search, async partial failures, keyboard selection and focus. The hook currently changes `activeIndex` on Arrow keys and resets it on updates; pointer hover is not reconciled in that hook. Confirm actual mounted pointer/keyboard/activation behavior before choosing the smallest repair and correct semantics.
- `accrue_admin/lib/accrue_admin/copy.ex` and `copy/billing_event.ex`, `copy/promotion_code.ex`, `copy/connect.ex`, `copy/locked.ex` are presentation/copy owners. `webhooks_live.ex` currently passes `row_label={{"event", "events"}}` while delivery-oriented result/replay copy is already present.

### Established Patterns and Integration Points

- Existing production investigation owners are `accrue_admin/lib/accrue_admin/live/events_live.ex`, `event_live.ex`, `webhooks_live.ex` and `webhook_live.ex`. Event and promotion-code detail source shows family breadcrumbs, related resources and familiar lazy evidence disclosure. Keep failure/uncertainty visible and avoid manufacturing activity.
- Catalog/Connect owners are `accrue_admin/lib/accrue_admin/live/coupons_live.ex`, `coupon_live.ex`, `promotion_codes_live.ex`, `promotion_code_live.ex`, `connect_accounts_live.ex` and `connect_account_live.ex`. Connect already distinguishes stored Stripe snapshots from local fee policy; preserve this boundary while improving composition/review.
- Destination decoders live in `accrue_admin/lib/accrue_admin/queries/events.ex`, `webhooks.ex`, `coupons.ex`, `promotion_codes.ex` and `connect_accounts.ex`. Observed examples are event search/type/actor/subject/source, webhook type/status/live mode, coupon search/validity, promotion-code search/active/parent and Connect search/type/readiness constraints. Planning must map full list/lens behavior and validation, not copy these examples as an exhaustive allowlist.
- `accrue_admin/lib/accrue_admin/live/dashboard_live.ex`, `components/app_shell.ex`, `sidebar.ex`, `topbar.ex` and `global_search.ex` are existing entry/navigation seams. Current Home and three search groups remain in scope; no new navigation taxonomy is needed.
- Cheap semantic proof owners include `accrue_admin/test/accrue_admin/scoped_path_test.exs`, the existing query tests, route-specific LiveView tests, `live/webhook_replay_test.exs`, `components/global_search_test.exs`, Copy tests and `accrue_admin/test/js/`. Map exact commands and focused controls in phase research/planning.
- Existing browser owners include `accrue_admin/e2e/admin-page-flow-phase191.spec.js`, `admin-interaction-overlay-phase199.spec.js`, `examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js` and `phase234-search-completion.spec.js`. Old passing evidence does not prove newly changed consumer behavior. Reuse authoritative mutation/job/dispatch/state observations in disposable fixtures.
- Host `/admin` is Admin, host `/billing` is Portal, and package fixture `/billing` is Admin. `mix accrue_admin.assets.build`, host compile and current served hashes establish freshness; host watchers and archived captures alone do not.

### Evidence Boundary of This Discussion

This pass loaded the approved context, performed a lightweight source scout, loaded Impeccable context and checked three focused primary references. No product code was edited, app started, fixture mutated, test or browser capture run, live provider consulted or remote CI observed. Findings above are source/planning evidence. Execution must confirm current served presentation and exercise the claimed behavior.
</code_context>

<specifics>
## Specific Ideas

Representative existing jobs to plan: filtered billing events → event → source delivery/subject; filtered failed deliveries → selected replay review → truthful result → bounded list return; filtered coupons → discount → related code → explicit parent; Connect account → local fee review/correction → policy result; Home → scoped search → pointer movement → Arrow key → Enter → exact record.

Reuse the Phase 241 lessons: verify result membership and label/destination agreement, observe real dispatch/state rather than transport absence, measure effective styles, and apply/measure text stress atomically so LiveView replacement cannot invalidate the baseline. Preserve recorded browser failures and isolated confirmations honestly. Do not reset the bounded visual budget or revive paid scoring.
</specifics>

<deferred>
## Deferred Ideas

Final complete selected Linux golden/mask review and stable Fake preview handoff belong to Phase 243. Portal cleanup, new diagnosis/causality/rooms, expanded search or catalog/Connect capabilities, new provider/freshness controls, arbitrary detail-origin stacks, scroll/pagination/search-state persistence, rebrand/framework/dependency migration, paid AI ratchet, CI redesign, release publication and unrelated historical debt remain outside this milestone. No new backlog item was promoted or invented by this discussion.
</deferred>

---

*Phase: 242-investigations-and-remaining-admin-surfaces*
*Context gathered: 2026-10-10*
