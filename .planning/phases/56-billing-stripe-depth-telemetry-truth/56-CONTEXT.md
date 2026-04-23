# Phase 56: Billing / Stripe depth + telemetry truth - Context

**Gathered:** 2026-04-22  
**Status:** Ready for planning

<domain>

## Phase boundary

Ship **BIL-01** as **one** bounded **`Accrue.Billing`** expansion: **list payment methods for a Stripe customer** (public read API on the Billing façade, **Fake-** and **Stripe-backed** via existing **`Accrue.Processor.list_payment_methods/2`**), with **regression tests** in the established **`BillingCase` / `Accrue.Processor.Fake`** style.

Ship **BIL-02** in the **same delivery slice**: **`guides/telemetry.md`** (and **`guides/operator-runbooks.md`** only if a **new** revenue-adjacent **ops** signal is introduced — **not expected** for this read path) stays **truthful** vs code — extend **billing firehose** documentation and **`accrue/test/accrue/telemetry/billing_span_coverage_test.exs`** contract; **`CHANGELOG.md`** records the capability; optional **`@doc since:`** on new public functions for Hex discoverability.

**Out of scope for Phase 56:** second processor (**PROC-08**), finance exports (**FIN-03**), new third-party UI kits, **BillingPortal.Configuration** API, integrator-milestone doc themes, **Hex publish** as a milestone theme. **Deferred BIL-01 alternatives** (separate future phases / backlog): public **`confirm_payment_intent` / `confirm_setup_intent`** on Billing; **`get_subscription_schedule` / sync**; **retrieve coupon / promotion code**; **`update_payment_method`** — each is valuable but **violates the “one slice”** rule if combined with list PMs.

</domain>

<decisions>

## Implementation decisions

*Synthesis from parallel research (billing surface, Fake/webhook tests, telemetry guides, semver/DX) plus maintainer directive: **all** gray areas covered in one coherent pass — user opted for research-backed defaults over interactive Q&A.*

### 1 — BIL-01 capability lock (**what** ships)

- **D-01 (primary — locked):** Implement **`Accrue.Billing.list_payment_methods/2`** and **`list_payment_methods!/2`** (final arity follows existing Billing read patterns, e.g. **`customer` + `opts`**), delegating to **`PaymentMethodActions`** (or the established payment-method action module) which calls **`Accrue.Processor.list_payment_methods/2`**. **Rationale:** Processor **Fake** and **Stripe** adapters already implement **`list_payment_methods/2`**; the Billing façade **does not** expose it — smallest **Stripe-first** gap, **read-only** (clear state semantics: “what Stripe knows now”), **no** new processor callbacks, **low** coupling risk to **`lattice_stripe`** churn vs list-charges-style gaps.
- **D-02 (NimbleOptions):** If Stripe list filters / pagination / `expand` need host-visible knobs, define a **small** options schema in the action module (**`validate!/2`** + `@doc` table) mirroring **`report_usage`** discipline — avoid unvalidated keyword soup.
- **D-03 (telemetry resource):** Wrap with **`span_billing(:payment_method, :list, customer, opts, fn -> … end)`** so billing firehose stays consistent with **`:attach` / `:detach` / `:set_default`**.
- **D-04 (runner-up — explicit deferral):** **`confirm_payment_intent` / `confirm_setup_intent`** on Billing is the **best second bet** (processor already implements; strong SCA DX) — **not** in Phase 56 unless BIL-01 is formally re-opened. **`get_subscription_schedule`** is the strongest **webhook-heavy** alternative — **higher** test matrix; defer unless planning explicitly swaps D-01.

### 2 — Fake + regression test bar (**how** we prove it)

- **D-05 (default lane):** **`use Accrue.BillingCase`**, **`Fake.reset_preserve_connect/0`**, **`StripeFixtures`** / **`Fake.scripted_response/2`** only when asserting failure branches — same primitives as **`accrue/test/accrue/processor/fake_phase3_test.exs`** (already lists PMs against Fake) and meter/connect tests.
- **D-06 (webhook / ingest):** **No merge-blocking requirement** to add **new** full **`Ingest.run` + `DispatchWorker`** paths **solely** for list PMs — listing is a **read** of processor state. If implementation touches **projection** or **cache invalidation** tied to **`payment_method.*`** webhooks, add **targeted** **`DefaultHandler`** or **`Accrue.Test.Webhooks.trigger/2`** coverage; otherwise **unit + processor contract** is sufficient.
- **D-07 (host boundary):** Add or extend **`examples/accrue_host`** tests **only** if Phase 56 work changes **HTTP**, signing, or router-adjacent behavior — **not** the default bar for this API.
- **D-08 (anti-patterns):** No giant one-off JSON blobs; no **`Oban.insert` / `Ingest` mocks** “for convenience”; no **`Process.sleep`** in new tests (**`guides/testing.md`** footguns).
- **D-09 (live Stripe):** Do **not** expand default CI with **`live_stripe`** for this slice; keep parity tests **tagged and excluded** as today.

### 3 — BIL-02 telemetry + docs (**truth** vs code)

- **D-10 (ops vs firehose):** This feature should introduce **no new `[:accrue, :ops, :*]`** row unless planning discovers a **real, low-cardinality, alertable** durable condition (unlikely for a list read). **Primary doc work:** **`[:accrue, :billing, :payment_method, :list, …]`** firehose line in **`guides/telemetry.md`** (billing spans subsection + **non-exhaustive** illustration list), aligned with **Phase 40 D-14** (verified examples only).
- **D-11 (catalog + runbooks):** Preserve **single ops table** SSOT (**Phase 40 D-01**, **Phase 45 D-05**). **Do not** fork ops rows into **`operator-runbooks.md`** for this slice unless D-10 is triggered.
- **D-12 (automation):** When **ops** set is unchanged, extend **`billing_span_coverage_test.exs`** / billing span inventory as needed so **new** façade functions cannot land **unspanned**. If a **new ops** tuple ever ships with BIL-01 scope creep, extend the **code-owned ops inventory test** pattern from Phase **40** / **45** — **prefer `mix test` over grep prose**; grep remains a **structural** guard (no second ops table) only.
- **D-13 (CHANGELOG + reconciliation):** **`accrue/CHANGELOG.md`** under **`## Unreleased`** → **`### Features` / `### Billing`** with host-facing bullets; if ops catalog or reconciliation footer is touched, bump **“last reconciled”** / **`Since:`** per **40 D-16** conventions.

### 4 — Public API + semver / DX (**how** hosts consume it)

- **D-14 (additive surface):** **New** public functions on **`Accrue.Billing`** (not silent keyword extension of unrelated APIs). Pair **`/2`** + **`!/2`** matching existing naming physics.
- **D-15 (semver):** Treat as **additive minor** in **`0.x`** line (current **`@version`** in **`accrue/mix.exs`** at ship time); no breaking default changes. **`guides/upgrade.md`** deprecation discipline applies if any later rename is needed — **not** in the initial landing.
- **D-16 (ExDoc):** Introduce **`@doc since: "0.x.y"`** (exact version at release cut) on **new** **`Accrue.Billing`** functions — first use acceptable here per Phase **40** intent; keep **`Accrue.Telemetry.Ops`** moduledoc as **short suffix list + link**, not duplicated schemas (**40 D-03**).
- **D-17 (host façade):** Document / generator touchpoints so **`MyApp.Billing`** (or installer output) remains the **supported** host seam per **`accrue/README.md`** — extend stubs if the installer emits **`MyApp.Billing`** delegates.
- **D-18 (ecosystem lessons):** Do **not** leak raw **`LatticeStripe`** structs as the **stable** contract at the façade — map to **Accrue schemas / plain maps** as elsewhere. Avoid **Pay/Cashier-style** “implicit PM selection” docs; list API stays **explicit customer** scope.

### Claude's discretion

- Exact **NimbleOptions** keys for list filters / pagination and **projection** shape (if any local cache).
- Whether **`@doc since:`** uses patch vs minor version string — follow whatever the **release** uses for that commit.
- Minor test file placement (`payment_method_actions_test.exs` vs new file) as long as **D-05–D-09** hold.

</decisions>

<canonical_refs>

## Canonical references

**Downstream agents MUST read these before planning or implementing.**

### Milestone + requirements

- `.planning/REQUIREMENTS.md` — **BIL-01**, **BIL-02**; out-of-scope table
- `.planning/ROADMAP.md` — Phase **56** goal + success criteria
- `.planning/PROJECT.md` — v1.14 charter; **PROC-08** / **FIN-03** non-goals; stability / façade narrative

### Prior telemetry / doc locks

- `.planning/phases/40-telemetry-catalog-guide-truth/40-CONTEXT.md` — ops catalog SSOT, firehose vs ops, OTel honesty, contract tests
- `.planning/phases/45-docs-telemetry-runbook-alignment/45-CONTEXT.md` — semantics blocks, runbook IA, meter ops narrative (**path:** `.planning/phases/45-docs-telemetry-runbook-alignment/45-CONTEXT.md`)

### Implementation touchpoints

- `accrue/lib/accrue/billing.ex` — façade + **`span_billing`**
- `accrue/lib/accrue/billing/payment_method_actions.ex` — delegate target (or sibling module name if refactored)
- `accrue/lib/accrue/processor.ex` — **`list_payment_methods/2`** callback
- `accrue/lib/accrue/processor/fake.ex` / `accrue/lib/accrue/processor/stripe.ex` — adapter bodies
- `accrue/test/support/billing_case.ex` — test harness
- `accrue/test/accrue/processor/fake_phase3_test.exs` — existing list PM Fake coverage pattern
- `accrue/test/accrue/telemetry/billing_span_coverage_test.exs` — span contract
- `accrue/guides/telemetry.md` — billing firehose + ops catalog
- `accrue/guides/operator-runbooks.md` — only if new ops playbook required (**D-11**)
- `accrue/guides/testing.md` — Fake-first, webhook replay, CI lanes
- `accrue/CHANGELOG.md` — Unreleased billing bullet
- `accrue/README.md` / `accrue/guides/upgrade.md` — host seam + semver story

</canonical_refs>

<code_context>

## Existing code insights

### Reusable assets

- **`Accrue.Processor.list_payment_methods/2`** on **Fake** and **Stripe** — no new processor surface required for D-01.
- **`Accrue.Billing`** **`span_billing(:payment_method, …)`** pattern for attach/detach/set_default — reuse **`:list`** action.
- **`BillingCase`**, **`StripeFixtures`**, **`Fake.scripted_response/2`** — standard regression stack.
- **`billing_span_coverage_test.exs`** — enforces “every public Billing function spanned.”

### Established patterns

- **Context façade + `*Actions` modules** + **`Repo.transact`** where writes exist (list is read-only; still follow action-module split for consistency).
- **Fake as default processor double**; **Mox** reserved for narrow seams — not routine Billing (**project testing philosophy**).

### Integration points

- **Payment method** lifecycle still driven by **webhooks** + existing **`PaymentMethodActions`** — list is **read**; document relationship in **`@moduledoc`** if hosts confuse “listed” vs “attached / default”.

</code_context>

<specifics>

## Specific ideas

- **Pay / Laravel Cashier / stripe-ruby:** Expose **list + confirm** patterns the way Stripe’s API does; Accrue Phase **56** locks **list** first to avoid **half-finished SCA** stories in the same milestone slice.
- **Research directive:** User requested **subagent research** and a **single coherent default** — all four gray areas were answered with **one** primary BIL-01 choice (**D-01**) so planning does not re-litigate capability pick unless scope is formally reopened.

</specifics>

<deferred>

## Deferred ideas

- **BIL-01 alternatives:** **`confirm_payment_intent` / `confirm_setup_intent`** on Billing; **`get_subscription_schedule`** (+ optional sync); **`retrieve_coupon` / `retrieve_promotion_code`**; **`update_payment_method`** — captured in **D-04**; each is a **separate** phase-sized expansion if prioritized.
- **Second ops tuple for list failures:** Only if product discovers an **alertable** read-path failure mode worth **`[:accrue, :ops, :*]`** — default **no**.

</deferred>

---

*Phase: 56-billing-stripe-depth-telemetry-truth*  
*Context gathered: 2026-04-22*
