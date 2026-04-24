# Phase 80 — Checkout session on `Accrue.Billing` — Research

**Question:** What do we need to know to plan **BIL-06** well?

## Summary

**BIL-06** is a thin **facade** on **`Accrue.Billing`**: mirror **`create_billing_portal_session/2`** (NimbleOptions on attrs → **`span_billing`** → delegate to session module with **`customer:`** injected from the first argument). Target delegate is **`Accrue.Checkout.Session.create/1`**, whose **`@create_schema`** is the source of truth for field types. The facade schema must be **`@create_schema` minus `:customer`** so unknown keys fail at the Billing boundary before processor I/O.

**Telemetry:** **`span_billing(:checkout_session, :create, customer, validated, fun)`** yields event prefix **`[:accrue, :billing, :checkout_session, :create, …]`**. Extend **`billing_metadata/4`** (or a dedicated branch) so **only** CONTEXT **D-01** allowlist keys are added from **validated** attrs: **`checkout_mode`**, **`checkout_ui_mode`**, **`checkout_line_items_count`**. Never put **`url`**, **`client_secret`**, raw **`line_items`** payloads, or full attr maps in metadata.

**Fake:** **`Accrue.Processor.Fake`** already implements **`checkout_session_create/2`** and **`with_script_or_stub(..., :checkout_session_create, ...)`**. Scripted failure uses the same tuple shape as portal tests: **`Fake.scripted_response(:checkout_session_create, {:error, err})`**.

## Implementation anchors

| Topic | Detail |
|-------|--------|
| Facade pattern | **`accrue/lib/accrue/billing.ex`** — **`create_billing_portal_session/2`**, **`@billing_portal_session_attrs_schema`**, **`span_billing(:billing_portal, :create, ...)`** |
| Session SSOT | **`accrue/lib/accrue/checkout/session.ex`** — **`@create_schema`**, **`create/1`**, **`create!/1`** |
| Span helper | **`accrue/lib/accrue/billing.ex`** — **`span_billing/5`**, **`billing_metadata/4`** |
| Telemetry contract | **`accrue/lib/accrue/telemetry.ex`** — explicit metadata only |
| Test precedent | **`accrue/test/accrue/billing/billing_portal_session_facade_test.exs`** |
| Fake hook | **`accrue/lib/accrue/processor/fake.ex`** — **`:checkout_session_create`** |

## Pitfalls

- **Alias collision:** **`Accrue.BillingPortal.Session`** is already aliased as **`Session`** in **`billing.ex`**. Checkout must use a **distinct alias** (e.g. **`CheckoutSession`**) for specs and delegation calls.
- **Schema drift:** Duplicated NimbleOptions keys on Billing must stay aligned with **`Accrue.Checkout.Session.@create_schema`** minus **`:customer`** — document a grep contract on both modules.
- **Metadata leakage:** Do not pass **unvalidated** attrs into **`span_billing`**’s metadata argument; only **`validate!`** output + derived counts.

## Open questions

- None blocking — **080-CONTEXT.md** locks telemetry allowlist and test matrix.

## Validation Architecture

**Dimension 8 (Nyquist) — feedback loops for this phase**

| Dimension | How satisfied |
|-----------|----------------|
| Unit | **`mix test test/accrue/billing/checkout_session_facade_test.exs`** after implementation tasks |
| Regression | **`mix test test/accrue/billing/`** or full **`mix test`** in **`accrue/`** before phase sign-off |
| Contract | **`mix compile --warnings-as-errors`** (from **`accrue/`**) when touching **`billing.ex`** |

**Wave 0:** Not applicable — **ExUnit** + **Accrue.BillingCase** already exist.

**Sampling:** After each commit that touches **`billing.ex`** or the new test file, run **`mix test test/accrue/billing/checkout_session_facade_test.exs`** from **`accrue/`** (exit **0**).

---

## RESEARCH COMPLETE
