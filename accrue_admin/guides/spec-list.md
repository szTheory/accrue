# List Page Spec (SPEC-LIST)

The List archetype covers the nine billing-object queue pages in `accrue_admin`: invoices,
subscriptions, customers, payments, coupons, promotion codes, and related list views. Each page
follows the same structural grammar: a `PageHeader` with breadcrumbs, title, stat-strip, and
filter toolbar; a persistent filter-chip row with result count and clear-all; a responsive
`data_table` that degrades to stacked label/value cards below the mobile breakpoint; and
server-side pagination.

The archetype's governing rule is **table-first, not card-first.** Billing operators scan across
rows to compare state, money, and time — tasks that tables serve and heterogeneous card grids do
not. Dense, scannable, paginated table rows serve the Finance-Ops invoice-queue and Support
customer-lookup jobs better than a friendlier-looking card layout. Work-queue defaults and
filter chips that answer "what am I looking at" are non-negotiable.

Audience: build agents for Phases 194–200, the `accrue_admin` maintainer, and adopters extending
the admin UI.

---

## SPEC-LIST — table-first, four-state, chips-count-clear

### Machine-checkable invariants

The following invariants are verified deterministically by the page-flow Playwright driver
(`phase191-page-flow-helpers.js`), source guards in `scripts/ci/verify_package_docs.sh`, or
`axe-core`. They must hold on every build.

| Invariant | How verified |
|-----------|--------------|
| **Renders 4 distinct states with distinct copy strings.** A list page must handle: (1) populated with data rows, (2) first-run empty (no records ever created — onboarding copy), (3) filtered-empty (filter excludes all results — "no open invoices" copy with a clear-filters affordance distinct from the first-run copy), (4) loading skeleton (skeleton rows matching the table column shape, not a spinner). The first-run-empty and filtered-empty states must not share the same copy string. | Playwright page-flow spec seeds fixtures for each state and asserts the distinct selector or copy string is present. The filtered-empty state must contain a `[data-ax-state="filtered-empty"]` or equivalent locator with a "clear filters" affordance; the first-run-empty must not contain that affordance. |
| **Filter chips, result count, and clear-all are all present when a filter is active.** When at least one filter parameter is active, the page must render: a removable chip for each active filter, a visible numeric result count, and a "clear all" / "clear filters" control. None of the three may be absent when a filter is active. | Playwright page-flow spec applies a filter, then asserts `[data-ax-filter-chips]` count > 0, `[data-ax-result-count]` is visible, and `[data-ax-clear-all]` is visible — all three checks must pass simultaneously. |
| **Every truncating cell pairs `text-overflow: ellipsis` with `min-width: 0` in the same CSS block.** A table cell that clips long strings with an ellipsis must also declare `min-width: 0` in the same rule or on the same element; without `min-width: 0` the ellipsis is ineffective in flex/grid containers and text overflows its parent. | New source guard in `scripts/ci/verify_package_docs.sh` (`require_regex`): for every CSS rule containing `text-overflow: ellipsis`, the same block must also contain `min-width: 0`. Pairs with a negative test in `PackageDocsVerifierTest`. |
| **No pagination controls rendered when total pages ≤ 1.** If the result set fits on a single page (or is empty), no "previous / next" pagination UI may appear in the DOM. Showing pagination for a one-page result is visual noise and implies more data exists. | Playwright page-flow spec: seed a fixture with ≤ page-size rows, assert `[data-ax-pagination]` is absent (or hidden). |

### Judge-graded criteria (12-dim rubric)

These items require human or adversarial-agent judgment. They are scored against the 12-dimension
rubric in `.planning/milestones/v1.53-phases/187-audit-baseline/187-RUBRIC.md` and are not
machine-enforceable without that rubric context.

**Column priority serves identity · state · money · time.**
In a 1024px viewport, the visible columns must prioritise identity (name, email, or record ID),
state (status badge), money (amount), and time (date). Plumbing columns (processor IDs, internal
UUIDs) must be deferred to the detail page or a secondary text line. A rubric reviewer must
confirm that the leftmost 3–4 columns carry the job-critical fields, and that no UUID or raw
internal identifier occupies a primary slot on any list page.

**"Deliberate dense" padding rhythm.**
List rows use compact padding (not card padding). The rubric criterion is that at least 8 full
rows are visible above the fold in a 1280×800 viewport on a populated list without scrolling.
Generous padding is reserved for the summary-list header on the detail archetype and for card
layouts in the mobile degradation. Reviewers will penalise any list page where padding expands
rows to match the card archetype's rhythm.

**Work-queue default is active, with "All" one chip away.**
Every list page opens with its work-queue filter pre-applied (e.g., `/invoices` shows
open/uncollectible; `/subscriptions` shows active). The "All" filter is reachable by one chip
tap or click without navigating away. A reviewer must confirm the default URL/params load the
queue view, and that a clearly labelled "All" chip is visible in the chip row.

---

*Guide home: `accrue_admin/guides/spec-list.md`*
*Part of the Phase 193 pattern-lock. Downstream consumers: Phases 196, 197.*
