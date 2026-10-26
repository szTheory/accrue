---
phase: "242"
slug: "investigations-and-remaining-admin-surfaces"
status: draft
shadcn_initialized: false
preset: none
created: "2026-10-10"
---

# Phase 242 — UI Design Contract

> Contract for the existing Events, Webhook Deliveries, Coupons, Promotion Codes, Connect, Home, navigation, and global search surfaces. This phase refines the established Admin product; it does not add a capability or replace its visual system.

## Design System

| Property | Value |
|----------|-------|
| Tool | Manual, package-owned Accrue Admin system; no shadcn |
| Preset | Not applicable |
| Component library | Existing `AccrueAdmin.Components` and Phoenix LiveView components; no new component framework |
| Icon library | Existing inline Heroicons via `AccrueAdmin.Components.Icon` |
| Font | Geist for interface text; Geist Mono for identifiers and technical values via `--ax-font-*` |

Operate mode, Cobalt identity, equal engineer and support/billing operator audiences, package-owned `--ax-*` roles, and the existing composition are locked by Phase 242 D-01/D-17 and the Phase 233 `DESIGN.md`. Phase 240 and 241 contracts carry forward. Reuse the current list, detail, related-resource, disclosure, review, shell, and search compositions according to their roles. Do not rerun design initialization, introduce a palette/font/framework/motion dependency, restyle Portal, or treat source candidates as freshly observed defects.

## Component Inventory

Enumerated by `find accrue_admin/lib/accrue_admin/components -maxdepth 1 -type f -name '*.ex' | wc -l` — 43 components — `accrue_admin`@1.6.0 — 2026-10-10.

This is the local component module set, not a closed allowlist. Inspect public functions and mounted behavior before choosing a component; existing modules below are known-good starting points.

| Component | Import path | Notes |
|-----------|-------------|-------|
| App shell / sidebar / topbar | `AccrueAdmin.Components.AppShell`, `.Sidebar`, `.Topbar` | Keep current static navigation, owner scope and shell geometry |
| Page header | `AccrueAdmin.Components.PageHeader` | Resource identity, current owner and task heading |
| Data table | `AccrueAdmin.Components.DataTable` | Use for comparison collections; retain record identity and actions at narrow widths |
| Detail | `AccrueAdmin.Components.Detail` | Grouped facts and section hierarchy |
| Related resources | `AccrueAdmin.Components.RelatedResources` | Accurate source/subject and coupon/code/parent links |
| JSON viewer / timeline | `AccrueAdmin.Components.JsonViewer`, `.Timeline` | Lazy exact evidence and observed activity; do not substitute for routine facts |
| Detail drawer / overlay | `AccrueAdmin.Components.DetailDrawer`, `.Overlay` | Existing focused review and keyboard/focus behavior |
| Button / input / select | `AccrueAdmin.Components.Button`, `.Input`, `.Select` | Preserve existing control semantics and appropriate hit geometry |
| Empty state / status badge | `AccrueAdmin.Components.EmptyState`, `.StatusBadge` | Distinguish no data, no match, unavailable and actual status with visible labels |
| Icon | `AccrueAdmin.Components.Icon` | Existing inline Heroicons; decorative icons do not supply names |
| Global search | `AccrueAdmin.Components.GlobalSearch` | Existing bounded Customers, Invoices and Subscriptions groups only |

## Phase 242 Surface Contract

The scan order for each investigation/detail/review is **resource identity and current scope → observed facts and material failure/uncertainty → supported next action → related evidence**. Keep the selected lens, active actionable filters, result membership, important blockers and exact review target visible. Do not impose a universal card, table, or column pattern.

| Surface | Primary visual anchor in the incumbent composition | Required hierarchy and interaction |
|---------|-----------------------------------------------|------------------------------------|
| Events list/detail | List: existing page heading/stat strip above the event table. Detail: event type in the existing summary card, followed by the event facts. | Label the append-only local billing event as an **event**. Keep actor, subject, exact type, source delivery, timestamp and material processing facts in the primary read path. Event → source delivery and subject links retain exact identity and authorized scope. Lazy Activity and Event payload disclosure remain discoverable; no absent activity or causal link is invented. Return labels name `Events` and restore only actual supported filter meanings. |
| Webhook delivery list/detail/replay | List: existing page heading and delivery table. Detail: delivery identity/summary followed by attempt and dispatch lifecycle facts. Replay review: existing review surface headed by its exact target and consequence. | Use **webhook delivery/deliveries** for selection, row counts and review; processing attempts, resulting billing events and a queued replay are distinct observations. Keep material failure, uncertainty, eligibility and diagnostics visible without opening raw JSON. Existing inline single/bulk replay review names the exact delivery or selected delivery set, owner, current eligibility, consequence and locked audit wording. Selection or fresh scope/eligibility/material-state change cannot silently change the set. Dismissal returns without dispatch. Results say only what evidence establishes: queued/accepted, skipped/ineligible, denied, failed or unknown; acceptance is not processing success or payment. Do not invite blind retry after acceptance when reread fails. |
| Coupon / promotion-code list and detail | Lists: existing heading/stat strip and family-specific table. Details: existing record summary card and its exact coupon/code identity; keep the linked parent/child facts next in the read path. | Distinguish a discount definition (**coupon**) from the customer-facing **promotion code** referring to it. Show code identity, parent, validity/activity, expiry, redemption bounds and provider restrictions when known. Preserve relevant coupon ↔ code relationships and exact parent identity. Missing/inaccessible parent is stated as unavailable and never linked to a plausible unrelated record; missing/unknown restriction is not described as unlimited. No catalog create/edit action is implied. Return labels identify the list family and retain only its validated active query/filter/parent constraint. |
| Connect list/detail/platform-fee review | List: existing heading/stat strip and connected-account table. Detail: connected account identity in its existing summary card. Fee review: existing drawer title, account target and fee preview/policy facts. | Lead with connected account and owner identity. Readiness, capability and requirements are the last stored Stripe observation; preserve the current statement that the page does not track when Stripe last reported them. Do not imply a report timestamp, live readiness, or provider change. Keep local platform-fee policy explicitly separate. The existing review is self-contained: exact account/owner, current local policy, proposed override or default consequence, exact amount/percentage semantics, validation result and observation limits. Preserve fresh target/policy/actor checks, step-up, duplicate protection, correction, dismissal without save, associated errors and focus return. |
| Home / static navigation | Home: existing page heading and current summary composition. Navigation: current selected owner and active destination in the existing sidebar. | Keep the current Home and familiar static navigation. Route, selected owner and visible destinations agree across Home, sidebar and breadcrumbs. Do not rebuild Home metrics or add navigation families. |
| Global search | Existing search dialog input followed directly by its grouped result list. | Keep existing Customers, Invoices and Subscriptions result groups (maximum five per group). Preserve result identity, real scoped links, current owner, focus containment/restoration and partial-group recovery. There is one authoritative active result: pointer hover/movement, Arrow Up/Down, async query completion, LiveView replacement and owner change produce the same visible active result and Enter destination. Use semantics suitable to the actual link/list widget; never add `aria-selected` to arbitrary links. A stale query/generation/owner response cannot become current. Search remains an immediate task; no query persistence claim is introduced. |

For all list-to-detail routes, the return link is a validated, family-specific destination/label pair: Events, Webhook Deliveries, Coupons, Promotion Codes or Connect. Direct and malformed entry uses that family's safe owner-scoped list fallback; structural breadcrumbs remain distinct from contextual result return. Preserve only keys that the destination currently decodes and actually consumes (owner, supported search/filter/lens and relevant relationship constraint; sorting only where already supported). No promise is made for pagination, accumulated rows, scroll restoration, or arbitrary nested return stacks. External, malformed/ambiguous, other-mount and unauthorized routes fail closed under existing `ScopedPath` and freshly resolved owner scope; caller parameters never select an owner.

## Spacing Scale

Use the installed `theme.css` roles and hierarchy. The 4px ladder is the task/layout scale; do not migrate or create a parallel scale.

| Token | Value | Usage |
|-------|-------|-------|
| `--ax-space-xs` | 4px | Icon gaps and small inline spacing |
| `--ax-space-sm` | 8px | Compact controls and related metadata |
| `--ax-space-md` | 16px | Default fact/control spacing |
| `--ax-space-lg` | 24px | Section separation |
| `--ax-space-xl` | 32px | Major task-group/layout gaps |
| `--ax-space-2xl` | 48px | Existing large page separation |
| `--ax-space-3xl` | 64px | Existing page-level separation |
| `--ax-space-2xs` | 2px | Deliberate dense table/data detail only |

Exceptions: 1px structural borders/rules; 2px dense data spacing. Neither exception replaces task or section separation. Retain existing 44px target direction for frequently activated standalone task buttons and icon controls, including intermediate-width coarse-pointer use; judge actual hit bounds in mounted built/served output. Dense inline links can remain compact when they remain separated and operable.

## Typography

Use existing composed roles, two weights only (400 and 600), and Geist/Geist Mono assignment. This table names the four primary phase roles; secondary metadata and mono technical roles remain existing, documented exceptions rather than a new scale.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 16px | 400 | 1.4 |
| Label | 14px | 600 | 1.4 |
| Section heading | 20px | 600 | 1.2 |
| Page heading | 28px | 600 | 1.2 |

Existing secondary body is 14px/400/1.4; eyebrow/metadata is 12px/600/1.4; large title is 24px/600/1.2. Geist Mono is 14px or 12px/400/1.4 for IDs, processor keys and technical payloads only, never prose. Preserve exact IDs and diagnostics with wrapping or deliberate disclosure; do not clip them or let metadata outrank record identity.

## Color

The 60/30/10 split is a compositional guide, not a measured pixel requirement. Resolve colors through theme-aware tokens and verify effective computed foreground/background in Light, Dark, System and any host-forced theme.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `--ax-base` (`--accrue-paper`, light `#FAFBFC`) | Page and broad neutral surfaces |
| Secondary (30%) | `--ax-elevated`, `--ax-sunken`, `--ax-border` | Grouped facts, panels, navigation and separation |
| Accent (10%) | `--ax-accent` / `--ax-accent-strong` (Cobalt; `--accrue-cobalt: #5D79F6`) | One primary task action, selected/current state and meaningful links |
| Destructive | `--ax-danger` / `--ax-danger-readable` | Destructive action and its consequence only |

Accent reserved for: one primary action in a local task group, current/selected lens or navigation, and purposeful inline links. Status uses intent tokens (`success`, `warning`, `danger`, `info`, `neutral`) with a readable visible label and never color alone. Use actual effective token values for contrast and focus; do not hard-code light-only colors in components.

## Copywriting Contract

Use incumbent `AccrueAdmin.Copy` families and exact diagnostic/provider names. Phase 242 D-16 locks **payment/Payments** for routine operator language, **Charge** only where exact model/API evidence requires it, distinct **event** vs **delivery**, human collection-method labels instead of raw enums, and review dismissal wording that cannot be mistaken for domain cancellation. Preserve `Copy.Locked` and all legal, audit, replay, diagnostic and provider meaning verbatim. The following are existing faithful strings, not proposals to replace them:

| Element | Copy |
|---------|------|
| Primary CTA | `View event`, `View webhook delivery`, `View coupon`, `View promotion code`, `View connected account`; use the resource-specific existing action for the actual row/relation. Review primary actions retain their exact existing action verb. |
| Events first-run empty | Heading: `No billing events yet.` Body: `Events appear when billing state changes are recorded.` |
| Events filtered empty | Heading: `No ledger rows match these filters.` Body: `Clear filters or adjust actor and source filters to see ledger rows.` |
| Webhook delivery first-run empty | `No webhook deliveries yet.` / `Deliveries appear after signed processor events are recorded.` |
| Coupon first-run empty | `No coupons yet.` / `Coupons appear after discount definitions sync locally.` Source: `accrue_admin/lib/accrue_admin/copy/coupon.ex` (`coupons_list_first_run_empty_title/body`; also `copy.ex` resource state `:coupons, :first_run_empty`). |
| Promotion-code first-run empty | `No promotion codes yet.` / `Codes appear after customer-facing discounts sync locally.` Source: `accrue_admin/lib/accrue_admin/copy/promotion_code.ex` (`promotion_codes_list_first_run_empty_title/body`; also `copy.ex` resource state `:promotion_codes, :first_run_empty`). |
| Connect first-run empty | `No connected accounts yet.` / `Accounts appear after onboarding starts.` Source: `accrue_admin/lib/accrue_admin/copy/connect.ex` (`connect_accounts_list_first_run_empty_title/body`; also `copy.ex` resource state `:connect_accounts, :first_run_empty`). |
| Webhook delivery filtered empty | `No webhook deliveries match these filters.` / `Clear filters or adjust status and type filters to see deliveries.` |
| Coupon / promotion-code filtered empty | `No coupons match these filters.` / `Clear filters or adjust the search to see coupons.`; `No promotion codes match these filters.` / `Clear filters or adjust the search to see promotion codes.` |
| Connect filtered empty | `No connected accounts match these filters.` / `Clear filters or adjust readiness filters to see connected accounts.` |
| Error state | Name the failed operation and established result, then offer only the supported safe next step. Preserve exact diagnostic details. Existing examples: `Event not found. Open the events list and confirm owner scope before retrying.` and `This Connect view failed to load. Retry from the Connect list; if it persists, inspect logs for the owner scope you selected.` An unavailable list/detail is never rendered as empty; partial evidence retains known facts and names missing evidence. |
| Search no match / unavailable group | Show no-match only when all current groups completed successfully; retain successful groups when another is unavailable. Retry targets only unavailable lookups. Do not claim global no-results when a group failed. |
| Replay review/dismissal | Preserve all exact strings in `AccrueAdmin.Copy.Locked`, including `Confirm webhook replay`, owner-bound confirmation and audit consequence, and blocked/step-up text. Dismissal states return to the delivery record; it never dispatches. |
| Fee review | Use the existing `Edit platform fee override` and `Save platform fee override` labels with exact account, local policy and proposed/default consequence. Dismissal returns to the connected account without saving. Keep exact validation and associated errors; do not imply Stripe readiness changed. |
| Destructive confirmation | No new destructive action is approved in this phase. Existing action-specific replay/fee review stays explicit and self-contained; never substitute generic `Cancel` or `Confirm` for its actual verb and target. |

Routine procedural narration may be shortened only if its fact, scope, consequence and exact legal/audit/provider meaning remain intact. Do not expose a raw collection enum as routine copy. No missing parent, unknown limit, absent activity, missing timestamp, zero amount, empty result, enqueue acknowledgement or unavailable observation may imply unrestricted, healthy, completed or current state.

## Responsive, Accessibility and Evidence Contract

- Keep essential identity, scope, facts, filters, selected result, diagnostics and supported actions usable at 320 CSS px, around existing intermediate breakpoints, and desktop widths. Ordinary content has no page-level horizontal scrolling; a genuinely two-dimensional comparison table can scroll in its own labeled region while preserving record identity/action access.
- Check intermediate/tablet coarse pointer independently of viewport size. Frequently activated standalone actions follow existing 44px target direction; measure clickable geometry, not height declarations. Preserve visible focus, meaningful headings, labels and programmatic association of field errors/status messages. Status remains understandable without color.
- Exercise pointer movement → Arrow navigation → Enter on the same search item, plus query completion, rerender, scope changes and unavailable-group retry. Assert active styling, appropriate accessible state and actual activated link agree. Confirm focus containment and logical restoration for search/replay/fee overlays and disclosure expanded state. Busy controls retain their real action label and disabled state through LiveView patch/reconnect; no reconnect dispatches a mutation. Repeated keyboard search stays immediate; honor reduced motion and ensure inactive overlays do not intercept focus/input.
- Cover first-run empty, queue-empty, filtered no-match, loading, populated, partial, unavailable, retry, denied/unsupported, stale review, pending, accepted/queued, skipped, failed and unknown as applicable. Each keeps the evidence-specific recovery path; no invented successful/healthy state. Include zero/one/many, long identifiers/names/diagnostics and missing source/subject/parent observations.
- Validate scoped result membership and return-label/path agreement against the destination's actual decoder. Validate replay selection/result counts and fee review target/consequence against authoritative state, dispatch/audit and authorization boundaries; a page non-GET count is not proof that no mutation occurred.
- Inspect changed surfaces as one bounded batch after a complete package build: desktop and narrow, effective themes, focus/busy/reconnect/disclosure, and responsive/coarse-pointer cases. Allow one corrective batch and at most one confirmation inspection. Record source, fixture, built/compiled and served asset provenance separately from exercised behavior. Current historical captures/source candidates are not fresh mounted defects. Physical browser zoom/device and speech-only testing, actual provider behavior and remote checks are reported only where genuinely observed; do not claim human UAT. Final Linux golden closure and feedback preview belong to Phase 243.

Named surfaces for the parent UI-consideration probe: Events collection/detail; Webhook Deliveries collection/detail/replay review; Coupons collection/detail; Promotion Codes collection/detail; Connect collection/account/fee review; Home and static navigation; Global Search dialog/results. The required probe-generated `## UI Considerations` state table is intentionally left to the orchestrator's deterministic post-verification probe; it is not authored in this contract.

## UI Considerations

Compiled `ui-consideration-probe.cjs` ran after independent approval on six authored surface descriptions. Delegated kind review used actual collection, form, navigation, control and static-content kinds, rather than treating heuristic cue matches as exhaustive. All **44 applicable items are resolved with explicit acceptance criteria; 0 backstop, 0 unresolved, 0 unclassified**. These are specified acceptance predicates, not executed proof. Empty/error wording remains in Copywriting Contract; domain safety/focus/state and evidence limits remain above.

| Item | Status | Verification | Acceptance criterion |
|---|---|---|---|
| E1/empty | resolved | explicit | Events list/detail: Zero records and filtered no-match have the distinct resource-specific Copy states; an unfilled applicable input has its required-field state. No unknown read is shown as zero. |
| E1/loading | resolved | explicit | Events list/detail: In-flight reads retain loading until current completion; a pending mutation retains its action name and disabled state through patches/reconnect without another dispatch. |
| E1/error | resolved | explicit | Events list/detail: Read failure, unavailable relation, invalid input, stale/denied review and failed/unknown outcome render their actual state with only the supported safe next step; dismissal sends no action. |
| E1/populated | resolved | explicit | Events list/detail: Typical authorized fixtures display exact identities and actual filtered membership, observed facts and failures before actions and lazy evidence; pointer/Arrow/Enter activation matches the single active search link where applicable. |
| E1/partial | resolved | explicit | Events list/detail: Confirmed facts/results remain visible when evidence/group/parent/preview is unavailable; absence never becomes healthy, unrestricted, zero or successful processing. Retry targets only supported unavailable lookups. |
| E1/overflow | resolved | explicit | Events list/detail: At 320 CSS px, intermediate and desktop widths ordinary content has no page overflow; exact IDs, controls and focus remain reachable. Only a labeled two-dimensional table region may scroll locally. |
| E1/zero-one-many | resolved | explicit | Events list/detail: Zero/one/many fixtures retain accurate resource nouns/counts, actual authorized membership, stable identity/action access and distinct empty/populated states; search remains bounded to five per existing group. |
| E1/long-text | resolved | explicit | Events list/detail: Long labels, names, IDs and diagnostics wrap or have full disclosure without hiding target, consequence, focus or actions under narrow layout, 200% text enlargement and text-spacing stress measured atomically. |
| E2/empty | resolved | explicit | Webhook deliveries and replay: Zero records and filtered no-match have the distinct resource-specific Copy states; an unfilled applicable input has its required-field state. No unknown read is shown as zero. |
| E2/loading | resolved | explicit | Webhook deliveries and replay: In-flight reads retain loading until current completion; a pending mutation retains its action name and disabled state through patches/reconnect without another dispatch. |
| E2/error | resolved | explicit | Webhook deliveries and replay: Read failure, unavailable relation, invalid input, stale/denied review and failed/unknown outcome render their actual state with only the supported safe next step; dismissal sends no action. |
| E2/populated | resolved | explicit | Webhook deliveries and replay: Typical authorized fixtures display exact identities and actual filtered membership, observed facts and failures before actions and lazy evidence; pointer/Arrow/Enter activation matches the single active search link where applicable. |
| E2/partial | resolved | explicit | Webhook deliveries and replay: Confirmed facts/results remain visible when evidence/group/parent/preview is unavailable; absence never becomes healthy, unrestricted, zero or successful processing. Retry targets only supported unavailable lookups. |
| E2/overflow | resolved | explicit | Webhook deliveries and replay: At 320 CSS px, intermediate and desktop widths ordinary content has no page overflow; exact IDs, controls and focus remain reachable. Only a labeled two-dimensional table region may scroll locally. |
| E2/zero-one-many | resolved | explicit | Webhook deliveries and replay: Zero/one/many fixtures retain accurate resource nouns/counts, actual authorized membership, stable identity/action access and distinct empty/populated states; search remains bounded to five per existing group. |
| E2/long-text | resolved | explicit | Webhook deliveries and replay: Long labels, names, IDs and diagnostics wrap or have full disclosure without hiding target, consequence, focus or actions under narrow layout, 200% text enlargement and text-spacing stress measured atomically. |
| E3/empty | resolved | explicit | Coupons and promotion codes: Zero records and filtered no-match have the distinct resource-specific Copy states; an unfilled applicable input has its required-field state. No unknown read is shown as zero. |
| E3/loading | resolved | explicit | Coupons and promotion codes: In-flight reads retain loading until current completion; a pending mutation retains its action name and disabled state through patches/reconnect without another dispatch. |
| E3/error | resolved | explicit | Coupons and promotion codes: Read failure, unavailable relation, invalid input, stale/denied review and failed/unknown outcome render their actual state with only the supported safe next step; dismissal sends no action. |
| E3/populated | resolved | explicit | Coupons and promotion codes: Typical authorized fixtures display exact identities and actual filtered membership, observed facts and failures before actions and lazy evidence; pointer/Arrow/Enter activation matches the single active search link where applicable. |
| E3/partial | resolved | explicit | Coupons and promotion codes: Confirmed facts/results remain visible when evidence/group/parent/preview is unavailable; absence never becomes healthy, unrestricted, zero or successful processing. Retry targets only supported unavailable lookups. |
| E3/overflow | resolved | explicit | Coupons and promotion codes: At 320 CSS px, intermediate and desktop widths ordinary content has no page overflow; exact IDs, controls and focus remain reachable. Only a labeled two-dimensional table region may scroll locally. |
| E3/zero-one-many | resolved | explicit | Coupons and promotion codes: Zero/one/many fixtures retain accurate resource nouns/counts, actual authorized membership, stable identity/action access and distinct empty/populated states; search remains bounded to five per existing group. |
| E3/long-text | resolved | explicit | Coupons and promotion codes: Long labels, names, IDs and diagnostics wrap or have full disclosure without hiding target, consequence, focus or actions under narrow layout, 200% text enlargement and text-spacing stress measured atomically. |
| E4/empty | resolved | explicit | Connect and fee review: Zero records and filtered no-match have the distinct resource-specific Copy states; an unfilled applicable input has its required-field state. No unknown read is shown as zero. |
| E4/loading | resolved | explicit | Connect and fee review: In-flight reads retain loading until current completion; a pending mutation retains its action name and disabled state through patches/reconnect without another dispatch. |
| E4/error | resolved | explicit | Connect and fee review: Read failure, unavailable relation, invalid input, stale/denied review and failed/unknown outcome render their actual state with only the supported safe next step; dismissal sends no action. |
| E4/populated | resolved | explicit | Connect and fee review: Typical authorized fixtures display exact identities and actual filtered membership, observed facts and failures before actions and lazy evidence; pointer/Arrow/Enter activation matches the single active search link where applicable. |
| E4/partial | resolved | explicit | Connect and fee review: Confirmed facts/results remain visible when evidence/group/parent/preview is unavailable; absence never becomes healthy, unrestricted, zero or successful processing. Retry targets only supported unavailable lookups. |
| E4/overflow | resolved | explicit | Connect and fee review: At 320 CSS px, intermediate and desktop widths ordinary content has no page overflow; exact IDs, controls and focus remain reachable. Only a labeled two-dimensional table region may scroll locally. |
| E4/zero-one-many | resolved | explicit | Connect and fee review: Zero/one/many fixtures retain accurate resource nouns/counts, actual authorized membership, stable identity/action access and distinct empty/populated states; search remains bounded to five per existing group. |
| E4/long-text | resolved | explicit | Connect and fee review: Long labels, names, IDs and diagnostics wrap or have full disclosure without hiding target, consequence, focus or actions under narrow layout, 200% text enlargement and text-spacing stress measured atomically. |
| E5/loading | resolved | explicit | Home/navigation: In-flight reads retain loading until current completion; a pending mutation retains its action name and disabled state through patches/reconnect without another dispatch. |
| E5/error | resolved | explicit | Home/navigation: Read failure, unavailable relation, invalid input, stale/denied review and failed/unknown outcome render their actual state with only the supported safe next step; dismissal sends no action. |
| E5/overflow | resolved | explicit | Home/navigation: At 320 CSS px, intermediate and desktop widths ordinary content has no page overflow; exact IDs, controls and focus remain reachable. Only a labeled two-dimensional table region may scroll locally. |
| E5/long-text | resolved | explicit | Home/navigation: Long labels, names, IDs and diagnostics wrap or have full disclosure without hiding target, consequence, focus or actions under narrow layout, 200% text enlargement and text-spacing stress measured atomically. |
| E6/empty | resolved | explicit | Global search: Zero records and filtered no-match have the distinct resource-specific Copy states; an unfilled applicable input has its required-field state. No unknown read is shown as zero. |
| E6/loading | resolved | explicit | Global search: In-flight reads retain loading until current completion; a pending mutation retains its action name and disabled state through patches/reconnect without another dispatch. |
| E6/error | resolved | explicit | Global search: Read failure, unavailable relation, invalid input, stale/denied review and failed/unknown outcome render their actual state with only the supported safe next step; dismissal sends no action. |
| E6/populated | resolved | explicit | Global search: Typical authorized fixtures display exact identities and actual filtered membership, observed facts and failures before actions and lazy evidence; pointer/Arrow/Enter activation matches the single active search link where applicable. |
| E6/partial | resolved | explicit | Global search: Confirmed facts/results remain visible when evidence/group/parent/preview is unavailable; absence never becomes healthy, unrestricted, zero or successful processing. Retry targets only supported unavailable lookups. |
| E6/overflow | resolved | explicit | Global search: At 320 CSS px, intermediate and desktop widths ordinary content has no page overflow; exact IDs, controls and focus remain reachable. Only a labeled two-dimensional table region may scroll locally. |
| E6/zero-one-many | resolved | explicit | Global search: Zero/one/many fixtures retain accurate resource nouns/counts, actual authorized membership, stable identity/action access and distinct empty/populated states; search remains bounded to five per existing group. |
| E6/long-text | resolved | explicit | Global search: Long labels, names, IDs and diagnostics wrap or have full disclosure without hiding target, consequence, focus or actions under narrow layout, 200% text enlargement and text-spacing stress measured atomically. |

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| No external component registry | None | Not applicable; no third-party registry or block is declared or introduced. |

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS

**Approval:** 2026-10-10 — independent rechecker approved all seven dimensions after the first-run copy/anchor revision. A generic spacing block was corrected against explicit D-17 authority; no incumbent token migration. UI considerations were specified by the compiled probe after approval. Product execution and runtime evidence remain pending.
