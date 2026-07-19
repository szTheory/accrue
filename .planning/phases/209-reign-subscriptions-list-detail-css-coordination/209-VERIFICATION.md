---
phase: 209-reign-subscriptions-list-detail-css-coordination
verified: 2026-07-19T18:48:03Z
status: passed
score: 12/12 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 209: Reign Subscriptions (list + detail CSS coordination) Verification Report

**Phase Goal:** The Subscriptions list (`subscriptions_live.ex`) is composed only from the canonical shared skeleton (AppShell → section.ax-page → PageHeader → FlashGroup → DataTable with FilterChipBar in :list_status), reads answer-first (one verdict, one invoice-queue entry point), and its per-row cells use the compact shared idiom — while the shared-CSS coordination with the out-of-scope subscription detail page (subscription_live.ex) is resolved so no later deletion can silently break it.
**Verified:** 2026-07-19T18:48:03Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Subscriptions list renders `section.ax-page` with no page-override classes | ✓ VERIFIED | `grep -c "ax-page-compact ax-subscriptions-page"` → 0; source shows `<section class="ax-page">` at `subscriptions_live.ex:91` |
| 2 | Nothing renders between `FlashGroup.flash_group` and the `DataTable` live_component (5 bespoke bands removed) | ✓ VERIFIED | `grep -c` for all 5 band classes + `ax-kpi-row`/`ax-page-header-compact` overrides → 0; source shows `FlashGroup.flash_group` at line 189 immediately followed by `<.live_component module={DataTable}` at line 191 |
| 3 | Exactly one health verdict (real `StatusBadge`, not hand-rolled) and exactly one primary CTA in `PageHeader :actions` | ✓ VERIFIED | Source `:description` slot renders one `<StatusBadge.status_badge>`; `:actions` renders one `ax-button-primary` ("Open invoice queue") + 2 unchanged secondaries (per resolved Open Question 2). Screenshot confirms: single amber "Action required" badge, single blue primary CTA. |
| 4 | 4-stat StatStrip in money-at-risk order, unwrapped (no `ax-kpi-row` div) | ✓ VERIFIED | Source shows `<StatStrip.stat_strip>` with exactly 4 `:stat` entries (Open invoices → Exposure → At-risk subscriptions → Failed webhooks), no wrapping div. Screenshot confirms all 4 stats render. |
| 5 | `identity_cell/3` and `billing_signals_cell/3` contain zero `<button>`/in-cell `ax-button` elements | ✓ VERIFIED | Region-scoped `awk`+`grep` on both function bodies → 0 matches for each |
| 6 | No new component file exists at `components/work_queue_callout.ex` (COMP-01 resolves inline) | ✓ VERIFIED | `ls accrue_admin/lib/accrue_admin/components/work_queue_callout.ex` → No such file |
| 7 | Every removed-band operator datum (open-invoice count, exposure $, at-risk count, failed-webhook count) relocated into the StatStrip/verdict, not dropped | ✓ VERIFIED | All 4 data points present in the new StatStrip; pre-existing `failed_webhook_count` field (already the same datum as the old "Failed payment/webhook count" KPI, confirmed via pre-209 git diff) carries forward as "Failed webhooks" |
| 8 | Detail page (`subscription_live.ex`) and dev component-kitchen still reference `.ax-inline-worklist*`/`.ax-audit-summary-row`; `subscriptions_live.ex` no longer does | ✓ VERIFIED | `grep -rl` confirms `ax-inline-worklist` → `subscription_live.ex` + `component_kitchen_live.ex` only; `ax-audit-summary-row` → `dashboard_live.ex` + `subscription_live.ex` + `component_kitchen_live.ex` only |
| 9 | `accrue_admin/assets/css/app.css` has zero diff for the entire phase | ✓ VERIFIED | `git diff --stat 1ae78727..93caa402 -- accrue_admin/assets/css/app.css` → empty; none of the 4 phase commits (`735cfb4f`, `29326067`, `6a1d87be`, `6baa5c1d`) touch `app.css` |
| 10 | `subscriptions_live_test.exs` fully green against the rebuild | ✓ VERIFIED | `mix test test/accrue_admin/live/subscriptions_live_test.exs` → 12 tests, 0 failures (independently re-run, matches Plan 01's pre-reign 12/12 baseline count) |
| 11 | Both generated artifacts rebuilt and committed (`accrue_admin.css`, `copy_strings.json`) | ✓ VERIFIED | `copy_strings.json` contains all 6 new `subscriptions_*` Copy strings incl. `"subscriptions_invoice_queue_cta":"Open invoice queue"`; `export_copy_strings.ex` allowlist extended; `git status --porcelain` on all phase files → clean (committed) |
| 12 | Post-reign Subscriptions PNG shows tighter density than pre-reign baseline; Subscription-detail PNG visually unbroken | ✓ VERIFIED | Directly read both current PNGs: Subscriptions list is dramatically denser (2 full data rows + all chrome visible vs. zero complete rows pre-reign per Plan 01's notes); Subscription-detail page structurally matches Plan 01's recorded pre-reign shape (same redundant-CTA sections, same long single-column layout) |

**Score:** 12/12 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` | Rebuilt spine + cells; dead code removed | ✓ VERIFIED | `mix compile --warnings-as-errors` clean; all grep gates pass |
| `accrue_admin/lib/accrue_admin/copy/subscription.ex` | 6 new Copy fns | ✓ VERIFIED | All 6 functions present (`grep -c` → 6) |
| `accrue_admin/lib/accrue_admin/copy.ex` | 6 new `defdelegate` entries | ✓ VERIFIED | Confirmed adjacent to existing `subscription_*` block |
| `accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs` | Migrated assertions | ✓ VERIFIED | 12/12 green, no coincidentally-passing assertions (2 misleading `"$0.00"` checks and 1 duplicate stale assertion correctly removed per investigation documented in SUMMARY) |
| `accrue_admin/priv/static/accrue_admin.css` | Rebuilt via mix task | ✓ VERIFIED | Rebuilt, zero diff (consistent with zero source CSS edits) |
| `examples/accrue_host/e2e/generated/copy_strings.json` | Rebuilt via mix task | ✓ VERIFIED | Contains all 6 new/changed Subscriptions strings |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `identity_cell/3` primary link | `/subscriptions/:id` | `href={scoped_path(mount_path, "/subscriptions/#{row.id}", owner_scope)}` | ✓ WIRED | Confirmed in source; text is `customer_label(row)` per D-01 |
| Single CTA | `invoice_queue_path/2` | unchanged helper | ✓ WIRED | `href={invoice_queue_path(@admin_mount_path, @current_owner_scope)}` unchanged |
| `subscriptions_live.ex` | shared CSS rules (`ax-inline-worklist*`, `ax-audit-summary-row`) | no longer referenced | ✓ WIRED (correctly un-wired) | Confirmed via grep; detail page + dev kitchen retain the references, CSS rules untouched in `app.css` |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| REIGN-01 | 209-01, 209-02, 209-03 | Canonical skeleton, bands/overrides removed | ✓ SATISFIED | All grep gates + compile clean + PNG evidence |
| REIGN-02 | 209-02, 209-03 | Compact cell idiom, no in-cell actions | ✓ SATISFIED | Cells rebuilt to `ax-stack-xs`/`ax-chip.ax-label`; zero `<button>`/`ax-button` in either cell. Per-row action was **dropped entirely** rather than moved to an actions column/DropdownMenu — a documented deviation from REQUIREMENTS.md's literal wording, resolved via CONTEXT.md decision D-01, and verified consistent with the actual reference pages (`invoices_live.ex`/`customers_live.ex` have zero DropdownMenu/action-column per-row patterns — confirmed via grep). |
| COMP-01 | 209-02, 209-03 | WorkQueueCallout extract-or-inline decision | ✓ SATISFIED | Resolved inline (D-02); no component file created; decision recorded in CONTEXT.md and both SUMMARYs |

No orphaned requirements — REQUIREMENTS.md lists no other Phase-209-mapped IDs beyond REIGN-01/02/COMP-01, all three declared in plan frontmatter and all three marked `[x]` Complete.

### Anti-Patterns Found

None. Scanned all 5 phase-modified files (`subscriptions_live.ex`, `copy/subscription.ex`, `copy.ex`, `subscriptions_live_test.exs`, `export_copy_strings.ex`) for `TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER`/stub markers — zero debt markers found. The only `placeholder` matches are legitimate HTML form-input `placeholder:` attributes, not stub markers.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Scoped test suite green | `mix test test/accrue_admin/live/subscriptions_live_test.exs` | 12 tests, 0 failures | ✓ PASS |
| Compile clean | `mix compile --warnings-as-errors` | no output, exit 0 | ✓ PASS |
| Full test suite | `mix test` (513 tests) | 506 passing, 7 failing | ⚠️ investigated, see below |
| Visual render (light) | Read `subscriptions.png` directly | matches claimed shape | ✓ PASS |
| Visual render (dark) | Read `subscriptions-dark.png` directly | matches claimed shape, theme-correct | ✓ PASS |
| Detail page unbroken | Read `subscription-detail.png` directly | structurally identical to Plan 01's recorded pre-reign shape | ✓ PASS |

**Full-suite `mix test` investigation:** Independently re-ran `mix test` (full suite) and got the same 506/513 result claimed in 209-03-SUMMARY.md. Cross-checked all 7 failing test names against the phase's `files_modified` — none reference `subscriptions_live.ex`, `subscriptions_live_test.exs`, `copy/subscription.ex`, `copy.ex`, or `export_copy_strings.ex`. Independently traced one failure (`subscription queries use status-safe list filters`) via `git log --follow -- accrue_admin/lib/accrue_admin/queries/subscriptions.ex` to commit `c696cd92` (`fix(208-04)`, predates this phase). This corroborates the SUMMARY's own documented investigation (`deferred-items.md`) and 209-03's `human_judgment: true` D6 coverage flag. Treated as informational, not a phase-209 gap — it does not block REIGN-01/REIGN-02/COMP-01 achievement, since none of the 7 failures are Subscriptions-list-related.

### Human Verification Required

None. All must-haves were verifiable programmatically (grep gates, compile, targeted + full test runs, direct PNG reads) with high confidence. No behavior-dependent state-transition/cancellation truths in this phase's scope required a runtime probe beyond what the LiveView test suite + direct screenshot inspection already covers.

### Gaps Summary

No gaps. All 12 derived must-haves (roadmap Success Criteria 1-5, cross-referenced against PLAN frontmatter must_haves across all 3 plans) are verified true in the codebase, not merely claimed in SUMMARY.md. The one intentional deviation from REQUIREMENTS.md's literal REIGN-02 wording (per-row action dropped entirely rather than moved to an actions column/DropdownMenu) is a documented, pre-execution design decision (CONTEXT.md D-01) that is independently verified to match the actual behavior of the reference pages (`invoices_live.ex`, `customers_live.ex`) — it satisfies the requirement's stated intent ("matching the good pages") even though it diverges from the requirement's parenthetical examples. The full-suite `mix test` 7 pre-existing failures are verified (independently, not just by trusting the SUMMARY) to be unrelated to this phase's files and were correctly logged to `deferred-items.md` rather than silently ignored or falsely claimed fixed.

---

*Verified: 2026-07-19T18:48:03Z*
*Verifier: Claude (gsd-verifier)*
