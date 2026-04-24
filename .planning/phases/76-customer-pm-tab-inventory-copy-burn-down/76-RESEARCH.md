# Phase 76 — Technical research

**Question:** What do we need to know to plan ADM-13 / ADM-14 well?

## RESEARCH COMPLETE

### Code anchors

- **`accrue_admin/lib/accrue_admin/live/customer_live.ex`**
  - Payment methods tab: lines ~176–184 — `h3` **"Payment methods"**, row template with literal **"Payment method"** fallback, bullet mask **"·••••"**, empty line **"No payment methods on file."**
  - **Cross-tab stragglers (defer code, list in ADM-13 inventory):** Subscriptions KPI `delta={... " payment methods"}`, charges empty **"No charges projected yet."**, tax KPI copy, breadcrumb/page chrome — outside **`"payment_methods"`** branch.
- **`accrue_admin/lib/accrue_admin/copy.ex`** — `defdelegate` pattern to `AccrueAdmin.Copy.Subscription`, `.Invoice`, etc.; root file stays thin.
- **`accrue_admin/lib/accrue_admin/copy/subscription.ex`** — Submodule template: small functions, no delegation layer inside submodule.
- **Tests:** `accrue_admin/test/accrue_admin/live/customer_live_test.exs` — covers default tab, events, metadata, invoices; **does not** assert `?tab=payment_methods` HTML today — Phase 76 should add ExUnit coverage per CONTEXT **D-11** using **Copy** literals, not a third raw English string.
- **Playwright:** `accrue_admin/e2e/phase7-uat.spec.js` + host specs — no dedicated customer PM tab scenario; CONTEXT **D-12** = touch-only if selectors break.
- **`examples/accrue_host/e2e/generated/copy_strings.json`** — regenerated via `mix accrue_admin.export_copy_strings` (see `scripts/ci/accrue_host_verify_browser.sh`); after new public Copy functions, re-export to keep browser allowlist aligned (lightweight Phase 76 task if CI/host pulls new strings).

### Pattern decision (locked in CONTEXT)

- New module **`AccrueAdmin.Copy.CustomerPaymentMethods`** (name may vary per implementer) + **`defdelegate`** from **`AccrueAdmin.Copy`** — matches **Copy.Invoice** / **Copy.Subscription** architecture.

### Pitfalls

- Editing KPI / charges / subscriptions copy “while here” — violates **D-08** / **D-09**; inventory must record deferrals.
- Duplicating English in **ExUnit** assertions — forbidden by **D-11**; use `Copy.*` functions in assertions.

---

## Validation Architecture

Phase 76 validation is **ExUnit-first** in `accrue_admin` with optional **`mix accrue_admin.export_copy_strings`** when new copy keys are exported to the host Playwright JSON.

**Primary commands**

- Quick: `cd accrue_admin && mix test test/accrue_admin/live/customer_live_test.exs`
- Package: `cd accrue_admin && mix test`
- Copy export (when Copy public API grows): `cd accrue_admin && mix accrue_admin.export_copy_strings --out ../examples/accrue_host/e2e/generated/copy_strings.json`

**Merge-blocking family** (run before merge; exact set per host CI — see `scripts/ci/README.md`): `verify_package_docs.sh`, host integration / VERIFY-01 scripts when admin routes are materially touched.

**Nyquist / sampling**

- After each LiveView or Copy edit: run **`customer_live_test.exs`**.
- After full wave: run **`mix test`** in `accrue_admin`.
