---
phase: 34
slug: operator-home-drill-flow-nav-model
status: verified
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-21
---

# Phase 34 — Validation strategy

> Nyquist validation: each requirement has automated verification mapped to ExUnit (and README inventory where doc-only). Phase execution complete; this document audited 2026-04-21.

---

## Test infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`accrue_admin`); host Playwright unchanged (VERIFY-01) |
| **Config** | `accrue_admin/mix.exs`; tests under `accrue_admin/test/` |
| **Quick run command** | `cd accrue_admin && mix test test/accrue_admin/scoped_path_test.exs test/accrue_admin/nav_test.exs test/accrue_admin/components/navigation_components_test.exs test/accrue_admin/live/dashboard_live_test.exs --warnings-as-errors` |
| **Full suite command** | `cd accrue_admin && mix test --warnings-as-errors` |
| **Estimated runtime** | ~5–15s quick slice; full package ~5s on this repo snapshot |

---

## Sampling rate

- **After task-level URL/nav changes:** Run the **quick run command** above.
- **Before merge / after plan 34-02:** Run **full suite command** (includes `customer_live_test`, `invoice_live_test`, `router_test`).
- **Doc-only task (34-03-02):** `grep`/README checks; no runtime beyond compile if no code change.

---

## Per-task verification map

| Task ID | Plan | Wave | Requirement | Threat ref | Secure behavior | Test type | Automated command | Status |
|---------|------|------|---------------|------------|-----------------|-----------|---------------------|--------|
| 34-01-01 | 01 | 1 | OPS-01 | T-nav-01 | Scoped URLs match `OwnerScope` | unit + compile | `mix compile --warnings-as-errors`; `mix test test/accrue_admin/scoped_path_test.exs` | green |
| 34-01-02 | 01 | 1 | OPS-01 | T-nav-01 | Table tests global / org / query | unit | `mix test test/accrue_admin/scoped_path_test.exs --warnings-as-errors` | green |
| 34-01-03 | 01 | 1 | OPS-01 | T-nav-02, T-ui-01 | Distinct paths; linked card + `aria-label` | component + LV | `navigation_components_test.exs`; `dashboard_live_test.exs` (KPI `href` + labels); `mix accrue_admin.assets.build` | green |
| 34-02-01 | 02 | 2 | OPS-02 | T-idor-01 | Invoice row `href` via `ScopedPath` | compile | `mix compile --warnings-as-errors` | green |
| 34-02-02 | 02 | 2 | OPS-02 | T-idor-01, T-nav-03 | Breadcrumb hrefs scoped; `current_path` unchanged pattern | integration | `mix test test/accrue_admin/router_test.exs --warnings-as-errors` | green |
| 34-02-03 | 02 | 2 | OPS-02 | T-idor-01 | HTML contains `/invoices/` and `/customers/` drill proof | integration | `mix test test/accrue_admin/live/customer_live_test.exs test/accrue_admin/live/invoice_live_test.exs --warnings-as-errors` | green |
| 34-03-01 | 03 | 1 | OPS-03 | T-conf-01 | Nav href parity vs former `AppShell` | compile + unit | `mix compile --warnings-as-errors`; `mix test test/accrue_admin/nav_test.exs` | green |
| 34-03-02 | 03 | 1 | OPS-03 | T-doc-01 | README route table matches `Router` | static | `grep -Fq "## Admin routes" accrue_admin/README.md` (CI: human/ review) | green |
| 34-03-03 | 03 | 1 | OPS-03 | — | Order: Home first; Webhooks before Event log | unit | `mix test test/accrue_admin/nav_test.exs --warnings-as-errors` | green |

---

## Wave 0 requirements

Existing infrastructure covers all phase requirements. No Wave 0 stub files required.

---

## Manual-only verifications

| Behavior | Requirement | Why manual | Test instructions |
|----------|-------------|------------|---------------------|
| First-open operator value | OPS-01 | Human judgment on information density vs noise | Mount `/billing` as platform admin; confirm KPI row reads as actionable, not misleading, for your fixture volumes. |
| Drill smoothness | OPS-02 | Subjective path length vs baseline | Customer → Invoices tab → invoice detail; confirm breadcrumb matches mental model and org banner still coherent with `?org=` when using org session. |

---

## Validation audit 2026-04-21

| Metric | Count |
|--------|-------|
| Gaps found | 1 |
| Resolved | 1 |
| Escalated | 0 |

**Gap closed:** Dashboard KPI deep links + `aria-label` text were not asserted in LiveView HTML; resolved by extending `dashboard_live_test.exs`.

---

## Validation sign-off

- [x] All tasks have automated verify commands or documented static checks
- [x] Sampling continuity maintained during phase execution
- [x] No watch-mode flags introduced
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-21
