---
phase: "241"
slug: "billing-operator-journeys"
status: approved
shadcn_initialized: false
preset: none
created: "2026-10-09"
reviewed_at: "2026-10-09"
---

# Phase 241 — UI Design Contract

> Contract for bounded propagation across subscription, invoice, payment, customer payment-method and Recovery/campaign journeys. It inherits Phase 240 and the v1.63 shared Admin direction; it does not create a new system or capability.

## Design System

| Property | Value |
|----------|-------|
| Tool | Manual, package-owned Accrue Admin system; no shadcn |
| Preset | Not applicable; incumbent system is already initialized |
| Component library | Existing `AccrueAdmin.Components` and LiveView components; no new component framework |
| Icon library | Existing inline Heroicons through `AccrueAdmin.Components.Icon` |
| Font | Geist for interface text; Geist Mono for identifiers and technical values, via `--ax-font-*` |

Use Operate mode, Cobalt identity, the existing hierarchy and current package tokens. Do not initialize or migrate a design system, add a font/motion/UI dependency, alter Portal, or introduce new dashboard chrome. Admin owns these roles in `accrue_admin/assets/css/theme.css`. Phoenix LiveView remains at the installed package/host lock versions 1.1.31/1.1.32.

## Component Inventory

Enumerated by `find accrue_admin/lib/accrue_admin/components -maxdepth 1 -type f -name '*.ex' | wc -l` — 43 components — `accrue_admin`@1.6.0 — 2026-10-09.

This is the local package module inventory, not a closed allowlist. Confirm actual public functions and variants before using a component. Reuse the existing modules and route owners below; there is no installed third-party component registry.

| Component / surface | Import path | Phase 241 use |
|---------------------|-------------|---------------|
| App shell, page header, breadcrumbs | `AccrueAdmin.Components.AppShell`, `.PageHeader`, `.Breadcrumbs` | Stable shell, record identity, owner/scope and structural location |
| Detail, related resources, tabs | `AccrueAdmin.Components.Detail`, `.RelatedResources`, `.Tabs` | Subscription facts, one related-billing group and same-customer context |
| Data table, filter chips | `AccrueAdmin.Components.DataTable`, `.FilterChipBar` | Existing filtered invoice/payment/subscription collections and active filters |
| Button, input, select, overlay, drawer | `AccrueAdmin.Components.Button`, `.Input`, `.Select`, `.Overlay`, `.DetailDrawer` | Existing action input/review/dismissal patterns; preserve owners |
| Money formatter, status badge, inline ID | `AccrueAdmin.Components.MoneyFormatter`, `.StatusBadge`, `.InlineId` | Exact money/currency, readable states and discoverable identifiers |
| Empty state, theme picker, icon | `AccrueAdmin.Components.EmptyState`, `.ThemePicker`, `.Icon` | Explicit empty distinctions, effective theme choice, existing iconography |
| Window selector, timeline | `AccrueAdmin.Components.WindowSelector`, `.Timeline` | Recovery 7d/30d/90d selection and existing historical campaign evidence |
| Route surfaces | `AccrueAdmin.Live.SubscriptionLive`, `.InvoiceLive`, `.InvoicesLive`, `.CustomerLive`, `.ChargeLive`, `.Analytics.CampaignLive`, `.Analytics.RecoveryLive` | Journey owners to inventory/inspect if changed; source names do not imply mounted proof |

## Phase Task Hierarchy and Layout Contract

Scan in this order: **identity and owner/scope → current facts → supported next action → related billing/evidence**. The primary visual anchor is the record identity and current lifecycle/status block at the top of the detail; a review's anchor is its action, exact target and requested intent. This applies equally to engineering and support operators. Keep technical identifiers, diagnostics, audit evidence and payloads available through existing disclosure without competing with task facts.

| Surface | Required hierarchy and behavior |
|---------|---------------------------------|
| Subscription detail | Lead with customer/subscription identity and current owner, lifecycle state, exact confirmed plan/amount/currency/period/collection facts, material blockers or uncertainty, then the supported subscription action group. Follow with one visible secondary related-billing group and deeper evidence. Do not let owner-wide invoice rows dominate; do not require a duplicated embedded invoice preview. |
| Subscription invoice destinations | Provide a customer-scoped link whose actual destination is `customer_id` filtered; when `status=open` is retained, label it **Open invoices for this customer**. Provide the distinct broader link **All open invoices in current scope**, using the actual selected-owner wording where applicable. Global Admin scope is not “this customer” or “this owner.” Never imply subscription-only filtering or retain an ignored `subscription_id` promise. Subscription-local counts, customer-wide results and owner/scope queues remain distinct. |
| Filtered list → detail → return | Keep existing owner and supported filters/lenses visible as active collection context. Each detail return label and URL come from the same validated destination: **Back to invoices**, **Back to payments**, **Back to subscriptions**, **Back to customers**, **Back to customer invoices**, **Back to customer payments**, **Back to customer subscriptions**, or **Back to Recovery**. Keep structural breadcrumbs separate from contextual return links. |
| Campaign / Recovery | Direct entry, missing/invalid origin, or unrelated list origin returns to scoped **Recovery**. A valid Recovery origin retains only owner and `7d`, `30d`, or `90d` window. Breadcrumb and explicit return agree. A selected-window caption may orient the user; do not narrate raw URLs. Keep current subscription state distinct from historical campaign timeline; retaining a Recovery window does not claim that campaign history is filtered to it. Missing, empty, loading, unavailable observations stay distinct. `View subscription` remains a separate destination. |
| Subscription/refund/payment-method review | Use the invoice review's semantic arrangement inside current route owners. Show action and exact target, legible target ID, material customer and owner/scope, current relevant state, exact requested amount/currency where applicable, supported consequence and timing, blockers/uncertainty, and provider/observation limits together. Subscription review distinguishes immediate vs scheduled effect and includes only confirmed supported previews. Refund identifies payment and reviewed refund amount/currency. Payment-method review names the method/customer and supported default/removal consequence. Missing amount/preview is unavailable, never zero or estimate. |
| Review dismissal and result | Confirmation names the specific action (for example the current action-specific **Cancel subscription** verb). Dismissal is **Back to subscription**, **Back to payment**, or the matching record return and cannot dispatch a domain action; Escape also dismisses only. Preserve correction before submission, associated validation/status, overlay focus containment and logical focus restoration if the trigger is replaced. Outcomes say only **accepted**, **pending**, **completed**, **failed**, **denied**, or **unknown** as evidence supports; acceptance/update is not settlement. Keep supported evidence/next step visible and never invite a blind retry after uncertainty. |

### Shared interaction and visual rules

- Preserve the incumbent Cobalt/quiet-confidence hierarchy, established route families and Home. No universal table layout: use tables where comparison warrants them and existing record-card/reflow variants where needed.
- Accents belong to the primary action of each local task group, selected/current navigation or filter state, and purposeful links. Status uses intent tokens plus readable text; destructive color is for destructive actions and their consequence only. Check effective computed contrast in light, dark, system and host-forced cases.
- Frequently activated standalone actions/icons follow the incumbent 44px target direction, including tablet/coarse-pointer contexts. Measure hit geometry in served output. Dense inline links may stay compact if clearly separated and operable.
- Keyboard navigation has visible unobscured focus. Validation/result messages are visually and programmatically associated. Real busy labels/icons and disabled state persist through LiveView patches; reconnect does not unlock or replay a staged action. Dismissed overlays become inert immediately and restore focus logically.
- Preserve stored Light/Dark/System preference, effective styles, OS changes while System is selected, persistence, and host-forced precedence. Inspect each changed consumer under effective themes.
- Keep frequent keyboard work immediate. Use incumbent brief motion only for feedback/spatial orientation; honor reduced motion, with no decorative list/page stagger and no animated money/counts. Motion never carries result meaning.
- Preserve fresh authorization, current owner, target/material-state revalidation, step-up, capability and duplicate protections in their existing owners. Never turn a display/helper into a second billing policy owner.

### Supported return boundary

Reuse `ScopedPath` and each destination's actual decoder. Retain only enumerated supported meanings: fresh current owner, destination-supported search/status/customer/collection filters, lens, supported sort/direction, same-customer tab, and valid Recovery window. A decoded query-free local list is valid. Derive the visible return label from the same validated meaning as its destination; caller text never controls the label. Stay inside configured Admin mount and approved route family, rebuild using fresh scope, strip supplied owner/secrets/unsupported parameters, and require customer detail returns to match the loaded customer's ID. For an otherwise valid local origin, discard any supplied organization/owner and rebuild with the fresh current owner. Use the existing safe scoped fallback for external, scheme-relative, ambiguous, invalid-route, foreign-mount, or wrong-customer destinations. Do not classify an otherwise valid local origin as invalid merely because it carries a stale or foreign supplied owner. Do not promise arbitrary origin, nested return stack, ignored keys, pagination/accumulated rows, scroll position, or URL equality as proof of restoration. Browser Back remains browser history.

### Controlling authority for incumbent typography and spacing

Phase 240's approved incumbent role map and documented spacing exceptions govern this bounded propagation. D-16 and the Phase 240 ratified contract preserve the semantic font roles already in `theme.css`, including 12/14/16/20/24/28px interface roles and 12/14px mono technical roles, with weights 400 and 600; the 4px spacing ladder likewise retains its explicit 2px dense-data and 1px structural exceptions. Apply those exact role and exception boundaries when evaluating Phase 241 surfaces. A generic four-size ceiling or a blanket multiple-of-four check does not supersede these approved decisions; neither is a request to flatten or migrate the incumbent system. This records the controlling contract and does not claim that a prior checker passed.

## Spacing Scale

Use the package's 4px rhythm. The deliberate dense and structural exceptions remain local to their existing uses.

| Token | Value | Usage |
|-------|-------|-------|
| `--ax-space-xs` | 4px | Icon gaps and inline padding |
| `--ax-space-sm` | 8px | Compact element spacing |
| `--ax-space-md` | 16px | Default control and fact-group spacing |
| `--ax-space-lg` | 24px | Section separation |
| `--ax-space-xl` | 32px | Major layout/task-group gaps |
| `--ax-space-2xl` | 48px | Large page-level separation where already used |
| `--ax-space-3xl` | 64px | Page-level spacing where already used |
| `--ax-space-2xs` | 2px | Deliberate dense table/data detail only |

Exceptions: 1px structural borders/rules; 2px dense-data spacing only. Neither replaces task/section spacing. Do not reopen source candidates as cosmetic defects without current served-output confirmation.

## Typography

Preserve existing semantic roles rather than flattening the package's established scale. Exactly two weights are used: 400 and 600.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 16px | 400 | 1.4 |
| Label | 14px | 600 | 1.4 |
| Heading / section title | 20px | 600 | 1.2 |
| Display / page title | 28px | 600 | 1.2 |

Other incumbent roles remain valid: 14px/400 secondary body; 12px/600 eyebrow/metadata; 24px/600 large title; Geist Mono 14px or 12px/400 for technical IDs/payload only. This phase changes no type scale. Allow long names and identifiers to wrap or disclose without clipping identity, money, state or actions.

## Color

The 60/30/10 split is a compositional guide; semantic tokens, not hard-coded light values, define actual colors.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `--ax-base` (`--accrue-paper`, light `#FAFBFC`) | Page background and broad neutral surfaces |
| Secondary (30%) | `--ax-elevated`, `--ax-sunken`, `--ax-border` | Grouped facts, related billing, nav and structural separation |
| Accent (10%) | `--ax-accent` / `--ax-accent-strong` (Cobalt; `--accrue-cobalt: #5D79F6`) | Primary local task CTA, selected/current state and purposeful links |
| Destructive | `--ax-danger` / `--ax-danger-readable` | Destructive actions and their consequential feedback only |

Accent reserved for: one primary action per local task group; current/selected navigation or filter; meaningful inline links. Status and money intent retain readable text/state labels. Validate effective foreground/background contrast across supported themes and host-forced behavior.

## Copywriting Contract

Preserve existing locked legal/audit wording and provider diagnostics. Use domain language that names the operation, known result and safe next step. Labels must describe the actual destination or action.

| Element | Copy |
|---------|------|
| Primary CTA and confirmation labels | Use the action-specific verb and noun from the current owners, only for actions actually rendered and eligible: subscription `swap_plan` — **Change plan**; `cancel_at_period_end` — **Cancel renewal**; `pause` — **Pause collection**; `resume` — **Resume subscription**; `update_quantity` — **Update quantity**; `add_item` — **Add item**; `update_item_quantity` — **Update item quantity**; `remove_item` — **Remove item**; `cancel_now` — **Cancel immediately**; `comp_subscription` — **Comp this subscription**. Refund uses **Review refund** then **Confirm refund**. Payment-method actions use **Set default payment method** and **Delete payment method**. Invoice review retains the existing action-specific label only when that surface changes: **Finalize invoice**, **Pay invoice**, **Void invoice**, or **Mark uncollectible**. Each confirmation names the exact target and consequence/timing using the current owner copy; never substitute generic **Confirm** or generic **Cancel** for a domain action. [Source: `copy/subscription.ex`, `charge_live.ex`, `copy/customer_payment_methods.ex`, and current LiveView action owners.] |
| Customer invoice link | **Open invoices for this customer** only when the actual query retains `customer_id` and `status=open`. |
| Current-scope invoice link | **All open invoices in current scope**; substitute the actual selected-owner name only when that scope is selected and confirmed. |
| Return link | **Back to invoices/payments/subscriptions/customers/customer invoices/customer payments/customer subscriptions/Recovery**, selected from the validated destination and current scope. |
| Empty state heading | Preserve the route's semantic empty distinction: **No invoices yet.** (no records), **No invoices match these filters.** (filtered zero results), or existing specific empty-work-queue copy. |
| Empty state body | For a filtered zero result: **Clear filters or adjust the search to see invoices.** For a collection queue: **View all invoices to review the ledger.** For first-run emptiness, preserve the existing instruction to confirm organization scope when records were expected. |
| Error state | State the failed operation and verified current result, then offer only a supported safe next step: retry an idempotent read, correct the named input, or return to the scoped record/list to inspect current evidence. Preserve exact provider diagnostic text. Do not suggest blind mutation retry. |
| Destructive confirmation and dismissal | Use existing action-specific copy naming the exact target, consequence, timing and audit effect. For subscription cancellation distinguish **Cancel immediately** from **Cancel renewal**. Review dismissal is a separate safe record return: **Back to subscription**, **Back to payment**, or **Back to invoice** as applicable. Dismissal and Escape clear staged review state only and never dispatch a domain action. |

Never infer zero money, healthy/completed state, settlement, or freshness from missing values, absent records, or unavailable evidence. Show accepted vs completed precisely. Keep unavailable/not-found, empty, no-match, partial, unsupported, denied/step-up, pending, failed, and unknown distinct, with only the next step the current owner supports.

## Responsive, Content and Accessibility Contract

- Propagate Phase 240 coverage to each changed consumer. Preserve essential identity, scope, exact currency/minor units, visible state and supported actions at 320 CSS px, intermediate widths (including existing 600/768px breakpoints), 1024px shell transition, desktop, and 400% zoom without ordinary page-level horizontal overflow. A genuinely two-dimensional table may use its own labeled scroll region while retaining record identity/actions.
- Check 200% text enlargement separately from browser zoom; check WCAG 1.4.12 text-spacing overrides (1.5× line height, 2× paragraph spacing, .12em letter spacing, .16em word spacing) for clipping, overlap, hidden focus and lost task access. CSS zoom simulation is not actual browser zoom.
- Test coarse-pointer context independently of viewport width. Keep standalone frequent task buttons/icons on existing 44px direction and verify actual hit rectangles in served assets/output.
- Light/Dark/System selector, host-forced theme precedence, OS change behavior and effective computed styles remain observable on each changed surface; do not infer effective theme from the selected control label.
- Long/missing customer, subscription, invoice, payment, method, ID, date, amount, line-item and source-event values have explicit wrap, disclosure or unavailable treatment. Never substitute zero for missing money. Keep exact currency/minor amount and confirmed-vs-observed status.
- Review surfaces are self-contained and keyboard-operable through correction, dismissal, confirmation and result. Focus stays contained while the existing overlay is active and returns logically when dismissed or replaced. Escaping/canceling a review never dispatches a billing action. Busy/reconnect control names and disabled state remain stable.
- Use readable text labels alongside state colors; associate validation and async results semantically. Accessibility-tree/axe checks supplement behavior evidence and do not establish screen-reader speech, physical-device proof, universal WCAG conformance or live-provider behavior.
- No acceptance claim is made from source alone: record source, fixture, built, compiled and served evidence distinctly. Confirm any source visual candidate in the currently served output before cosmetic correction. Rebuild Admin assets with `mix accrue_admin.assets.build` and confirm served CSS/JS/font identity.

## Motion

Use only incumbent `--ax-dur-1: 120ms`, `--ax-dur-2: 180ms`, `--ax-dur-3: 240ms`, and `--ax-dur-exit: 140ms` roles when movement aids feedback or spatial orientation. Keep frequent keyboard actions immediate and transitions interruptible. Reduced motion removes nonessential travel; dismissed overlays become inert immediately. No animated money/counts, decorative stagger, or state/result meaning communicated only by animation.

## Acceptance Owners and Evidence Limits

Each owning change adds recurring proof and a focused negative control at existing owners. Keep one complete build/check and one batched desktop/narrow/effective-theme inspection, one corrective batch, and at most one confirming inspection per agreed batch. Do not run or require human UAT; optional feedback is not a delivery gate. Do not add a broad screenshot matrix, fixed sleeps, retries or loosened pixel thresholds. Final reviewed Linux goldens belong to Phase 243.

| Concern | Existing owner / surface | Concrete assertion and limit |
|---------|--------------------------|-----------------------------|
| Customer vs scope invoice destination | `SubscriptionLive`, `InvoicesLive`, invoice query/decoder | The customer link's decoded `customer_id` and retained `status=open` match the visible customer wording and exact result membership; the separate scope link returns the broader authorized set. No subscription-only filter is claimed. |
| Filtered detail return | `ScopedPath`, invoice/payment/subscription/customer list/detail LiveViews | Assert label equals validated parsed destination; only supported decoded fields survive; query-free local origins work; supplied owner is stripped and rebuilt from fresh current scope for otherwise valid local origins; invalid route, wrong customer, alternate mount and external/scheme-relative origin fall back safely. Do not claim pagination or scroll restoration. |
| Campaign / Recovery return | `CampaignLive`, `RecoveryLive` | Direct/invalid/unrelated origin returns to scoped Recovery; valid Recovery `7d`/`30d`/`90d` and current owner survive; breadcrumb/explicit return agree. Current state and historical campaign timeline remain distinct. |
| Action review and safety | `SubscriptionLive`, `ChargeLive`, `CustomerLive`, `InvoiceLive`; their existing auth/action owners | Review visibly includes exact target/ID, material customer+scope, exact amount/currency when supported, consequence/timing and uncertainty. Stale target/scope/state, denial, step-up, duplicate and capability checks remain enforced at their current owners. Dismiss/Escape do not dispatch; correction works before submission. |
| Action outcome and reconnect | Existing action/result and mounted browser owners | Outcomes are evidence-specific accepted/pending/completed/failed/denied/unknown; local acknowledgement never means settlement. Busy/reconnect preserves disabled controls and cannot replay. A non-GET HTTP observer alone proves only HTTP-scoped behavior; LiveView no-mutation needs authoritative dispatch/state/audit assertions in disposable fixtures. |
| Responsive, focus and effective theme | Existing package browser/mounted-host, axe/tree, CSS token/build owners for each changed route | Inspect actual served output for changed consumers in one desktop/narrow and effective-theme batch; test keyboard correction/dismissal/focus return, coarse pointer independently from viewport, zoom/text enlargement limits, status labels and measured hit rectangles. Axe/tree checks supplement, not certify speech, physical devices or universal WCAG. |
| Asset provenance | `mix accrue_admin.assets.build`, package served CSS/JS/font owners | Rebuild and confirm compiled served CSS/JS/font identity. Host watcher/source state is not proof of package freshness; report source, fixture, built, compiled and served evidence separately. |

## UI Considerations

Compiled `ui-consideration-probe.cjs` ran after independent approval on seven authored surface descriptions. Propose-then-confirm used the delegated agent review to union actual kinds (static content, navigation, collection, form and controls). All **40 applicable items are resolved with explicit acceptance criteria; 0 backstop, 0 unresolved, 0 unclassified**. Resolution means the contract is specified; it does not claim execution passed. Empty/error wording remains in Copywriting Contract. Existing action safety/busy/reconnect/domain states remain in their dedicated contract sections.

| Item | Status | Verification | Acceptance criterion |
|------|--------|--------------|----------------------|
| E1/overflow | resolved | explicit | Subscription detail: At 320 CSS px, intermediate and desktop widths, ordinary content has no page overflow; long identity/ID/money/state/actions remain reachable by wrap or disclosure; only a labeled two-dimensional collection may scroll locally. |
| E1/long-text | resolved | explicit | Subscription detail: Long names, IDs, action labels and diagnostics remain readable or fully disclosed without clipping target, money, status, focus or actions under narrow layout, 200% text enlargement and text-spacing overrides. |
| E2/empty | resolved | explicit | Related billing and invoice results: For zero records or unfilled inputs, render the applicable existing empty/no-match/required-input state from the Copywriting Contract; keep a supported read or correction action reachable. |
| E2/loading | resolved | explicit | Related billing and invoice results: Pending reads retain their loading state; busy submissions retain the action name/icon and disabled state through patches/reconnect; loaded zero and unknown are separate states. |
| E2/error | resolved | explicit | Related billing and invoice results: A rejected read, invalid input, denied/stale review or failed/unknown action displays its associated evidence-specific error/result and only a supported safe next step; dismissal sends no action. |
| E2/populated | resolved | explicit | Related billing and invoice results: Typical populated fixtures retain exact identity/IDs, authorized membership and current state; subscription facts/actions precede the single related-billing group; Recovery history remains distinct from current state. |
| E2/partial | resolved | explicit | Related billing and invoice results: Partial fixtures explicitly render absent money/preview/evidence as unavailable while keeping confirmed facts and blockers visible; missing values do not become zero or settlement. |
| E2/overflow | resolved | explicit | Related billing and invoice results: At 320 CSS px, intermediate and desktop widths, ordinary content has no page overflow; long identity/ID/money/state/actions remain reachable by wrap or disclosure; only a labeled two-dimensional collection may scroll locally. |
| E2/zero-one-many | resolved | explicit | Related billing and invoice results: Zero, one and many authorized records preserve explicit empty versus populated states, separate local/customer/scope counts and exact record membership without a decorative aggregate query. |
| E2/long-text | resolved | explicit | Related billing and invoice results: Long names, IDs, action labels and diagnostics remain readable or fully disclosed without clipping target, money, status, focus or actions under narrow layout, 200% text enlargement and text-spacing overrides. |
| E3/loading | resolved | explicit | Contextual returns: Pending reads retain their loading state; busy submissions retain the action name/icon and disabled state through patches/reconnect; loaded zero and unknown are separate states. |
| E3/error | resolved | explicit | Contextual returns: A rejected read, invalid input, denied/stale review or failed/unknown action displays its associated evidence-specific error/result and only a supported safe next step; dismissal sends no action. |
| E3/overflow | resolved | explicit | Contextual returns: At 320 CSS px, intermediate and desktop widths, ordinary content has no page overflow; long identity/ID/money/state/actions remain reachable by wrap or disclosure; only a labeled two-dimensional collection may scroll locally. |
| E3/long-text | resolved | explicit | Contextual returns: Long names, IDs, action labels and diagnostics remain readable or fully disclosed without clipping target, money, status, focus or actions under narrow layout, 200% text enlargement and text-spacing overrides. |
| E4/empty | resolved | explicit | Subscription/refund/payment-method reviews: For zero records or unfilled inputs, render the applicable existing empty/no-match/required-input state from the Copywriting Contract; keep a supported read or correction action reachable. |
| E4/loading | resolved | explicit | Subscription/refund/payment-method reviews: Pending reads retain their loading state; busy submissions retain the action name/icon and disabled state through patches/reconnect; loaded zero and unknown are separate states. |
| E4/error | resolved | explicit | Subscription/refund/payment-method reviews: A rejected read, invalid input, denied/stale review or failed/unknown action displays its associated evidence-specific error/result and only a supported safe next step; dismissal sends no action. |
| E4/partial | resolved | explicit | Subscription/refund/payment-method reviews: Partial fixtures explicitly render absent money/preview/evidence as unavailable while keeping confirmed facts and blockers visible; missing values do not become zero or settlement. |
| E4/overflow | resolved | explicit | Subscription/refund/payment-method reviews: At 320 CSS px, intermediate and desktop widths, ordinary content has no page overflow; long identity/ID/money/state/actions remain reachable by wrap or disclosure; only a labeled two-dimensional collection may scroll locally. |
| E4/long-text | resolved | explicit | Subscription/refund/payment-method reviews: Long names, IDs, action labels and diagnostics remain readable or fully disclosed without clipping target, money, status, focus or actions under narrow layout, 200% text enlargement and text-spacing overrides. |
| E5/loading | resolved | explicit | Action outcomes: Pending reads retain their loading state; busy submissions retain the action name/icon and disabled state through patches/reconnect; loaded zero and unknown are separate states. |
| E5/error | resolved | explicit | Action outcomes: A rejected read, invalid input, denied/stale review or failed/unknown action displays its associated evidence-specific error/result and only a supported safe next step; dismissal sends no action. |
| E5/overflow | resolved | explicit | Action outcomes: At 320 CSS px, intermediate and desktop widths, ordinary content has no page overflow; long identity/ID/money/state/actions remain reachable by wrap or disclosure; only a labeled two-dimensional collection may scroll locally. |
| E5/long-text | resolved | explicit | Action outcomes: Long names, IDs, action labels and diagnostics remain readable or fully disclosed without clipping target, money, status, focus or actions under narrow layout, 200% text enlargement and text-spacing overrides. |
| E6/empty | resolved | explicit | Recovery/campaign: For zero records or unfilled inputs, render the applicable existing empty/no-match/required-input state from the Copywriting Contract; keep a supported read or correction action reachable. |
| E6/loading | resolved | explicit | Recovery/campaign: Pending reads retain their loading state; busy submissions retain the action name/icon and disabled state through patches/reconnect; loaded zero and unknown are separate states. |
| E6/error | resolved | explicit | Recovery/campaign: A rejected read, invalid input, denied/stale review or failed/unknown action displays its associated evidence-specific error/result and only a supported safe next step; dismissal sends no action. |
| E6/populated | resolved | explicit | Recovery/campaign: Typical populated fixtures retain exact identity/IDs, authorized membership and current state; subscription facts/actions precede the single related-billing group; Recovery history remains distinct from current state. |
| E6/partial | resolved | explicit | Recovery/campaign: Partial fixtures explicitly render absent money/preview/evidence as unavailable while keeping confirmed facts and blockers visible; missing values do not become zero or settlement. |
| E6/overflow | resolved | explicit | Recovery/campaign: At 320 CSS px, intermediate and desktop widths, ordinary content has no page overflow; long identity/ID/money/state/actions remain reachable by wrap or disclosure; only a labeled two-dimensional collection may scroll locally. |
| E6/zero-one-many | resolved | explicit | Recovery/campaign: Zero, one and many authorized records preserve explicit empty versus populated states, separate local/customer/scope counts and exact record membership without a decorative aggregate query. |
| E6/long-text | resolved | explicit | Recovery/campaign: Long names, IDs, action labels and diagnostics remain readable or fully disclosed without clipping target, money, status, focus or actions under narrow layout, 200% text enlargement and text-spacing overrides. |
| E7/empty | resolved | explicit | Same-customer tabs: For zero records or unfilled inputs, render the applicable existing empty/no-match/required-input state from the Copywriting Contract; keep a supported read or correction action reachable. |
| E7/loading | resolved | explicit | Same-customer tabs: Pending reads retain their loading state; busy submissions retain the action name/icon and disabled state through patches/reconnect; loaded zero and unknown are separate states. |
| E7/error | resolved | explicit | Same-customer tabs: A rejected read, invalid input, denied/stale review or failed/unknown action displays its associated evidence-specific error/result and only a supported safe next step; dismissal sends no action. |
| E7/populated | resolved | explicit | Same-customer tabs: Typical populated fixtures retain exact identity/IDs, authorized membership and current state; subscription facts/actions precede the single related-billing group; Recovery history remains distinct from current state. |
| E7/partial | resolved | explicit | Same-customer tabs: Partial fixtures explicitly render absent money/preview/evidence as unavailable while keeping confirmed facts and blockers visible; missing values do not become zero or settlement. |
| E7/overflow | resolved | explicit | Same-customer tabs: At 320 CSS px, intermediate and desktop widths, ordinary content has no page overflow; long identity/ID/money/state/actions remain reachable by wrap or disclosure; only a labeled two-dimensional collection may scroll locally. |
| E7/zero-one-many | resolved | explicit | Same-customer tabs: Zero, one and many authorized records preserve explicit empty versus populated states, separate local/customer/scope counts and exact record membership without a decorative aggregate query. |
| E7/long-text | resolved | explicit | Same-customer tabs: Long names, IDs, action labels and diagnostics remain readable or fully disclosed without clipping target, money, status, focus or actions under narrow layout, 200% text enlargement and text-spacing overrides. |

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| No external component registry | None | Not applicable; no third-party blocks declared or introduced. |

## Checker Sign-Off

- [x] Dimension 1 Copywriting: FLAG — standalone Resume should name its target; disposition below.
- [x] Dimension 2 Visuals: FLAG — name the primary anchor; disposition below.
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS under the ratified incumbent authority.
- [x] Dimension 5 Spacing: PASS under the ratified incumbent exceptions.
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS

**Approval:** 2026-10-09 — independent rechecker approved: five PASS dimensions, two nonblocking recommendations. The initial generic typography/spacing blocks were resolved by explicit Phase 240/D-16 authority; no scale migration was authorized. The routine recommendation dispositions are **Resume subscription** for a standalone subscription resume CTA (retain the existing action key and effect), and the primary anchor named in the hierarchy above. These small authoring clarifications do not claim another independent checker run. Tests, mounted inspection and remote CI remain execution evidence, not planning claims.
