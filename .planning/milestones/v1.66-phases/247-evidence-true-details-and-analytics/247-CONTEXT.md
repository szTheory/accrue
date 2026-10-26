# Phase 247: Evidence-True Details and Analytics - Context

**Gathered:** 2026-10-11
**Status:** Ready for planning
**Mode:** Auto; owner delegated recommendations and continuation. Decisions below are agent recommendations adopted under that authorization, not invented individual owner answers.

<domain>
## Phase Boundary
Operators can read, investigate and act on existing details and recovery data with consistent language and exact, appropriately qualified evidence. Covers TIME-01, LANG-02, STATE-02, DETAIL-01, DETAIL-02 and METRIC-01. Preserve billing behavior, provider semantics, authorization, owner scope, confirmations and step-up. No new billing capabilities, rooms, Portal work, rebrand, dependencies migration or broad redesign. Phase 246 collection controls/search and identity-copy baseline is complete; extend it without repeating that phase.
</domain>

<decisions>
## Implementation Decisions

### Time and trustworthy copying
- **D-01:** Default timestamp display to browser-local time with an explicit timezone; shared Local/UTC preference persists consistently across Admin. Before client formatting, server fallback is explicitly UTC. Use existing browser Intl APIs; add no dependency. Date-only values stay dates; analytics query windows remain UTC.
- **D-02:** Clicking or keyboard-activating an actual timestamp copies its exact ISO 8601 UTC instant, including available precision, regardless of display preference. Provide truthful accessible toast/status feedback only after clipboard success; failure offers a usable manual-copy fallback. Preserve 44px touch targets and keyboard focus. Missing timestamps are plain unavailable text, never a pretend copy control.

### Language, destinations and attention
- **D-03:** Match navigation, page names and breadcrumb destinations. Use concrete nouns such as Payments, Invoices, Webhooks and Payment recovery, qualified by actual task context. Collection names should not imply the only purpose is recovery. Breadcrumbs express real parent hierarchy; omit artificial Analytics or Dashboard roots when they are not actual parents. Webhook parent reads Webhooks, never Back to webhooks.
- **D-04:** Reserve semantic attention for demonstrated actionable conditions. Concise status labels have supporting detail nearby when needed. Missing payment method can merit attention; ordinary values need no success decoration. Absence of plan, fee, snapshot or history must not imply misconfiguration, pending work, failure or completion without evidence. Replace Signals/Billing signals with explicit field meanings. Essential explanations stay visible; help is supplemental and keyboard/touch-accessible.

### Detail hierarchy and actions
- **D-05:** Put page identity and concise status in the shared page header; remove redundant inspector eyebrow/card framing where it obscures the actual page. Prioritize observed problem/state and supported next action, then useful metadata, history and payload. Avoid repeating ID/status/timestamp in multiple blocks without investigative value. Exact keys and IDs remain accessible and copyable.
- **D-06:** Replay has one coherent action section with consistent naming and a short truthful explanation of effect and eligibility. Remove DLQ primitive and implementation narration. Preserve action-time authorization, current owner, step-up and confirmations; accepted/queued replay is not completed processing. No business logic weakening or new retry behavior.
- **D-07:** Activity and payload have obvious disclosure affordances and accessible expanded state; retain lazy behavior where it serves a purpose. Important state/actions are visible. Empty history reads as one coherent empty state, with distinct dispatch/billing subhistories only when that distinction helps. Tree/Raw are consistent tabs and Copy is a separate action; retain exact JSON, keyboard support and disclosure behavior.
- **D-08:** Extend shared detail metadata/copy patterns to other existing details and action reviews. A small Copy details action may copy an allowlisted plain-text investigation summary of visible IDs, exact UTC times and observed state. Exclude secrets and full raw payload by default; do not turn this into a new export feature. Owner and permission boundaries apply equally to summaries.

### Payment recovery analytics
- **D-09:** Group comparable metrics by currency and preserve available, actual zero, absent and unsupported currency distinctions. Never fill absent values with zero or invent an amount. Keep recurring monthly revenue definitions distinct from cash recovered and confirmed churn; retain current formulas and qualify their meaning.
- **D-10:** Definitions belong in concise body/help text, not oversized delta pills. Remove duplicated definitions and unsupported Money saved/Churned revenue claims. Align the UTC window selector with shared controls and deliberate spacing. Data coverage is informational, separate from the selected window; a coverage label must not disguise a link to cutoff-semantics documentation. Help must describe its destination.

### Shared implementation and proof
- **D-11:** Refine incumbent components/tokens first. Use Impeccable for critique, hierarchy and visual inspection; its scores or font preferences do not override owner direction. No new dependencies for formatting, clipboard or toasts. Exceptions require a concrete consumer reason. Avoid cosmetic loops after named defects are resolved.
- **D-12:** Bind each objective rule to the cheapest credible existing test owner. Cover local/UTC, exact copying, clipboard failure, missing evidence, authorization and accepted-versus-completed outcomes. Render representative detail/action/analytics pages populated at narrow/wide and light/dark; inspect actual images and served assets. Use one batched review, corrective batch and confirmation, reopen only for demonstrated defects. Do not recapture all Phase 245/246 images without a changed shared concern.

### Agent's Discretion
Exact component composition, concise final copy, placement of one time preference, restrained status tone, and test split are delegated. Choose supported behavior from source rather than inventing explanations. Research unresolved technical facts once and use existing owners.
</decisions>

<specifics>
## Specific Ideas
Owner rejected the lookup control, tiny spinner, dual hover/keyboard highlights, bulky filter cards, glued names/IDs, overlong pills, jargon, confusing breadcrumbs, hidden disclosure affordances, oversized payload controls and prose metric deltas. Phase 246 addressed collection/search issues; this phase owns detail/analytics manifestations. Owner wants exact timestamps copied in UTC with feedback, local display, readable investigation summaries, truthful replay language and useful information ordering for support/billing operators. Scrypath/Mailglass lessons: language follows observed state; exact technical evidence remains available; green proof stays attached to the revision tested.
</specifics>

<canonical_refs>
## Canonical References
Downstream agents MUST read these before planning or implementation.
- `.planning/notes/2026-10-11-admin-owner-feedback.md` — canonical detailed owner feedback and screenshots.
- `.planning/REQUIREMENTS.md` — six Phase 247 requirements and milestone scope.
- `.planning/ROADMAP.md` — phase goal, dependency and observable criteria.
- `.planning/PROJECT.md` — approved milestone and boundaries.
- `.planning/phases/245-rendered-baseline-and-realistic-preview/245-CONTEXT.md` — protected preview and realistic/held-out distinction.
- `.planning/phases/246-collection-controls-and-search/246-CONTEXT.md` — completed shared controls and identity conventions.
- `.planning/phases/246-collection-controls-and-search/246-VERIFICATION.md` — completed baseline, proof limits and current source identity.
- `.planning/phases/246-collection-controls-and-search/246-UI-SPEC.md` — incumbent shared design contract.
</canonical_refs>

<code_context>
## Existing Code Insights
### Reusable Assets
- `accrue_admin/lib/accrue_admin/components/detail.ex`: detail sections/fields, summary lists and summary-card header; improve shared composition rather than page-local overrides.
- `accrue_admin/lib/accrue_admin/components/breadcrumbs.ex`: native hierarchical navigation.
- `accrue_admin/lib/accrue_admin/components/kpi_card.ex`: delta/meta slots currently allow long prose to become pill-like decoration.
- `accrue_admin/lib/accrue_admin/components/json_viewer.ex`: preserve payload inspection while cleaning controls.
- Existing clipboard controls and ID badges already support exact copy and responsive unique IDs; reuse their ownership and preserve 44px targets.
### Integration Points
- `accrue_admin/lib/accrue_admin/live/webhook_live.ex`: header UTC facts; replay eligibility/actions; lazy Activity/Raw payload disclosures; exact audit/history. Current DLQ explanation requires plain language.
- `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex`: asynchronous scoped query, UTC bounds, per-currency pairs and unavailable states; correct presentation without changing query formulas.
- `accrue_admin/lib/accrue_admin/copy.ex` and copy modules own state-aware wording. AppShell owns navigation/preferences; JS hooks own client formatting/clipboard lifecycle.
</code_context>

<deferred>
## Deferred Ideas
- Phase 248 owns reproducible scenario selection outside production UI and integrated proof across the milestone.
- New billing actions, product scenario controls, broad data-model changes and unrelated font/redesign suggestions remain out of scope.
- Remote publishing/tagging is not authorized; keep GSD tags local. Original Phase 243 preview is protected.
</deferred>
