# Architecture Research

**Domain:** Accrue v1.25 — **`Accrue.Billing`** checkout composition + planning artifact flow  
**Researched:** 2026-04-24  
**Confidence:** HIGH

## Standard Architecture

### System Overview

```
Host `MyApp.Billing` (generated facade)
        │
        ▼
Accrue.Billing  ──span[:accrue,:billing,:checkout_session,:create]──►  Accrue.Checkout.Session.create/1
        │                                                      │
        │                                                      ▼
        │                                            Processor (Stripe | Fake)
        ▼
Accrue.Billing.Customer  (persisted row + processor customer id)
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| **`Accrue.Billing`** | Public billing context API; span + metadata; NimbleOptions on attrs | **`def create_checkout_session(%Customer{}, attrs)`** merges **`customer:`** into map passed to **`Session.create/1`**. |
| **`Accrue.Checkout.Session`** | Stripe param build + struct projection + **`Inspect`** masking | Unchanged core; **`Billing`** is thin wrapper. |
| **`Accrue.Processor`** | **`checkout_session_create/2`** | Already implemented Stripe + Fake. |

## Recommended Project Structure

No new top-level apps — work confined to:

```
accrue/lib/accrue/billing.ex          # new API + schemas + span
accrue/test/accrue/billing/           # new *_test.exs beside portal tests
accrue/test/accrue/telemetry/billing_span_coverage_test.exs
accrue/guides/telemetry.md
examples/accrue_host/                 # VERIFY / README only if INT-12 demands
.planning/research/v1.17-FRICTION-INVENTORY.md
```

### Structure Rationale

- **`Billing`** remains the **only** supported public “context” for hosts per installer / First Hour story.  
- **`Checkout`** namespace stays for session types and low-level create — avoids renaming shipped modules.

## Architectural Patterns

### Pattern 1: Facade + delegate (matches **BIL-04**)

**What:** **`Accrue.Billing`** validates attrs, wraps **`span_billing`**, calls **`Accrue.BillingPortal.Session`** / **`Accrue.Checkout.Session`**.  
**When to use:** Any new Stripe surface that hosts should reach through **`MyApp.Billing`**.  
**Trade-offs:** Thin file growth vs. discoverability — acceptable; action modules not required until **`billing.ex`** becomes unwieldy (existing pattern mixes **`defdelegate`** to action modules + inline portal).

### Pattern 2: Metadata sanitization

**What:** Span metadata uses **`billing_metadata/4`** — never pass raw **`attrs`** maps containing URLs or secrets.  
**When to use:** Always for **BIL-06**.  
**Trade-offs:** Less debug detail in traces — use **`operation_id`** and **`customer_id`** instead.

## Data Flow

### Checkout create (hosted mode)

```
Host calls Billing.create_checkout_session(customer, attrs)
    → NimbleOptions.validate!(attrs)
    → span [:accrue,:billing,:checkout_session,:create]
    → Checkout.Session.create(%{customer: customer, …merged…})
    → Processor.checkout_session_create/2
    → {:ok, %Accrue.Checkout.Session{url: …}}  (url not logged in telemetry)
```

## Integration Points

| Boundary | Communication | Notes |
|----------|---------------|-------|
| **`Billing` ↔ `Checkout.Session`** | function call | Session already accepts **`%Customer{}`** in **`@create_schema`**. |
| **`Billing` ↔ telemetry catalog`** | docs + test allowlist | **`guides/telemetry.md`** must list **`checkout_session.create`**. |

## Anti-Patterns

### Anti-Pattern 1: Two public checkout APIs

**What people do:** Export **`Accrue.Checkout`** and **`Accrue.Billing`** checkout without guidance.  
**Why it's wrong:** Host tutorial inconsistency; harder VERIFY matrix.  
**Do this instead:** Treat **`Accrue.Billing.create_checkout_session`** as the **recommended** path; keep **`Accrue.Checkout`** as low-level escape hatch (documented).

## Sources

- **`accrue/lib/accrue/checkout/session.ex`**  
- **`accrue/lib/accrue/billing.ex`** (**billing portal** block)  
- **`accrue/lib/accrue/checkout.ex`** (thin **`Accrue.Checkout`** module)

---
*Architecture research for: Accrue v1.25*  
*Researched: 2026-04-24*
