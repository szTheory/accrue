# Phase 77 — Technical research

**Question:** What do we need to know to plan **ADM-15** / **ADM-16** well?

**Sources:** `77-CONTEXT.md`, `76-VERIFICATION.md`, `verify01-admin-a11y.spec.js`, `accrue_host_verify_browser.sh`, `accrue_host_seed_e2e.exs`, `theme-exceptions.md`.

## Findings

### 1. Merge-blocking VERIFY-01 spine (ADM-15)

- **`scripts/ci/accrue_host_verify_browser.sh`** seeds the DB, runs **`mix accrue_admin.export_copy_strings --out ../examples/accrue_host/e2e/generated/copy_strings.json`**, starts Phoenix, then **`npm run e2e`**. Any new Playwright spec under **`examples/accrue_host/e2e/`** that the default Playwright config picks up is automatically merge-blocking when this script runs in CI.
- **`verify01-admin-a11y.spec.js`** already defines **`scanAxe(page)`** using **`AxeBuilder({ page }).analyze()`** filtered to **`critical` + `serious`** — match this exactly (CONTEXT **D-06**).
- **Customer detail + `payment_methods` tab:** URL shape **`/billing/customers/:id?tab=payment_methods&org=<slug>`** matches **`AccrueAdmin.Live.CustomerLive`** (`tab` query param normalized in `handle_params`).
- **Fixture key:** **`admin_denial_customer_id`** is already written by **`accrue_host_seed_e2e.exs`** and enforced by **`verify_e2e_fixture_jq.sh`** — no seed contract change required for a minimal PM-tab journey (org-scoped customer row exists).
- **Copy-backed assertions:** **`copy_strings.json`** already exports **`customer_payment_methods_section_heading`**, **`customer_payment_methods_empty_copy`**, etc. — use **`copyStrings.<key>`** only, never duplicate English strings in JS (CONTEXT **D-05**).
- **Light + dark on desktop only:** Mirror **`core-admin-invoices-index`** and the **customers index** test: `test.skip` for `chromium-mobile` / `chromium-mobile-tagged`; optional **`waitForFunction`** on sidebar active link after dark theme (CONTEXT **D-09**).
- **Documentation SSOT:** Extend **`examples/accrue_host/docs/verify01-v112-admin-paths.md`** with a table row linking **`test.describe` title ↔ URL template ↔ ADM-15** (same style as Phase 55 invoice rows).

### 2. Theme + copy hygiene (ADM-16)

- **`accrue_admin/guides/theme-exceptions.md`** uses a **register table** (durable bypasses) plus **phase reviewer notes** when audits find no new debt (Phase 53/55 precedent). For Phase 77, if **`CustomerLive`** `payment_methods` branch introduces no new hex/inline hacks, add a **short Phase 77 reviewer note** only (CONTEXT **D-11–D-12**).
- **`export_copy_strings`** output path for host Playwright is fixed relative to monorepo root: run from **`accrue_admin`** with **`--out ../examples/accrue_host/e2e/generated/copy_strings.json`** — CI already does this before **`npm run e2e`**; local/PR workflow is regenerate-on-conflict (CONTEXT **D-15–D-17**).

### 3. Out of scope (explicit)

- **Subscriptions KPI / charges empty** cross-tab strings: remain second-class unless explicitly migrated (CONTEXT **D-19**); do not add separate VERIFY journeys per straggler in this phase.
- **Splitting** `verify01-admin-a11y.spec.js` — defer until file size forces it (CONTEXT **D-04**).

## Risks / mitigations

| Risk | Mitigation |
|------|------------|
| Flaky axe after theme toggle | Single `analyze()` at terminal state; reuse sidebar `waitForFunction` pattern from existing tests |
| Drift between Copy and JSON | Regenerate **`copy_strings.json`** after any Copy module change; CI regenerates in browser script |
| Wrong customer id in URL | Assert **`fixture.admin_denial_customer_id`** truthy like **`invoice_id`** in invoice tests |

## Validation Architecture

**Nyquist / Dimension 8 — how execution proves ADM-15 and ADM-16**

| Dimension | Evidence path |
|-----------|----------------|
| **Automated merge-blocking** | `bash scripts/ci/accrue_host_verify_browser.sh` (or host `npm run e2e` with same env as CI) must pass after Plan 01 lands — includes new customer PM-tab axe scenario |
| **Static / doc** | `rg` asserts on **`verify01-v112-admin-paths.md`** row for ADM-15; **`77-VERIFICATION.md`** records closure statements with file:line citations |
| **Copy artifact honesty** | After any `AccrueAdmin.Copy.*` change: `cd accrue_admin && mix accrue_admin.export_copy_strings --out ../examples/accrue_host/e2e/generated/copy_strings.json` then `git diff --exit-code examples/accrue_host/e2e/generated/copy_strings.json` in CI-equivalent check |
| **Theme posture** | `theme-exceptions.md` contains dated Phase 77 note or register rows only if real debt ships |

**Sampling (executor):**

- After **Plan 01** tasks touching only Playwright/docs: `cd examples/accrue_host && npx playwright test e2e/verify01-admin-a11y.spec.js --grep "<new test title substring>"` (desktop project).
- After **Plan 02** (docs + Mix export): `cd accrue_admin && mix compile` + optional full browser script if time budget allows before phase close.

**Wave 0:** Not required — Playwright + Mix already installed via existing host CI path.

---

## RESEARCH COMPLETE
