# Phase 27 — Technical research

**Phase:** 27 — Microcopy and operator strings  
**Question:** What do we need to know to plan COPY-01..COPY-03 well?

## RESEARCH COMPLETE

### Current string hot spots (code)

| Surface | File | Pattern today |
|---------|------|----------------|
| DataTable defaults | `accrue_admin/lib/accrue_admin/components/data_table.ex` | `assign_new(:empty_title, fn -> "No rows found" end)` and generic filter body — second SSOT risk |
| Money indexes | `customers_live.ex`, `subscriptions_live.ex`, `invoices_live.ex`, `charges_live.ex` | Per-route `empty_title` / `empty_copy` with **“Adjust the … filters or wait for …”** chorus; jargon: **DLQ**, **processor**, **billing cycle**, **projection** |
| Webhooks index | `webhooks_live.ex` | Same chorus + **DLQ** in primary empty copy |
| Webhook detail | `webhook_live.ex` | **Module attributes** for locked denial/replay strings (`@owner_access_denied`, `@replay_blocked`, etc.) — good concentration point to lift into `AccrueAdmin.Copy` family |
| Out-of-scope indexes | `coupons_live.ex`, `connect_accounts_live.ex`, `events_live.ex`, `promotion_codes_live.ex` | Same anti-pattern; **Phase 27 CONTEXT D-04** — do not migrate copy in this phase unless INV-03 promotes them |
| Money detail | `customer_live.ex`, `subscription_live.ex`, `invoice_live.ex`, `charge_live.ex` | Mix of `push_flash/2`, `put_flash`, inline strings; some `inspect(reason)` error paths — copy tier vs diagnostic leakage boundary |

### Ecosystem / product patterns (brief)

- **OSS billing UIs** (Pay, Nova resources, Filament tables): operator strings tend to be **centralized or keyed** so integrators and tests do not chase literals across templates.
- **Accrue-specific:** Phase **20-UI-SPEC** and **21-UI-SPEC** own **locked** wording for org/tax/replay; Phase **25 INV-03** is the accountability grid — any COPY fix that closes a Partial row must update **Evidence** in the same change train.

### Elixir / LiveView implementation notes

- **Named functions** in `AccrueAdmin.Copy` (and optional `AccrueAdmin.Copy.Locked`) keep HEEx readable: `<%= Copy.customers_index_empty_title() %>` or function components — avoid compile-time macro soup for v1.6.
- **`DataTable`:** `assign_new/3` can call `&Copy.data_table_default_empty_title/0` so routes that omit assigns still get Tier A voice once defaults change.
- **Tests:** Assert `rendered` contains `Copy.function()` return substring **or** import `Copy` in tests and compare — aligns with COPY-03.
- **Playwright (host):** `phase13-canonical-demo.spec.js` already uses `getByRole` and **exact** strings for replay confirmation (`Replay webhook for the active organization?`) — after migration, strings must remain **character-identical** if they are UI-SPEC–locked; update tests only when **meaning** changes (semver minor per CONTEXT).

### Pitfalls

1. **Paraphrasing locked strings** — fails Phase 20 contract and breaks host E2E; migrate **verbatim** into `Copy.Locked` (or equivalent).
2. **Scattering new literals** during migration — duplicates defeat COPY-03; every semantic string gets one `Copy.*` function.
3. **`inspect(reason)` in operator-visible flashes** — information disclosure / noisy UX; research does not mandate removal in 27 but plans should flag **security-relevant** flashes for threat model (prefer human messages where trivial).
4. **Merge order with Phase 26** — same `*_live.ex` files; executor should **rebase after 26** if both land in parallel; CONTEXT allows `Copy` scaffolding with minimal LiveView churn first.

### Recommendations for planner

1. **Three waves → three plans** (or two plans if wave 2+3 combined): money indexes + `Copy` foundation; money detail + destructive; webhooks + automation/doc + INV-03.
2. Each plan ends with **INV-03** row touches where applicable (D-04 hygiene).
3. Optional **smallest shippable** duplicate-literal check: `mix` task that `Code.string_to_quoted!` on `copy.ex` and lists public function strings **or** a 20-line shell script in `bin/` — prefer not to block on Credo custom check unless already patterned in repo.

---

## Validation Architecture

**Dimension 8 (Nyquist):** Execution must prove COPY-01..03 with **automated** checks after each wave, not only manual reading.

| Dimension | How Phase 27 satisfies it |
|-----------|---------------------------|
| **Correctness** | ExUnit: rendered index/detail HTML contains expected `AccrueAdmin.Copy` substrings for Tier A surfaces in scope |
| **Regression** | Host Playwright unchanged for locked literals **or** updated in same PR with CHANGELOG `### Host-visible copy` |
| **Security** | Threat model per plan: no new raw echo of secrets in copy changes; replay denial strings unchanged semantically |
| **Observability** | N/A for copy-only phase |
| **Performance** | N/A — compile-time strings only |
| **Compatibility** | Semver: function names stable; English wording patch unless meaning changes (document in CHANGELOG) |
| **Operability** | `mix test` paths documented in VALIDATION.md |
| **Sampling** | After each task group: targeted `mix test` files listed in plan `<verify>` |

**Wave 0:** Not required — `accrue_admin` already has `mix test` and Floki/LiveViewTest stack from prior phases.

**Sign-off criterion:** `accrue_admin` tests green for touched modules; host `e2e` subset referenced in plans green when Playwright strings change.
