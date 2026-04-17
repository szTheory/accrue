# Phase 21 — Technical Research

**Question:** What do we need to know to plan VERIFY-01’s **executable** half (admin + host + Fake + browser) well?

**Sources:** `.planning/phases/21-admin-and-host-ux-proof/21-CONTEXT.md`, Phase 20 completion (loaders, `?org=`, denial copy), `examples/accrue_host` Playwright harness, `scripts/ci/accrue_host_seed_e2e.exs`.

---

## 1. Test pyramid and ownership

- **Library packages** (`accrue`, `accrue_admin`): stay ExUnit-fast; assert strings and assigns in `*_live_test.exs` where LiveView behavior is owned.
- **Host example** (`examples/accrue_host`): owns ConnCase, LiveViewTest, and Playwright. VERIFY-01 browser proofs belong here, not in package-default `mix test` for `accrue`.
- **AccrueHost.Billing** (and siblings): all new host billing proofs should call the same public modules evaluators copy — no ad-hoc `Repo` queries to Accrue schema from host LiveViews.

---

## 2. Playwright harness (current + extensions)

- **Fixture contract:** `global-setup.js` runs `mix run scripts/ci/accrue_host_seed_e2e.exs` with `ACCRUE_HOST_E2E_FIXTURE` path; specs read JSON via `readFixture()`.
- **Reseed:** `reseedFixture()` exists in `phase13-canonical-demo.spec.js` — use **only** for flows that mutate billing graph (CONTEXT D-01).
- **Extensions needed:** fixture map must grow **named keys** (`org_alpha_slug`, `org_beta_slug`, `tax_invalid_customer_hint`, optional emails) without breaking existing keys consumed by phase13 spec (`password`, `normal_email`, `admin_email`, etc.).
- **Projects:** `playwright.config.js` should keep `workers: 1` until DB isolation exists; add grep/tag for `@mobile` subset per CONTEXT.

---

## 3. Admin IA: lists vs detail

- **Indexes:** `customers_live.ex`, `subscriptions_live.ex`, `invoices_live.ex`, `charges_live.ex` (and associated templates) are the money-relevant surfaces.
- **Single classifier:** introduce or extend one module (e.g. `AccrueAdmin.BillingPresentation` or extend existing query projection) that maps DB fields → `{ownership_class, tax_health}` where `tax_health` is `:off | :active | :invalid_or_blocked`.
- **Detail:** `customer_live.ex`, `subscription_live.ex`, `invoice_live.ex`, `charge_live.ex` (where applicable) get a **Tax & ownership** card using the **same** function so list/detail cannot drift.
- **Shell:** `accrue_admin/components/app_shell.ex` already builds org-scoped links — add **visible** active-organization label + name when `?org=` is present (CONTEXT D-02).

---

## 4. Tax and org data sources

- Reuse Phase 18–19 tax-risk fields and Phase 20 owner scope; invalid-location messaging should align with existing flash/copy patterns from tax work — grep `tax` and `Tax` in `accrue_admin` and host `subscription_live` for current strings before inventing new ones.

---

## 5. Webhook / replay denial proofs

- Phase 20 locked ambiguous replay copy and cross-org denial. Phase 21 adds **browser** assertions: Playwright (admin session) or host-mounted admin tests must hit the same strings — prefer reusing exact literals from `20-UI-SPEC.md` / live modules.

---

## 6. Requirements traceability

- `REQUIREMENTS.md` maps VERIFY-01 to Phase 21 **and** Phase 22. This phase covers only the **executable** slice (D-04); finance narrative is Phase 22.

---

## Validation Architecture

> Nyquist / Dimension 8: every plan wave must have automated feedback on the host + admin surfaces it touches.

| Dimension | How Phase 21 samples it |
|-----------|-------------------------|
| Unit / component | `accrue_admin` LiveView tests for new assigns, badges, denial paths |
| Integration | `examples/accrue_host` `mix test` for `AccrueHost.Billing` and billing LiveViews |
| Browser | `npx playwright test` from `examples/accrue_host` (Chromium default; `@mobile` optional job) |
| Security / ORG-03 | Assert no cross-org row leakage; replay denial strings unchanged |
| Regression | Re-run phase13 canonical spec after fixture shape change |

**Wave 0:** Not required — Playwright + Mix already installed; extend fixture and specs.

**Risk:** Fixture JSON shape change can break `phase13-canonical-demo.spec.js` — mitigation: backward-compatible keys + update phase13 to read new optional keys only when present.

---

## RESEARCH COMPLETE

Planning can proceed with `21-CONTEXT.md`, `21-UI-SPEC.md`, and this document as inputs.
