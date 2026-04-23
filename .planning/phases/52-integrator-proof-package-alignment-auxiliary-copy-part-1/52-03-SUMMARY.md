---
phase: 52-integrator-proof-package-alignment-auxiliary-copy-part-1
plan: "03"
subsystem: ui
tags: [copy, liveview, coupons, promotion_codes, defdelegate]

requires: []
provides:
  - AccrueAdmin.Copy.Coupon and Copy.PromotionCode SSOT modules
  - defdelegate wiring on AccrueAdmin.Copy facade
  - Coupons* and PromotionCode* LiveViews call AccrueAdmin.Copy
  - ExUnit uses Copy for asserted operator strings
affects: []

tech-stack:
  added: []
  patterns:
    - "Domain copy modules + defdelegate facade matching Copy.Subscription"

key-files:
  created:
    - accrue_admin/lib/accrue_admin/copy/coupon.ex
    - accrue_admin/lib/accrue_admin/copy/promotion_code.ex
  modified:
    - accrue_admin/lib/accrue_admin/copy.ex
    - accrue_admin/lib/accrue_admin/live/coupons_live.ex
    - accrue_admin/lib/accrue_admin/live/coupon_live.ex
    - accrue_admin/lib/accrue_admin/live/promotion_codes_live.ex
    - accrue_admin/lib/accrue_admin/live/promotion_code_live.ex
    - accrue_admin/test/accrue_admin/live/coupons_live_test.exs
    - accrue_admin/test/accrue_admin/live/coupon_live_test.exs
    - accrue_admin/test/accrue_admin/live/promotion_codes_live_test.exs
    - accrue_admin/test/accrue_admin/live/promotion_code_live_test.exs

key-decisions:
  - "Use fully qualified AccrueAdmin.Copy in LiveViews for explicit routing and plan acceptance checks"

patterns-established:
  - "coupon_* and promotion_code_* copy function prefixes"

requirements-completed: [AUX-01, AUX-02]

duration: 35min
completed: 2026-04-22
---

# Phase 52 Plan 03 Summary

**Coupon and promotion-code admin surfaces route static operator English through `AccrueAdmin.Copy` with new `copy/coupon.ex` and `copy/promotion_code.ex` modules, `defdelegate` on the facade, and LiveView tests sourcing asserted strings from the same API.**

## Task Commits

1. **Domain modules** — `de32144`
2. **Facade defdelegates** — `74d07e4`
3. **LiveView migration** — `57890bf`
4. **Tests** — `19411f1`

## Self-Check: PASSED

- `cd accrue_admin && mix compile --warnings-as-errors`
- `mix test` on the four touched LiveView test modules
- `rg 'Discount management' coupons_live.ex` — no raw literal (routed via Copy)

---
*Phase: 52-integrator-proof-package-alignment-auxiliary-copy-part-1*
