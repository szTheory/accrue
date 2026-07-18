---
quick_id: 260718-kf9
title: Align the "Scale Customer" persona with the real Scale plan (fix orphan price_premium)
status: complete
date: 2026-07-18
commit: 1ba06cba
---

# Quick Task 260718-kf9 — Summary

## What changed
- `priv/repo/seeds/hero_accounts.exs` — the enterprise "Scale Customer" persona now subscribes to
  `"price_metered"` (the catalog **Scale** plan) instead of the orphan `"price_premium"`; removed the stale
  "assuming price_premium exists" placeholder comments.
- `config/config.exs` — the `:advanced_reports` entitlement plan `premium: [price_ids: ["price_premium"]]`
  → `scale: [price_ids: ["price_metered"]]` (the `:premium` key was referenced nowhere else), so the
  persona keeps advanced-reports access on its new plan.
- `test/accrue_host_web/live/entitlements_guard_test.exs` — the two *entitled* subscriptions moved
  `price_premium` → `price_metered`.

## Why
`price_premium` was never in `AccrueHost.Billing.Plans`, so `plan_label/1` fell back to the raw id and
`plan_badge/2`/`active_plan_id/1` matched no card — the persona's plan showed as "price_premium" with
nothing highlighted. The persona is literally the "Scale Customer" on the "Scale plan", so `price_metered`
(Scale) is the correct catalog id; moving the entitlement with it preserves the feature-gating demo and
ties `:advanced_reports` to the visible top tier.

## Verification
- `rg price_premium examples/accrue_host` → no hits (host fully migrated).
- `mix test .../entitlements_guard_test.exs` → **3/0**.
- Playwright (live, reseeded) as enterprise@: current subscription reads **"Plan Scale"** (no raw id),
  the **Scale** card shows **"Current plan"**, Launch/Studio show "Available".
- Entitlement preserved: `/app/reports/advanced` as enterprise@ renders "Cohort performance / …advanced
  cohort reporting through its active plan." (entitled; not redirected).
- Applied via `make reset` (seeds are idempotent, so a fresh volume was required); FakeHydration then
  loaded 135 customers / 123 subscriptions.

## Notes
- Demo data/config only — no core `accrue` change. Pre-existing dirty files + `mix.lock` left untouched.
- The upstream `accrue` package's `subscription_actions_test.exs` still uses `"price_premium"` as a generic
  id — intentionally left alone (independent unit tests, not the host catalog).
