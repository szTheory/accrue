---
quick_id: 260622-i2c
slug: admin-uat-green-up
date: 2026-06-22
status: complete
---

# Summary: Green the accrue_admin Playwright browser UAT

The only remaining main-CI red (after the doc-gate fix 260622-h7h) was the accrue_admin **Playwright
browser UAT** — also folded into the Release gate via the Phase 192 step. The failures were
**pre-existing e2e spec-drift** from the redesign arc (h72 webhooks selection-retry → io6 customers
filter removal → olr stat-strip → fql headers) that shipped without updating the Playwright specs
(every task ran only `mix test`, never the UAT), **plus one genuine responsive bug**. Iterated
**locally** (the config auto-boots `mix accrue_admin.e2e.server`; chromium installed) — no CI loops.
3 atomic code commits on `main`.

## Result

`cd accrue_admin && npx playwright test` → **92 passed, 0 failed** across BOTH `chromium-desktop`
and `chromium-mobile`, every spec. `mix compile --warnings-as-errors` clean. Full admin
`mix test --seed 0` on a clean DB → **350 tests, 0 failures**.

## 9 distinct fixes — 1 real app bug, 8 spec-drift (none weakened/skipped)

| Spec:line | Was (broken) | Now (shipped contract) | Type |
|---|---|---|---|
| `phase191:197` customer-detail 320px clip | doc overflowed ~34px | KPI delta wraps; overflow 0 | **APP FIX** |
| `phase7-uat:29` dashboard | `heading "Dashboard"` / "Accrue Admin" / `button "Dark"` | h1 "Billing operations" / `img "Accrue Ops"` / `radio "Dark"` | drift |
| `phase7-uat:68` + `phase191:307` webhooks bulk | `prepare-bulk-replay`/`confirm-bulk-replay` + old copy | `toggle-all`→`bulk-action`→`confirm-retry-selected`; h1 "Webhooks"; `/failed every automatic retry/` | drift |
| `phase191:352` state-copy | `?status=no-records` (filter removed) | `?q=<no-match>` → DataTable empty-state | drift |
| `admin-baseline:584` (mobile) | 30s default timeout (axe sweep ~30s+) | restored `test.setTimeout(240_000)` | drift |
| `admin-interactions:1069` focus-ring | live `.focus()` (UA `:focus-visible` never fires, WR-07) | probe forced-focus specimens `[data-ax-state="focus"]` | drift |
| `admin-motion-trace:110` nav | `data-collapse-toggle` (collapse removed in nr8) | mobile sidebar overlay `data-sidebar-toggle` | drift |
| `dropdown-dismiss:8` | summary click + "Status badges" text (gone) | open via `dispatchEvent`, assert outside-click dismiss | drift |

## The one real app fix (not a spec edit)

`phase191:197`: the customer-summary **Tax-risk KPI delta** had `.ax-kpi-delta { white-space:
nowrap }`, so a long delta caption ("No disabled recurring tax or finalization failures") forced the
KPI grid — and the document — ~34px past 320px. Fixed in `assets/css/app.css`
(`.ax-kpi-delta { white-space: normal; overflow-wrap: anywhere }` + `.ax-kpi-card { min-width: 0 }`)
and rebuilt + committed `priv/static/accrue_admin.css`. The helper at
`phase191-page-flow-helpers.js:295` was NOT loosened.

## Commits (code only)
- `90952f5f` — fix: KPI delta wrap + rebuilt bundle (the 320px overflow bug)
- `b457523c` — test: webhooks selection-driven realign (phase191:307,:352, phase7-uat) + dashboard drift
- `ff97c4e9` — test: remaining drift (focus-ring, motion-trace, dropdown, baseline timeout)

## Notes
- **The executor's flagged `mix test` "failure" (`webhooks_live_test:106`, count==2) was e2e-DB
  pollution, NOT real** — the e2e server seeds committed webhook rows into the shared `MIX_ENV=test`
  DB, which inflate count assertions in a subsequent `mix test` (Ecto sandbox sees pre-existing
  committed rows). After `ecto.drop/create` (test_helper re-migrates on startup), full admin
  `mix test --seed 0` = 350/0. **Gotcha: after running the local e2e UAT, reset the test DB before
  trusting `mix test`.**
- No assertion was weakened/skipped/deleted; spec edits repoint to the shipped DOM/copy; the real
  clipping defect was fixed in the app.
- Guardrails honored: no `examples/accrue_host/**`, StatusBadge, CSP, ROADMAP, `.planning/` touched.

## Lesson (process)
Per-task verification of `cd accrue_admin && mix test` does NOT run the Playwright UAT or the core
package doc-contract tests — both are CI-only. UI/copy/DOM changes silently drift these. Run
`npx playwright test` (admin UAT) + `bash scripts/ci/verify_package_docs.sh` locally alongside
`mix test` when touching admin UI.
