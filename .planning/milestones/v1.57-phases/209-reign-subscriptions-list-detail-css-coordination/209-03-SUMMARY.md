---
phase: 209-reign-subscriptions-list-detail-css-coordination
plan: 03
subsystem: testing
tags: [phoenix-liveview, admin-ui, subscriptions, css-coordination, playwright, floki]

# Dependency graph
requires:
  - phase: 209-02
    provides: "Rebuilt subscriptions_live.ex PageHeader/cell shape, 6 new Copy.Subscription functions, zero shared-CSS edits"
provides:
  - "D-04 shared-CSS-coordination proof: grep-gate confirms zero remaining band/shared-class references in subscriptions_live.ex, correct residual ownership by subscription_live.ex/dashboard_live.ex/component_kitchen_live.ex, zero app.css diff"
  - "subscriptions_live_test.exs fully migrated and green (12/12) against the post-reign template"
  - "Both generated artifacts (accrue_admin.css, copy_strings.json) rebuilt and confirmed/committed; export_copy_strings allowlist extended to cover the 6 new Subscriptions Copy functions"
affects: [210, 211]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Scoped Floki assertions (find element by class + assert text/href) replace bare html =~ substring checks on IDs, per RESEARCH Pitfall 4 — avoids coincidental passes"

key-files:
  created:
    - .planning/phases/209-reign-subscriptions-list-detail-css-coordination/deferred-items.md
  modified:
    - accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs
    - accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex
    - examples/accrue_host/e2e/generated/copy_strings.json

key-decisions:
  - "Playwright's default outputDir-clearing wiped Plan 01's baseline PNG holding directory (nested under test-results/) when Task 1 re-ran the capture — fell back to Plan 01's detailed prose geometry notes as the comparison target instead of pixel-baseline PNGs, since the pre-reign code no longer exists to re-capture."
  - "Added the 6 new Plan-02 Copy.Subscription functions to the export_copy_strings mix task's static allowlist (Rule 2 auto-fix) — without this, rebuilding the artifact was a silent no-op and the plan's own acceptance criterion (grep 'Open invoice queue' in copy_strings.json) would fail, defeating T-209-05's stated anti-drift mitigation."
  - "Removed two coincidentally-passing '$0.00' assertions (one in the header test, one in the column-priority test) rather than keeping them per the plan's literal line-by-line instruction — investigation proved both matched the now-deleted invoice-queue-records band's per-row remaining-amount text, not the Exposure stat aggregate (which is non-zero, DB-state-dependent, in this environment)."
  - "Removed one duplicate stale 'Open failed-delivery debugger' assertion the plan's literal instruction said to keep (L296 of the original file) — that string no longer renders anywhere post-reign; keeping it would fail the test."

patterns-established: []

requirements-completed: [REIGN-01, REIGN-02, COMP-01]

coverage:
  - id: D1
    description: "D-04 shared-CSS-coordination grep-gate: zero band/override/shared-class references remain in subscriptions_live.ex; correct residual ownership by subscription_live.ex/dashboard_live.ex/component_kitchen_live.ex; zero app.css diff for the phase; no work_queue_callout.ex component file"
    requirement: "REIGN-01"
    verification:
      - kind: unit
        ref: "grep -c against subscriptions_live.ex (band classes, shared classes) returns 0; grep -rl residual ownership matches exactly the expected file sets; git diff --stat accrue_admin/assets/css/app.css empty; ls work_queue_callout.ex fails"
        status: pass
    human_judgment: false
  - id: D2
    description: "Detail page (subscription_live.ex) visually unbroken post-reign; Subscriptions list shows single-verdict/single-CTA/4-stat/no-bands shape with density at-or-tighter than pre-reign"
    requirement: "REIGN-01"
    verification:
      - kind: automated_ui
        ref: "RATCHET_SURFACES=subscriptions,subscription-detail npx playwright test e2e/admin-visuals.spec.js (2/2 passed); PNGs read directly and compared against Plan 01's prose geometry notes (pixel baseline was lost — see Deviations)"
        status: pass
    human_judgment: false
  - id: D3
    description: "subscriptions_live_test.exs fully migrated to the post-reign template and green, same 12-test count as Plan 01's baseline"
    requirement: "REIGN-02"
    verification:
      - kind: unit
        ref: "cd accrue_admin && mix test test/accrue_admin/live/subscriptions_live_test.exs"
        status: pass
    human_judgment: false
  - id: D4
    description: "Both generated artifacts (accrue_admin.css, copy_strings.json) rebuilt via their mix tasks and committed where changed"
    requirement: "REIGN-02"
    verification:
      - kind: unit
        ref: "mix accrue_admin.assets.build (exit 0, zero diff); mix accrue_admin.export_copy_strings --out ../examples/accrue_host/e2e/generated/copy_strings.json (exit 0, contains 'Open invoice queue')"
        status: pass
    human_judgment: false
  - id: D5
    description: "COMP-01 confirmed resolved inline — no work_queue_callout.ex component file exists"
    requirement: "COMP-01"
    verification:
      - kind: unit
        ref: "ls accrue_admin/lib/accrue_admin/components/work_queue_callout.ex fails"
        status: pass
    human_judgment: false
  - id: D6
    description: "Full accrue_admin mix test suite reviewed at the phase boundary; 506/513 green with 7 pre-existing failures unrelated to this plan's files, traced via git blame to prior unrelated work and logged to deferred-items.md rather than fixed (scope-boundary rule)"
    verification: []
    human_judgment: true
    rationale: "The plan's own acceptance criterion demands mix test exit 0 with zero failures. The 7 remaining failures trace via git log to source files last touched by unrelated commits (208-04 ratchet rounds, 260718-u1s token refactor) that predate this plan's execution and are outside files_modified. A human should confirm this scope read is correct before the phase is considered fully closed."
duration: 25min
completed: 2026-07-19
status: complete
---

# Phase 209 Plan 03: D-04 verification, test migration, artifact rebuild Summary

**Proved the phase's namesake shared-CSS-coordination risk held via a 6-point grep-gate + PNG re-capture, migrated all 12 tests in `subscriptions_live_test.exs` to the post-reign template (still 12/12 green), and rebuilt/committed both generated artifacts — extending the `export_copy_strings` allowlist so it actually captures the 6 new Subscriptions copy strings instead of silently no-op'ing.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-07-19T18:15:00Z (approx)
- **Completed:** 2026-07-19T18:40:35Z
- **Tasks:** 3 completed
- **Files modified:** 3 (`subscriptions_live_test.exs`, `export_copy_strings.ex`, `copy_strings.json`) + 1 new evidence doc (`deferred-items.md`)

## Accomplishments

- **Task 1 — D-04 grep-gate + PNG verification:** All six grep/diff checks passed exactly as the plan's acceptance criteria required: zero band/override/shared-class references remain in `subscriptions_live.ex`; `ax-inline-worklist` residual ownership is exactly `subscription_live.ex` + `component_kitchen_live.ex`; `ax-audit-summary-row` residual ownership is exactly `dashboard_live.ex` + `subscription_live.ex` + `component_kitchen_live.ex`; `accrue_admin/assets/css/app.css` has zero diff for the entire phase; no `work_queue_callout.ex` file exists. Re-ran the scoped Playwright capture (2/2 projects passed) and read the fresh PNGs directly: the Subscriptions list shows exactly one verdict badge ("Action required"), one primary CTA ("Open invoice queue"), the 4-stat StatStrip (Open invoices / Exposure / At-risk subscriptions / Failed webhooks), no bands between header and table, and markedly tighter density than the pre-reign baseline (2 full table rows plus all header chrome visible without scrolling, vs. zero complete rows visible pre-reign). The Subscription-detail page rendered structurally identical to Plan 01's recorded pre-reign shape (same redundant-CTA sections, same section order) — confirmed visually unbroken since `subscription_live.ex` was never touched.
- **Task 2 — Test migration:** Rewrote all affected assertions in `subscriptions_live_test.exs` test-by-test per the plan's line-by-line instructions: verdict checks now match the `StatusBadge` label text ("Action required"/"Healthy"), "exposure" capitalized to "Exposure", CTA copy updated to "Open invoice queue"/"Open invoices", removed assertions on retired bands/in-cell buttons/dead helper chain, and added positive assertions for the surviving secondary actions and the new `ax-status-badge`/"Failed webhooks" stat. Renamed the identity-cell test and replaced two bare `html =~ subscription.customer_id/processor_id` substring checks with scoped Floki assertions (find `a.ax-link`/`a.ax-label.ax-muted`, assert both text and href) per RESEARCH Pitfall 4. Final count: 12 tests, 0 failures — same count as Plan 01's baseline.
- **Task 3 — Artifact rebuild + full-suite gate:** `mix accrue_admin.assets.build` produced zero diff (expected, confirms D-04's zero-CSS-edit claim). `mix accrue_admin.export_copy_strings --out ../examples/accrue_host/e2e/generated/copy_strings.json` initially produced a **zero diff** because none of Plan 02's 6 new `Copy.Subscription` functions were in the task's static allowlist — added them (Rule 2 auto-fix) and re-ran; the regenerated JSON now contains `"subscriptions_invoice_queue_cta":"Open invoice queue"` and the other 5 new/renamed strings. Full `mix test` (513 tests) came back 506 passing / 7 failing; investigated each failure via `git log -- <source file>` and confirmed all 7 trace to files last touched by unrelated prior work (Phase 208-04 ratchet rounds, the `260718-u1s` token refactor) — none touch this plan's `files_modified`. Logged to `deferred-items.md` per the scope-boundary rule rather than fixed.

## Task Commits

1. **Task 1: D-04 grep-gate + PNG verification** — no code commit (read-only verification; grep-gate + PNG re-capture only, matching the plan's own framing of this task as evidence-gathering)
2. **Task 2: Migrate subscriptions_live_test.exs to post-reign shape** — `6a1d87be` (test)
3. **Task 3: Rebuild + commit both generated artifacts; full-suite green gate** — `6baa5c1d` (feat)

**Plan metadata:** committed via `docs(209-03): complete plan` (see final commit hash below).

## Files Created/Modified

- `accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs` — all retired-class/copy assertions migrated; identity-cell test renamed and rewritten with scoped Floki assertions.
- `accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex` — allowlist extended with the 6 new `subscriptions_*` Copy functions.
- `examples/accrue_host/e2e/generated/copy_strings.json` — regenerated; now includes the 6 new/changed Subscriptions strings.
- `.planning/phases/209-reign-subscriptions-list-detail-css-coordination/deferred-items.md` — new; logs the 7 pre-existing, out-of-scope `mix test` failures found during the full-suite gate.
- `accrue_admin/priv/static/accrue_admin.css` / `.js` — rebuilt, zero diff (confirmed, not skipped).

## Decisions Made

- Playwright's default `outputDir` clearing wiped Plan 01's pre-reign baseline PNG holding directory (`test-results/admin-visuals-baseline-209/`) when Task 1 re-ran the capture, because it lives nested under `test-results/`, which Playwright clears before every run. Fell back to Plan 01's detailed prose geometry notes (recorded in `209-01-SUMMARY.md`) as the comparison target — the newly captured PNGs matched that prose description exactly on both the list page (single verdict/CTA/4-stat/no-bands/tight density) and the detail page (unchanged structure).
- Added the 6 new Plan-02 `Copy.Subscription` functions to `export_copy_strings`'s static allowlist (Rule 2 auto-fix). The plan's Task 3 asserted the export "WILL produce a real diff" from Plan 02's copy changes, but the allowlist is curated and none of the new functions were in it — rebuilding was a silent no-op that would have failed the plan's own acceptance criterion and left T-209-05's stated anti-drift mitigation unfulfilled.
- Removed two "$0.00" assertions (header test + column-priority test) that the plan's literal per-line instructions said to keep. Investigation (via a throwaway probe test) showed both matched the now-deleted invoice-queue-records band's per-invoice remaining-amount text, not the Exposure stat aggregate — the real Exposure value in this DB state is non-zero (`$592.50`). Kept per Rule 1 (bug auto-fix: a literal-but-broken instruction cannot be followed over the test actually passing).
- Removed one duplicate "Open failed-delivery debugger" assertion (L296 of the original test file) that the plan's literal "Keep L295-298" range included but that duplicates a string already correctly deleted at L283 earlier in the same test — the string doesn't render anywhere post-reign.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Plan 01's baseline PNG holding directory was destroyed mid-task**
- **Found during:** Task 1, after re-running the Playwright capture
- **Issue:** `test-results/admin-visuals-baseline-209/` (Plan 01's pre-reign PNG evidence) lives nested under `test-results/`, which Playwright's default config clears before each run. Re-running the scoped capture for Task 1's comparison silently deleted the pixel baseline this task needed to diff against.
- **Fix:** Fell back to Plan 01 SUMMARY's detailed prose geometry notes as the comparison target instead of pixel-diffing PNGs. The newly captured PNGs (read directly) matched that prose exactly.
- **Files modified:** none (test-infrastructure discovery, not a source change)
- **Commit:** n/a (no code change; documented here and in Task 1's evidence above)

**2. [Rule 2 - Missing Critical] export_copy_strings allowlist missing all 6 new Subscriptions Copy functions**
- **Found during:** Task 3, after running `mix accrue_admin.export_copy_strings` and finding zero diff
- **Issue:** The mix task's allowlist is a curated static list; none of Plan 02's 6 new `Copy.Subscription` functions (`subscriptions_index_breadcrumb`, `subscriptions_invoice_queue_cta`, `subscriptions_health_verdict_healthy`, `subscriptions_health_verdict_action_required`, `subscriptions_route_line`, `subscriptions_kpi_section_aria_label`) were in it. Rebuilding the artifact was a silent no-op, defeating the anti-drift purpose of T-209-05's mitigation and failing the plan's own acceptance criterion.
- **Fix:** Added all 6 functions to the allowlist, re-ran the export task; JSON now contains the new/changed strings.
- **Files modified:** `accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex`, `examples/accrue_host/e2e/generated/copy_strings.json`
- **Verification:** `grep -c "Open invoice queue" copy_strings.json` returns 1
- **Committed in:** `6baa5c1d`

**3. [Rule 1 - Bug] Two coincidentally-passing "$0.00" assertions removed**
- **Found during:** Task 2, running `mix test` after the initial migration pass
- **Issue:** Both `assert html =~ "$0.00"` assertions (header test, column-priority test) failed post-migration. Root-cause investigation (throwaway probe test) showed they never tested the Exposure stat's actual value — they coincidentally matched the now-deleted invoice-queue-records band's per-invoice `amount_remaining_minor` text, which happened to render "$0.00" for a specific seeded invoice. The real Exposure aggregate in this test's DB state is non-zero.
- **Fix:** Removed both assertions (they test content that no longer exists; keeping them literally per the plan's line list would break the test for a reason unrelated to the plan's intent).
- **Files modified:** `accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs`
- **Verification:** `mix test test/accrue_admin/live/subscriptions_live_test.exs` — 12/12 green
- **Committed in:** `6a1d87be`

**4. [Rule 1 - Bug] Duplicate stale "Open failed-delivery debugger" assertion removed**
- **Found during:** Task 2, cross-checking the plan's "Keep L295-298" range against the source
- **Issue:** L296 of the original file duplicated an already-correctly-deleted assertion (L283) on a string (`"Open failed-delivery debugger"`) that no longer renders anywhere in the post-reign template. The plan's literal line-range instruction would have kept a guaranteed-failing assertion.
- **Fix:** Excluded L296 while keeping L295, L297, L298 as instructed.
- **Files modified:** `accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs`
- **Verification:** `mix test test/accrue_admin/live/subscriptions_live_test.exs` — 12/12 green
- **Committed in:** `6a1d87be`

---

**Total deviations:** 4 auto-fixed (1 blocking test-infra loss, 1 missing-critical allowlist gap, 2 bug fixes to coincidentally-passing/stale assertions)
**Impact on plan:** All four were necessary to reach a fully-green, non-coincidental test suite and a genuinely-drift-checked artifact rebuild. No scope creep — every fix stayed within Task 1-3's own files and intent.

## Issues Encountered

**Full-suite `mix test` gate: 506/513 green, 7 pre-existing failures out of scope.** Task 3's acceptance criteria calls for `mix test` (full suite) to exit 0. It does not — 7 tests fail, all traced via `git log -- <source file>` to files last modified by unrelated prior work (`related_resources.ex`/`dashboard_live.ex`/query-module changes from the parked Phase 208-04 ratchet rounds; `theme.css`'s dark-shim mismatch from the separate `260718-u1s` admin token refactor). None of the 7 failing tests reference any file this plan touched. Per the executor's scope-boundary rule, these were logged to `deferred-items.md` rather than fixed. See that file for the full failure-to-commit trace table and a recommended maintainer follow-up.

## Known Stubs

None — this plan produces test/verification/artifact changes only, no new UI surface.

## Threat Flags

None — no new trust-boundary or interpolation surface introduced. The Floki-based identity-cell assertions read existing rendered HTML (already passed through `escape/1` by `subscriptions_live.ex`, per Plan 02's T-209-01 mitigation); no new dynamic value handling was added in this plan.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Phase 209 (Reign Subscriptions) is functionally complete: D-04's shared-CSS-coordination risk is proven held, `subscriptions_live_test.exs` is green and non-coincidental, both generated artifacts are rebuilt and committed, COMP-01 confirmed resolved inline.
- Phase 210 (Reign Home + IA/copy) can proceed — its scope (`dashboard_live.ex`) is untouched by this plan and still references the shared `.ax-inline-worklist*`/`.ax-audit-summary-row` classes exactly as Phase 211's eventual grep-gate expects.
- **Carry-forward for the maintainer:** the 7 pre-existing `mix test` failures logged in `deferred-items.md` are unrelated to Phase 209 but should be triaged — likely quick, mechanical class/copy syncs — either standalone or folded into the still-open Phase 208-04/205 maintainer-gated cleanup when v1.56 is revisited.
- No blockers to closing Phase 209 itself.

---
*Phase: 209-reign-subscriptions-list-detail-css-coordination*
*Completed: 2026-07-19*

## Self-Check: PASSED

All modified/created files (`subscriptions_live_test.exs`, `export_copy_strings.ex`, `copy_strings.json`, `deferred-items.md`, this SUMMARY.md) verified present on disk via `[ -f ... ]`. Both task commits (`6a1d87be`, `6baa5c1d`) verified present in `git log --oneline --all`.
