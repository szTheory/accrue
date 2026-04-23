# Phase 54 — Technical research

**Question:** What do we need to know to plan **ADM-07** (published parity matrix) and **ADM-08** (invoice anchor burn-down) well?

---

## Router SSOT for ADM-07 rows

- **`accrue_admin/lib/accrue_admin/router.ex`** `live_session :accrue_admin` lists every mounted operator surface. **Core** rows for the matrix are the **11** `live/3` entries in **54-CONTEXT D-17** (dashboard through webhooks show). Auxiliary **`/coupons*`**, **`/promotion-codes*`**, **`/connect*`**, **`/events`** are **excluded** from the core table (**D-18**).
- **`dev_routes?`** gated **`/dev/*`** entries are **out of table** with prose note only (**D-18**).

---

## ADM-08 anchor implementation hotspots

### `InvoicesLive`

- Already uses **`Copy.invoices_index_empty_title/0`** and **`Copy.invoices_index_empty_copy/0`** for empty state.
- **Remaining P0 literals** (operator-visible): breadcrumb labels, page eyebrow/headline/body, KPI card labels/meta strings, **DataTable** column labels, filter field labels, status/collection **select option** human labels, **`assign(:page_title, "Invoices")`**, and **`aria-label="Invoice summary"`**.
- **Dynamic / data-driven** strings (customer names, money from `format_money`, status atoms via `humanize/1`) stay computed — **do not** force through Copy unless they are **fixed English templates** (e.g. `" · "` joiners around **semantic** words may stay mechanical).

### `InvoiceLive`

- Already uses **`Copy`** for several flashes and warnings (`invoice_select_action_warning`, `invoice_pdf_open_info`, `invoice_action_recorded_info`).
- **Tests** (`invoice_live_test.exs`) assert many **raw English** fragments (`"Tax & ownership"`, `"Open PDF"`, `"Confirm action"`, etc.) — migrating HEEx to Copy **requires** updating tests to **`Copy.*`** or **`html_escape`**-safe equivalents (**D-10**).

### Copy module layout

- **`accrue_admin/lib/accrue_admin/copy.ex`** already holds invoice-adjacent strings; high-volume expansion should use **`lib/accrue_admin/copy/invoice.ex`** + **`defdelegate`** from **`AccrueAdmin.Copy`** to avoid an unmaintainable single file (**50-CONTEXT D-07**).

---

## VERIFY-01 / Playwright

- **`examples/accrue_host/e2e/verify01-admin-a11y.spec.js`** currently focuses **customers** / **subscriptions** (and related paths) — **grep** shows **no invoice-specific** merge-blocking flow in that file at planning time.
- **Implication:** Phase 54 likely **does not** touch Playwright; if invoice HEEx changes alter strings used elsewhere, apply **minimal** edits only (**D-14**).

---

## ExDoc / Hex discoverability

- **`accrue_admin/mix.exs`** today: `extras: ["README.md", "guides/admin_ui.md"]`. **`core-admin-parity.md`** must be added to **`extras`** and **`groups_for_extras`** alongside **`admin_ui.md`** (**54-CONTEXT D-01, D-04**).

---

## Validation Architecture

> Nyquist **Dimension 8** — every wave must leave the repo in a **checkable** state with **fast feedback** between tasks.

| Dimension | Strategy for Phase 54 |
|-----------|------------------------|
| **Automated spine** | **`mix test`** on **`accrue_admin`** scoped to **`live/invoices_live_test.exs`**, **`live/invoice_live_test.exs`**, and any new **`copy/*_test`** if added. **`mix compile`** for the umbrella paths touched. |
| **Sampling rate** | After **each** ADM-08 task that edits Elixir: run the **invoice LiveView tests** (target **&lt; 60s** on dev hardware). After **wave 1** (docs-only): `mix compile` in **`accrue_admin`** (and root if `mix.exs` workspace requires). |
| **Manual** | Spot-check **invoice index + detail** in **`examples/accrue_host`** dev server for **regressions** in headings/KPIs after large Copy refactors — optional, not gate-blocking if tests cover strings. |
| **CI honesty** | Do **not** claim VERIFY-01 merge-blocking coverage for invoices until **ADM-09** — matrix column documents **`planned — Phase 55 (ADM-09)`**. |

**Wave 0:** Not required — **ExUnit** + **`mix compile`** already exist; no new test framework install.

---

## Risks / landmines

- **Over-migration:** Moving **data-derived** or **Stripe enum** labels into Copy without stable keys creates churn — keep **status filter values** (`draft`, `open`, …) as **data**; migrate **column headers** and **fixed English chrome**.
- **`humanize/1`** output for statuses is **English** but **generic** — product decision: leave as-is (**D-10** scoping) unless CONTEXT amended.
- **PDF / step-up** strings: some already Copy-backed; ensure **modal** and **destructive action** labels share Copy with tests.

---

## RESEARCH COMPLETE

Planning can proceed with **54-CONTEXT.md** as the decision lock and this file for implementation hotspots.
