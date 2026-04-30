# Phase 94: Strategy + capability matrix + target lock - Research

**Researched:** 2026-04-29
**Domain:** Processor-support strategy, capability truth, and planning/CI enforcement
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

All items in this block are copied verbatim from `094-CONTEXT.md`. [VERIFIED: 094-CONTEXT.md]

### Locked Decisions

### Strategic posture

- **D-01:** Accrue adopts **explicit first-party supported slice + custom adapters outside that slice** as the official processor-support posture. The public promise is not “any adapter implementing `Accrue.Processor` is effectively supported”; the public promise is “the documented Accrue billing facade is first-party supported across the named capability slice for `Fake`, `Stripe`, and the chosen second provider.”
- **D-02:** `Fake` remains the **required deterministic proof lane** and merge-blocking default for processor work. Provider-backed runs are fidelity / parity lanes for supported features, not the primary development loop.
- **D-03:** `guides/custom_processors.md` remains an extension-point document, not adoption-front-door guidance. A custom adapter may be compatible with the internal boundary without becoming first-party supported, release-gated, or parity-promised.
- **D-04:** Top-level and strategic docs should avoid “processor-agnostic” wording. Accrue is **facade-first and capability-explicit**, not lowest-common-denominator by marketing claim.

### Target-provider decision

- **D-05:** Lock **Braintree** as the official second-provider target for the Phase 1 dual-provider track.
- **D-06:** Rationale for Braintree:
  - It is the closest plausible **direct gateway** match to Accrue’s current Stripe-first shape: customer records, vaulted payment methods, recurring billing, transactions/refunds, and webhook events.
  - It preserves the principle of least surprise better than Adyen or PayPal direct because Accrue’s current public surface is already Stripe-shaped around customer, subscription, payment method, and webhook-backed state convergence.
  - It offers better maintainer leverage for this repo than enterprise-heavy alternatives because there is a real Elixir package surface and a more tractable gateway mental model than hand-rolling against broader enterprise APIs.
  - It stays inside the already-locked strategy boundary: **Stripe-like gateway**, not merchant-of-record, not finance-system expansion.
- **D-07:** Explicit non-targets for this track:
  - **Merchant-of-record providers** such as Paddle, Lemon Squeezy, and FastSpring. They are the wrong product boundary for Accrue’s locked strategy even if some hosted UX is attractive.
  - **Adyen** for Phase 1. Technically capable, but too enterprise-specific and too far from Accrue’s current facade and ecosystem ergonomics.
  - **PayPal direct subscriptions**. Too wallet-first and approval-flow-specific to serve as the first official “Stripe-like” second provider.
  - **Bank-debit specialists** such as GoCardless. Wrong capability center of gravity for this phase.

### Official capability slice

- **D-08:** The official second-provider slice for this track is **Gateway subscription core**.
- **D-09:** Gateway subscription core means Accrue first-party support is centered on:
  - customer create / retrieve / update
  - payment-method vault acquisition as the provider’s supported hosted or client-tokenized handoff
  - one real subscription acquisition path through the public facade
  - webhook verify / parse
  - webhook-backed convergence of local subscription and invoice truth for the supported lifecycle
  - explicit capability gating for unsupported surfaces
- **D-10:** For the chosen second provider, the first real public-facade story should center on **direct subscription creation and lifecycle truth**, not on Stripe Checkout or Stripe Billing Portal parity.
- **D-11:** The second-provider slice is intentionally **not** “Stripe-near parity” and **not** “hosted billing UX parity everywhere.” Those are different strategic bets and would force abstraction churn before the second provider is even real.
- **D-12:** Phase 94/95/96 should therefore treat the following as **out of slice** for first-party second-provider support:
  - `Accrue.Billing.create_checkout_session/2` parity
  - `Accrue.Billing.create_billing_portal_session/2` parity
  - embedded checkout
  - setup-intent / payment-intent parity
  - payment-method CRUD parity beyond what is minimally needed for the supported gateway subscription path
  - plan swap / quantity mutation / pause / resume / schedules / preview / proration parity
  - refunds, coupons, promotion codes, metering, and Connect

### Public-facade interpretation

- **D-13:** The public facade remains the product boundary, but processor support must be **capability-labeled**. Every processor-touched public API should be treated as one of:
  - supported on all first-party processors
  - Stripe-only
  - out of the official second-provider slice
- **D-14:** For this milestone, `Accrue.Billing.subscribe/3` is the primary candidate public facade for the second-provider thin slice. It already matches the direct-gateway shape more naturally than `create_checkout_session/2` or `create_billing_portal_session/2`.
- **D-15:** `create_checkout_session/2` and `create_billing_portal_session/2` remain valuable public APIs, but they should be documented as **Stripe-first** until another first-party processor proves them honestly.
- **D-16:** Capability rows should describe **semantic behaviors**, not provider jargon. Example: “webhook-backed subscription lifecycle convergence” is the contract; provider event names are implementation details.

### Capability-matrix shape

- **D-17:** The capability matrix should be the first-class truth artifact for processor support. New processor work starts by naming capability rows before implementation work spreads.
- **D-18:** The matrix should evolve beyond the current broad legacy defaults in `Accrue.Processor.Capabilities` and add explicit rows needed for honest multi-provider support, including semantics similar to:
  - `customer.create/retrieve/update`
  - `payment_method.vault_acquisition`
  - `subscription.direct_create`
  - `subscription.fetch`
  - `subscription.cancel`
  - `subscription.lifecycle_webhook_projection`
  - `invoice.lifecycle_webhook_projection`
  - `webhook.verify`
  - `webhook.parse`
  - `checkout.hosted_handoff` only where truly supported
  - `billing_portal.hosted_self_serve` only where truly supported
- **D-19:** Unsupported capabilities must fail **clearly and early** via capability checks, not by implying Stripe parity and surprising integrators later.

### Architecture and DX lessons applied

- **D-20:** Accrue should learn from **Laravel Cashier** by naming provider tracks honestly instead of pretending all billing systems fit one uniform contract.
- **D-21:** Accrue should learn from **Pay (Rails)** that multi-provider support can work if the shared surface stays bounded and the docs warn that complex provider behaviors diverge.
- **D-22:** Accrue should explicitly avoid the **ActiveMerchant** trap: too much gateway breadth creates lowest-common-denominator pressure, leaky abstractions, and DX erosion.
- **D-23:** The Ecto / Active Storage / Active Job lesson applies: adapters are real, but first-party support must enumerate exactly what is guaranteed. Internal adapter compatibility is not the same thing as public support.

### Recommended wording for strategy and docs

- **D-24:** Strategy/docs should use wording in this shape:
  - Accrue officially supports the documented billing facade across `Fake`, `Stripe`, and `Braintree` for the capability slice listed in the processor matrix.
  - `Fake` is the deterministic local and CI proof lane.
  - Provider-backed runs are fidelity checks for supported features, not the primary development loop.
  - Custom processors remain an extension point through `Accrue.Processor`, but they are outside first-party parity and release guarantees unless explicitly listed in the support matrix.

### GSD shift-left defaults

- **D-25:** Shift these defaults left for future billing-facade / processor discuss-plan work:
  - assume first-party support means **named capability slice**, not generic processor parity
  - assume `Fake` remains merge-blocking deterministic SSOT
  - assume provider-backed lanes are fidelity checks, not mainline proof
  - assume new processor work needs a capability-matrix row before API expansion
  - assume every processor-facing public API must be labeled “all first-party,” “Stripe-only,” or “out of slice”
- **D-26:** These defaults should be reopened only for high-impact choices such as adding a provider, expanding the first-party slice, changing release-gate philosophy, or promoting a Stripe-only API into the official multi-provider contract.

### the agent's Discretion

- Exact names for the new capability-matrix leaves introduced in Phase 95.
- Whether the second-provider thin slice in Phase 96 uses an installer-generated host example, the canonical demo host, or both.
- Whether Braintree’s hosted/client-tokenized payment-method acquisition should surface as a new facade helper or stay internal to the host example in the first implementation pass.

### Deferred Ideas (OUT OF SCOPE)

- Full parity for `create_checkout_session/2` outside Stripe
- Full parity for `create_billing_portal_session/2` outside Stripe
- Processor-agnostic support for advanced subscription mutations, schedules, preview/proration, refunds, coupons, promotion codes, metering, and Connect
- Merchant-of-record provider support
- Any finance / accounting / **FIN-03** expansion
- Community plugin ecosystem posture for processors
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROC-09 | Accrue records a persistent processor-expansion strategy, an explicit capability matrix for the official second-processor track, and a locked target-provider decision with written rationale. [VERIFIED: REQUIREMENTS.md] | This research identifies the canonical artifact pattern, the matrix/verifier coupling pattern, the Braintree capability evidence, the Fake-first proof posture, and the validation architecture needed to make those truths persistent and merge-visible. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/][CITED: https://github.com/pay-rails/pay] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Phase 94 must stay within the locked stack floor of Elixir 1.17+, OTP 27+, Phoenix 1.8+, Ecto 3.12+, and PostgreSQL 14+, and it must not recommend legacy compatibility work. [VERIFIED: CLAUDE.md]
- Existing required dependencies remain `lattice_stripe`, `oban`, `swoosh`, `ecto_sql`, `postgrex`, `nimble_options`, `telemetry`, and `chromic_pdf`; this phase should not introduce a competing payment abstraction library. [VERIFIED: CLAUDE.md]
- Webhook signature verification is mandatory and non-bypassable, raw body capture must happen before `Plug.Parsers`, sensitive Stripe fields must never be logged, and stored payment-method detail must remain processor references rather than PII. [VERIFIED: CLAUDE.md]
- All public entry points are expected to emit `:telemetry`, so capability labeling or support truth added in later phases must preserve telemetry discipline rather than bypass the facade. [VERIFIED: CLAUDE.md]
- The monorepo structure is fixed: `accrue/` and `accrue_admin/` are sibling Mix projects with shared CI and shared guides, so processor-support truth should live in repo-level planning/docs artifacts rather than in a package-specific silo. [VERIFIED: CLAUDE.md]

## Summary

Phase 94 is a repo-truth phase, not a runtime-library phase. The main planning problem is not “how do we call Braintree?” but “how do we stop the repo from implying Stripe parity where the product only intends a bounded second-provider slice?” The codebase already shows the underlying tension: `Accrue.Processor` is broad and Stripe-shaped, while `Accrue.Processor.Capabilities` currently deep-merges broad legacy defaults that still read as near-parity. [VERIFIED: codebase grep]

Accrue already has a house pattern for this kind of truth: one canonical matrix artifact, one dedicated bash verifier, one paired ExUnit smoke harness, and one merge-visible CI lane that fails when prose and support claims drift. The adoption proof matrix, `verify_adoption_proof_matrix.sh`, `verify_package_docs.sh`, and `package_docs_verifier_test.exs` together show the exact planning pattern to reuse here. [VERIFIED: codebase grep]

Externally, Braintree fits the locked “Stripe-like direct gateway” scope well enough for the next phases: its recurring-billing docs require customers with vaulted payment methods plus plans/subscriptions, its webhook system exposes signed notification parsing, and its JS client path explicitly supports Hosted Fields and client-token setup for tokenized vault acquisition. That makes Braintree a credible target for the narrow “gateway subscription core” slice without forcing merchant-of-record or hosted-portal parity claims. [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/][CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/overview/][CITED: https://developer.paypal.com/braintree/docs/guides/hosted-fields/overview/javascript/v3/][CITED: https://developer.paypal.com/braintree/docs/guides/client-sdk/setup/javascript/v3/]

**Primary recommendation:** Make Phase 94 produce one canonical processor-support matrix artifact plus one explicit strategy update in `.planning/STRATEGY.md`, and wire both into a shift-left verifier/test pair before Phase 95 changes code. The matrix should define semantic capability rows, provider columns (`Fake`, `Stripe`, `Braintree`), and a required label for each public API: `all first-party`, `Stripe-only`, or `out of slice`. [VERIFIED: codebase grep][ASSUMED]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Persistent strategic posture and target-provider lock | Repository docs / planning [VERIFIED: codebase grep] | CI / validation [VERIFIED: codebase grep] | `.planning/STRATEGY.md`, `.planning/ROADMAP.md`, and `.planning/REQUIREMENTS.md` are already the strategic SSOT surfaces, but this repo treats major documentation truth as merge-visible via bash verifiers and CI. [VERIFIED: codebase grep] |
| Capability matrix semantics | API / backend [VERIFIED: codebase grep] | Repository docs / planning [VERIFIED: codebase grep] | The matrix rows must describe backend-owned semantic behavior such as customer ops, direct subscription creation, webhook verify/parse, and webhook-backed projection. The written matrix then becomes the planning/documentation contract for those semantics. [VERIFIED: codebase grep] |
| Public API support labeling | API / backend [VERIFIED: codebase grep] | Repository docs / planning [VERIFIED: codebase grep] | Support truth belongs at the facade boundary because `Accrue.Billing` is the user-facing product seam, but the labels need a written artifact so docs and later code paths agree. [VERIFIED: codebase grep] |
| Fake deterministic proof lane policy | CI / validation [VERIFIED: codebase grep] | API / backend [VERIFIED: codebase grep] | The repo already treats Fake as the deterministic merge-blocking path and live Stripe as advisory parity, so processor-support posture must preserve that lane split. [VERIFIED: codebase grep] |
| Braintree thin-slice feasibility inputs for later phases | API / backend [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/] | Browser / client [CITED: https://developer.paypal.com/braintree/docs/guides/hosted-fields/overview/javascript/v3/] | The supported slice depends on server-side customer/subscription/webhook behavior plus browser-side tokenized payment-method acquisition. [CITED: https://developer.paypal.com/braintree/docs/guides/client-sdk/setup/javascript/v3/] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `.planning/STRATEGY.md` | current repo artifact [VERIFIED: codebase grep] | Persistent strategic tracker | `PROC-08` already uses this file as the active strategic parent, so Phase 94 should extend it rather than create a competing strategy story elsewhere. [VERIFIED: codebase grep] |
| `examples/accrue_host/docs/adoption-proof-matrix.md` | current repo artifact [VERIFIED: codebase grep] | Matrix-artifact precedent | The repo already uses a first-class matrix document to answer “what is supported/proven, where, and against what realism.” Phase 94 should reuse that artifact pattern for processor support truth. [VERIFIED: codebase grep] |
| `scripts/ci/verify_adoption_proof_matrix.sh` | current repo artifact [VERIFIED: codebase grep] | Matrix-verifier precedent | This script establishes the repo’s same-PR co-update discipline for a matrix document and its enforcement layer. [VERIFIED: codebase grep] |
| `scripts/ci/verify_package_docs.sh` | current repo artifact [VERIFIED: codebase grep] | Merge-blocking doc-truth gate | Documentation truth is already enforced through fixed needles and CI, so Phase 94 should plug into that shift-left culture rather than rely on prose alone. [VERIFIED: codebase grep] |
| `Accrue.Processor.Capabilities` | current module [VERIFIED: codebase grep] | Capability declaration precedent | Capability truth already has a code seam, but the current legacy-default merge is too broad to serve as the only public support contract. [VERIFIED: codebase grep] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `braintree` (Hex) | `0.16.0` — published 2025-03-27 [VERIFIED: hex.pm API] | Candidate Elixir server SDK for later Braintree adapter work | Use in Phase 95/96 feasibility and adapter planning; Phase 94 only needs it as evidence that a real Elixir package surface exists. [VERIFIED: hex.pm API] |
| `braintree-web` (npm) | `3.141.0` — registry modified 2026-04-23 [VERIFIED: npm registry] | Browser tokenization / Hosted Fields path for vaulted payment-method acquisition | Use when planning the host-side payment-method handoff for Braintree. [VERIFIED: npm registry][CITED: https://developer.paypal.com/braintree/docs/guides/client-sdk/setup/javascript/v3/] |
| `accrue/test/accrue/docs/package_docs_verifier_test.exs` | current repo artifact [VERIFIED: codebase grep] | ExUnit shell-out pattern for bash verifiers | Reuse when adding a processor-matrix verifier so docs truth is tested both in bash and in ExUnit. [VERIFIED: codebase grep] |
| `accrue/guides/custom_processors.md` | current repo artifact [VERIFIED: codebase grep] | Extension-point posture | Keep as the custom-adapter story, but do not let it become the first-party support contract. [VERIFIED: codebase grep] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| One canonical processor-support matrix plus verifier [ASSUMED] | Strategy bullets spread across `README`, guides, and planning notes | Cheaper short-term, but the repo’s own history shows that scattered support claims drift unless a single matrix and verifier own them. [VERIFIED: codebase grep] |
| Semantic capability rows such as `subscription.lifecycle_webhook_projection` [VERIFIED: 094-CONTEXT.md] | Provider-jargon rows keyed to Stripe or Braintree event names | Provider jargon leaks implementation details into the contract and makes honest multi-provider support harder to reason about. [VERIFIED: 094-CONTEXT.md] |
| Locked Braintree target [VERIFIED: 094-CONTEXT.md] | Reopen provider selection inside Phase 94 planning | Out of scope: D-05 already locks Braintree, so the planning work should deepen the choice rather than re-litigate it. [VERIFIED: 094-CONTEXT.md] |

**Installation:**
```bash
# No new package install is required to complete Phase 94 itself.
# Verified candidate packages for later phases:
#   mix hex.search --package braintree
#   npm view braintree-web version
```

**Version verification:** `braintree` Hex package `0.16.0` was published on 2025-03-27, and `braintree-web` npm package is at `3.141.0` with registry modification timestamp 2026-04-23. [VERIFIED: hex.pm API][VERIFIED: npm registry]

## Architecture Patterns

### System Architecture Diagram

```text
094-CONTEXT.md + REQUIREMENTS.md + STRATEGY.md
                |
                v
      Phase 94 strategic synthesis
      - provider lock rationale
      - explicit capability rows
      - public API support labels
      - explicit out-of-slice exclusions
                |
                v
    Canonical processor-support truth artifact(s)
    - strategy tracker update
    - capability matrix doc
                |
                v
      Shift-left enforcement layer
      - bash verifier(s)
      - ExUnit shell-out smoke
      - docs-contracts-shift-left CI
                |
                v
         Downstream consumers
      Phase 95 conformance/boundary hardening
      Phase 96 Braintree thin slice + positioning
```

The important flow is: planning truth first, verifier truth second, implementation truth third. This repo already treats unenforced support prose as drift-prone. [VERIFIED: codebase grep]

### Recommended Project Structure

```text
.planning/
├── STRATEGY.md                     # Strategic posture and target-provider rationale
├── processor-support-matrix.md     # Canonical processor capability matrix [ASSUMED]
└── REQUIREMENTS.md                 # PROC-09 traceability anchor

scripts/ci/
├── verify_package_docs.sh          # Existing doc truth gate
└── verify_processor_support_matrix.sh  # Dedicated matrix verifier [ASSUMED]

accrue/test/accrue/docs/
└── processor_support_matrix_test.exs   # ExUnit shell-out smoke or extension of existing verifier tests [ASSUMED]
```

### Pattern 1: Canonical Matrix + Verifier Pair
**What:** One matrix artifact owns provider-support truth, and one bash verifier owns the required literal needles for that matrix. [VERIFIED: codebase grep]
**When to use:** Any time the repo needs a stable, merge-visible contract for “what is supported where” rather than free-form prose. [VERIFIED: codebase grep]
**Example:**
```bash
# Source: scripts/ci/verify_adoption_proof_matrix.sh
require_substring "## Layering note (local proof vs merge-blocking CI)" "Layer B/C layering heading"
require_substring "Accrue.Billing.create_checkout_session/2" "checkout facade API in matrix"
require_substring "billing_portal_session_facade_test.exs" "billing portal facade ExUnit path in matrix"
```

### Pattern 2: Semantic Capability Rows
**What:** Capability rows describe contract semantics, not provider implementation names. [VERIFIED: 094-CONTEXT.md]
**When to use:** When the same public behavior could be backed by different provider APIs or event names. [VERIFIED: 094-CONTEXT.md]
**Example:**
```markdown
| Capability | Fake | Stripe | Braintree | Public Label |
|------------|------|--------|-----------|--------------|
| customer.create | yes | yes | yes | all first-party |
| subscription.direct_create | yes | yes | yes | all first-party |
| checkout.hosted_handoff | yes | yes | no | Stripe-only |
| billing_portal.hosted_self_serve | yes | yes | no | Stripe-only |
| invoice.lifecycle_webhook_projection | yes | yes | yes | all first-party |
```

### Pattern 3: Fake-First Proof, Provider-Backed Fidelity
**What:** Fake remains the required deterministic lane, while provider-backed runs stay advisory fidelity checks. [VERIFIED: codebase grep]
**When to use:** Any processor-support planning that might otherwise over-rotate toward slow or flaky networked tests. [VERIFIED: codebase grep]
**Example:**
```text
Blocking lane: Accrue.Processor.Fake + mix verify / mix verify.full
Advisory lane: live provider tests such as mix test.live
```

### Anti-Patterns to Avoid

- **Prose-only support claims:** The repo already uses matrix-plus-verifier discipline for truthy support narratives, so Phase 94 should not rely on README prose alone. [VERIFIED: codebase grep]
- **Provider-jargon capability rows:** Rows like “Stripe Checkout Session” or “Braintree notification kind” describe implementation details, not the support contract. [VERIFIED: 094-CONTEXT.md]
- **Legacy-default capability truth:** Keeping the current broad defaults as the main public contract would imply support breadth that the bounded second-provider slice does not promise. [VERIFIED: codebase grep]
- **Reopening target-provider selection:** Braintree is locked by context; Phase 94 planning should operationalize that lock, not relitigate it. [VERIFIED: 094-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| First-party support truth | Marketing prose about “processor-agnostic” support | Explicit capability matrix + verifier | The repo already enforces matrix truth elsewhere, and the context explicitly rejects processor-agnostic marketing claims. [VERIFIED: codebase grep][VERIFIED: 094-CONTEXT.md] |
| Provider parity model | New lowest-common-denominator abstraction in Phase 94 | Bounded gateway-subscription slice with capability labels | Cashier and Pay show that honest provider-specific boundaries age better than pretending every processor is the same. [CITED: https://laravel.com/docs/12.x/billing][CITED: https://github.com/pay-rails/pay] |
| Gateway breadth precedent | ActiveMerchant-style everything-gateway scope | Named first-party provider list with explicit exclusions | ActiveMerchant explicitly aims for a consistent interface across supported gateways, which is the exact abstraction pressure Accrue wants to avoid here. [CITED: https://github.com/activemerchant/active_merchant] |
| New proof topology | Custom Phase-94-only validation story | Existing Fake-blocking + advisory-provider lane split | The repo already has a stable proof taxonomy that downstream phases can reuse. [VERIFIED: codebase grep] |

**Key insight:** The dangerous hand-rolled thing in this phase is not code; it is support semantics. If Phase 94 invents a soft, unenforced notion of support, later phases will spend time undoing documentation and contract drift before they can ship real provider behavior. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Legacy Capability Defaults Imply More Support Than Intended
**What goes wrong:** The repo keeps a broad capability map that still reads like Stripe-near parity even after strategy narrows the first-party slice. [VERIFIED: codebase grep]
**Why it happens:** `Accrue.Processor.Capabilities` deep-merges a truthy legacy default map before adapter declarations narrow leaves. [VERIFIED: codebase grep]
**How to avoid:** Treat the written matrix as the public SSOT and plan Phase 95 to align code-level declarations to that matrix instead of treating legacy defaults as authoritative. [VERIFIED: codebase grep][ASSUMED]
**Warning signs:** Support prose starts saying “processor-agnostic,” or a public API lacks a label such as `all first-party`, `Stripe-only`, or `out of slice`. [VERIFIED: 094-CONTEXT.md]

### Pitfall 2: Matrix Drift from Verifiers
**What goes wrong:** The matrix doc, strategy text, bash verifier, and ExUnit smoke harness stop matching. [VERIFIED: codebase grep]
**Why it happens:** This repo intentionally uses fixed-string verifier needles, so any truth artifact that changes without same-PR verifier edits produces silent narrative drift until CI is touched. [VERIFIED: codebase grep]
**How to avoid:** Plan Phase 94 as a co-update slice: matrix artifact, strategy copy, verifier changes, and test changes in the same plan or wave. [VERIFIED: codebase grep]
**Warning signs:** A new processor row exists in docs, but no bash verifier or ExUnit shell-out mentions it. [VERIFIED: codebase grep][ASSUMED]

### Pitfall 3: Hosted UX Scope Creep
**What goes wrong:** Planning starts smuggling checkout, billing-portal, embedded, or setup-intent parity into the “thin slice.” [VERIFIED: 094-CONTEXT.md]
**Why it happens:** Both Braintree and Stripe have client-side flows, so teams are tempted to generalize “hosted acquisition exists” into “hosted product parity exists.” [CITED: https://developer.paypal.com/braintree/docs/guides/hosted-fields/overview/javascript/v3/]
**How to avoid:** Keep `payment_method.vault_acquisition` distinct from `checkout.hosted_handoff` and `billing_portal.hosted_self_serve` in the matrix. [VERIFIED: 094-CONTEXT.md]
**Warning signs:** `create_checkout_session/2` or `create_billing_portal_session/2` appears in the supported Braintree slice before any capability label says `Stripe-only`. [VERIFIED: 094-CONTEXT.md]

## Code Examples

Verified patterns from current repo sources:

### Capability Guard Pattern
```elixir
# Source: accrue/lib/accrue/checkout/session.ex
defp ensure_checkout_support!(:create) do
  unless Processor.supports?([:checkout, :create]) do
    raise Accrue.APIError,
      code: "processor_operation_unsupported",
      message: "#{Processor.name()} does not support checkout creation"
  end
end
```

This is the concrete precedent for “unsupported must fail clearly and early.” [VERIFIED: codebase grep]

### Matrix Verifier Pattern
```bash
# Source: scripts/ci/verify_adoption_proof_matrix.sh
require_substring "phx.gen.auth" "phx.gen.auth mention"
require_substring "use Accrue.Billable" "Accrue.Billable hook"
require_substring "linked `1.0.0` pair" "linked 1.0.0 pair proof needle"
```

This is the concrete precedent for locking a matrix artifact to required literals through a dedicated script. [VERIFIED: codebase grep]

### Braintree Planning Shape
```text
Server side:
  create customer with vaulted payment method
  create or attach plan-backed subscription
  verify and parse webhook notifications
  project subscription/invoice lifecycle back into local truth

Client side:
  generate client token
  tokenize card/payment method through Hosted Fields or equivalent
```

That shape is directly supported by Braintree’s recurring billing, webhook, Hosted Fields, and client-SDK docs. [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/][CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/overview/][CITED: https://developer.paypal.com/braintree/docs/guides/hosted-fields/overview/javascript/v3/][CITED: https://developer.paypal.com/braintree/docs/guides/client-sdk/setup/javascript/v3/]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| One generic billing package story | Provider-specific products/docs for Stripe vs Paddle in Laravel Cashier | Current Laravel 12 docs as crawled on 2026-04-29 [CITED: https://laravel.com/docs/12.x/billing][CITED: https://laravel.com/docs/12.x/cashier-paddle] | Honest divergence is normal; separate provider stories are ecosystem-standard, not a weakness. [CITED: https://laravel.com/docs/12.x/billing][CITED: https://laravel.com/docs/12.x/cashier-paddle] |
| Hidden processor list behind abstraction | Explicit supported processor list in Pay (`Stripe`, `Paddle`, `Braintree`, `Lemon Squeezy`, `Fake Processor`) | Current Pay README as crawled on 2026-04-29 [CITED: https://github.com/pay-rails/pay] | Accrue can name supported processors and still keep a shared billing facade. [CITED: https://github.com/pay-rails/pay] |
| Broad “consistent interface across all gateways” ambition | Bounded support surfaces with explicit provider divergence warnings | ActiveMerchant remains the cautionary broad abstraction reference as crawled on 2026-04-29 [CITED: https://github.com/activemerchant/active_merchant] | Supports the Phase-94 decision to avoid lowest-common-denominator pressure. [CITED: https://github.com/activemerchant/active_merchant] |

**Deprecated/outdated:**

- “Processor-agnostic” marketing for Accrue’s public surface is outdated for this track; the locked strategy is facade-first and capability-explicit instead. [VERIFIED: 094-CONTEXT.md]
- Treating provider-backed tests as the primary development loop is outdated for this repo; Fake is the deterministic required lane and live provider runs are advisory fidelity checks. [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The best new canonical file home for the capability matrix is a dedicated `.planning/processor-support-matrix.md` linked from `.planning/STRATEGY.md`. [ASSUMED] | Architecture Patterns | Low to medium. The planner may create the right artifact with a different filename or embed it directly in `STRATEGY.md`. |
| A2 | A dedicated `scripts/ci/verify_processor_support_matrix.sh` plus a paired ExUnit shell-out test is the cleanest enforcement pattern, rather than only extending `verify_package_docs.sh`. [ASSUMED] | Architecture Patterns, Validation Architecture | Low. The repo could fold the new needles into existing verifiers instead of adding a new one. |

## Open Questions (RESOLVED)

1. **Should the processor capability matrix be its own file or a major section inside `.planning/STRATEGY.md`?**
   Resolution: use a dedicated `.planning/processor-support-matrix.md` and have `.planning/STRATEGY.md`, `.planning/PROJECT.md`, `accrue/guides/custom_processors.md`, `scripts/ci/verify_package_docs.sh`, and `scripts/ci/verify_processor_support_matrix.sh` point back to it. This follows the repo’s matrix-plus-verifier pattern while keeping strategic narrative and support-table diffs separate. [RESOLVED per A1][VERIFIED: codebase grep]

2. **Will Phase 96 expose Braintree vault acquisition through a new facade helper or keep it inside the host example first?**
   Resolution: explicitly defer the delivery choice to Phase 96, but lock `payment_method.vault_acquisition` into the Phase 94 matrix so the capability is visible regardless of where the first host/runtime seam lands. This is an allowed discretion area and does not block Phase 94. [DEFERRED TO PHASE 96][CITED: https://developer.paypal.com/braintree/docs/guides/hosted-fields/overview/javascript/v3/][VERIFIED: 094-CONTEXT.md]

3. **How granular should Phase-95 capability leaves become?**
   Resolution: keep Phase 94 at semantic row granularity using the context’s named behaviors, then let Phase 95 choose the exact code representation so long as it preserves the same contract semantics and matrix labels. Phase 94 therefore locks behavior names, not implementation-key syntax. [RESOLVED][VERIFIED: 094-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `bash` | Bash verifier scripts | ✓ [VERIFIED: shell probe] | 5.2.37 [VERIFIED: shell probe] | — |
| `jq` | Hex/API inspection and any JSON-aware verifier work | ✓ [VERIFIED: shell probe] | 1.7.1 [VERIFIED: shell probe] | Plain grep/sed if needed [ASSUMED] |
| `mix` | ExUnit docs/verifier tests | ✓ [VERIFIED: shell probe] | Mix 1.19.5 / OTP 28 [VERIFIED: shell probe] | — |
| `node` | Host browser verification stack | ✓ [VERIFIED: shell probe] | v22.14.0 [VERIFIED: shell probe] | — |
| `npm` | Browser/tooling dependencies and package verification | ✓ [VERIFIED: shell probe] | 11.1.0 [VERIFIED: shell probe] | — |
| PostgreSQL on localhost:5432 | Full host `mix verify.full` contract | ✓ [VERIFIED: shell probe] | accepting connections [VERIFIED: shell probe] | Bounded docs-only verifiers if host suite is not needed during doc drafting [ASSUMED] |

**Missing dependencies with no fallback:**
- None found. [VERIFIED: shell probe]

**Missing dependencies with fallback:**
- None found. [VERIFIED: shell probe]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Bash verifier scripts + ExUnit shell-out tests + GitHub Actions `docs-contracts-shift-left` / `host-integration` lanes. [VERIFIED: codebase grep] |
| Config file | `.github/workflows/ci.yml` and package-local `mix.exs` aliases. [VERIFIED: codebase grep] |
| Quick run command | `bash scripts/ci/verify_package_docs.sh` and, if added, the processor-matrix verifier. [VERIFIED: codebase grep][ASSUMED] |
| Full suite command | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` plus `bash scripts/ci/accrue_host_uat.sh` when Phase 94 changes host-facing proof docs. [VERIFIED: codebase grep] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROC-09 | Strategy tracker contains locked posture, provider lock, and explicit non-goals. [VERIFIED: REQUIREMENTS.md] | bash doc contract [ASSUMED] | `bash scripts/ci/verify_processor_support_matrix.sh` or extension of `verify_package_docs.sh` [ASSUMED] | ❌ Wave 0 [ASSUMED] |
| PROC-09 | Capability matrix names the official slice and labels out-of-slice / Stripe-only surfaces. [VERIFIED: REQUIREMENTS.md] | bash doc contract + ExUnit shell-out [ASSUMED] | `bash scripts/ci/verify_processor_support_matrix.sh` and `cd accrue && mix test test/accrue/docs/processor_support_matrix_test.exs` [ASSUMED] | ❌ Wave 0 [ASSUMED] |
| PROC-09 | Existing docs/proof language stays aligned with Fake-first and advisory-provider lane posture. [VERIFIED: REQUIREMENTS.md][VERIFIED: codebase grep] | existing bash verifiers | `bash scripts/ci/verify_package_docs.sh` and `bash scripts/ci/verify_adoption_proof_matrix.sh` [VERIFIED: codebase grep] | ✅ |

### Sampling Rate

- **Per task commit:** `bash scripts/ci/verify_package_docs.sh` and the processor-matrix verifier if Phase 94 adds one. [VERIFIED: codebase grep][ASSUMED]
- **Per wave merge:** `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` plus any new docs-verifier ExUnit harness. [VERIFIED: codebase grep][ASSUMED]
- **Phase gate:** `bash scripts/ci/accrue_host_uat.sh` only if host README / adoption proof surfaces are touched; otherwise the docs-contracts-shift-left bundle is sufficient. [VERIFIED: codebase grep][ASSUMED]

### Wave 0 Gaps

- [ ] `scripts/ci/verify_processor_support_matrix.sh` or equivalent `verify_package_docs.sh` extension to make processor-support truth merge-visible. [ASSUMED]
- [ ] `accrue/test/accrue/docs/processor_support_matrix_test.exs` or extension of `package_docs_verifier_test.exs` to smoke-test the new verifier from ExUnit. [ASSUMED]
- [ ] CI wiring in `.github/workflows/ci.yml` if a new dedicated script is introduced instead of extending an existing one. [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: phase scope] | Not a Phase-94 concern; this phase does not change auth flows. [VERIFIED: phase scope] |
| V3 Session Management | no [VERIFIED: phase scope] | Not a Phase-94 concern. [VERIFIED: phase scope] |
| V4 Access Control | no [VERIFIED: phase scope] | Not a Phase-94 concern. [VERIFIED: phase scope] |
| V5 Input Validation | yes [VERIFIED: codebase grep] | Capability checks must keep unsupported operations failing early and explicitly rather than falling through to wrong provider behavior. [VERIFIED: codebase grep] |
| V6 Cryptography | yes [VERIFIED: CLAUDE.md][CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/overview/] | Reuse existing webhook-signature verification patterns; never hand-roll or soften webhook verification in service of “generic” processor support. [VERIFIED: CLAUDE.md][CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/overview/] |

### Known Threat Patterns for processor-support docs/contracts

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unsupported operation silently treated as supported | Tampering | Capability matrix + explicit `Processor.supports?` gates + public API labels. [VERIFIED: codebase grep][VERIFIED: 094-CONTEXT.md] |
| Webhook verification parity weakened for “generic” adapters | Spoofing | Keep `webhook.verify` and `webhook.parse` as explicit first-class rows and preserve non-bypassable signature verification language. [VERIFIED: CLAUDE.md][VERIFIED: 094-CONTEXT.md] |
| Processor docs leak PII or secret handling shortcuts | Information Disclosure | Reuse current repo security posture: no raw secret logging, no payment-method PII storage, and no copied payloads in docs/tests. [VERIFIED: CLAUDE.md][VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)

- `094-CONTEXT.md`, `.planning/REQUIREMENTS.md`, `.planning/STRATEGY.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` — phase scope, locked decisions, and milestone traceability. [VERIFIED: codebase grep]
- `accrue/lib/accrue/processor.ex`, `accrue/lib/accrue/processor/capabilities.ex`, `accrue/lib/accrue/processor/stripe.ex`, `accrue/lib/accrue/processor/fake.ex`, `accrue/lib/accrue/checkout/session.ex` — current processor boundary, capability defaults, and early-failure precedent. [VERIFIED: codebase grep]
- `accrue/guides/custom_processors.md`, `accrue/guides/testing.md`, `guides/testing-live-stripe.md`, `examples/accrue_host/docs/adoption-proof-matrix.md`, `scripts/ci/verify_package_docs.sh`, `scripts/ci/verify_adoption_proof_matrix.sh`, `.github/workflows/ci.yml`, `accrue/test/accrue/docs/package_docs_verifier_test.exs` — repo truth and verifier patterns. [VERIFIED: codebase grep]
- Braintree recurring billing overview: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/ [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/]
- Braintree webhooks overview: https://developer.paypal.com/braintree/docs/reference/general/webhooks/overview/ [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/overview/]
- Braintree Hosted Fields overview: https://developer.paypal.com/braintree/docs/guides/hosted-fields/overview/javascript/v3/ [CITED: https://developer.paypal.com/braintree/docs/guides/hosted-fields/overview/javascript/v3/]
- Braintree client SDK setup: https://developer.paypal.com/braintree/docs/guides/client-sdk/setup/javascript/v3/ [CITED: https://developer.paypal.com/braintree/docs/guides/client-sdk/setup/javascript/v3/]
- Hex.pm API for `braintree` `0.16.0` and npm registry for `braintree-web` `3.141.0`. [VERIFIED: hex.pm API][VERIFIED: npm registry]

### Secondary (MEDIUM confidence)

- Laravel Cashier Stripe docs: https://laravel.com/docs/12.x/billing [CITED: https://laravel.com/docs/12.x/billing]
- Laravel Cashier Paddle docs: https://laravel.com/docs/12.x/cashier-paddle [CITED: https://laravel.com/docs/12.x/cashier-paddle]
- Pay (Rails) repository README/docs index: https://github.com/pay-rails/pay [CITED: https://github.com/pay-rails/pay]
- ActiveMerchant repository README/About section: https://github.com/activemerchant/active_merchant [CITED: https://github.com/activemerchant/active_merchant]

### Tertiary (LOW confidence)

- None. All meaningful external claims were verified against official docs, registries, or the checked-in codebase. [VERIFIED: research synthesis]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - the repo artifact pattern, verifier topology, and candidate Braintree package versions were all verified directly from the codebase or registries. [VERIFIED: codebase grep][VERIFIED: hex.pm API][VERIFIED: npm registry]
- Architecture: HIGH - the phase boundary, strategic parent artifacts, and processor-capability/code seams are explicit in checked-in planning and code files. [VERIFIED: codebase grep]
- Pitfalls: HIGH - the failure modes are visible in existing capability defaults, docs/verifier coupling, and the locked Phase-94 scope. [VERIFIED: codebase grep][VERIFIED: 094-CONTEXT.md]

**Research date:** 2026-04-29
**Valid until:** 2026-05-29 for repo-internal planning patterns, and 2026-05-13 for Braintree package/doc currency because provider SDK/docs can move faster. [ASSUMED]
