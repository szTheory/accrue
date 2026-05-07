# Phase 110: Lifecycle Semantics & Self-Serve Clarity - Research

**Researched:** 2026-05-06 [VERIFIED: local session date]
**Domain:** Subscription lifecycle semantics, provider-honest self-serve copy, and LiveView lifecycle presentation across `accrue`, `accrue_portal`, `accrue_admin`, and the example host. [VERIFIED: .planning/milestones/v1.35-phases/110-lifecycle-semantics-self-serve-clarity/110-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: repo-local code, docs, and targeted tests were inspected directly]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Canonical lifecycle documentation shape
- **D-01:** Publish one canonical lifecycle semantics guide organized by **action + state glossary**, not by provider-specific narratives and not API-reference-first.
- **D-02:** The canonical guide should define the meaning of each Accrue lifecycle action and state once, then attach provider labels such as:
  - `native`
  - `host-owned`
  - `unsupported`
  - `testing/local-only` where Fake behavior needs qualification
- **D-03:** Provider-specific guides, troubleshooting docs, and API docs should point back to this lifecycle guide rather than compete with it as alternate truth sources.
- **D-04:** API docs should stay precise, but they are secondary for lifecycle meaning. The conceptual lifecycle guide is the SSOT for mental model, operator meaning, and UI copy anchors.

### Cancellation posture
- **D-05:** For paid subscriptions, the default Accrue-owned lifecycle posture should be **turn off renewal now, keep access through the paid-through date**.
- **D-06:** Wherever Accrue owns customer or operator copy, prefer wording like:
  - `Cancel renewal`
  - `End at period end`
  - `Access continues until DATE`
  over ambiguous wording like `Cancel` when that could be read as immediate access termination.
- **D-07:** **Immediate cancellation** remains available as an explicit, exceptional path for support-led, compliance, fraud, or intentionally hard-stop flows. It should not be the primary recommended self-serve action.
- **D-08:** Do not promise identical gateway behavior behind this posture:
  - Stripe can support scheduled cancellation and reversal natively.
  - Braintree may require Accrue to express the product contract in local semantics instead of implying Stripe-shaped native reversibility.
- **D-09:** Never collapse these into one vague state in copy:
  - `active`
  - `scheduled to end` / `canceling`
  - `ended`

### Unsupported and divergent lifecycle semantics
- **D-10:** Use **explicit capability-driven messaging with next-step guidance** for divergent or unsupported lifecycle operations.
- **D-11:** Avoid abstract parity wording like `semantics vary by processor` when a more direct explanation is available.
- **D-12:** Errors, guide copy, and touched UI text should say what the processor can do, what Accrue owns locally, and what the operator or user should do next.
- **D-13:** When Braintree or another processor cannot support a lifecycle action the same way Stripe does, prefer wording like:
  - `Braintree does not support this Accrue pause/unpause semantic.`
  - `Create a new subscription after cancellation rather than implying reversible resume support.`
  over generic `unsupported` phrasing with no next step.
- **D-14:** Fake should be described honestly as the deterministic proof lane and local/testing semantics source, not as evidence that every provider has equivalent lifecycle affordances.

### Touched UI and copy scope
- **D-15:** Phase 110 should include **one focused lifecycle clarity improvement across touched surfaces**, not a broad visual redesign and not docs-only.
- **D-16:** The preferred improvement shape is a shared lifecycle summary/copy layer that:
  - names lifecycle states plainly
  - shows access-end timing explicitly
  - gives provider-aware action helper text where needed
  - avoids offering copy that implies unsupported Braintree semantics
- **D-17:** Favor shared copy and shared HEEx/component-level presentation over page-by-page bespoke wording.
- **D-18:** Good bounded targets include:
  - lifecycle status summary language
  - helper text under cancel/resume/pause actions
  - explicit `access ends on ...` copy
  - provider-aware follow-up guidance after lifecycle actions
- **D-19:** Do not widen this into general portal/admin theming, retention-product work, or broad UX experimentation.

### Status vocabulary and least-surprise UX
- **D-20:** Touched copy and docs should clearly distinguish at least these lifecycle states:
  - `active`
  - `canceling`
  - `paused`
  - `past_due`
  - `ended`
- **D-21:** The lifecycle glossary should be the source that UI and docs use for these labels so wording cannot drift independently across surfaces.
- **D-22:** Where webhook convergence lag can plausibly affect perception, copy may acknowledge local refresh/convergence rather than implying impossible instant global truth.

### Ecosystem and strategy lessons to preserve
- **D-23:** Learn from Stripe-hosted lifecycle ergonomics where they are strong, but do not project Stripe-only behavior onto Braintree.
- **D-24:** Learn from Pay and Cashier that bounded multi-provider support works when the shared surface is narrow, explicit, and honest about divergence.
- **D-25:** Continue avoiding the ActiveMerchant trap: do not smooth over structural provider differences into misleading facade sameness.

### GSD shift-left preference
- **D-26:** Reaffirm the user's standing preference for future discuss/planning passes in this track:
  - research deeply
  - synthesize one cohesive recommendation package
  - auto-resolve low-impact forks
  - only escalate materially high-impact product, support-contract, or long-term API decisions
- **D-27:** Current `.planning/config.json` already partially encodes this behavior. Future GSD passes should continue honoring it without reopening low-impact lifecycle wording or supportability forks by default.

### the agent's Discretion
- Exact filename and placement of the canonical lifecycle guide, as long as it becomes the single lifecycle SSOT and other touched docs point back to it.
- Exact component/copy implementation for the focused lifecycle clarity improvement, as long as it stays bounded and provider-honest.
- Exact phrasing for capability-driven helper text and typed error copy, as long as it states the processor truth and recommended next step clearly.

### Deferred Ideas (OUT OF SCOPE)
- Broad portal/admin redesign or heavy theming work
- New lifecycle primitives or widened processor capability promises
- Retention-product expansion, cancellation-reason productization, or generalized churn tooling
- Any attempt to erase structural Stripe/Braintree differences behind one misleading lifecycle abstraction
- GSD-wide workflow rewrites beyond the already-present config and the reinforced preference captured here
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LIF-01 | Accrue MUST publish one canonical lifecycle semantics guide that explains cancel, cancel-at-period-end, resume, pause/unpause, lifecycle status labels, and post-action convergence across Stripe, Fake, and Braintree with explicit native/host-owned/unsupported labeling. | Use existing core predicates and action APIs as the semantic source, add one guide under `accrue/guides/`, and convert `braintree-local-portal.md`, `portal_configuration_checklist.md`, and lifecycle-facing runtime copy to point back to that guide. [VERIFIED: accrue/lib/accrue/billing/subscription.ex, accrue/lib/accrue/billing/query.ex, accrue/lib/accrue/billing/subscription_actions.ex, accrue/guides/braintree-local-portal.md, accrue/guides/portal_configuration_checklist.md] |
| LIF-02 | Any Accrue-owned lifecycle copy or UI touched in this milestone MUST prefer least-surprise subscription behavior, clearly distinguish states like `active`, `canceling`, `paused`, `past_due`, and `ended`, and avoid implying Stripe-only semantics on Braintree. | Reuse the existing centralized copy seams in `accrue_portal` and `accrue_admin`, align the example host cancel copy, and add/assert status plus access-end wording in targeted LiveView tests. [VERIFIED: accrue_portal/lib/accrue_portal/copy.ex, accrue_admin/lib/accrue_admin/copy/subscription.ex, examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex, accrue_portal/test/accrue_portal/live/subscription_live_test.exs, accrue_portal/test/accrue_portal/live/subscriptions_live_test.exs, accrue_admin/test/accrue_admin/live/subscription_live_test.exs] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Keep the phase inside the existing Elixir/Phoenix/Ecto/PostgreSQL stack floor: Elixir `1.17+`, OTP `27+`, Phoenix `1.8+`, Ecto `3.12+`, PostgreSQL `14+`. [CITED: CLAUDE.md]
- Do not introduce a new processor story or broaden processor scope beyond the existing Stripe + Braintree track. [CITED: CLAUDE.md]
- Preserve the security posture: webhook signature verification remains mandatory, raw-body handling stays before parsers, sensitive Stripe fields never get logged, and payment-method details remain references rather than stored PII. [CITED: CLAUDE.md]
- Preserve the observability posture: public entry points should continue emitting telemetry and should not gain copy-only branches that hide operational state transitions. [CITED: CLAUDE.md]
- Respect the monorepo layout: `accrue/`, `accrue_portal/`, and `accrue_admin/` are sibling mix projects, so verification and copy changes must be package-local and co-updated. [CITED: CLAUDE.md]
- Execution should stay inside the active GSD phase workflow rather than ad-hoc edits. [CITED: CLAUDE.md]

## Summary

The semantic source of truth already exists in code, not in prose. `Accrue.Billing.Subscription` defines the real lifecycle predicates, `Accrue.Billing.Query` mirrors them for database reads, and `Accrue.Billing.SubscriptionActions` encodes the current action contract, including the split between immediate cancel, cancel-at-period-end, resume, pause, and unpause plus typed unsupported errors for Braintree. [VERIFIED: accrue/lib/accrue/billing/subscription.ex, accrue/lib/accrue/billing/query.ex, accrue/lib/accrue/billing/subscription_actions.ex]

The main drift is in docs and presentation. Stripe’s portal checklist already teaches the desired least-surprise posture of “end at period end and keep access” while the Braintree local-portal guide still teaches immediate cancellation as the self-serve example, and the touched UI surfaces still show raw status strings or ambiguous cancel labels instead of a shared glossary-backed lifecycle summary. [VERIFIED: accrue/guides/portal_configuration_checklist.md, accrue/guides/braintree-local-portal.md, accrue_portal/lib/accrue_portal/live/subscription_live.ex, accrue_portal/lib/accrue_portal/live/subscriptions_live.ex, accrue_admin/lib/accrue_admin/live/subscription_live.ex, examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex]

The bounded execution shape should therefore be: one canonical lifecycle guide, one shared lifecycle summary/copy pass across already-touched LiveView surfaces, and one proof pass that extends targeted tests and doc assertions without reopening processor capabilities or redesigning UI. That shape satisfies both `LIF-01` and `LIF-02` while preserving the locked provider-honest and least-surprise decisions. [VERIFIED: .planning/REQUIREMENTS.md, .planning/milestones/v1.35-phases/110-lifecycle-semantics-self-serve-clarity/110-CONTEXT.md]

**Primary recommendation:** Publish `accrue/guides/lifecycle_semantics.md`, make it the only lifecycle glossary SSOT, and drive one shared lifecycle-summary copy layer into portal/admin/example-host surfaces instead of editing each page independently. [VERIFIED: accrue/guides, accrue_portal/lib/accrue_portal/copy.ex, accrue_admin/lib/accrue_admin/copy/subscription.ex, examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Lifecycle meaning and action semantics | API / Backend | Database / Storage | The authoritative behavior already lives in `Subscription`, `Query`, and `SubscriptionActions`, and UI should mirror those semantics instead of inventing new ones. [VERIFIED: accrue/lib/accrue/billing/subscription.ex, accrue/lib/accrue/billing/query.ex, accrue/lib/accrue/billing/subscription_actions.ex] |
| Customer self-serve lifecycle wording | Frontend Server (SSR) | API / Backend | `accrue_portal` LiveViews render server-side copy and currently call billing actions directly, so least-surprise wording belongs in shared portal copy/presentation helpers backed by existing predicates. [VERIFIED: accrue_portal/lib/accrue_portal/copy.ex, accrue_portal/lib/accrue_portal/live/subscription_live.ex, accrue_portal/lib/accrue_portal/live/subscriptions_live.ex] |
| Admin/operator lifecycle wording and action affordances | Frontend Server (SSR) | API / Backend | `accrue_admin` already exposes lifecycle summaries, status filters, and action forms through LiveView, making it the right tier for provider-aware helper text and explicit state summaries. [VERIFIED: accrue_admin/lib/accrue_admin/live/subscriptions_live.ex, accrue_admin/lib/accrue_admin/live/subscription_live.ex] |
| Example-host lifecycle teaching | Frontend Server (SSR) | API / Backend | The example host is the proof and teaching surface for host-owned wording; its current cancel copy is independent and must be realigned to the same semantics. [VERIFIED: examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex, .planning/milestones/v1.35-phases/109-support-contract-truth/109-CONTEXT.md] |
| Post-action convergence explanation | API / Backend | Frontend Server (SSR) | Webhook/local projection is the runtime truth boundary, but surfaced copy may need to acknowledge convergence lag so users are not promised impossible instant global truth. [VERIFIED: accrue/guides/webhooks.md, accrue/guides/webhook_gotchas.md, .planning/milestones/v1.35-phases/110-lifecycle-semantics-self-serve-clarity/110-CONTEXT.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | `1.19.5` | Runtime for all touched packages | The workspace runtime is current and above the repo floor, and Phase 110 is entirely within existing Elixir code and docs. [VERIFIED: `elixir --version`, CLAUDE.md] |
| Phoenix | `1.8.5` | LiveView host framework for portal/admin/example-host surfaces | All touched UI surfaces are Phoenix LiveViews in the existing monorepo; no new presentation framework is warranted. [VERIFIED: accrue/mix.lock, accrue_portal/mix.lock, accrue_admin/mix.lock] |
| Phoenix LiveView | `1.1.28` | Server-rendered lifecycle copy and action surfaces | Portal, admin, and example-host lifecycle pages are LiveView-based already, so the clarity pass should reuse that seam rather than add client-side UI indirection. [VERIFIED: accrue/mix.lock, accrue_portal/mix.lock, accrue_admin/mix.lock, accrue_portal/lib/accrue_portal/live/subscription_live.ex, accrue_admin/lib/accrue_admin/live/subscription_live.ex] |
| Ecto | `3.13.5` | Lifecycle predicate/query backing and projection storage | The lifecycle truth depends on Ecto schemas and query fragments already in place, especially `canceling`, `paused`, `past_due`, and `canceled`. [VERIFIED: accrue/mix.lock, accrue/lib/accrue/billing/subscription.ex, accrue/lib/accrue/billing/query.ex] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Accrue.Billing.Subscription` | in-repo module | Canonical lifecycle predicates and glossary source | Use whenever a surface needs to decide whether a subscription is active, canceling, paused, past due, or ended; do not branch on raw `status`. [VERIFIED: accrue/lib/accrue/billing/subscription.ex, accrue/test/accrue/billing/subscription_predicates_test.exs] |
| `Accrue.Billing.Query` | in-repo module | Database-side equivalents of lifecycle predicates | Use for admin list filters, counters, and any page that needs lifecycle-safe query semantics. [VERIFIED: accrue/lib/accrue/billing/query.ex, accrue_admin/lib/accrue_admin/live/subscriptions_live.ex] |
| `Accrue.Billing.SubscriptionActions` | in-repo module | Canonical action semantics and typed unsupported errors | Use as the action contract source for docs and helper text, especially the Braintree unsupported/resume/pause guidance. [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex, accrue/test/accrue/billing/subscription_actions_test.exs] |
| `AccruePortal.Copy` and `AccrueAdmin.Copy.Subscription` | in-repo modules | Centralized copy seams | Use these instead of embedding bespoke strings in LiveViews during the clarity pass. [VERIFIED: accrue_portal/lib/accrue_portal/copy.ex, accrue_admin/lib/accrue_admin/copy/subscription.ex] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Reusing predicates and query helpers | Raw `status` checks in each surface | The repo already documents raw status branching as incorrect because `cancel_at_period_end` and `ended_at` change meaning without changing `status`. [VERIFIED: accrue/lib/accrue/billing/subscription.ex, accrue/lib/accrue/billing/query.ex] |
| Shared copy/presentation helpers on touched surfaces | Page-by-page string edits | Page-level edits would preserve drift and violate the locked preference for a shared lifecycle summary/copy layer. [VERIFIED: .planning/milestones/v1.35-phases/110-lifecycle-semantics-self-serve-clarity/110-CONTEXT.md, accrue_portal/lib/accrue_portal/copy.ex, accrue_admin/lib/accrue_admin/copy/subscription.ex] |
| Explicit provider-aware helper text | Generic “semantics vary by processor” wording | The context explicitly rejects vague parity language and the code already exposes precise unsupported semantics for Braintree. [VERIFIED: .planning/milestones/v1.35-phases/110-lifecycle-semantics-self-serve-clarity/110-CONTEXT.md, accrue/lib/accrue/billing/subscription_actions.ex] |

**Installation:** No new package installation is recommended for this phase because all necessary seams are already present in the monorepo. [VERIFIED: accrue/lib/accrue/billing/subscription.ex, accrue_portal/lib/accrue_portal/copy.ex, accrue_admin/lib/accrue_admin/copy/subscription.ex]

## Architecture Patterns

### System Architecture Diagram

```text
Billing action request
  -> LiveView surface (`accrue_portal` / `accrue_admin` / example host)
    -> shared lifecycle copy/presentation helper
      -> `Accrue.Billing.Subscription` predicates + `Accrue.Billing.Query`
        -> rendered status / access-end / helper text
    -> `Accrue.Billing.SubscriptionActions`
      -> provider capability / processor behavior
        -> local projection update + event
          -> webhook/local convergence messaging back to UI/docs

Canonical docs path
  -> `accrue/guides/lifecycle_semantics.md`
    -> linked from provider-specific guides and runtime-facing helper text
```

The current architecture already separates semantic truth, UI copy seams, and action execution; Phase 110 should connect them, not replace them. [VERIFIED: accrue/lib/accrue/billing/subscription.ex, accrue/lib/accrue/billing/subscription_actions.ex, accrue_portal/lib/accrue_portal/live/subscription_live.ex, accrue_admin/lib/accrue_admin/live/subscription_live.ex, accrue/guides/braintree-local-portal.md]

### Recommended Project Structure

```text
accrue/
├── guides/
│   ├── lifecycle_semantics.md          # New lifecycle glossary/action SSOT
│   ├── braintree-local-portal.md       # Links back to lifecycle SSOT
│   ├── portal_configuration_checklist.md
│   └── webhooks.md / webhook_gotchas.md
accrue_portal/lib/accrue_portal/
├── copy.ex                             # Shared customer-facing lifecycle strings
└── live/
    ├── subscription_live.ex            # Detail lifecycle summary/actions
    └── subscriptions_live.ex           # List lifecycle summary/actions
accrue_admin/lib/accrue_admin/
├── copy/subscription.ex                # Shared admin-facing lifecycle strings
└── live/
    ├── subscription_live.ex            # Admin detail helper text/actions
    └── subscriptions_live.ex           # Existing lifecycle list reference
examples/accrue_host/lib/accrue_host_web/live/
└── subscription_live.ex                # Host-facing lifecycle wording mirror
```

This shape keeps the new SSOT in `accrue/guides/`, uses existing copy seams, and confines UI work to already-touched lifecycle pages. [VERIFIED: accrue/guides, accrue_portal/lib/accrue_portal/copy.ex, accrue_admin/lib/accrue_admin/copy/subscription.ex, examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex]

### Pattern 1: Predicate-First Lifecycle Presentation

**What:** Build human-facing lifecycle labels and summaries from `Subscription` predicates and `Query` helpers rather than from raw `status`. [VERIFIED: accrue/lib/accrue/billing/subscription.ex, accrue/lib/accrue/billing/query.ex]

**When to use:** Any touched docs or LiveViews that need to distinguish `active`, `canceling`, `paused`, `past_due`, or `ended`. [VERIFIED: .planning/REQUIREMENTS.md, accrue_admin/lib/accrue_admin/live/subscriptions_live.ex]

**Example:**

```elixir
# Source: accrue_admin/lib/accrue_admin/live/subscription_live.ex
[
  Accrue.Billing.Subscription.active?(subscription) && "active",
  Accrue.Billing.Subscription.canceling?(subscription) && "canceling",
  Accrue.Billing.Subscription.paused?(subscription) && "paused",
  Accrue.Billing.Subscription.past_due?(subscription) && "past due",
  Accrue.Billing.Subscription.canceled?(subscription) && "canceled"
]
```

### Pattern 2: Provider-Honest Lifecycle Action Guidance

**What:** Keep one shared action vocabulary, but attach provider-specific helper text where support diverges. [VERIFIED: .planning/milestones/v1.35-phases/110-lifecycle-semantics-self-serve-clarity/110-CONTEXT.md, accrue/lib/accrue/billing/subscription_actions.ex]

**When to use:** Resume, pause, unpause, and cancel flows where Stripe and Braintree differ materially. [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex, accrue/test/accrue/billing/subscription_actions_test.exs]

**Example:**

```elixir
# Source: accrue/lib/accrue/billing/subscription_actions.ex
%Accrue.APIError{
  code: "processor_operation_unsupported",
  message:
    "Braintree subscriptions cannot be resumed through resume/2 because provider-side cancellations cannot be reactivated."
}
```

### Pattern 3: Docs-as-SSOT With Runtime Linkback

**What:** Put conceptual truth in one guide, then link to it from adjacent guides and runtime-facing errors instead of duplicating semantics in multiple places. [VERIFIED: .planning/milestones/v1.35-phases/110-lifecycle-semantics-self-serve-clarity/110-CONTEXT.md, accrue/test/accrue/billing/billing_portal_session_facade_test.exs]

**When to use:** Any lifecycle-facing guide touched in this milestone and any error/help copy that would otherwise explain provider divergence inline. [VERIFIED: accrue/guides/braintree-local-portal.md, accrue/guides/portal_configuration_checklist.md, accrue/test/accrue/billing/billing_portal_session_facade_test.exs]

**Example:**

```elixir
# Source: accrue/test/accrue/billing/billing_portal_session_facade_test.exs
assert err.message =~ "guides/braintree-local-portal.md"
```

### Anti-Patterns to Avoid

- **Raw status branching:** `status == :active` is not sufficient because `cancel_at_period_end` and `ended_at` change lifecycle meaning. [VERIFIED: accrue/lib/accrue/billing/subscription.ex]
- **Immediate-cancel-first self-serve examples:** This conflicts with the locked least-surprise posture and already disagrees with the Stripe portal checklist. [VERIFIED: accrue/guides/braintree-local-portal.md, accrue/guides/portal_configuration_checklist.md, .planning/milestones/v1.35-phases/110-lifecycle-semantics-self-serve-clarity/110-CONTEXT.md]
- **Generic unsupported wording:** The action layer already contains precise Braintree unsupported messages; flattening them to “not supported” would lose the required next-step guidance. [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex]
- **Broad UI redesign:** The requirement and context both restrict UI work to lifecycle clarity improvements only. [VERIFIED: .planning/REQUIREMENTS.md, .planning/milestones/v1.35-phases/110-lifecycle-semantics-self-serve-clarity/110-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Lifecycle status logic | New page-local condition trees | `Accrue.Billing.Subscription` predicates and `Accrue.Billing.Query` fragments | Those modules already capture the edge cases around `cancel_at_period_end`, `pause_collection`, `ended_at`, and dunning status. [VERIFIED: accrue/lib/accrue/billing/subscription.ex, accrue/lib/accrue/billing/query.ex] |
| Provider divergence messaging | Fresh ad-hoc Braintree wording per page | `SubscriptionActions` error semantics plus shared copy helpers | Braintree support truth is already typed in the action layer and tested explicitly. [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex, accrue/test/accrue/billing/subscription_actions_test.exs, accrue/test/accrue/processor/braintree_test.exs] |
| Lifecycle docs spread | Separate guide narratives that each redefine cancel/resume/pause | One lifecycle glossary guide with linkbacks | The phase context explicitly locks a single conceptual SSOT. [VERIFIED: .planning/milestones/v1.35-phases/110-lifecycle-semantics-self-serve-clarity/110-CONTEXT.md] |

**Key insight:** Phase 110 is a truth-alignment pass, not a capability pass, so the lowest-risk plan is to reuse the existing semantic code and narrow the work to docs plus copy/presentation seams. [VERIFIED: .planning/ROADMAP.md, .planning/REQUIREMENTS.md, accrue/lib/accrue/billing/subscription.ex]

## Common Pitfalls

### Pitfall 1: Treating `status` as the whole lifecycle

**What goes wrong:** A row with `status: :active` and `cancel_at_period_end: true` reads as simply “active” even though it is already scheduled to end. [VERIFIED: accrue/lib/accrue/billing/subscription.ex, accrue/test/accrue/billing/subscription_predicates_test.exs]
**Why it happens:** Raw `status` is easier to print than applying the canonical predicates. [VERIFIED: accrue/lib/accrue/billing/subscription.ex]
**How to avoid:** Base all touched copy and filters on `canceling?/1`, `paused?/1`, `past_due?/1`, and `canceled?/1`. [VERIFIED: accrue/lib/accrue/billing/subscription.ex, accrue/lib/accrue/billing/query.ex]
**Warning signs:** UI that shows only `@subscription.status`, or docs that talk about “cancel” without mentioning access timing. [VERIFIED: accrue_portal/lib/accrue_portal/live/subscription_live.ex, examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex]

### Pitfall 2: Projecting Stripe reversal semantics onto Braintree

**What goes wrong:** Docs or UI imply that Braintree supports scheduled cancellation reversal, pause, or unpause the same way Stripe does. [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex, accrue/test/accrue/billing/subscription_actions_test.exs]
**Why it happens:** The shared facade exposes common verbs, but the capability map and typed errors still diverge by provider. [VERIFIED: accrue/test/accrue/processor/capabilities_test.exs, accrue/test/accrue/processor/braintree_test.exs]
**How to avoid:** Attach provider-aware helper text and next-step guidance anywhere these verbs are documented or surfaced. [VERIFIED: .planning/milestones/v1.35-phases/110-lifecycle-semantics-self-serve-clarity/110-CONTEXT.md, accrue/lib/accrue/billing/subscription_actions.ex]
**Warning signs:** Copy that says only “Resume” or “Pause collection” with no processor qualification on Braintree-facing surfaces. [VERIFIED: accrue_admin/lib/accrue_admin/copy/subscription.ex, accrue_admin/lib/accrue_admin/live/subscription_live.ex]

### Pitfall 3: Keeping the current Braintree local-portal cancellation example

**What goes wrong:** The Braintree guide continues teaching immediate self-serve cancel as the default, which contradicts the locked least-surprise posture and the Stripe portal checklist. [VERIFIED: accrue/guides/braintree-local-portal.md, accrue/guides/portal_configuration_checklist.md]
**Why it happens:** The guide predates Phase 110’s clarified cancellation posture. [VERIFIED: .planning/milestones/v1.35-phases/110-lifecycle-semantics-self-serve-clarity/110-CONTEXT.md, accrue/guides/braintree-local-portal.md]
**How to avoid:** Replace that section with glossary-linked wording that explains the Braintree-local contract without implying reversible native semantics. [VERIFIED: .planning/milestones/v1.35-phases/110-lifecycle-semantics-self-serve-clarity/110-CONTEXT.md]
**Warning signs:** Examples centered on `Billing.cancel(subscription)` for customer self-serve flows. [VERIFIED: accrue/guides/braintree-local-portal.md]

### Pitfall 4: Leaving convergence invisible

**What goes wrong:** Users and operators are told the UI is instantly final when the actual state still depends on local projection and webhook convergence. [VERIFIED: accrue/guides/webhooks.md, accrue/guides/webhook_gotchas.md]
**Why it happens:** Copy tends to describe the happy path while the system architecture is webhook-backed and eventually convergent. [VERIFIED: accrue/guides/webhooks.md, accrue/guides/webhook_gotchas.md]
**How to avoid:** Keep success copy explicit but allow wording like local refresh/convergence where an action may not be globally settled yet. [VERIFIED: .planning/milestones/v1.35-phases/110-lifecycle-semantics-self-serve-clarity/110-CONTEXT.md]
**Warning signs:** Flash messages or guide text that describe irreversible finality for scheduled or webhook-backed state changes. [VERIFIED: accrue_portal/lib/accrue_portal/copy.ex, examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex]

## Code Examples

Verified patterns from repo sources:

### Canonical canceling predicate

```elixir
# Source: accrue/lib/accrue/billing/subscription.ex
def canceling?(%__MODULE__{
      status: :active,
      cancel_at_period_end: true,
      current_period_end: %DateTime{} = cpe
    }) do
  DateTime.compare(cpe, Accrue.Clock.utc_now()) == :gt
end
```

### Query-side canceling filter

```elixir
# Source: accrue/lib/accrue/billing/query.ex
from(s in query,
  where:
    s.status == :active and s.cancel_at_period_end == true and
      s.current_period_end > ^now
)
```

### Braintree unsupported resume guidance

```elixir
# Source: accrue/lib/accrue/billing/subscription_actions.ex
%Accrue.APIError{
  code: "processor_operation_unsupported",
  http_status: 422,
  message:
    "Braintree subscriptions cannot be resumed through resume/2 because provider-side cancellations cannot be reactivated."
}
```

### Existing portal least-surprise copy seam

```elixir
# Source: accrue_portal/lib/accrue_portal/copy.ex
def subscription_cancel_body,
  do: "Cancel at period end to keep access through the current billing period."
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Treat lifecycle meaning as provider-specific narrative scattered across guides and UIs | Use one shared lifecycle glossary, then annotate provider behavior as native, host-owned, unsupported, or testing/local-only | Required by Phase 110’s locked decisions gathered on 2026-05-06 | This prevents guide/UI drift without widening processor promises. [VERIFIED: .planning/milestones/v1.35-phases/110-lifecycle-semantics-self-serve-clarity/110-CONTEXT.md] |
| Self-serve cancel wording defaults to generic “cancel” | Self-serve wording should default to “cancel renewal / end at period end / access continues until DATE” | Required by Phase 110’s cancellation posture lock | This aligns customer expectation with the already-paid-through access window. [VERIFIED: .planning/milestones/v1.35-phases/110-lifecycle-semantics-self-serve-clarity/110-CONTEXT.md, accrue/guides/portal_configuration_checklist.md] |
| Braintree local-portal guide teaches immediate cancellation in its sample flow | The supported public story should describe Braintree honestly while still preferring least-surprise self-serve semantics and explicit next steps | Drift identified on the current branch | This is the highest-signal docs correction for `LIF-01`. [VERIFIED: accrue/guides/braintree-local-portal.md, .planning/REQUIREMENTS.md] |

**Deprecated/outdated:**

- The “Offer immediate cancellations using Accrue’s cancel functions” section in `braintree-local-portal.md` is outdated for Phase 110’s self-serve posture even though immediate cancel still exists as an operator path. [VERIFIED: accrue/guides/braintree-local-portal.md, .planning/milestones/v1.35-phases/110-lifecycle-semantics-self-serve-clarity/110-CONTEXT.md]
- Raw status display in touched portal/example-host surfaces is insufficient because it hides `canceling` and `ended` semantics. [VERIFIED: accrue_portal/lib/accrue_portal/live/subscription_live.ex, examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex, accrue/lib/accrue/billing/subscription.ex]

## Execution Shape

1. **Slice A: Canonical lifecycle SSOT guide.** Add `accrue/guides/lifecycle_semantics.md`, structure it as action glossary plus state glossary, and link to it from `braintree-local-portal.md`, `portal_configuration_checklist.md`, and any touched webhook/lifecycle docs rather than duplicating meaning. [VERIFIED: .planning/milestones/v1.35-phases/110-lifecycle-semantics-self-serve-clarity/110-CONTEXT.md, accrue/guides/braintree-local-portal.md, accrue/guides/portal_configuration_checklist.md, accrue/guides/webhooks.md, accrue/guides/webhook_gotchas.md]
2. **Slice B: Shared lifecycle summary/copy pass.** Introduce one small shared lifecycle presentation helper per touched UI package, or one core-backed helper consumed by those packages if the planner finds that lower-risk, then route portal detail/list, admin detail, and example-host cancellation/status wording through it. Do not broaden into theming or unrelated views. [VERIFIED: accrue_portal/lib/accrue_portal/copy.ex, accrue_portal/lib/accrue_portal/live/subscription_live.ex, accrue_portal/lib/accrue_portal/live/subscriptions_live.ex, accrue_admin/lib/accrue_admin/copy/subscription.ex, accrue_admin/lib/accrue_admin/live/subscription_live.ex, examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex]
3. **Slice C: Proof and drift gates.** Extend targeted ExUnit coverage to assert glossary labels, access-end copy, and provider-aware helper text on touched surfaces, and add one docs assertion for the new guide plus linkbacks from adjacent guides. [VERIFIED: accrue/test/accrue/billing_portal_test.exs, accrue_portal/test/accrue_portal/live/subscription_live_test.exs, accrue_portal/test/accrue_portal/live/subscriptions_live_test.exs, accrue_admin/test/accrue_admin/live/subscription_live_test.exs, examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs]

## Open Questions (RESOLVED)

1. **Should the shared lifecycle presenter live in core or stay package-local?**
   - What we know: The semantic source belongs in core, but the existing copy seams are package-local and already thin. [VERIFIED: accrue/lib/accrue/billing/subscription.ex, accrue_portal/lib/accrue_portal/copy.ex, accrue_admin/lib/accrue_admin/copy/subscription.ex]
   - What's unclear: Whether a cross-package presenter reduces drift more than it increases coupling across sibling apps. [VERIFIED: repo structure and touched files]
   - RESOLVED: Keep semantics in core and keep presentation helpers package-local for Phase 110. This preserves the existing sibling-package boundaries, uses the already-thin copy seams, and avoids introducing a new cross-package dependency surface just to solve wording drift. If later phases still see duplication after the glossary is stable, a tiny shared presenter can be reconsidered with concrete evidence. [VERIFIED: .planning/milestones/v1.35-phases/110-lifecycle-semantics-self-serve-clarity/110-CONTEXT.md, accrue_portal/lib/accrue_portal/copy.ex, accrue_admin/lib/accrue_admin/copy/subscription.ex, repo package layout]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | All package-local verification lanes | ✓ | `1.19.5` | — [VERIFIED: `elixir --version`] |
| OTP | All package-local verification lanes | ✓ | `28` | — [VERIFIED: `elixir --version`] |
| Mix | Running targeted ExUnit suites | ✓ | `1.19.5` | — [VERIFIED: `mix --version`] |
| `accrue` package deps | Core lifecycle proof lane | ✓ | lockfile-resolved | — [VERIFIED: `mix test` in `accrue`] |
| `accrue_admin` package deps | Admin lifecycle proof lane | ✓ | lockfile-resolved | — [VERIFIED: `mix test` in `accrue_admin`] |
| `accrue_portal` package deps | Portal lifecycle proof lane | ✗ | missing `rendro` in current test env | Run `mix deps.get` in `accrue_portal` before the portal lane. [VERIFIED: `mix test` in `accrue_portal`] |

**Missing dependencies with no fallback:**

- None for planning; the only current execution blocker is the missing `rendro` dependency in the `accrue_portal` test environment. [VERIFIED: `mix test` in `accrue_portal`]

**Missing dependencies with fallback:**

- The portal verification lane can be restored by fetching package dependencies before running the targeted tests. [VERIFIED: `mix test` in `accrue_portal`]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit across sibling mix projects. [VERIFIED: accrue/test/test_helper.exs, accrue_portal/test/test_helper.exs, accrue_admin/test/test_helper.exs] |
| Config file | `test/test_helper.exs` per package. [VERIFIED: accrue/test/test_helper.exs, accrue_portal/test/test_helper.exs, accrue_admin/test/test_helper.exs] |
| Quick run command | `cd accrue && mix test test/accrue/billing/subscription_cancel_test.exs test/accrue/billing/subscription_predicates_test.exs test/accrue/billing/subscription_actions_test.exs && cd ../accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/live/subscriptions_live_test.exs` [VERIFIED: local test runs on 2026-05-06] |
| Full suite command | Run `mix test` in `accrue`, `accrue_portal`, and `accrue_admin` after restoring missing portal deps. [VERIFIED: accrue/mix.exs, accrue_portal/mix.exs, accrue_admin/mix.exs, local test runs on 2026-05-06] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LIF-01 | Canonical lifecycle predicates and action semantics remain the source truth for cancel, cancel-at-period-end, resume, pause, unpause, and unsupported Braintree behavior. | unit/integration | `cd accrue && mix test test/accrue/billing/subscription_cancel_test.exs test/accrue/billing/subscription_predicates_test.exs test/accrue/billing/subscription_actions_test.exs` | ✅ [VERIFIED: local run passed in `accrue`] |
| LIF-01 | Adjacent docs link back to the lifecycle SSOT and do not drift on cancellation posture. | unit/doc | Add a guide-content assertion beside the existing portal checklist doc test. [VERIFIED: accrue/test/accrue/billing_portal_test.exs] | ❌ Wave 0 |
| LIF-02 | Portal detail/list surfaces render least-surprise cancellation behavior and stay customer-scoped. | live/integration | `cd accrue_portal && mix test test/accrue_portal/live/subscription_live_test.exs test/accrue_portal/live/subscriptions_live_test.exs` | ✅ but currently blocked by missing deps [VERIFIED: files exist; local run blocked in `accrue_portal`] |
| LIF-02 | Admin detail/list surfaces preserve lifecycle-safe summaries and action semantics. | live/integration | `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/live/subscriptions_live_test.exs` | ✅ [VERIFIED: local run passed in `accrue_admin`] |
| LIF-02 | Example-host wording mirrors the clarified lifecycle contract. | live/integration | Extend `cd examples/accrue_host && mix test test/accrue_host_web/live/subscription_live_test.exs` with lifecycle copy assertions. [VERIFIED: examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs] | ✅ but coverage gap |

### Sampling Rate

- **Per task commit:** Run the package-local targeted suite for the package touched by that commit. [VERIFIED: repo has package-local test entrypoints and local targeted runs]
- **Per wave merge:** Re-run the core + admin targeted lifecycle suites and the portal suite once `accrue_portal` deps are restored. [VERIFIED: local test runs and portal blocker]
- **Phase gate:** All lifecycle-targeted suites plus the new doc assertion must pass before `/gsd-verify-work`. [VERIFIED: .planning/config.json sets `workflow.nyquist_validation` to true]

### Wave 0 Gaps

- [ ] Add a new doc assertion for the lifecycle SSOT guide and linkbacks; current doc coverage only checks the Stripe portal checklist. [VERIFIED: accrue/test/accrue/billing_portal_test.exs]
- [ ] Extend portal LiveView tests to assert status/access-end/helper text, not just scoped cancel behavior. [VERIFIED: accrue_portal/test/accrue_portal/live/subscription_live_test.exs, accrue_portal/test/accrue_portal/live/subscriptions_live_test.exs]
- [ ] Extend the example-host LiveView test to cover cancellation wording; current host test coverage does not assert the lifecycle cancel posture at all. [VERIFIED: examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs]
- [ ] Restore `accrue_portal` test dependencies before running the portal lane. [VERIFIED: local `mix test` failure in `accrue_portal`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Keep host/portal/admin auth boundaries unchanged; Phase 110 should not widen access for lifecycle actions. [VERIFIED: accrue_portal/lib/accrue_portal/live/subscription_live.ex, accrue_admin/lib/accrue_admin/live/subscription_live.ex, examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex] |
| V3 Session Management | yes | Preserve existing Plug and LiveView session continuity, especially for mounted portal flows. [VERIFIED: accrue/guides/braintree-local-portal.md, CLAUDE.md] |
| V4 Access Control | yes | Reuse current scoped subscription loading and owner-scope guards in portal/admin/example-host surfaces. [VERIFIED: accrue_portal/test/accrue_portal/live/subscription_live_test.exs, accrue_portal/test/accrue_portal/live/subscriptions_live_test.exs, accrue_admin/test/accrue_admin/live/subscription_live_test.exs] |
| V5 Input Validation | yes | Keep lifecycle action inputs flowing through current validated action APIs and typed errors rather than new unchecked params. [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex] |
| V6 Cryptography | no | Phase 110 does not introduce new cryptographic behavior. [VERIFIED: touched scope is docs/copy/lifecycle presentation] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-customer subscription action leakage | Elevation of privilege | Preserve current scoped loaders and customer/owner-scoped tests on portal/admin surfaces. [VERIFIED: accrue_portal/test/accrue_portal/live/subscription_live_test.exs, accrue_portal/test/accrue_portal/live/subscriptions_live_test.exs, accrue_admin/test/accrue_admin/live/subscription_live_test.exs] |
| Misleading lifecycle copy causing unintended destructive actions | Tampering / Repudiation | Make self-serve wording explicit about renewal timing and access end dates; keep immediate cancel exceptional. [VERIFIED: .planning/milestones/v1.35-phases/110-lifecycle-semantics-self-serve-clarity/110-CONTEXT.md, accrue/guides/portal_configuration_checklist.md] |
| Unsupported-operation ambiguity leading to unsafe operator workarounds | Tampering | Preserve typed `processor_operation_unsupported` errors with next-step guidance. [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex, accrue/test/accrue/billing/subscription_actions_test.exs] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|

All claims in this research were verified or cited from repo-local evidence — no user confirmation is needed before planning. [VERIFIED: research inputs in this session]

## Sources

### Primary (HIGH confidence)

- `.planning/milestones/v1.35-phases/110-lifecycle-semantics-self-serve-clarity/110-CONTEXT.md` - locked Phase 110 scope, decisions, and canonical refs. [VERIFIED: file read]
- `.planning/REQUIREMENTS.md` - `LIF-01` and `LIF-02` requirement text. [VERIFIED: file read]
- `.planning/ROADMAP.md`, `.planning/PROJECT.md`, `.planning/STRATEGY.md`, `.planning/processor-support-matrix.md`, `.planning/STATE.md` - active milestone boundary and provider-honest support posture. [VERIFIED: file read]
- `.planning/milestones/v1.35-phases/109-support-contract-truth/109-CONTEXT.md`, `.planning/milestones/v1.31-phases/094-strategy-capability-matrix-target-lock/094-CONTEXT.md`, `.planning/milestones/v1.31-phases/095-official-processor-contract-conformance-harness/095-CONTEXT.md`, `.planning/milestones/v1.31-phases/096-chosen-second-provider-thin-slice/96-CONTEXT.md` - locked prior provider-honest and Fake-first decisions. [VERIFIED: file read]
- `accrue/lib/accrue/billing/subscription.ex`, `accrue/lib/accrue/billing/query.ex`, `accrue/lib/accrue/billing/subscription_actions.ex` - actual lifecycle semantics and provider divergence. [VERIFIED: file read]
- `accrue_portal/lib/accrue_portal/copy.ex`, `accrue_portal/lib/accrue_portal/live/subscription_live.ex`, `accrue_portal/lib/accrue_portal/live/subscriptions_live.ex` - customer lifecycle copy and action surfaces. [VERIFIED: file read]
- `accrue_admin/lib/accrue_admin/copy/subscription.ex`, `accrue_admin/lib/accrue_admin/live/subscription_live.ex`, `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` - admin lifecycle summary and action surfaces. [VERIFIED: file read]
- `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` - example-host lifecycle wording. [VERIFIED: file read]
- `accrue/guides/braintree-local-portal.md`, `accrue/guides/portal_configuration_checklist.md`, `accrue/guides/webhooks.md`, `accrue/guides/webhook_gotchas.md` - current docs truth and drift points. [VERIFIED: file read]
- `accrue/test/accrue/billing/subscription_cancel_test.exs`, `accrue/test/accrue/billing/subscription_predicates_test.exs`, `accrue/test/accrue/billing/subscription_actions_test.exs`, `accrue/test/accrue/processor/capabilities_test.exs`, `accrue/test/accrue/processor/braintree_test.exs`, `accrue/test/accrue/billing_portal_test.exs`, `accrue_portal/test/accrue_portal/live/subscription_live_test.exs`, `accrue_portal/test/accrue_portal/live/subscriptions_live_test.exs`, `accrue_admin/test/accrue_admin/live/subscription_live_test.exs`, `accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs`, `examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs` - current proof anchors and gaps. [VERIFIED: file read]
- Local verification runs on 2026-05-06 - `accrue` targeted lifecycle suite passed, `accrue_admin` targeted lifecycle suite passed, and `accrue_portal` targeted lifecycle suite is currently blocked by missing `rendro` deps. [VERIFIED: local `mix test` runs]

### Secondary (MEDIUM confidence)

- None. All substantive claims above were drawn directly from repo-local artifacts. [VERIFIED: research inputs in this session]

### Tertiary (LOW confidence)

- None. [VERIFIED: research inputs in this session]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - the phase stays inside the already-installed Elixir/Phoenix/Ecto stack and needs no new dependencies. [VERIFIED: CLAUDE.md, mix.lock files, local runtime checks]
- Architecture: HIGH - the lifecycle truth, copy seams, and action surfaces are all explicit in the current codebase. [VERIFIED: core modules and LiveView files inspected]
- Pitfalls: HIGH - the key drift points are directly visible in code/docs/tests and partially confirmed by targeted test runs. [VERIFIED: inspected files and local `mix test` runs]

**Research date:** 2026-05-06 [VERIFIED: local session date]
**Valid until:** 2026-06-05 for planning purposes, unless Phase 110 scope or lifecycle runtime semantics change before execution. [VERIFIED: stable brownfield scope in current milestone artifacts]
