# Detail Page Spec (SPEC-DETAIL)

The Detail archetype covers all single-object pages in `accrue_admin`: subscriptions, customers,
invoices, payments, coupons, and their related objects. These pages share a vertical disclosure
spine: breadcrumbs → GOV.UK-style summary-list header (always-on state) → action menu
(≤2 primary buttons + overflow) → collapsible drill sections → one related-resources strip →
lazy activity timeline and raw JSON at the bottom.

The archetype's governing rule is **summary-then-drill, not everything-at-once.** The pattern was
developed to remediate `subscription_live.ex` — historically the worst "info dump" offender, with
~25 always-visible zones and 10 permanently-expanded inline action forms — as the Phase 195
remediation target. It eliminates the "info dump" by layering content by frequency-of-need per
persona, without deleting any information.

Audience: build agents for Phases 194–200, the `accrue_admin` maintainer, and adopters extending
the admin UI.

---

## SPEC-DETAIL — summary-then-drill

### Machine-checkable invariants

The following invariants are verified deterministically by the page-flow Playwright driver
(`phase191-page-flow-helpers.js`), source guards in `scripts/ci/verify_package_docs.sh`, or
`axe-core`. They must hold on every build.

| Invariant | How verified |
|-----------|--------------|
| **≤2 primary action buttons visible, plus one overflow/dropdown menu.** A detail page may expose at most two primary-level action `<button>` elements (e.g., "Cancel renewal", "Retry invoice") that are visible without invoking any menu. All remaining actions must be collected into a single overflow/dropdown menu. Showing three or more primary-level buttons is a scope violation. | Playwright page-flow spec: `page.locator('[data-ax-primary-action]').count()` must be ≤ 2; `page.locator('[data-ax-action-overflow-menu]').count()` must be ≥ 1 (when more than two actions exist). |
| **Action forms are NOT pre-expanded on page load.** On initial load, the count of visible `<form>` elements inside the action band must be zero. Forms appear only after the operator invokes the corresponding menu item or drawer trigger. | Playwright page-flow spec: on `page.goto(detail_url)`, assert `page.locator('[data-ax-action-band] form:visible').count() === 0`. |
| **Exactly one related-resources strip per page.** Duplicate related-resources cards are a known defect (subscription_live.ex has a second "related billing" nav card that duplicates the canonical strip). Each detail page must render exactly one element matching the related-resources strip selector. | Playwright page-flow spec: `page.locator('[data-ax-related-resources]').count() === 1`. |
| **Overlay/drawer is hit-testable above its scrim, with body scroll locked.** When a drawer or modal overlay is open: (a) the overlay panel's primary action button and at least one focusable control inside it must be click-reachable while the scrim is present (`assertTopPointerTarget` on the panel's primary action); (b) the page body must not scroll when the operator wheels over the scrim (body `scrollTop` unchanged before/after wheel event). | Playwright page-flow spec uses `assertTopPointerTarget(overlayPrimaryAction)` + a body-scroll assertion. Covers both desktop and a mobile viewport. Aligns with Pitfall-1 and Pitfall-2 acceptance criteria from PITFALLS.md. |

### Judge-graded criteria (12-dim rubric)

These items require human or adversarial-agent judgment. They are scored against the 12-dimension
rubric in `.planning/milestones/v1.53-phases/187-audit-baseline/187-RUBRIC.md` and are not
machine-enforceable without that rubric context.

**Summary-list answers "what state, what's wrong" at a glance.**
The GOV.UK-style summary-list header (key/value rows with row-level "Change" affordances) must
carry, above the fold at 1280×800, the answer to: current status badge, customer name/link,
current period, next renewal or cancellation date, and dunning state if applicable. A rubric
reviewer must confirm that this information is visible without scrolling and without opening any
menu or section, and that the summary-list rows carry a visually-hidden "Change" context string
on each action link (accessibility requirement, GOV.UK summary-list semantics).

**No card-in-card double border.**
A detail page must not nest an `ax-card` element inside another `ax-card` element where both
render a visible border. Content groupings inside a card use spacing and heading hierarchy
alone, not a second border ring. A rubric reviewer will flag any rendered screenshot where
two concentric rectangular borders are visible around a related block of content (e.g., the
tax-risk panel inside the actions card, or the confirm-panel inside the actions card).

**Tabs used only for peer record-sets, never for primary state or critical actions.**
Tabs are acceptable only where the tabbed content represents genuinely mutually-exclusive,
equal-weight record collections with short (1–2 word) labels (Customer-360 pattern: Subscriptions,
Invoices, Payments). Using tabs to hide primary status information or a critical action is an
anti-pattern per NN/g and Baymard research (27–43% of users miss horizontal tabs). A reviewer
must confirm: (a) if any tabs are present, each tab label is ≤ 3 words and no tab contains the
primary state summary or a critical action; (b) the primary state is in the always-visible
summary-list header, not behind a tab.

---

*Guide home: `accrue_admin/guides/spec-detail.md`*
*Part of the Phase 193 pattern-lock. Downstream consumers: Phases 195, 198, 199.*
