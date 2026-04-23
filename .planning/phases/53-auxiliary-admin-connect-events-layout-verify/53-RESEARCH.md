# Phase 53 — Technical research

**Question:** What do we need to know to plan **Connect + events Copy**, **token discipline**, and **VERIFY-01** extension well?

## Stack and constraints

- **Elixir / Phoenix LiveView** admin in `accrue_admin`; **host-mounted** proof in `examples/accrue_host` with Playwright + `@axe-core/playwright`.
- **Copy SSOT:** `AccrueAdmin.Copy` + `defdelegate` into `accrue_admin/lib/accrue_admin/copy/*.ex` (proven pattern: `Coupon`, `PromotionCode`, `Subscription` in Phase 52).
- **Naming (CONTEXT D-09–D-10):** new modules `Copy.Connect` and `Copy.BillingEvent`; prefixes `connect_accounts_*`, `connect_account_*`, `billing_events_*`, `billing_event_*` (reserved).
- **No live deauthorize UI** (D-06): destructive modal copy in UI-SPEC is reserved — do not wire `handle_event` for Stripe deauthorize in this phase.
- **VERIFY-01:** extend `examples/accrue_host/e2e/verify01-admin-a11y.spec.js`; reuse `waitForLiveView`, `login`, `readFixture` / `reseedFixture` from `e2e/support/fixture.js`; **no `networkidle`**; desktop light+dark where existing tests skip mobile; serious+critical axe only.
- **Copy → JSON → Playwright:** `mix accrue_admin.export_copy_strings --out ../examples/accrue_host/e2e/generated/copy_strings.json` from `accrue_admin/`; allowlist in `lib/mix/tasks/accrue_admin.export_copy_strings.ex` must include **every** function name asserted from `copyStrings` in new/edited specs (D-12).
- **CI order:** `scripts/ci/accrue_host_verify_browser.sh` already chains assets → export → npm e2e — plans must not break that order.

## Route inventory (admin scope)

Under host billing mount (e.g. `/billing`):

| LiveView | Path pattern |
|----------|--------------|
| `ConnectAccountsLive` | `/connect?org=<slug>` |
| `ConnectAccountLive` | `/connect/:id?org=<slug>` |
| `EventsLive` | `/events?org=<slug>` |
| `CouponsLive` / `CouponLive` | `/coupons`, `/coupons/:id` |
| `PromotionCodesLive` / `PromotionCodeLive` | `/promotion-codes`, `/promotion-codes/:id` |

## UI-SPEC copy targets (→ `AccrueAdmin.Copy`)

Locked strings include: **Save platform fee override**, **Apply filters**, Connect/events empty headings and bodies, generic Connect error copy. KPI labels and table chrome currently **raw English** in `connect_accounts_live.ex` — migrate per AUX-03/AUX-05.

## Theme exceptions

- Register only **real** deviations in `accrue_admin/guides/theme-exceptions.md`; remove or replace placeholder `none-yet` row when first real entry ships (Phase 50 register format).

## Inventory artifact (D-04 / ADM-06 extension)

- Extend **`examples/accrue_host/docs/verify01-v112-admin-paths.md`** (or successor name if maintainers rename for v1.13) with **explicit rows** for `/connect`, `/connect/:id`, `/events`, plus **coupon index + one drill** and **promotion-code index + one drill** as required by **D-03** closure from Phase 52.
- Add a **requirement column** or adjacent mapping table: each merge-blocking `test.describe` / spec block ↔ **AUX-03..AUX-06** (at minimum AUX-06 for VERIFY-only rows).

## Pitfalls

- **Allowlist drift:** adding `copyStrings.foo` in JS without `@allowlist` entry silently drops key from JSON export map — acceptance tests must grep-assert export keys.
- **Fake / fixture data:** Connect list may be empty; tests must assert **empty-state Copy strings** or seed-dependent affordances consistent with existing subscription test (subscriptions index uses empty title).
- **Org scope:** follow existing pattern: `login` → **Go to billing** → org button → `goto` path with `?org=`.

## Validation Architecture

**Goal:** Execution agents get continuous, automated feedback without running the full CI matrix on every commit.

| Dimension | Approach |
|-----------|----------|
| **Unit / component** | `mix test` in `accrue_admin` for Copy modules and `Phoenix.LiveViewTest` where added for Connect/events (fast). |
| **Integration** | `mix test` in `examples/accrue_host` if router or session wiring changes. |
| **VERIFY-01 (blocking)** | From repo root: `bash scripts/ci/accrue_host_verify_browser.sh` **or** documented equivalent: `cd accrue_admin && mix assets.build && mix accrue_admin.export_copy_strings --out …` then `cd examples/accrue_host && npm run e2e -- verify01-admin-a11y.spec.js` (exact npm invocation per host `package.json`). |
| **Sampling** | After each plan wave touching Copy or specs: re-run **export** + **focused Playwright** for changed spec file; before phase close: full `accrue_host_verify_browser.sh` green. |
| **Manual** | None required for merge — axe + Playwright are canonical. Optional: visual skim of Connect detail fee override (non-blocking). |

**Nyquist / Dimension 8:** Every plan task that changes production HEEx or Copy must name an **automated** verify step (`mix test` path or Playwright grep) in PLAN.md `<verify>`.

## RESEARCH COMPLETE
