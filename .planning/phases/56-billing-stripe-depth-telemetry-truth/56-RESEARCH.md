# Phase 56 — Technical research

**Phase:** Billing / Stripe depth + telemetry truth  
**Question:** What do we need to know to plan BIL-01 + BIL-02 well?

## RESEARCH COMPLETE

### 1. Locked capability (BIL-01)

- **Public API:** `Accrue.Billing.list_payment_methods/2` and `list_payment_methods!/2`, arity aligned with other read paths (`customer` as `%Accrue.Billing.Customer{}`, `opts \\ []`).
- **Delegation:** New functions in `PaymentMethodActions` call `Processor.__impl__().list_payment_methods/2` with params `%{customer: customer.processor_id}` (atom key), matching `Fake.list_payment_methods/2` stub in `fake_phase3_test.exs` (`%{customer: cus.id}` on Fake customer id).
- **Span:** `span_billing(:payment_method, :list, customer, opts, fn -> … end)` → telemetry event prefix `[:accrue, :billing, :payment_method, :list]` (via `Accrue.Telemetry.span/3` in `span_billing/5`).
- **Return contract:** Preserve processor `{:ok, %{object: "list", data: data, has_more: …}}` shape (Stripe + Fake already agree via `translate_resource` / Fake handler). CONTEXT D-18: avoid leaking raw `LatticeStripe` structs as the stable façade contract; document in `@doc` if maps are Stripe-shaped plain maps.

### 2. NimbleOptions (D-02)

- **Stripe list filters:** `LatticeStripe.PaymentMethod.list/3` accepts string-keyed params (Stripe adapter uses `stringify_keys`). If hosts need `type`, `limit`, `ending_before`, `starting_after`, mirror `MeterEventActions` / `report_usage` — small `NimbleOptions` schema in `PaymentMethodActions`, `validate!/2`, documented table in `@moduledoc`. If no host-visible filters in v1 slice, accept `[]` only and document extension point.

### 3. Fake + tests (D-05–D-09)

- **Harness:** `use Accrue.BillingCase`, `Fake.reset_preserve_connect/0`, create customer + attach PM(s), assert `Billing.list_payment_methods(customer, [])` returns expected count.
- **New test file:** e.g. `accrue/test/accrue/billing/payment_method_list_test.exs` (or extend existing billing payment method tests) — keep assertions on **public** `Accrue.Billing` where possible for BIL-01 bar.
- **Failure path:** `Fake.scripted_response(:list_payment_methods, …)` only if implementing error translation tests; optional per CONTEXT D-06.
- **Coverage test:** `billing_span_coverage_test.exs` regex requires `Accrue.Telemetry.span` in `billing.ex` source for each public function — new entries must appear in `def … span_billing` blocks (same pattern as attach/detach).

### 4. Telemetry + docs (BIL-02)

- **Firehose:** Add one verified example line `accrue.billing.payment_method.list` (or dotted convention matching doc style) under billing spans in `guides/telemetry.md` § billing examples; align with Phase 40 “verified examples only.”
- **Ops catalog:** No new `[:accrue, :ops, :*]` for read-path unless product mandates (CONTEXT default: none).
- **CHANGELOG:** `accrue/CHANGELOG.md` Unreleased → Features/Billing bullet.
- **ExDoc:** `@doc since: "0.x.y"` on new Billing functions (version at ship per CONTEXT D-16).

### 5. Out of scope (explicit)

- PROC-08 second processor, FIN-03, BillingPortal.Configuration, new UI kits, webhook-only work unless list touches projection (not expected).

---

## Validation Architecture

**Nyquist / execution sampling**

| Dimension | Strategy |
|-----------|----------|
| **Automated proof** | `cd accrue && mix test test/accrue/billing/payment_method_list_test.exs` (or chosen path) after implementation tasks; full `mix test` in `accrue` before phase close. |
| **Contract** | `billing_span_coverage_test.exs` — blocks merge if new `Accrue.Billing` public fun lacks span wiring. |
| **Docs** | Grep: `guides/telemetry.md` contains substring for `payment_method` + `list` billing span example; CHANGELOG contains `list_payment_methods` or equivalent host-facing phrase. |
| **Security** | Read path only — acceptance tests assert no new logging of raw card PAN/CVC; metadata stays low-cardinality (`billing_metadata/4` pattern). |

**Wave 0:** Not applicable — ExUnit + existing BillingCase already present.

**Manual:** None required unless maintainer runs optional `live_stripe` tagged suite (excluded from default CI per D-09).

---

*Research for phase 56 — 2026-04-23*
