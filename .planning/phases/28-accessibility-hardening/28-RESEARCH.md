# Phase 28 — Technical research

**Phase:** 28 — Accessibility hardening  
**Question:** What do we need to know to plan A11Y-01..04 well?

## RESEARCH COMPLETE

### Normative sources

| Source | Relevance |
|--------|-----------|
| [Phoenix.LiveView.JS](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html) | `push_focus/2`, `pop_focus/1`, `focus_first/2` for dialog open/close without stealing focus on every patch |
| [ARIA APG — Dialog (Modal)](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/) | Initial focus, Escape dismisses when cancellable, return focus, name exposed to AT |
| WCAG 2.2 AA (contrast) | Body, labels, controls on representative routes; axe `color-contrast` serious/critical |
| `@axe-core/playwright` | Already in `examples/accrue_host/package.json` ^4.11 — wire to VERIFY-01 journey |

### Current implementation (code)

| Concern | File / area | Finding |
|---------|--------------|---------|
| Step-up shell | `accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex` | `role="dialog"`, `aria-labelledby="step-up-title"` present; submit control is `class="ax-link"` with literal **"Verify"** — CONTEXT + UI-SPEC require **"Verify identity"** via `AccrueAdmin.Copy` |
| Step-up state | `accrue_admin/lib/accrue_admin/step_up.ex`, `charge_live.ex`, `invoice_live.ex`, `subscription_live.ex` | `step_up_submit` clears pending on success; **no** `JS.pop_focus` / `push_focus` today — focus restoration is implicit browser behavior only |
| Data grid | `data_table.ex` | Desktop branch is `<table class="ax-data-table-grid">` with `<thead>` and `scope="col"` — **no** `<caption>`; mobile uses `<dl>` (keep) |
| Representative indexes | `customers_live.ex`, `webhooks_live.ex` | `live_component` `DataTable` with `id="customers"` / `id="webhooks"` — correct injection points for `table_caption` assign per CONTEXT D-02 |
| Focus rings | `accrue_admin/assets/css/app.css` | `:focus-visible` rules exist for `.ax-button`, `.ax-link`, `.ax-field-control`, sidebar, etc. — step-up inner controls should be checked for gaps (e.g. modal-scoped first focus) |
| Host E2E | `examples/accrue_host/e2e/verify01-admin-mounted.spec.js` | Login → org → customers URL + `waitForLiveView` — **extend** this file or add sibling `verify01-admin-a11y.spec.js` per CONTEXT D-03/D-04 |

### Ecosystem / product patterns

- **Mountable admin libraries** (Rails engines, Nova): hosts own global a11y; Accrue documents **one** optional `phx-hook` for tab cycle + optional `inert` so we do not require Alpine/Radix (CONTEXT D-01).
- **Table naming:** `<caption class="sr-only">` (or utility equivalent) aligned with page title / `Copy` beats duplicate `aria-label` strings on `<table>`.

### Pitfalls

1. **Focus on every LiveView render** — attaching `JS.focus_first` to events that fire on validation errors causes focus theft; bind focus JS to **dialog mount** (`phx-mounted` on the `:if={@pending}` subtree) or explicit open transition only.
2. **Double trap** — document that hosts with a global focus manager must not stack Accrue’s hook twice (CONTEXT D-01).
3. **Axe flake** — scans before `waitForLiveView` complete will false-positive; always await LiveView connection like existing VERIFY-01 specs.
4. **Theme for contrast** — A11Y-03 needs **explicit** light and dark; toggle UI or `data-theme` on `:root` in host fixture — do not rely only on `prefers-color-scheme` unless documented.

### Recommendations for planner

1. **Wave 1 (parallel):** Plan 01 = step-up + focus + Copy + ExUnit; Plan 02 = `DataTable` optional caption + customers/webhooks + component test.
2. **Wave 2:** Plan 03 = host Playwright axe + forced themes + short `28-VERIFICATION.md` (or phase doc) listing manual contrast gaps axe misses.
3. Every plan includes `<threat_model>` (admin surfaces: XSS-safe copy, no credential echo in new strings).

---

## Validation Architecture

**Dimension 8 (Nyquist):** Prove A11Y-01..04 with automated commands after each wave where feasible; document residual manual contrast gaps.

| Dimension | How Phase 28 satisfies it |
|-----------|---------------------------|
| **Correctness** | ExUnit / LiveViewTest: focus order, caption markup, Escape handler presence; Playwright: axe violations filtered to `critical` + `serious` |
| **Regression** | Existing step-up tests extended; new host spec fails CI if serious a11y regressions on customers path |
| **Security** | Copy changes remain static English; no new interpolation of user secrets into operator-visible strings; modal still CSRF-protected via LiveView |
| **Observability** | N/A |
| **Performance** | Hook + axe scan bounded to one journey; optional second URL behind same spec file only if flake budget allows |
| **Compatibility** | Optional `DataTable` assign defaults `nil` — no API break for other LiveViews |
| **Operability** | `VALIDATION.md` lists `mix test` paths and `npm run e2e` under `examples/accrue_host` |
| **Sampling** | After each plan: run plan `<automated>` blocks; wave 2 ends with full host a11y spec |

**Wave 0:** Not required — ExUnit and Playwright already present.

**Sign-off criterion:** `accrue_admin` tests green for touched modules; `examples/accrue_host` `npm run e2e -- e2e/verify01-admin-a11y.spec.js` (or chosen path) green in CI matrix that already runs VERIFY-01.
