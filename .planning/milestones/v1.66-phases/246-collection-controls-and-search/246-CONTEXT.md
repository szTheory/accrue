# Phase 246: Collection Controls and Search - Context

**Gathered:** 2026-10-11
**Status:** Ready for planning
**Mode:** Automatic single pass; owner approved continuation and recommended choices.

<domain>
## Phase Boundary
Deliver FILTER-01, FILTER-02, FILTER-03, SEARCH-01 and TABLE-01 on existing Admin collections and global billing search. Refine shared controls, representation of URL/query state, table reading order and responsive geometry. Preserve authorization, owner scope, existing query capabilities, pagination and exact billing evidence. Detail/timestamp/analytics semantics remain Phase 247; reproducible scenario and integrated proof remain Phase 248.
</domain>

<decisions>
## Implementation Decisions
### One coherent collection region
- **D-01:** Keep stable page identity above a compact shared collection region: view choice, general search and labeled primary criteria; secondary criteria may use an explicit Filters disclosure. Applied constraints and result count sit close to results. Remove the large duplicate Filters card and repeated resets. View/navigation links are not active filter chips.
- **D-02:** Use compact native selects for multiple categorical dimensions (especially Connect charges, payouts, account type, details and authorization). Visible labels distinguish similar All/Enabled/Disabled choices. Reserve segmented radios for genuinely small mutually exclusive choices; avoid five wrapping segmented groups.
- **D-03:** Genuine active chips have an X removal affordance with explicit accessible name, keyboard focus and touch target. Keep one predictable reset-all action. Clear/remove preserve owner scope and unrelated constraints. Distinguish all-results count, current filtered count and paginated visible count; do not fabricate totals.
### Status and search truth
- **D-04:** Existing multi-status invoice/subscription queues need a shared labeled checkbox selection pattern representing combinations rather than showing All. Within status use OR, across criteria AND. Controls, canonical URL, query, selected chips and rows agree. Default queues, All, direct URL, remove-one and back/forward must be tested together.
- **D-05:** Correct Coupons All/Valid disagreement and other selected-versus-focused styles at their owning state logic. A focus outline must not appear as a second selection. Preserve search and organization scope during transitions.
- **D-06:** A single general search advertises only actual predicates. Do not silently broaden backend matching or drop exact relationship filters to make the toolbar simpler. Place distinct exact Customer/Coupon/Source webhook criteria in secondary filters, named precisely; consolidate only truly equivalent entry points. Preserve host-defined account types and unknown event keys. Prefer native selects or existing suggestions for finite categories; do not replace unbounded/custom values with incomplete hard-coded enums.
### Global billing search
- **D-07:** Replace the nested, two-line lookup trigger with one compact search affordance reflecting customers/invoices/subscriptions and its shortcut. Give the dialog concise orientation, balanced padding, compact readable result groups and a subordinate keyboard footer. Remove internal “scoped list” language and excessive initial guidance.
- **D-08:** One active result governs pointer, keyboard, ARIA and Enter activation. Pointer movement can update that active target; stationary hover must not produce a second selected style after keyboard movement. Preserve input focus, focus containment/return, async generation/owner checks, successful-group retention and retry semantics.
- **D-09:** Loading is visible only while a current request is pending; hidden must win in served CSS. Use a deliberately sized existing spinner with reduced-motion support and a meaningful accessible loading state. No dependency is needed.
### Shared table reading
- **D-10:** Separate primary readable identity from secondary exact identifier through shared cell layout. Prevent concatenation and long unbroken content from displacing status, money and dates. Full identifiers remain accessible and copyable; use existing copy infrastructure where available. Avoid giant rows, arbitrary wide identity columns and crowded edges.
- **D-11:** Order columns by the actual investigation task: recognizable record/customer, significant state, money, relevant timing; secondary ownership/tax/technical facts get explicit labels and suitable priority. Preserve data semantics rather than inventing fee/plan status; Phase 247 owns those semantic corrections. State pills remain concise and restrained, and compound state descriptions do not become paragraphs in pills.
- **D-12:** Fix shared empty-state title/body/action grouping and common spacing at the shared owner. Maintain recovery actions and truthful distinctions between filtered zero, absent records and unavailable reads. Shared fixes must apply to representative consumers plus explicit exceptions; avoid page-local CSS repairs.
### Acceptance and stopping rule
- **D-13:** Use existing components/tokens, query owners, LiveView/Node tests and mounted host/browser checks. No new dependency, redesign or migration. Establish a UI design contract before source changes. Use one batched rendered review, one corrective batch and one confirmation for a coherent slice; further iteration requires a named defect.
- **D-14:** Exercise URL/control/query/result agreement and actual mounted interactions, not handler-only or string assertions. Include narrow/wide, light/dark, long name/ID, keyboard/pointer and scope-preserving reset representatives. Bind rendered evidence to changed source and served assets. Keep Phase 245 baseline immutable; write new evidence separately. Optional DOM metadata must be read without waiting for absent elements; wait for LiveView connection before hook interactions.
### Agent discretion
Choose exact control layout, secondary-filter disclosure and sensible column widths using these rules and the existing Accrue identity. Auto-follow recommended choices. Stop only for a genuine new scope fork or external irreversible action. No repeat owner approval is needed.
</decisions>

<canonical_refs>
## Canonical References
- `.planning/notes/2026-10-11-admin-owner-feedback.md` — all concrete owner feedback and cross-project lessons; do not reduce to generic polish.
- `.planning/REQUIREMENTS.md` and `.planning/ROADMAP.md` — approved phase ownership and observable acceptance.
- `.planning/phases/245-rendered-baseline-and-realistic-preview/245-FINDINGS.md` — shared findings and all 13 detailed owner-topic dispositions.
- `.planning/phases/245-rendered-baseline-and-realistic-preview/245-COVERAGE.md` and `captures/manifest.json` in that directory — actual baseline and explicit limits.
- `.planning/phases/245-rendered-baseline-and-realistic-preview/245-UI-REVIEW.md` — bounded visual assessment.
- `PRODUCT.md` — personas, host ownership, truthful billing state and accessibility.
- `accrue_admin/lib/accrue_admin/components/data_table.ex` and `filter_chip_bar.ex` in that directory — current repeated collection owners.
- `accrue_admin/lib/accrue_admin/components/global_search.ex` and `accrue_admin/assets/js/hooks/command_palette.js` — search ownership and preserved async/focus contracts.
- `examples/accrue_host/README.md` — supported ordinary host; retain protected Phase 243 preview.
</canonical_refs>

<code_context>
## Existing Code Insights
DataTable.filter_toolbar currently hides all field labels, provides select/segmented inputs and keeps unsupported defined filter params as hidden fields. FilterChipBar mixes navigation and constraints, defaults active=true and renders Clear links with optional noncompact Filters framing. CommandPalette already tracks one activeIndex and pointermove; separate CSS hover is a likely second-highlight owner. EmptyState has separate title/copy/actions classes, so grouping belongs in shared CSS. Per-page query and filter declarations own supported predicates and URL state. Existing inline_id/clipboard/status components and shared table CSS supply reusable owners. No codebase map is present; these concrete sources were scouted directly.
</code_context>

<specifics>
## Specific Ideas
Connect's unlabeled paired Enabled filters, Coupons All/Valid mismatch, invoice open/uncollectible and subscription past_due/canceling combinations, duplicate Customer ID fields, tiny idle spinner and two active search results are named correctness/interaction targets. Ordinary preview is now separate from boundary fixtures; continue exercising long names in tests even though ordinary captures use plausible names. Preserve exact technical evidence while making scan language natural.
</specifics>

<deferred>
## Deferred Ideas
Timestamp local-display/UTC-copy convention, global destination naming/breadcrumb changes, fee/history/plan evidence semantics, webhook replay/payload/disclosure hierarchy and recovery metrics: Phase 247. Scenario tooling and full owner finding/evidence reconciliation: Phase 248. No production scenario picker, new billing capability, Portal changes or remote tags.
</deferred>
