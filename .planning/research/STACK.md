# Stack Research

**Domain:** Accrue v1.25 — billing facade + integrator contracts (brownfield Elixir / Phoenix billing library)  
**Researched:** 2026-04-24  
**Confidence:** HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Elixir / OTP | 1.17+ / 27+ (project floor) | Language + runtime | Already locked in **`.planning/PROJECT.md`**; no change for checkout facade. |
| `lattice_stripe` | `~> 1.1` | Stripe HTTP + structs | Existing **`LatticeStripe.Checkout.Session`** path already used by **`Accrue.Processor.Stripe`**; facade only composes. |
| `nimble_options` | `~> 1.1` | Attr validation on **`Accrue.Billing`** | Same pattern as **`create_billing_portal_session/2`** (**BIL-04**); keeps invalid keys fail-fast at API boundary. |
| `Accrue.Telemetry.span/3` | core | Billing entry-point observability | Contract: every public **`Accrue.Billing`** function spanned or audited (**`billing_span_coverage_test.exs`**). |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Accrue.Checkout.Session` | core | Typed checkout session create/fetch | **Required** delegate target for **`create_checkout_session`** — do not duplicate Stripe param assembly in **`Billing`**. |
| ExUnit + Fake processor | test | Deterministic checkout proofs | **Required** for **BIL-06**; mirrors billing-portal Fake tests from **v1.24**. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `scripts/ci/verify_package_docs.sh` | Install literal / `mix.exs` alignment | Touch **First Hour** only when it reduces confusion (**BIL-07** stretch). |
| `scripts/ci/verify_v1_17_friction_research_contract.sh` | Friction table row-count / structure | Run when **INV-03** adds or closes inventory rows. |

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Delegate to **`Accrue.Checkout.Session`** | Call **`Processor.checkout_session_create`** from **`Billing`** directly | Rejected — duplicates param projection and breaks single place for **`Inspect`** masking of **`client_secret`**. |
| **`span_billing(:checkout_session, :create, …)`** | New top-level telemetry domain **`:checkout`** | Rejected for v1.25 — billing span catalog and OTel naming expect **`[:accrue, :billing, …]`** family. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Logging **`url`** or **`client_secret`** from checkout session | Bearer-equivalent credentials | **`Inspect` impl** on **`Accrue.Checkout.Session`** + PII-safe span metadata only (**`customer_id`**, ids). |
| New Hex deps for “research” | Maintenance posture | None — stack unchanged. |

## Version Compatibility

| Anchor | Compatible With | Notes |
|--------|-----------------|-------|
| `accrue` **0.3.1** on branch | `lattice_stripe` **~> 1.1** | No lockfile churn required for facade-only milestone unless publish cadence dictates. |

## Sources

- **`accrue/lib/accrue/billing.ex`** — **`create_billing_portal_session`** + **`span_billing`** patterns.  
- **`accrue/lib/accrue/checkout/session.ex`** — **`@create_schema`**, **`create/1`**.  
- **`.planning/milestones/v1.24-REQUIREMENTS.md`** — **BIL-04** / **BIL-05** acceptance pattern.  
- **`CLAUDE.md` / `.planning/PROJECT.md`** — stack floor and non-goals.

---
*Stack research for: Accrue v1.25*  
*Researched: 2026-04-24*
