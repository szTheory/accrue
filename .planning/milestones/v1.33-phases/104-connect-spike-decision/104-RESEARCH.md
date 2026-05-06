# Phase 104: Connect Spike / Decision - Research

**Researched:** 2026-05-02
**Domain:** Braintree marketplace / Hyperwallet payout feasibility
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Decision target
- **D-01:** Keep Phase 104 as a decision spike, not a platform-design phase.
- **D-02:** The best default is **go/no-go plus a narrow if-go slice contract**. That preserves a reusable outcome from the spike without committing Accrue to a large marketplace architecture.
- **D-03:** Avoid a full architecture target in this phase. It would overfit the project to false provider commonality and likely pull the codebase toward a payout-platform design before the boundary is actually justified.

### Parity bar
- **D-04:** If the spike is positive, the right bar is **core `Accrue.Connect` semantic parity with loud exclusions**.
- **D-05:** Do not chase near-Stripe parity. Braintree + Hyperwallet is not Stripe Connect, and pretending otherwise would create support debt and misleading APIs.
- **D-06:** If a smaller marketplace slice is pursued, it should stay honest about what it covers and what it does not. Minimal onboarding/payout-only support is viable only if it is labeled as such, not sold as full Connect parity.

### Product boundary
- **D-07:** Keep Braintree pay-ins and Hyperwallet payouts as separate truths in the docs and module boundaries.
- **D-08:** Use one `Accrue.Connect` umbrella story for discoverability, but keep provider ownership visible in types, docs, capability labels, and failure paths.
- **D-09:** Do not hide the split behind a unified abstraction. The lowest-surprise, most supportable shape is explicit provider boundaries under a marketplace umbrella.

### Rejection posture
- **D-10:** If the spike says no, reject marketplace parity as **strategically out of bounds unless the project boundary changes**.
- **D-11:** Do not use the weaker posture of "v1.x only" or "until adopter demand" as the final answer. Those are too soft for this project and invite zombie scope.
- **D-12:** Reopening this decision should require an explicit strategy change plus a new milestone, not informal roadmap drift.

### the agent's Discretion
- Exact marketplace terminology if a go decision is made, as long as it stays capability-explicit and provider-honest.
- Exact thin-slice shape if the spike is positive, provided it does not imply full Stripe parity.

### Deferred Ideas (OUT OF SCOPE)
- Full Braintree marketplace parity.
- Any future payout-platform abstraction that would generalize marketplace support beyond the current direct-gateway boundary.
- A unified abstraction that hides provider ownership behind a single money-movement API.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BT-08 | Developer MUST conduct a technical spike on PayPal Hyperwallet to evaluate feasibility of Connect parity. | Official docs show Hyperwallet is a separate payout program with its own REST/webhook/admin setup, which means the spike must evaluate operational enablement and capability mismatch, not just API shape. [CITED: https://docs.hyperwallet.com/assets/docs/onboarding/client-requirements.pdf] |
| BT-09 | Developer MUST document a final decision to either implement Hyperwallet or explicitly reject the Connect capability for Braintree. | Repo strategy and phase context already require a hard go/no-go plus loud exclusions; existing docs-verifier patterns can make the decision artifact merge-blocking. [VERIFIED: codebase grep] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Accrue is locked to Elixir 1.17+, OTP 27+, Phoenix 1.8+, Ecto 3.12+, and PostgreSQL 14+. [VERIFIED: CLAUDE.md]
- `lattice_stripe`, `oban`, `ecto_sql`, `postgrex`, `nimble_options`, `telemetry`, and `chromic_pdf` are required project dependencies; `sigra` is optional. [VERIFIED: CLAUDE.md]
- Webhook signature verification is mandatory and sensitive payment fields must never be logged. [VERIFIED: CLAUDE.md]
- Public entry points are expected to emit telemetry, and host apps own long-running infra such as Oban and ChromicPDF supervision. [VERIFIED: CLAUDE.md] [VERIFIED: codebase grep]
- The repo is a monorepo with sibling Mix projects; planning should preserve capability-explicit, first-party-support boundaries instead of widening abstractions speculatively. [VERIFIED: CLAUDE.md] [VERIFIED: codebase grep]
- No project-local skills were found in `.claude/skills/` or `.agents/skills/` during this session. [VERIFIED: file scan]

## Summary

Accrue already ships a substantial Stripe-shaped `Accrue.Connect` facade with local account projection, onboarding links, login links, platform-fee helpers, destination charges, separate charge-and-transfer, and transfer helpers, while the Braintree adapter currently advertises no marketplace or Connect capability in its capability map. [VERIFIED: codebase grep]

Official provider docs show why Phase 104 must stay a decision spike. Braintree still documents marketplace/sub-merchant concepts and webhooks, but its recurring billing guide explicitly says recurring billing is not compatible with Braintree Marketplace. Hyperwallet onboarding material describes a separate payout program that requires its own webhook listener URLs, admin users, API-credential recipients, and recommends REST API plus webhooks for payee registration and issuing payments. PayPal's current payout/AAC docs further show a separate seller-recipient onboarding path built around payer IDs and payout APIs, not Stripe-style connected-account balance semantics. [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/sub-merchant-account/] [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/] [CITED: https://docs.hyperwallet.com/assets/docs/onboarding/client-requirements.pdf] [CITED: https://developer.paypal.com/docs/payouts/standard/login-with-payouts/] [CITED: https://developer.paypal.com/docs/payouts/standard/integrate-api/]

**Primary recommendation:** Plan Phase 104 as a documentation/decision phase with a default **no-go** outcome; only permit a future **go** if the deliverable is narrowed to explicit seller onboarding plus payout orchestration under `Accrue.Connect`, with loud exclusions for Stripe-only money-movement semantics such as destination charges, separate charge-and-transfer, login-link parity, and unified balance behavior. [VERIFIED: codebase grep] [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/] [CITED: https://docs.hyperwallet.com/assets/docs/onboarding/client-requirements.pdf]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Seller/payee onboarding start | Browser / Client | API / Backend | Hosted provider flows start from a user redirect/button, but the server owns generated URLs, redirect URIs, and state binding. [CITED: https://developer.paypal.com/braintree/docs/guides/braintree-auth/server-side/] [CITED: https://developer.paypal.com/docs/payouts/standard/login-with-payouts/] |
| Provider account binding and webhook ingest | API / Backend | Database / Storage | Credentials, webhook auth, local projection, and event persistence are server-owned concerns. [CITED: https://docs.hyperwallet.com/assets/docs/onboarding/client-requirements.pdf] [VERIFIED: codebase grep] |
| Capability labels and unsupported-path failures | API / Backend | Frontend Server (docs) | Accrue already models public support via capability maps and typed unsupported behavior, then mirrors that truth into docs/tests. [VERIFIED: codebase grep] |
| Final decision artifact and support-matrix truth | Frontend Server (docs) | API / Backend | The repo already uses docs verifiers and docs tests to lock public capability truth. [VERIFIED: codebase grep] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:braintree` | `0.16.0` | Existing gateway adapter and the concrete source of Braintree marketplace constraints. [VERIFIED: mix hex.info braintree] | Already locked in `accrue/mix.exs`; the phase should reason from the real adapter surface, not introduce a new pay-in stack. [VERIFIED: codebase grep] |
| `Accrue.Connect` | repo local | Existing public marketplace facade whose current semantics are Stripe-shaped. [VERIFIED: codebase grep] | Any go/no-go decision must be expressed relative to this facade because it is already public API. [VERIFIED: codebase grep] |
| `Accrue.Processor.Capabilities` | repo local | Existing capability-label SSOT for supported vs unsupported processor behavior. [VERIFIED: codebase grep] | This is the correct place to make any future Braintree/Hyperwallet slice honest and explicit. [VERIFIED: codebase grep] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ExUnit docs tests | repo local | Merge-blocking documentation and verifier coverage. [VERIFIED: codebase grep] | Use for the final Phase 104 decision artifact so BT-09 is enforceable, not just prose in a phase folder. [VERIFIED: codebase grep] |
| `verify_processor_support_matrix.sh` | repo local | Existing docs contract script for processor capability truth. [VERIFIED: codebase grep] | Reuse if the final decision changes the public processor-support matrix or Connect capability labels. [VERIFIED: codebase grep] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Adding a Hyperwallet runtime dependency in Phase 104 | No new dependency in Phase 104 | This phase is decision-only; adding code dependencies before a go decision creates false momentum and hides the real product-boundary question. [VERIFIED: codebase grep] |
| Faux "full Connect parity" | Narrow provider-explicit onboarding/payout slice | Less symmetry, but materially lower support debt and consistent with the phase constraints. [VERIFIED: codebase grep] [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/] |

**Installation:** None. Phase 104 should not add runtime dependencies. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

The only if-go architecture that fits the evidence is provider-explicit and split by money flow. [VERIFIED: codebase grep] [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/] [CITED: https://docs.hyperwallet.com/assets/docs/onboarding/client-requirements.pdf]

```text
Seller starts setup in host UI
  |
  v
Accrue.Connect (discoverability umbrella)
  |
  +--> Braintree pay-in path
  |      |
  |      +--> Buyer charges / subscriptions / vaulting
  |      +--> Existing Accrue.Billing + Braintree adapter
  |
  +--> Hyperwallet payout path
         |
         +--> Payee registration / transfer-method setup / payout status
         +--> Hyperwallet REST API + webhook listener
         +--> Local projection + events + capability-labeled docs

Forbidden path:
  Pretend both branches are one Stripe-like connected-account balance system
```

### Recommended Project Structure

```text
accrue/
├── lib/accrue/connect/          # existing public marketplace-facing domain
├── lib/accrue/processor/        # capability maps and provider adapters
├── guides/                      # operator + integrator truth
└── test/accrue/docs/            # docs contract tests for public claims
```

### Pattern 1: Provider-Explicit Umbrella

**What:** Keep `Accrue.Connect` as the discoverability umbrella, but expose provider ownership in names, capability labels, docs, and unsupported errors. [VERIFIED: codebase grep] [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/]

**When to use:** If the spike ends in go, but only for a narrow onboarding/payout slice. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: /Users/jon/projects/accrue/accrue/lib/accrue/processor/capabilities.ex
label = Accrue.Processor.Capabilities.support_label([:billing_portal, :create])

unless Accrue.Processor.Capabilities.supports?(capabilities, [:billing_portal, :create]) do
  {:error, unsupported_error(label)}
end
```

### Pattern 2: Decision Artifact as Public Contract

**What:** Treat the final go/no-go result as public contract truth, mirrored in docs and enforced with tests/scripts. [VERIFIED: codebase grep]

**When to use:** Always for BT-09, because the repo already treats support-matrix drift as a test failure. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: /Users/jon/projects/accrue/accrue/test/accrue/docs/processor_support_matrix_test.exs
assert {output, 0} =
         System.cmd("bash", [script], cd: root, stderr_to_stdout: true)

assert output =~ "verify_processor_support_matrix: OK"
```

### Anti-Patterns to Avoid

- **Unified Connect abstraction over split providers:** This hides the Braintree pay-in / Hyperwallet payout split and conflicts with the phase constraints. [VERIFIED: codebase grep] [CITED: https://docs.hyperwallet.com/assets/docs/onboarding/client-requirements.pdf]
- **Planning Stripe-style charge-routing parity:** `Accrue.Connect` already exposes Stripe-specific money-movement helpers, and Braintree recurring billing is documented as incompatible with Braintree Marketplace. [VERIFIED: codebase grep] [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/]
- **Treating provider enablement as a later ops detail:** Hyperwallet onboarding requires webhook URLs, authorized users, and production support contacts before real execution. [CITED: https://docs.hyperwallet.com/assets/docs/onboarding/client-requirements.pdf]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Seller KYC / onboarding UX | Custom collection forms for provider verification data | Provider-hosted onboarding/AAC/embedded flows where the provider owns identity collection | The official docs center provider-owned onboarding, redirect URIs, and payer/payee identity flows; custom KYC UI expands liability and drift risk. [CITED: https://developer.paypal.com/braintree/docs/guides/braintree-auth/server-side/] [CITED: https://developer.paypal.com/docs/payouts/standard/login-with-payouts/] [CITED: https://docs.hyperwallet.com/assets/docs/onboarding/client-requirements.pdf] |
| Payout execution and status transport | Homegrown payout ledger or transfer rail | Hyperwallet or PayPal payout APIs plus webhooks | The provider already owns payment execution and recommends API plus webhook delivery for status changes. [CITED: https://docs.hyperwallet.com/assets/docs/onboarding/client-requirements.pdf] [CITED: https://developer.paypal.com/docs/payouts/standard/integrate-api/] |
| Public capability truth | Ad hoc README wording | Existing capability map plus docs verifier/test pattern | The repo already has a support-matrix SSOT and tests around it. [VERIFIED: codebase grep] |
| Retry / webhook delivery flow | Synchronous controller-only retry logic | Existing Accrue webhook/event/Oban patterns | Operational guidance and test setup already assume async webhook handling and projection persistence. [VERIFIED: codebase grep] |

**Key insight:** The hard part here is not raw HTTP integration; it is honest boundary-setting around provider-owned onboarding, payout execution, and public API semantics. [CITED: https://docs.hyperwallet.com/assets/docs/onboarding/client-requirements.pdf] [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Calling it "Connect parity" when the payout model is structurally different

**What goes wrong:** Planning assumes Stripe-like connected accounts, platform fees, and transfer semantics will map directly onto Braintree plus Hyperwallet. [VERIFIED: codebase grep]

**Why it happens:** `Accrue.Connect` is already rich on Stripe, which creates symmetry pressure, but the official provider docs describe separate pay-in, onboarding, and payout systems. [VERIFIED: codebase grep] [CITED: https://docs.hyperwallet.com/assets/docs/onboarding/client-requirements.pdf] [CITED: https://developer.paypal.com/docs/payouts/standard/login-with-payouts/]

**How to avoid:** Force the phase deliverable to list supported and unsupported semantics explicitly. [VERIFIED: codebase grep]

**Warning signs:** Language like "full parity," "same as Stripe," or "shared balance" appears without exclusions. [VERIFIED: 104-CONTEXT.md]

### Pitfall 2: Assuming Braintree recurring subscriptions can underwrite marketplace parity

**What goes wrong:** Planner scopes subscription-payin plus seller-payout flows as one integrated Braintree marketplace story. [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/]

**Why it happens:** Braintree still exposes marketplace/sub-merchant docs, but the recurring billing guide explicitly marks incompatibility. [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/] [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/sub-merchant-account/]

**How to avoid:** Treat buyer billing and seller payouts as separate provider truths from the start. [VERIFIED: 104-CONTEXT.md]

**Warning signs:** Plans reuse destination-charge or subscription language for payout features without naming Hyperwallet separately. [VERIFIED: codebase grep]

### Pitfall 3: Treating Hyperwallet enablement as "just another API"

**What goes wrong:** The plan ignores operational prerequisites until execution time. [CITED: https://docs.hyperwallet.com/assets/docs/onboarding/client-requirements.pdf]

**Why it happens:** The API surface looks tractable, but the official onboarding form requires admin users, webhook URLs, support contacts, and credential recipients. [CITED: https://docs.hyperwallet.com/assets/docs/onboarding/client-requirements.pdf]

**How to avoid:** Make commercial/ops enablement an explicit blocker in any future go plan. [CITED: https://docs.hyperwallet.com/assets/docs/onboarding/client-requirements.pdf]

**Warning signs:** A plan starts with schema or adapter work before proving sandbox/program availability. [CITED: https://docs.hyperwallet.com/assets/docs/onboarding/client-requirements.pdf]

### Pitfall 4: Letting decision docs drift from capability truth

**What goes wrong:** BT-09 is "satisfied" in a phase note, but package docs and support matrix still imply broader support. [VERIFIED: codebase grep]

**Why it happens:** The repo has multiple public truth surfaces. [VERIFIED: codebase grep]

**How to avoid:** Require doc tests or verifier needles for any public-facing outcome. [VERIFIED: codebase grep]

**Warning signs:** `104-RESEARCH.md` says no-go, but `Accrue.Connect` docs or support matrix still read as parity-ready. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from existing repo sources:

### Capability-Gated Public Support

```elixir
# Source: /Users/jon/projects/accrue/accrue/lib/accrue/processor/capabilities.ex
def first_party_supported?(capabilities, path)
    when is_map(capabilities) and is_list(path) do
  support_label(path) == "all first-party" and supports?(capabilities, path)
end
```

### Docs Contract Test Pattern

```elixir
# Source: /Users/jon/projects/accrue/accrue/test/accrue/docs/processor_support_matrix_test.exs
test "processor support matrix script passes" do
  root = repo_root()
  script = Path.join(root, "scripts/ci/verify_processor_support_matrix.sh")
  assert File.exists?(script)

  assert {output, 0} = System.cmd("bash", [script], cd: root, stderr_to_stdout: true)
  assert output =~ "verify_processor_support_matrix: OK"
end
```

### Official PayPal AAC Onboarding Shape

```javascript
// Source: https://developer.paypal.com/docs/payouts/standard/login-with-payouts/
paypal.PayoutsAAC.render({
  env: "<sandbox/production>",
  clientId: { production: "<production clientId>", sandbox: "<sandbox clientId>" },
  merchantId: "<Merchant Account ID>",
  pageType: "<signup/login>"
}, "#container");
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Treat multi-provider support as generic gateway parity | Treat support as explicit capability slices with honest exclusions | Accrue strategy locked this posture on 2026-04-29, and Phase 104 context tightens it further on 2026-05-02. [VERIFIED: codebase grep] | Planning should prefer a hard boundary over a broad abstraction. [VERIFIED: 104-CONTEXT.md] |
| Use Braintree recurring billing as the base for marketplace parity | Braintree docs say recurring billing is not compatible with Braintree Marketplace | Current official docs, viewed 2026-05-02. [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/] | Stripe-style `Accrue.Connect` money-flow helpers should be presumed out of scope for Braintree. [VERIFIED: codebase grep] |
| Treat payouts as a thin extension of pay-ins | Treat payouts as a separate provider program with separate onboarding and webhook setup | Current Hyperwallet and PayPal payout docs, viewed 2026-05-02. [CITED: https://docs.hyperwallet.com/assets/docs/onboarding/client-requirements.pdf] [CITED: https://developer.paypal.com/docs/payouts/standard/login-with-payouts/] | Any future go plan must include enablement and ops work, not just adapter code. [CITED: https://docs.hyperwallet.com/assets/docs/onboarding/client-requirements.pdf] |

**Deprecated/outdated:**

- "Near-Stripe parity" as the planning target for this phase is outdated by the locked phase decisions and contradicted by the provider split in current docs. [VERIFIED: 104-CONTEXT.md] [CITED: https://docs.hyperwallet.com/assets/docs/onboarding/client-requirements.pdf]

## Assumptions Log

All claims in this research were verified or cited in this session. No user confirmation is required for unstated assumptions.

## Open Questions (RESOLVED)

1. **Does BT-09 require only a phase-local decision artifact, or must public package docs and the processor-support matrix change in the same phase?**
   - What we know: the requirement says the final decision must be documented, and the repo already enforces public docs truth with tests/scripts. [VERIFIED: codebase grep]
   - Resolution: Phase 104 should update any public support-matrix/doc surface that would otherwise mislead adopters, so BT-09 is satisfied as repo truth rather than a phase-local note. [VERIFIED: codebase grep]

2. **If the outcome is go, is onboarding limited to existing merchant/payout accounts or expected to create new ones?**
   - What we know: Braintree Auth connect flow is closed beta, while Hyperwallet onboarding requires explicit program setup and contact exchange. [CITED: https://developer.paypal.com/braintree/docs/guides/braintree-auth/server-side/] [CITED: https://docs.hyperwallet.com/assets/docs/onboarding/client-requirements.pdf]
   - Resolution: Treat provider-program eligibility as a blocker for any future go implementation. Phase 104 should preserve only a narrow if-go contract and must not plan runtime work that assumes sandbox or production access already exists. [CITED: https://docs.hyperwallet.com/assets/docs/onboarding/client-requirements.pdf]

3. **Should a no-go decision also state the reopening condition?**
   - What we know: the locked phase context says reopening should require an explicit strategy change plus a new milestone. [VERIFIED: 104-CONTEXT.md]
   - Resolution: Yes. The final artifact should embed the reopening rule anywhere adopters or maintainers could otherwise misread the boundary as "maybe later," especially in public docs and strategy/support-matrix truth. [VERIFIED: 104-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Docs tests / verifiers | ✓ [VERIFIED: local command] | `1.19.5` [VERIFIED: local command] | - |
| Mix | Docs tests / verifiers | ✓ [VERIFIED: local command] | `1.19.5` [VERIFIED: local command] | - |
| Node.js | Optional docs/tooling scripts | ✓ [VERIFIED: local command] | `v22.14.0` [VERIFIED: local command] | - |
| Hyperwallet program access | Any future real integration | Unknown / unverified [CITED: https://docs.hyperwallet.com/assets/docs/onboarding/client-requirements.pdf] | - | Treat as blocker until commercially enabled. [CITED: https://docs.hyperwallet.com/assets/docs/onboarding/client-requirements.pdf] |

**Missing dependencies with no fallback:**

- None for Phase 104 itself; this phase can complete as research/docs work. [VERIFIED: codebase grep]

**Missing dependencies with fallback:**

- Real Hyperwallet sandbox/program access is not required for the decision artifact, but it would be required before any go implementation phase. [CITED: https://docs.hyperwallet.com/assets/docs/onboarding/client-requirements.pdf]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix aliases. [VERIFIED: codebase grep] |
| Config file | `accrue/test/test_helper.exs` plus `accrue/mix.exs` aliases. [VERIFIED: codebase grep] |
| Quick run command | `mix test test/accrue/docs/processor_support_matrix_test.exs -x` [VERIFIED: codebase grep] |
| Full suite command | `mix test.all` [VERIFIED: codebase grep] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BT-08 | Spike artifact captures official feasibility constraints and provider split. [CITED: https://docs.hyperwallet.com/assets/docs/onboarding/client-requirements.pdf] [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/] | docs contract | `mix test test/accrue/docs/connect_hyperwallet_decision_test.exs -x` | Created in Plan 01, Task 1 |
| BT-09 | Final go/no-go decision is mirrored in public docs/support matrix if the public contract changes. [VERIFIED: codebase grep] | docs contract | `mix test test/accrue/docs/connect_hyperwallet_decision_test.exs -x` and, if matrix touched, `mix test test/accrue/docs/processor_support_matrix_test.exs -x` | Created in Plan 01 / existing matrix test |

### Sampling Rate

- **Per task commit:** `mix test test/accrue/docs/connect_hyperwallet_decision_test.exs -x` once the new docs test exists. [VERIFIED: recommended from existing test pattern]
- **Per wave merge:** `mix test test/accrue/docs/processor_support_matrix_test.exs -x` when capability docs are touched. [VERIFIED: codebase grep]
- **Phase gate:** `mix test.all` before `/gsd-verify-work`. [VERIFIED: codebase grep]

### Wave 0 Gaps

- None. Existing ExUnit docs-test infrastructure already exists, and the only missing asset is the new `connect_hyperwallet_decision_test.exs` file created in Plan 01 before the guide-verification task runs. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [CITED: https://developer.paypal.com/docs/payouts/standard/login-with-payouts/] | Hosted onboarding must be tied back to the authenticated host actor, and provider identity results should be bound server-side. [CITED: https://developer.paypal.com/docs/payouts/standard/login-with-payouts/] |
| V3 Session Management | no [VERIFIED: phase scope] | Host app session rules remain existing project concerns; this phase is a decision artifact. [VERIFIED: phase scope] |
| V4 Access Control | yes [VERIFIED: codebase grep] | Keep provider account ownership explicit and fail unsupported flows loudly through existing capability boundaries. [VERIFIED: codebase grep] |
| V5 Input Validation | yes [VERIFIED: codebase grep] | Keep using `NimbleOptions`, typed errors, and explicit capability checks for any future Connect slice. [VERIFIED: codebase grep] |
| V6 Cryptography | yes [CITED: https://developer.paypal.com/braintree/docs/guides/braintree-auth/server-side/] [CITED: https://docs.hyperwallet.com/assets/docs/onboarding/client-requirements.pdf] | Use provider OAuth/state, webhook auth/signature verification, and secret storage; never hand-roll these controls. [CITED: https://developer.paypal.com/braintree/docs/guides/braintree-auth/server-side/] [CITED: https://docs.hyperwallet.com/assets/docs/onboarding/client-requirements.pdf] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Redirect-state tampering during hosted onboarding | Spoofing | Verify returned `state` values exactly as documented by Braintree OAuth/connect flows. [CITED: https://developer.paypal.com/braintree/docs/guides/braintree-auth/server-side/] |
| Fake or replayed payout-status webhooks | Tampering | Require authenticated webhook delivery and route it through Accrue's existing async ingest/persist/retry pattern. [CITED: https://docs.hyperwallet.com/assets/docs/onboarding/client-requirements.pdf] [VERIFIED: codebase grep] |
| Leakage of short-lived onboarding or dashboard URLs | Information Disclosure | Follow the existing `Accrue.Connect` pattern of redacting sensitive URLs in `Inspect` output and never logging bearer URLs. [VERIFIED: codebase grep] |
| Capability confusion leading to unauthorized or misleading operations | Elevation of Privilege | Keep provider ownership visible in docs/types/capability labels and reject unsupported operations early. [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)

- Local codebase grep and file reads - `104-CONTEXT.md`, `v1.33-REQUIREMENTS.md`, `STATE.md`, `STRATEGY.md`, `ROADMAP.md`, `accrue/lib/accrue/connect.ex`, `accrue/lib/accrue/processor/braintree.ex`, `accrue/lib/accrue/processor/capabilities.ex`, `accrue/guides/custom_processors.md`, `accrue/guides/operator-runbooks.md`, `accrue/test/accrue/docs/processor_support_matrix_test.exs`, `accrue/test/test_helper.exs`, `accrue/mix.exs`, `accrue_portal/mix.exs`. [VERIFIED: codebase grep]
- `mix hex.info braintree` - verified locked/current package version `0.16.0`. [VERIFIED: mix hex.info braintree]
- Braintree recurring billing overview - compatibility constraint with Marketplace. [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/]
- Braintree sub-merchant webhook reference - current marketplace webhook surface. [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/sub-merchant-account/]
- Braintree Auth server-side connect flow - closed-beta onboarding/OAuth flow and state requirements. [CITED: https://developer.paypal.com/braintree/docs/guides/braintree-auth/server-side/]
- Hyperwallet client requirements PDF - REST/webhook/drop-in recommendations and operational prerequisites. [CITED: https://docs.hyperwallet.com/assets/docs/onboarding/client-requirements.pdf]
- PayPal Log in with PayPal for Payouts - current AAC onboarding flow and payer-ID acquisition. [CITED: https://developer.paypal.com/docs/payouts/standard/login-with-payouts/]
- PayPal Payouts API integration guide - current payout API shape. [CITED: https://developer.paypal.com/docs/payouts/standard/integrate-api/]

### Secondary (MEDIUM confidence)

- PayPal Multiparty overview - current marketplace feature framing and partner-fee constraints. [CITED: https://developer.paypal.com/docs/multiparty/]

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - the phase should reuse existing repo stack, and the only external package claim (`:braintree` 0.16.0) was verified directly. [VERIFIED: mix hex.info braintree]
- Architecture: MEDIUM - the provider split is well evidenced, but any future go implementation still depends on commercial program access and exact scope choices. [CITED: https://docs.hyperwallet.com/assets/docs/onboarding/client-requirements.pdf]
- Pitfalls: HIGH - the main pitfalls are directly supported by locked phase constraints, current code shape, and current provider docs. [VERIFIED: codebase grep] [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/]

**Research date:** 2026-05-02
**Valid until:** 2026-05-09
