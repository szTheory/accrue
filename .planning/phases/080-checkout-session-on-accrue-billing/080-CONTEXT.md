# Phase 80: Checkout session on `Accrue.Billing` - Context

**Gathered:** 2026-04-24  
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship **`Accrue.Billing.create_checkout_session/2`** (+ **`!`**) per **BIL-06**: first arg **`%Accrue.Billing.Customer{}`**, attrs aligned with **`Accrue.Checkout.Session.create/1`** except **`:customer`** (first argument); **NimbleOptions** validation on the facade; delegate to **`Accrue.Checkout.Session.create/1`**; **`span_billing(:checkout_session, :create, …)`** with **PII-safe** metadata (no checkout **URL**, **`client_secret`**, or raw attrs blob); **Fake** ExUnit (happy path + failure coverage per decisions below). **INT-12** / golden-path doc needles are **Phase 81** unless explicitly pulled into **80** in the same PR.

**Out of scope:** **PROC-08**, **FIN-03**, embedded Checkout UI in admin.

</domain>

<decisions>
## Implementation Decisions

### Telemetry / span metadata (research: OTel cardinality, Stripe secret-handling, sibling parity)

- **D-01:** Extend span metadata with a **strict, documented allowlist** of **low-cardinality, non-secret** checkout dimensions, **namespaced** so they never collide with existing `billing_metadata/4` keys: **`checkout_mode`**, **`checkout_ui_mode`**, **`checkout_line_items_count`** (values from **validated** attrs only — atoms/enums/small integers). **Do not** add URLs, `client_secret`, `client_reference_id`, raw maps, or Stripe-shaped blobs. Rationale: `Accrue.Telemetry.span/3` does not auto-merge raw args, but **operators** need sliceable signal (subscription vs payment vs setup; hosted vs embedded; empty vs fat cart) without the **Cashier/Pay** footgun of logging redirect URLs or full Stripe objects. Portal facade may stay **slimmer** on metadata (fewer semantic modes); checkout is the higher-branching surface.

- **D-02:** Add **tests** (in the dedicated facade test file) that attach to **`[:accrue, :billing, :checkout_session, :create, :start]`** and assert the allowlist keys are present when expected and that **`inspect(metadata)`** never contains `http`, `client_secret`, or serialized line-item payloads. Mirrors the discipline in **`billing_portal_session_facade_test.exs`**.

- **D-03 (pairs with Phase 81):** **`guides/telemetry.md`** and **`billing_span_coverage_test.exs`** must list the new attributes when **BIL-07** runs — record dependency so **80** does not silently ship undocumented dimensions.

### Test layout

- **D-04:** New file **`accrue/test/accrue/billing/checkout_session_facade_test.exs`** (module e.g. **`Accrue.Billing.CheckoutSessionFacadeTest`**) **adjacent** to **`billing_portal_session_facade_test.exs`**, same **`Accrue.BillingCase`**, **async: false**, Fake + telemetry patterns. Matches existing **`test/accrue/billing/`** decomposition and **grep-first** DX.

### `@doc` / ExDoc

- **D-05:** **Hybrid “portal-shaped facade, Session-shaped options”:** Same **categories** as **`create_billing_portal_session/2`** — short purpose; attrs align with **`Accrue.Checkout.Session.create/1`** except **`:customer`**; **`NimbleOptions.ValidationError`** on bad attrs; **one** explicit bearer-credential warning (URL / `client_secret`); **telemetry** event name + OTel-style name; links to **`m:Accrue.Checkout.Session`** (and guides when checkout-specific). **Do not** duplicate the full option catalog or long **embedded** narrative in **`Accrue.Billing`**; **`Accrue.Checkout.Session` `@moduledoc` / `@create_schema`** remain SSOT for field semantics — minimizes drift, preserves **“Billing is the supported front door”** story.

### ExUnit failure classes

- **D-06 (required):** **Processor failure** via **`Fake.scripted_response(:checkout_session_create, {:error, …})`**, asserting **`{:error, _}`** propagates through **`Billing.create_checkout_session/2`** — same contract as **`billing_portal_session_facade_test.exs`** **`:portal_session_create`** path.

- **D-07 (required, small):** **One** **`NimbleOptions.ValidationError`** test for an **invalid / unknown attr key** at the **Billing** facade (structural assertion, no fragile message regex). BIL-06 mandates NimbleOptions on the facade; this proves the **outer** schema is wired and catches drift if **`Session`** schema evolves but **`Billing`** forgets to mirror.

- **D-08 (Claude’s discretion):** Additional Fake scenarios (e.g. multiple error shapes) only if they stay trivially small; otherwise defer to **`Accrue.Checkout.Session`** tests.

### GSD / process (shift-left)

- **D-09:** For **billing facade** phases (thin **`Accrue.Billing`** delegations + Fake + telemetry), treat **layout, doc shape, telemetry allowlist discipline, and default failure-test recipe** as **pre-decided** via **`.planning/config.json` → `workflow.discuss_default_billing_facade_*`** — **skip re-litigation** in future **`/gsd-discuss-phase`** unless the phase touches **semver, breaking public API, security classification, or Hex publish** (then **`discuss_high_impact_confirm`** still applies).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — **BIL-06** (authoritative acceptance for Phase 80)
- `.planning/ROADMAP.md` — Phase **80** row, **v1.25** milestone boundary
- `.planning/PROJECT.md` — Core value, **v1.25** goal (checkout facade + integrator honesty)

### Prior phase context

- `.planning/phases/079-friction-inventory-maintainer-pass/079-CONTEXT.md` — Explicitly defers **BIL-06** to Phase **80**

### Implementation references

- `accrue/lib/accrue/billing.ex` — **`create_billing_portal_session/2`** pattern (**NimbleOptions**, **`span_billing`**, delegate)
- `accrue/lib/accrue/checkout/session.ex` — **`@create_schema`**, **`create/1`**, security **`Inspect`**
- `accrue/lib/accrue/telemetry.ex` — Span contract (no raw arg merge)
- `accrue/test/accrue/billing/billing_portal_session_facade_test.exs` — Fake + telemetry + **`!`** map precedent
- `accrue/lib/accrue/processor/fake.ex` — **`:checkout_session_create`** scripted hook

### Phase 81 coupling

- `.planning/REQUIREMENTS.md` — **BIL-07**, **INT-12** (catalog, span coverage test, integrator surfaces)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`BillingPortalSessionFacadeTest`** — copy structure for checkout (setup customer, happy path, **`Fake.scripted_response`**, telemetry attach/detach, bang + map).
- **`span_billing` / `billing_metadata`** — extend in one place for **`checkout_session`** resource so metadata policy stays centralized.

### Established patterns

- Facade validates with **NimbleOptions** then delegates; **bang** re-raises like portal.
- **Fake** op names mirror **`handle_call`** tuples (`:checkout_session_create`).

### Integration points

- **`billing_span_coverage_test.exs`** will need the new event segment when catalog is updated (**81** or same PR if combined).

</code_context>

<specifics>
## Specific ideas

- Research synthesis (parallel agents, 2026-04-24): **Pay / Cashier** teach “don’t log Stripe objects or redirect URLs”; **OTel** teaches **bounded attributes** over blobs; **ExDoc** idioms favor **thin wrapper + `m:` links** to SSOT modules.
- **Telemetry:** Prefer **B** (allowlisted dimensions) over purely minimal **A** for checkout only — intentional mild asymmetry vs portal due to richer branching.

</specifics>

<deferred>
## Deferred ideas

- **INT-12** doc/verifier needle updates — default **Phase 81** unless **80** ships docs in same milestone slice.
- **Structural invariant** replacing magic row-count verifiers (from **079-CONTEXT** D-09) — separate hygiene phase, not **80**.

</deferred>

---

*Phase: 080-checkout-session-on-accrue-billing*  
*Context gathered: 2026-04-24*
