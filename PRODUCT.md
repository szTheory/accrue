# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

- **Elixir, Ecto, and Phoenix developers** adopt Accrue to add billing to an existing application. They integrate the library, configure processors and webhooks, connect application policy, and maintain that integration over time.
- **Engineers and support/billing operators are equal primary users of Accrue Admin.** They investigate customer billing, understand subscriptions and invoices, handle payment and recovery work, and inspect events and webhook failures. The interface must support operators who do not know Accrue's internal modules while retaining useful diagnostic detail for engineers.
- **Customers of the host application** use customer billing and Portal flows to subscribe, review invoices, and manage supported subscription and payment-method actions. They may act for themselves or, when authorized by the host, for a company, team, or another billed account. A customer's company billing manager remains a Portal user; vendor staff use Accrue Admin under a separate operator permission boundary.

## Product Purpose

Accrue gives Elixir applications a reusable billing engine and practical interfaces for operating it. It brings subscriptions, invoices, payments, recovery, entitlements, and billing history into the application's own domain without requiring each host team to build that machinery again.

Success means a developer can integrate a working billing loop, an operator can understand a customer's current billing state and take an appropriate action, and a customer can complete the supported self-service task. The result and its limitations must be understandable afterward.

## Positioning

Accrue is an open-source Elixir billing library for Phoenix applications. Its distinguishing mechanism is a durable local billing model: processor responses and verified webhooks become local Ecto projections and auditable events, consumed through a host-owned billing facade and the companion interfaces.

Stripe or Braintree remains authoritative for the money movement it processes. Accrue's local model supports application reads, billing operations, and access decisions while preserving the boundary between a local observation and a confirmed remote outcome. Accrue is integrated into a host application; it is not a separately hosted billing service.

## Operating Context

- The monorepo contains `accrue` for billing semantics, `accrue_admin` for operator interfaces, and `accrue_portal` for customer self-service. The `web` platform describes the browser interfaces and documentation; the core product is an Elixir library.
- Host applications own their Repo, migrations, Oban supervision, authentication, sessions, application membership and authorization policy, routing, and runtime secrets. Generated host code becomes host-owned after installation.
- Billing ownership is a host-domain choice. Core Billable models can represent a person, organization, or other account; the authenticated actor and the entity paying are separate concepts. The Portal product direction is one reusable interface for personal, organization/custom, and mixed hosts, with host-owned account selection and per-action permissions. Simple personal use should require no organization model or account picker.
- Developers begin with the host billing facade and signed-webhook path, then mount the operator or customer interfaces as needed. Mount paths are host-configurable.
- Operator work connects customer and subscription investigation, invoice and payment handling, overdue-payment recovery, and event/webhook diagnosis. Preserve the relevant customer, organization, object, and filter context when moving between those tasks.
- Admin and Portal use the core billing semantics rather than creating separate implementations of billing rules. Operator access does not imply access for a customer session, and customer-side billing management does not imply operator access. Billing context must stay explicit through checkout, confirmations, account changes, and return to the host application.
- `examples/accrue_host` is the canonical local evaluation host. Its fictional Cadence application and Fake processor provide realistic, repeatable billing scenarios without live payment credentials. The mounted operator entry is `/admin`; the example also exposes customer billing paths.

## Capabilities and Constraints

- Existing capabilities include customer and subscription lifecycle operations, invoices, charges and payment methods, coupons and promotion codes, recovery workflows, entitlements, connected-account surfaces, and billing event/webhook inspection. Availability of an operation depends on the supported processor and host configuration.
- Provider differences must remain explicit. Stripe's checkout and billing portal use upstream hosted URLs; Braintree uses supported mounted first-party checkout and Portal flows. Fake provides deterministic evaluation and test behavior. Consult `.planning/processor-support-matrix.md` and the relevant package guides before claiming parity or enabling an action.
- Webhook signatures, idempotency, asynchronous processing, and event ordering are part of the billing contract. An accepted request, queued job, received webhook, updated local projection, and completed processor action are different outcomes.
- Missing, stale, or unavailable evidence must not be presented as a confirmed success or failure. In particular, incomplete local information alone does not prove that a customer's billing is inactive.
- Preserve authorization, tenant scope, action eligibility, and required confirmation or step-up checks. The interface must make the affected object, action, and consequence clear, including distinctions such as immediate cancellation versus cancellation at period end.
- Host authorization, exact customer/resource ownership, and supported provider behavior all constrain an action. An old form must not silently act on a different billed account after a context switch. A read-only customer must not receive a broader provider-hosted management grant merely because they may view local billing information.
- Keep domain language consistent across UI, documentation, and public APIs. Customers, subscriptions, invoices, payments/charges, entitlements, webhook deliveries, and audit events have distinct meanings. Use understandable operator language while retaining exact identifiers and technical evidence where they support investigation.
- Production operator copy is host-visible. `accrue_admin/lib/accrue_admin/copy.ex` and its related modules hold shared language; locked legal and replay wording has an existing contract. Improving wording must preserve its factual meaning, action scope, and safety requirements.
- Accrue follows a stable-core, demand-driven expansion posture. Refining an existing interface does not itself approve new billing capabilities or expand the advertised support boundary.

## Brand Commitments

The product is **Accrue**, with the tagline **“Billing state, modeled clearly.”** Existing identity assets live under `brandbook/`, including `brandbook/logo/`. The ratified identity record is `.planning/milestones/v1.52-phases/180-brand-audit-dna-lock/BRAND-DNA.md`; this product record does not replace it.

The established voice is measured, exact, native, and durable. Use direct, calm language, concrete domain nouns, and actions that describe their outcome. Avoid hype, filler, invented claims, and internal implementation narration in routine operator tasks. `brandbook/voice.md` supplies the existing voice guidance; technical detail should be appropriate to the audience and task.

## Evidence on Hand

- `accrue/guides/architecture.md`, `accrue/guides/first_hour.md`, the package READMEs, and the processor support matrix document the integration and ownership boundaries.
- `examples/accrue_host` supplies a fictional application, seeded customer states, mounted interfaces, and browser workflows. These are demonstrations, not customer testimonials or external adoption evidence.
- `accrue_admin` contains shared components, Storybook/component examples, state fixtures, LiveView and browser tests, and saved screenshots. Existing screenshots and archived verification records describe their captured source and scenarios; they do not automatically establish the current interface's appearance or usability.
- The repository contains billing, webhook, provider, accessibility, and interaction checks. Claims about production readiness or provider behavior must stay within the evidence actually exercised. Do not invent usage figures, customer endorsements, performance results, or compliance claims.
- Core supports polymorphic billing ownership, but the current mounted Portal resolves billing from the authenticated user. The proposed optional billable-resolution/action-authorization contract is documented in `.planning/notes/2026-10-07-portal-billable-context-contract.md`; it is a refinement target, not a claim of implemented mixed-account Portal support.

## Product Principles

1. **Fit the host application.** Keep ownership explicit and let adopters retain their application policy and customer relationships.
2. **Make billing state understandable.** Connect the affected object, observed state, appropriate next action, and resulting evidence without obscuring uncertainty.
3. **Serve routine work and deeper investigation together.** Keep common tasks discoverable and preserve precise diagnostic information for operators who need it.
4. **Reduce surprise and inconsistency.** Use familiar interaction conventions and coherent domain language; each refinement should strengthen the shared system.
5. **Reduce operator effort without hiding consequences.** Automate supported work where useful, retain necessary human decisions, and make action outcomes truthful and inspectable.

## Accessibility & Inclusion

WCAG AA is the existing accessibility target, not a claim that every current surface has been freshly certified. Operator and customer workflows should remain usable with keyboard navigation, assistive technology, touch, and narrow viewports. Maintain visible focus, meaningful names and labels, understandable errors, and status information that does not depend on color alone. Honor reduced-motion preferences and keep essential information available without hover or animation.
