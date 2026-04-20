# Phase 26 — Technical research

**Question:** What do we need to know to plan hierarchy and `ax-*` alignment well?

**Status:** Ready for planning

---

## 1. Scope anchors (from inventory + specs)

- **Normative surfaces:** Money indexes (`CustomersLive`, `SubscriptionsLive`, `InvoicesLive`, `ChargesLive`), money detail modules (`*Live` show pages under those domains), `WebhooksLive`, `WebhookLive` — per `26-CONTEXT.md` D-01 and `25-INV-03-spec-alignment.md` rows for Phase 26.
- **Non-goals:** Library-wide re-skin of coupons/connect/events unless INV-03 explicitly tags them; no new public `<.ax_*>` API renames (D-02).
- **UI contracts:** `26-UI-SPEC.md` is normative for nesting, chip typography, spacing tokens, and theme rules; inherits `20-UI-SPEC.md` / `21-UI-SPEC.md`.

---

## 2. Current implementation notes

### 2.1 List rows and signals (UX-01)

- Index LiveViews use `AppShell` → single inner `<section class="ax-page">` → `DataTable` with `columns` + `card_fields`.
- **Customers** `billing_signals_cell/1` renders **two** `span.ax-chip.ax-text-12` for ownership + tax labels (`customers_live.ex` ~L170–177). `26-UI-SPEC.md` requires **label** scale (14px semibold) for list signal chips on touched surfaces — expect migrating `ax-text-12` → token/class aligned with Phase 21 (e.g. shared chip class from `theme.css` / existing label utilities).
- **Parity work:** Apply the same row-signal cluster rules across subscriptions, invoices, charges indexes wherever tax/ownership (or equivalent) chips exist; keep **exactly two** row signals per `21-UI-SPEC` where applicable.

### 2.2 Detail pages (UX-02)

- Detail LiveViews (`customer_live`, `subscription_live`, `invoice_live`, `charge_live`) should expose **one** outer `ax-page`, KPI blocks in `ax-kpi-grid` / `KpiCard`, cards as `ax-card` without inner `ax-page` acting as card chrome, and no forbidden nested-card patterns from Phase 20.
- Executor should diff each file for duplicate `ax-page` wrappers inside cards and KPI ordering vs `26-UI-SPEC.md` “Layout and DOM hierarchy”.

### 2.3 Webhooks (UX-03)

- `webhooks_live.ex` and `webhook_live.ex` already use `ax-kpi-grid`, breadcrumbs, and table patterns — verify **font-size / padding** classes match money index tables (`ax-body`, table cell padding using `--ax-space-*`). Remove webhook-only one-off smaller body classes if present.

### 2.4 Theme tokens (UX-04)

- Semantic source: `accrue_admin/assets/css/theme.css`.
- Registry: `26-theme-exceptions.md` — append rows before merge for any unavoidable literal; prefer new semantic variables in `theme.css` first (`26-CONTEXT.md` D-04).

---

## 3. Test stack (library)

- **Primary:** `Phoenix.LiveViewTest` + `AccrueAdmin.LiveCase` (`test/support/live_case.ex`), endpoint `AccrueAdmin.TestEndpoint`, routes under `/billing/...`.
- **Hierarchy assertions:** `mix.exs` already includes `{:lazy_html, ">= 0.1.0", only: :test}` — prefer **`LazyHTML`** tree queries for counting `ax-page`, `main`, or nested depth before adding `:floki`. If a specific assertion is awkward in LazyHTML, add `:floki` to **test-only** deps with a one-line rationale in the plan task.
- **Commands:** `mix test test/accrue_admin/live/` scoped to touched modules; full package `mix test` in `accrue_admin/` before phase sign-off.

---

## 4. Traceability (INV-03)

- After each surface fix, update the relevant **clause row** status/evidence in `.planning/phases/25-admin-ux-inventory/25-INV-03-spec-alignment.md` (Partial → Aligned) or document explicit deferral with target phase — per D-01 hybrid accountability.

---

## 5. Risks and mitigations

| Risk | Mitigation |
|------|------------|
| String-only tests miss nesting regressions | Add LazyHTML (or Floki) counts for `ax-page` / `main` on edited LiveViews |
| Token change breaks host branding | Touch only semantic variables / documented utilities; exceptions go to `26-theme-exceptions.md` |
| Scope creep into Phase 27/28 | Copy unchanged unless moved with markup; no new a11y program or Playwright matrix in admin CI |

---

## Validation Architecture

> Nyquist Dimension 8 — structured feedback during execution.

### Automated spine

| Layer | Tooling | When |
|-------|---------|------|
| Unit / LiveView | ExUnit + `Phoenix.LiveViewTest` | After every task that changes HEEx |
| HTML shape | `LazyHTML` (existing test dep) | Tasks that assert hierarchy / single landmark |
| Package gate | `cd accrue_admin && mix test` | End of each plan wave + before verify-work |

### Sampling expectations

- **Per task:** Run `mix test path/to/matching_test.exs` (or file pattern from task).
- **Per wave:** Run full `accrue_admin` test suite (fast enough for library package).
- **Manual:** None required for Phase 26 primary gate; host Playwright only if a change cannot be expressed in LiveViewTest (unlikely for this phase).

### Wave 0

- **Not required** — ExUnit infrastructure and LiveCase already exist; no new framework install.

### Coverage map (requirements → verify type)

| REQ | Verify |
|-----|--------|
| UX-01 | LiveView tests on four index modules + optional LazyHTML structure |
| UX-02 | LiveView tests on four detail modules + nesting asserts |
| UX-03 | `webhooks_live_test`, `webhook_live_test` + class token grep vs money tables |
| UX-04 | Grep for raw `#RRGGBB` in touched HEEx (allowlisted via registry file) + `theme.css` diff review |

---

## RESEARCH COMPLETE
