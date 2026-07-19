---
phase: 209-reign-subscriptions-list-detail-css-coordination
plan: 01
subsystem: testing
tags: [playwright, elixir, phoenix-liveview, admin-ui, visual-regression, baseline]

# Dependency graph
requires: []
provides:
  - "Confirmed-green pre-reign Elixir test baseline for subscriptions_live_test.exs (12 tests, 0 failures)"
  - "Pre-reign PNG baseline set (Subscriptions + Subscription-detail, light + dark, desktop + mobile) preserved outside git under accrue_admin/test-results/admin-visuals-baseline-209/"
  - "Documented pre-reign visual shape (triplicated CTAs/verdicts, dense multi-line rows, tall header chrome) for Plan 03 to diff against"
affects: [209-02, 209-03]

# Tech tracking
tech-stack:
  added: []
  patterns: []

key-files:
  created:
    - accrue_admin/test-results/admin-visuals-baseline-209/chromium-desktop/subscriptions.png
    - accrue_admin/test-results/admin-visuals-baseline-209/chromium-desktop/subscriptions-dark.png
    - accrue_admin/test-results/admin-visuals-baseline-209/chromium-desktop/subscription-detail.png
    - accrue_admin/test-results/admin-visuals-baseline-209/chromium-desktop/subscription-detail-dark.png
    - accrue_admin/test-results/admin-visuals-baseline-209/chromium-mobile/subscriptions.png
    - accrue_admin/test-results/admin-visuals-baseline-209/chromium-mobile/subscriptions-dark.png
    - accrue_admin/test-results/admin-visuals-baseline-209/chromium-mobile/subscription-detail.png
    - accrue_admin/test-results/admin-visuals-baseline-209/chromium-mobile/subscription-detail-dark.png
    - "(+ 8 matching .bbox.json sidecars, one per PNG above)"
  modified: []

key-decisions:
  - "No source, test, or CSS file was touched in this plan — both tasks are read-only evidence capture, exactly as specified."
  - "Baseline PNGs copied from the ephemeral test-results/admin-visuals/{project}/ output into a dedicated holding directory test-results/admin-visuals-baseline-209/{project}/ so Plan 02's re-runs of the same Playwright spec do not overwrite the pre-reign evidence."

patterns-established: []

requirements-completed: [REIGN-01]

coverage:
  - id: D1
    description: "Pre-reign Elixir test baseline (subscriptions_live_test.exs) confirmed green with an exact pass count recorded for Plan 03 to diff against"
    requirement: "REIGN-01"
    verification:
      - kind: unit
        ref: "cd accrue_admin && mix test test/accrue_admin/live/subscriptions_live_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Pre-reign PNG baseline (Subscriptions + Subscription-detail, light + dark, desktop + mobile) captured and preserved in a gitignored holding directory, with geometry/shape read directly and recorded"
    requirement: "REIGN-01"
    verification:
      - kind: e2e
        ref: "cd accrue_admin && RATCHET_SURFACES=subscriptions,subscription-detail npx playwright test e2e/admin-visuals.spec.js"
        status: pass
    human_judgment: false

duration: 5min
completed: 2026-07-19
status: complete
---

# Phase 209 Plan 01: Pre-reign evidence baseline Summary

**Captured a confirmed-green 12/12 Elixir test run plus an 8-PNG (+8 bbox.json) light/dark/desktop/mobile visual baseline for Subscriptions list + Subscription-detail, preserved outside git, before any markup edit lands.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-07-19T18:02:48Z
- **Completed:** 2026-07-19T18:07:00Z
- **Tasks:** 2 completed
- **Files modified:** 0 (source/tests/CSS untouched — this plan is read-only evidence capture)

## Accomplishments

- Confirmed the pre-reign Elixir test baseline for `subscriptions_live_test.exs` is green: **12 tests, 0 failures** — matches the 12/12 figure RESEARCH.md recorded at commit `f6278ff9`, no drift since.
- Ran the scoped Playwright capture (`RATCHET_SURFACES=subscriptions,subscription-detail`) against both configured projects (`chromium-desktop`, `chromium-mobile`) — 2/2 passed.
- Copied the full output (8 PNGs + 8 `.bbox.json` sidecars across both projects) from the ephemeral `test-results/admin-visuals/{project}/` into the durable, gitignored holding directory `test-results/admin-visuals-baseline-209/{project}/` so Plan 02's edits and any re-capture of the live spec cannot overwrite the pre-reign evidence.
- Confirmed via `git status --porcelain` and `git check-ignore -v` that none of the baseline files are staged and the `test-results/` gitignore rule (`.gitignore:28`) covers the new holding directory.
- Read all four desktop-project PNGs (subscriptions light/dark, subscription-detail light/dark) directly and recorded the pre-reign visual shape below for Plan 03's density-no-regression and detail-page-unbroken comparison.

### Pre-reign visual shape notes (for Plan 03 to diff against)

**Subscriptions list (`/billing/subscriptions`, 1280×900 viewport, fullPage capture ~1280×1396):**
- Header chrome (search bar + theme toggle) occupies the top ~45px; below it a "Primary queue" promo band, an "Open-invoice queue records" card, an H1 + "Primary order" action row, a KPI ribbon, and two callout cards ("At-risk queue" / "Who did what, when?") all precede the actual data table — roughly **760px of chrome before the table's column headers appear**. At the 900px viewport height, **zero complete table rows are visible without scrolling**.
- The table itself renders only 2 seed rows but each row is very tall (~290–300px) because every row inlines a multi-line customer-detail block, a state badge, plan/amount text, renewal date, and a stacked "Signals / audit" block (audit line + invoice-queue line + webhook-status line + CTA button + owner/tax chips + "Open audit context" link) — dense, but heavily vertically expanded per row.
- **Triplicated CTA:** "Open dedicated invoice queue" / "Work open invoices" family of actions appears 4 times before or within the table: the top Primary-queue banner button, the "Open dedicated invoice queue records" inline link, the queue-records card button, and the Primary-order action row button.
- **Triplicated verdict:** "At risk" status is asserted 3 times in different components: the per-row state badge, the "At-risk queue" callout copy ("1 subscription in dunning"), and the filter chip ("At risk · 1 at-risk subscription - dunning funnel").
- Dark mode preserves the identical layout/geometry — only color tokens change (confirmed via the `-dark` capture); no dark-mode-specific breakage observed pre-reign.

**Subscription-detail (`/billing/subscriptions/:id`, fullPage capture ~1280×1650+):**
- Similarly CTA-redundant: "Open dunning funnel and at-risk analytics" appears 3 times (a top-of-section link, a bordered orange button, and a duplicate secondary button directly below it), and 3 near-duplicate invoice-queue actions exist ("Work global invoice queue", "Work all open invoice records", "Work all invoices in queue").
- Page opens with a full-width red "Billing status: No — billing is not active" banner, then a "SUBSCRIPTION DETAIL" eyebrow + H1, a "Global invoice queue workspace" card, a "Related billing" list, a definition-list block (Billing health verdict / Lifecycle state / Billing setup gaps / etc.), an "ACTIONS" section, "Billing & items", "Dunning & recovery" (with its own nested duplicate CTAs), "Tax & compliance", and finally "Activity audit log" + "Raw JSON" — a long single-column scroll with no left/right density split.
- Dark mode again preserves identical layout/geometry with only color-token changes.

## Task Commits

Both tasks are read-only (zero source/test/CSS files changed) — no per-task code commits were made, matching the plan's `files_modified: []` declaration and threat model ("no trust boundary crossed... zero writes to application source, tests, or CSS"). The only artifact produced is the gitignored PNG baseline set, which is intentionally never committed.

**Plan metadata:** committed via `docs(209-01): complete pre-reign evidence baseline plan` (see final commit hash below).

## Files Created/Modified

- `accrue_admin/test-results/admin-visuals-baseline-209/{chromium-desktop,chromium-mobile}/subscriptions{,-dark}.png` (+ `.bbox.json`) — gitignored, not committed.
- `accrue_admin/test-results/admin-visuals-baseline-209/{chromium-desktop,chromium-mobile}/subscription-detail{,-dark}.png` (+ `.bbox.json`) — gitignored, not committed.
- No application source, test, or CSS file was created or modified.

## Decisions Made

- Copied (rather than moved) the Playwright output into the holding directory, leaving `test-results/admin-visuals/{project}/` untouched, so any other tooling that reads the default capture path is unaffected.
- Recorded the exact pass count (12 tests, 0 failures) rather than assuming the RESEARCH.md figure, per the task's explicit instruction to diff against what is actually true at execution time.

## Deviations from Plan

None — plan executed exactly as written. Both tasks were read-only as designed; the test count matched the RESEARCH.md-documented baseline (12/12) with no drift.

## Issues Encountered

None.

## Known Stubs

None — this plan produces only evidence artifacts (test output + PNGs), no application code.

## Threat Flags

None — this plan performs zero writes to application source, tests, or CSS (per the plan's own threat model, T-209-00 accept/no-mitigation-needed).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 02 (markup/CSS edits) can proceed with a known-good pre-reign starting point: 12/12 green tests and a full light/dark/desktop/mobile PNG baseline preserved at `accrue_admin/test-results/admin-visuals-baseline-209/{project}/`.
- Plan 03's density-no-regression and detail-page-unbroken checks have a concrete "before" artifact (not just a description) to diff against, including the specific triplicated-CTA/verdict shapes this phase's reign work is expected to resolve.
- No blockers.

---
*Phase: 209-reign-subscriptions-list-detail-css-coordination*
*Completed: 2026-07-19*

## Self-Check: PASSED

All 8 baseline PNGs + this SUMMARY.md verified present on disk via `[ -f ... ]`. No per-task code commits exist to verify (both tasks were read-only; zero source/test/CSS files changed).
