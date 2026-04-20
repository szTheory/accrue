---
status: passed
phase: 29-mobile-parity-and-ci
updated: 2026-04-20
---

# Phase 29 — Verification

## Merge gate (CI)

Pull requests already run **`host-integration`** with full Playwright; this phase adds **`e2e/verify01-admin-mobile.spec.js`**. Ensure admin assets are rebuilt when changing `accrue_admin/assets` (see `mix accrue_admin.assets.build` in `accrue_admin`).

Focused local checks:

```bash
cd examples/accrue_host && npx playwright test e2e/phase13-canonical-demo.spec.js --project=chromium-desktop
cd examples/accrue_host && npx playwright test e2e/verify01-admin-mobile.spec.js --project=chromium-mobile
cd accrue_admin && mix test
```

## Requirements coverage

| ID | Evidence |
| --- | --- |
| **MOB-01** | `e2e/support/overflow.js` + `verify01-admin-mobile.spec.js` — `expectNoHorizontalOverflow` on customers index and customer detail after `waitForLiveView` on **chromium-mobile**. |
| **MOB-02** | `initShellNav` + CSS overlay; Playwright opens **Menu**, asserts sidebar Dashboard/Customers/Subscriptions links, **Escape** clears `ax-shell-nav-open`. README subsection documents operator contract. |
| **MOB-03** | Same mobile spec: login → billing → org switcher → customers list → customer detail URL with overflow checks (`scrollIntoViewIfNeeded` on org button). |

## Human verification

None required for merge; README subsection captures operator expectations adjacent to VERIFY-01.
