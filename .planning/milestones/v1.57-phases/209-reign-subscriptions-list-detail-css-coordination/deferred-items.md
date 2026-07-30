# Deferred Items — Phase 209 Plan 03

Out-of-scope discoveries found while running the full `mix test` suite gate
(Task 3). Per the executor's scope-boundary rule, these are pre-existing
failures unrelated to this plan's `files_modified`
(`subscriptions_live.ex`, `subscriptions_live_test.exs`, `copy/subscription.ex`,
`copy.ex`, `export_copy_strings.ex`) and are logged here rather than fixed.

## 7 pre-existing `mix test` failures (full suite)

All 7 traced via `git log -- <file>` to source files last modified by prior,
unrelated work — none touched by Plan 01/02/03 of Phase 209:

| # | Test | Source file at fault | Last touched by (unrelated commit) |
|---|------|----------------------|-------------------------------------|
| 1 | `Timeline related resources keep item rhythm...` (`DisplayComponentsTest`) | `lib/accrue_admin/components/related_resources.ex` (renders `class="ax-card ax-related ax-related-resources"`; test expects exactly `class="ax-card ax-related"`) | `b29b2703 fix(208-04): resolve eleventh ratchet UI findings` |
| 2 | `Phase 200 Storybook dark shim mirrors every dark ax token from theme css` (`ThemeTest`) | `assets/css/theme.css` | `42e2be0b refactor(260718-u1s): single-source admin dark --ax-* set` |
| 3 | `renders RelatedResources card with coupon link and events link` (`PromotionCodeLiveTest`) | same `related_resources.ex` class mismatch as #1 | `b29b2703 fix(208-04)` |
| 4 | `renders RelatedResources card with promotion codes and events links` (`CouponLiveTest`) | same `related_resources.ex` class mismatch as #1 | `b29b2703 fix(208-04)` |
| 5 | `subscription queries use status-safe list filters` (`Queries.QueryModulesTest`) | `lib/accrue_admin/queries/*.ex` | `c696cd92 fix(208-04): resolve third ratchet UI findings` |
| 6 | `admin sessions mount the billing page` (`AuthHookTest`) | `lib/accrue_admin/live/dashboard_live.ex` (`Copy.dashboard_display_headline/0` text no longer matches rendered dashboard) | `5a373e38 fix(208-04): resolve round 96 ratchet findings` |
| 7 | `renders RelatedResources card with events link` (`ConnectAccountLiveTest`) | same `related_resources.ex` class mismatch as #1 | `b29b2703 fix(208-04)` |

## Root cause hypothesis

Per `MEMORY.md`, v1.56 (Phases 205–209) was **PARKED 2026-07-19** with
Phase 208 only "3/5" complete ("208-04/05 maintainer-gated + non-converging
on IA findings → superseded by v1.57/SEED-004"). The `related_resources.ex`
component and `dashboard_live.ex`/query-module changes from the in-flight
208-04 ratchet round appear to have landed without their corresponding test
updates before the milestone was parked. `theme.css`'s dark-shim mismatch
traces to the separate `260718-u1s` admin token refactor (also unrelated to
Phase 209).

## Action taken

None — out of scope per the executor's scope-boundary rule (only fix issues
directly caused by the current task's changes). Task 3's scoped verification
(`subscriptions_live_test.exs`, the two generated-artifact rebuilds) is
green; the full-suite gate is 506/513 green with these 7 pre-existing
failures carried forward unchanged by this plan.

## Recommended follow-up

Flag for the maintainer to either fix these 7 tests (likely quick,
mechanical class/copy syncs) or fold them into the 208-04/208-05
maintainer-gated cleanup when v1.56 is revisited/formally closed.
