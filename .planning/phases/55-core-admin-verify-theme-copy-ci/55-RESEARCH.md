# Phase 55 — Technical research

**Question:** What do we need to know to plan **ADM-09** (merge-blocking VERIFY-01 on `/invoices` + `/invoices/:id`), **ADM-10** (theme-exceptions + doc SSOT), and **ADM-11** (`export_copy_strings` / `copy_strings.json` / allowlist)?

## Findings

### VERIFY-01 spine (host)

- **Canonical CI:** `scripts/ci/accrue_host_verify_browser.sh` runs `mix accrue_admin.assets.build` → `mix accrue_admin.export_copy_strings --out …/e2e/generated/copy_strings.json` → full `npm run e2e` (includes `verify01-admin-a11y.spec.js`).
- **Patterns:** `examples/accrue_host/e2e/verify01-admin-a11y.spec.js` — `scanAxe` filters **serious** + **critical** only; **desktop-only** theme scans via `test.skip` on `chromium-mobile` / `chromium-mobile-tagged`; **`domcontentloaded`** + `waitForLiveView` after navigation; **light + dark** on customers index; auxiliary flows use **light-only** where specified.
- **Copy anti-drift:** Spec reads `copy_strings.json` from disk; every `copyStrings.<key>` must appear in `@allowlist` in `accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex` (Phase **53** precedent). Delegated `AccrueAdmin.Copy.Invoice` functions are exported as keys on **`AccrueAdmin.Copy`** (0-arity names in JSON).
- **Playwright tags (1.57):** Use `test.describe('title', { tag: '@core-admin-invoices-index' }, () => { … })` (or equivalent **single** top-level describe per **55-CONTEXT D-03**) so HTML reports / `grep` can bind matrix ids.

### Invoice anchor surfaces

- **Routes:** `/billing/invoices?org=<slug>` and `/billing/invoices/:id?org=<slug>` (mount-relative `/invoices` per **54-CONTEXT** + host **`/billing`** prefix — mirror existing tests’ URL construction).
- **InvoicesLive / InvoiceLive:** Operator strings from **`AccrueAdmin.Copy.Invoice`** via **`AccrueAdmin.Copy`** delegates (**`copy.ex`**). Table uses **`invoice_link/2`** for drill-down — detail can be reached by **fixture `invoice_id`** URL **or** index → first row, but **fixture-backed id** matches Connect detail stability (**55-CONTEXT**).
- **Seed gap:** `scripts/ci/accrue_host_seed_e2e.exs` today emits **`connect_account_id`** but **no `invoice_id`**. Listing may be **empty** without an inserted **`Accrue.Billing.Invoice`** (and required FKs / processor fields per **`accrue/lib/accrue/billing/invoice.ex`**). Planning assumes **minimal invoice insert** + **`invoice_id` in fixture JSON** + **cleanup** in `cleanup_fixture_footprint!` using a stable **`inv_host_browser_*`** `processor_id` prefix (mirror subscription/connect patterns).

### PDF / tab / download (**55-CONTEXT D-07–D-09**)

- **Merge-blocking:** Assert **billing record UI** — controls **`Open PDF`**, **`Download rendered PDF`**, **`Open rendered PDF`** (names from **`copyStrings`**) are **visible** and **enabled** after LiveView settles; **no** `try/catch` swallowing failures.
- **Strict binary / popup:** Optional second `test.step` when harness is deterministic; if not, document advisory in **`core-admin-parity.md`** / host VERIFY doc — **never** silent pass.

### Parity matrix (**ADM-09**)

- **`accrue_admin/guides/core-admin-parity.md`:** Invoice rows currently **`Named VERIFY flow id` —** and **`VERIFY-01 lane`** `planned — Phase 55 (ADM-09)`. **Same change-set** as merge-blocking specs: set ids to **`core-admin-invoices-index`** and **`core-admin-invoices-detail`**, flip lane to **`merge-blocking`** (**D-04**).
- **Drift guard (D-05):** Optional script under `scripts/ci/` — e.g. verify every `merge-blocking` row’s **Named VERIFY flow id** appears in `verify01-admin-a11y.spec.js` (and optionally no orphan `@core-admin-*` tags). Wire into existing CI only if a **documented** hook point exists (avoid drive-by workflow redesign).

### Theme + contributor docs (**ADM-10**)

- **SSOT:** `accrue_admin/guides/theme-exceptions.md` — add rows **only** for intentional deviations introduced or discovered in this phase (**55-CONTEXT D-18**); otherwise **Phase 53-style reviewer note** if audit finds **zero** bypasses.
- **`admin_ui.md`:** Still links **`.planning/phases/26-…/26-theme-exceptions.md`** — replace with **`theme-exceptions.md`** (package path) per **D-19**.

### Export task (**ADM-11**)

- **`Mix.Tasks.AccrueAdmin.ExportCopyStrings`:** `@allowlist` is explicit `~w(... )a`; **Jason.encode!** map sorted by key order in output — keys sorted alphabetically in JSON (stable). Extend allowlist **only** with keys referenced as **`copyStrings.*`** in new/edited specs for invoice flows (**bounded** closure).

## Pitfalls

- **Empty invoices table** without seed → flaky or vacuous index tests.
- **`networkidle`** on LiveView — forbidden / discouraged (**53** plans).
- **Over-broad allowlist** — violates **D-13** (invoice VERIFY closure only).
- **Silent PDF downgrade** — violates **D-09**.

## Validation Architecture

**Nyquist / execution sampling**

| Dimension | Strategy |
|-----------|----------|
| Automated gate | `bash scripts/ci/accrue_host_verify_browser.sh` from repo root after any change to seed, spec, export task, or generated JSON. |
| Fast feedback | `cd examples/accrue_host && npm run e2e:a11y` (or targeted `playwright test … --grep @core-admin-invoices`) **after** `export_copy_strings` from `accrue_admin/` when iterating locally. |
| Copy drift | `rg` loop: every `copyStrings.` key in `verify01-admin-a11y.spec.js` ⊆ `@allowlist` (same command family as **53-02**). |
| Docs | Grep `core-admin-parity.md` for **`core-admin-invoices-index`** / **`core-admin-invoices-detail`** and **`merge-blocking`** after matrix edit. |

**Wave 0:** Not required — Playwright + Mix task already exist.

---

## RESEARCH COMPLETE
