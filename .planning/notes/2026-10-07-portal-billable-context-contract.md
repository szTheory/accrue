---
date: "2026-10-07 09:23"
promoted: false
---

# Portal billing context: personal, company and mixed hosts

Status: researched approach accepted by the owner for the proposed UI refinement milestone, 2026-10-07. Supersedes the personal-versus-workspace question in the earlier scope brief. Exact API signatures remain implementation choices. No implementation or runtime verification is claimed.

## Recommendation

**Support personal, organizational and custom billables through one reusable customer Portal.** Preserve a simple personal-billing default. Add a small optional host integration adapter that resolves the billed entity and authorizes each action. Hosts that support both personal and company billing use the same Portal with different authorized contexts.

Admin and Portal identify different audiences and authority. Personal and company billing identify different owners of a bill. They are independent choices:

| Person using the UI | Billed entity | Interface |
| --- | --- | --- |
| Individual customer | Their User or personal Account | Customer Portal |
| Company employee allowed to manage billing | Their Organization, Team or BillingAccount | Customer Portal |
| Person who has a personal subscription and belongs to several companies | One explicitly selected, authorized billable at a time | The same customer Portal |
| Vendor support engineer or billing operator | Customers within the operator's authorized scope | Accrue Admin |

A customer's company billing administrator does not thereby become an Accrue Admin operator. An organization is not necessarily the application's tenant or workspace: one host billing account could pay for several workspaces. The host maps its domain to the billable record. Accrue should not impose that mapping.

This recommendation requires no new tenancy tables, organization membership product, universal roles, mandatory account picker, duplicated Portal or dependency. It does require a real, bounded Portal integration change, beyond CSS and copy.

## Current implementation and why it needs this change

Source review across architecture, authorization and product/UX found:

- `Accrue.Billable` supports arbitrary host schemas. `Customer` already identifies the owner by **owner_type + owner_id + processor**. The canonical example has both User and Organization billables. Personal billing is a valid use case, not an inferior migration step toward organizations.
- Portal's `CustomerSession` currently calls `Billing.customer(current_user)`. It couples the authenticated actor to the owner of billing. That restricts the UI more than the underlying library.
- Extra `on_mount` hooks run before Portal's default resolver, which assigns the customer again. POST controllers resolve independently. Overriding an assign in a host hook cannot provide a consistent solution.
- `Accrue.Auth` provides authentication, Admin admission, audit identity and optional step-up integration. It has no general `can?` or action authorization callback. Company billing policy needs an explicit Portal contract.
- Existing Portal queries and payment/subscription/checkout guards scope resources to a Customer. Preserve these protections alongside host authorization.
- Core `Billing.customer/1` and the example host's `find_customer/1` omit processor from their current lookup, while Portal's no-create POST lookup includes it. With multiple historical provider rows for the same billable, these paths can disagree. Correct the bounded lookup inconsistency; do not introduce per-request provider routing. Current processor dispatch is configuration-based.
- The example's Organization billing links sometimes enter the User-bound Portal. This is an integration mismatch, not evidence that either ownership model should be removed.

These findings follow from source. No browser flow, gateway call, production data condition or cross-account incident was reproduced during this research.

## Small integration contract

Recommend **one optional Portal access adapter with two responsibilities**. Exact names and signatures are implementation choices, not a proposed new API that already exists.

1. **Resolve:** given the authenticated actor and host selection context, return an actual billable record and minimal display/navigation metadata, or a classified error. Resolve without performing provider writes. Hosts explicitly map their own selection references to records; user-supplied owner-type strings must not trigger arbitrary module/atom/schema lookup.
2. **Authorize:** decide whether the actor may perform a named action on that billable and a server-loaded target, with normalized action intent. Examples include viewing invoices, adding/removing a payment method, changing to a particular plan, canceling with the applicable timing, completing checkout, or issuing a hosted billing session.

The library then materializes/validates the exact Customer, scopes every target to it, checks supported processor/resource behavior and invokes existing core billing operations. Authorization errors and unknown actions fail closed. A custom resolver must not silently inherit unrestricted personal permissions if it omits an authorizer.

| Concept | Owner and meaning |
| --- | --- |
| Authenticated actor | Existing host authentication; normally the signed-in person. Used for current permissions and action attribution. The actor need not be Billable. |
| Billable entity | Host-selected User, Account, Organization, Team, Project or another supported schema. Stable owner type and lossless owner ID distinguish it. |
| Accrue Customer | Library billing identity for the billable and supported configured processor; owns local subscription/invoice/method records. |
| Processor / connected account | Existing configuration and host-verified provider context. A company ID is not a Stripe connected-account ID. |
| Requested action and target | Server-loaded record plus normalized intent, such as target plan and cancellation mode. Neither a URL ID nor a prior preview grants permission. |
| Display name and return/switch links | Host presentation inputs, rendered safely and validated as destinations; never authority. |

**Default compatibility:** with no new adapter, retain the current authenticated-person billable behavior, routes, login return and supported operations. Existing simple installations should not need to learn a new context module. Keep `Auth.current_user` unchanged; making it return an Organization would corrupt shared actor semantics.

**Custom integration:** support organization-only and mixed hosts through the same adapter/UI. Do not require Sigra, Phoenix's generated Scope shape, a particular membership schema or multiple Portal mounts. The current router's fixed pipeline/live-session names do not establish multi-mount support; duplicating mounts is unnecessary for this design.

Use a small transport-neutral context envelope so the same contract works on initial HTTP request, connected LiveView, subsequent events and controller POST. Host code supplies only required selection data through the existing session/routing boundary. Do not rely on receiving a Plug.Conn during WebSocket events or serialize whole user/membership structs into forms.

## Permission and lifecycle rules

### Resolve and authorize before provisioning

First authenticate the actor, resolve the selected billable and authorize the relevant read. Only then look up the exact owner/provider Customer. `Billing.customer/1` can create remote/local state, so it must not run for a denied or invalid company selection.

Preserve legacy personal lazy creation as a tested compatibility path. For custom contexts, make provisioning deliberate: an invoice viewer does not automatically receive authority to create a billing customer. An authorized billable with no Customer is an empty/unprovisioned state; an unauthorized billable is a denial; an unavailable resolver/provider is an availability error.

With a custom adapter, genuinely absent selection follows host policy. An explicit invalid, deleted or unauthorized selection must never fall back to personal billing, the first organization, another Customer or global operator scope.

### Authorize the intended context at every action

**A form may act only on the billing account it displayed.** Pin the intended billable/customer/processor context, and freshly authenticate and authorize that same target before an operation. A signed reference prevents tampering; it is not a durable permission grant.

This is especially important for add-card POST, which has no existing subscription or method ID to anchor it. Selecting company B in another tab must not make a form opened for company A save a payment method to B. Preview/confirmation state must similarly remain bound to the original subscription, plan and account.

Recommended default is independent, clearly labelled Portal flows/tabs with fresh permission checks. If a host requires one global active-workspace policy, a mismatch rejects the stale form and requires deliberate reselection. Either policy is acceptable; silent retargeting is not. An explicit account switch starts a fresh context and clears pending confirmations/previews/card acquisition as appropriate. A mount-time LiveView session snapshot does not automatically observe changed browser cookies.

Apply the same guards to disconnected/connected mount, protected reads/navigation, reconnect, LiveView events and all POST routes. Re-fetch membership and target state before mutation. A cached `can_manage` flag can help render controls but cannot authorize an operation. Permission to preview is not permission to commit later.

Host authorization, customer ownership, current resource state and processor capability must all agree. A company finance role can be allowed to replace a card while forbidden to cancel a subscription. Library roles such as owner/admin/member must not be hardcoded; the example can keep its existing host policy.

The host remains responsible for its programmatic Billing calls. The Portal adapter governs Portal entry points; it does not turn core Billing into a universal authenticated policy engine.

### Hosted sessions are grants of capability

A read-only customer may be allowed to inspect invoices without being allowed to obtain a provider-hosted URL that enables canceling or changing a plan. Authorize session creation for its actual customer and server-selected features/configuration. If the provider cannot represent the permitted subset, do not issue a broader session.

Keep checkout initiation/completion separately authorized. A local checkout token identifies a persisted target, not a login or membership grant. Its stored Customer/provider remain fixed. The host may resolve an authorized target from that server-loaded checkout even when another context was last selected, provided the page clearly names the billed entity; otherwise require an explicit selection step.

Braintree's current local Portal handoff is a shared mount URL and does not identify the requested Customer. Preserve intended context through the host entry/binding and reauthorize it on arrival. Adding an arbitrary customer ID to the URL is not sufficient.

Validate return destinations, keep secrets/bearer URLs/nonces out of context logs and screenshots, and read actual server evidence after provider return. A success query parameter cannot establish payment. Authorization when issuing a hosted session cannot promise immediate revocation of that already-issued upstream session.

### Keep the actual person in audit history

Use the existing `Auth.actor_id` and restoring `Actor.with_actor` mechanism around authorized operations. A company action should identify the human actor and the company's billing resource, not substitute the company ID for the person. An HTTP process dictionary does not automatically carry into LiveView or asynchronous work.

Existing Events can record actor and subject relationships; they do not automatically merge a new Portal context map. `Auth.log_audit` may be a no-op. Do not claim durable audit evidence merely because an assign or callback exists. Verify the actual emitted event for changed Portal operations, preserve operation/causation IDs and secret redaction, and leave downstream webhook/system attribution truthful. No second audit framework is needed.

Fresh permission checks reduce stale authority, but do not make a membership change and remote payment atomic. Preserve existing idempotency and transaction conventions; do not add long database locks around provider calls or promise instantaneous cross-system revocation. Stronger ordering can remain a host-specific policy requirement.

## Customer experience and example coverage

| Host use case | Portal behavior |
| --- | --- |
| Personal-only SaaS | “Billing” or “Your billing”; no company vocabulary, role badges or account picker. No synthetic personal organization. |
| Company-only SaaS | “Billing for [company]”; host determines viewing and each management permission. Company billing managers remain customer-side users. |
| Mixed personal + multiple companies | Host selector or entry links choose one authorized entity; Portal clearly names it and keeps records, cards, confirmations and return context separate. |
| Custom Account/Team/Project billable | Same integration without hardcoded Organization schema or labels. The host maps service usage to the responsible billing entity. |
| Existing delegated client management | A host-authorized delegate can act for one client billable. This does not imply consolidated agency invoices, shared cards, parent-payer settlement or customer impersonation features. |

Account discovery and selection remain host-owned. Reuse the host's existing switcher; Portal can show its current billing identity and an optional “Switch billing account” link. A universal in-package picker is unnecessary for the milestone. Include display metadata for clear labels, including duplicate/long names, but never use display text for authorization.

The canonical example should demonstrate both personal and organization billing through the same package, plus a mixed fixture with two organizations and different permissions. It may keep workspace billing as its main application journey. This demo emphasis must not become a library constraint. Keep the vendor's branding separate from the billed entity's name, and keep operator Admin navigation out of normal customer tasks.

Do not introduce operator impersonation to make demos easier. Any future staff “view as customer” action needs an explicit authorized and attributed mechanism. Ordinary Portal context selection grants no operator bypass.

## Alternatives considered

| Alternative | Tradeoff and decision |
| --- | --- |
| Personal-only Portal | Smallest current implementation, but excludes ordinary B2B adoption despite core polymorphism. Retain as default behavior, not the limit. |
| Separate personal/company Portal implementations | Duplicates UI, state, security and fixes; custom billables still need further variants. Use one implementation. |
| Organization or personal-team model required for everyone | Fits some scaffolds but imposes extra records and vocabulary on personal-only products. Avoid as a library requirement. |
| Host builds all non-personal billing UI | Flexible, but forfeits reusable self-service for a common use case. Keep customization possible without requiring it. |
| Override current_user or current_customer through mount hooks | Conflates actor and billed party or misses POST/action authorization. Reject as the supported integration path. |
| Host returns only Customer ID / read-manage flags | Small interface, but hides owner/provider validation and action-specific intent; stale flags can grant too much. Use billable resolution plus fresh per-action policy. |
| Optional resolver + action authorizer | Small public integration contract, reuses current UI/core and supports both models. Recommended; no new runtime dependency. |
| Universal tenancy, account picker or per-request processor routing | Substantially broader than the demonstrated integration need. Defer until separately required. |

## Milestone implications and bounded proof

Replace the pending either/or decision with this generic contract. Settle it in the first milestone phase and implement/prove it before calling host-to-Portal checkout/self-service complete. This is the only new Portal integration boundary needed for the ownership problem. Keep the seven proposed outcome phases; do not create another design or authorization platform project.

Use existing ExUnit/LiveView/controller/provider-contract suites and a few host browser transitions. Proposed acceptance, not executed results:

1. No-adapter personal install retains routes, customer identity, cold start and allowed operations.
2. Non-billable actor can act for an authorized custom billable; a person can separately enter their own bill and two companies' bills through one Portal.
3. Same owner ID with different owner types and one owner with two provider Customer rows remain distinct; configured-processor selection agrees across create/no-create/GET/POST.
4. Read-only and action-limited roles get appropriate UI and direct forged event/POST denial; no denied provider call or mutation occurs.
5. Invalid/deleted/foreign selection never falls back or provisions a Customer. Authorized unprovisioned context remains distinct.
6. Membership/session revocation after render blocks later protected action/reconnect; cached permission or preview cannot grant execution.
7. Cross-tab and account-switch tests prove add-card and plan-confirm forms never retarget another Customer. Expired auth never auto-replays a payment.
8. Foreign subscription/card/checkout IDs fail customer ownership checks even when the host allows the operation in principle.
9. Hosted-session features match permission; Braintree local handoff preserves target; checkout token/return query alone never authorizes or proves payment.
10. Core events identify the actual actor and correct subject; restoring context helpers clean up on success and exceptions, with secrets excluded.
11. Representative personal/company captures prove appropriate labels and account context. Reuse the full route inventory; do not multiply every screenshot by every role and account type.

Update adopter documentation and installer/examples together: personal default, organization/custom adapter, mixed selection, action-policy checks, provisioning behavior and stable context. Describe personal and company ownership as equally supported integration patterns once implementation passes its proof. Until then, distinguish this target from the current user-bound Portal.

No owner choice between these use cases is needed. Exact callback names, context representation, finite action names and existing Phoenix binding mechanism are delegated implementation decisions. Consolidated payers, new role-management features, anonymous token login, new billing semantics and simultaneous dynamic processor routing remain separately scoped capabilities.

## Primary precedents and source evidence

These sources inform the recommendation without implying identical APIs or adding dependencies:

- [Pay Rails Customer model](https://github.com/pay-rails/pay/blob/main/app/models/pay/customer.rb) associates a customer with a polymorphic owner: a useful precedent for separating billing ownership from a fixed authenticated-user model.
- [Laravel Cashier billable model](https://laravel.com/framework/docs/13.x/billing#billable-model) allows a configured billable model beyond the usual User. This supports host ownership choice; that documentation alone does not prove simultaneous mixed-model support.
- [Laravel Jetstream teams](https://jetstream.laravel.com/features/teams.html) demonstrates host current-team and permission concepts. Its personal-team convention belongs to that scaffold and need not be imposed on Accrue.
- [Stripe Portal sessions](https://docs.stripe.com/api/customer_portal/sessions/create) target a Customer and configuration/return destination. [Stripe integration guidance](https://docs.stripe.com/customer-management/integrate-customer-portal) supports authenticating before issuance. Connected-account options are not human membership policy.
- [Phoenix LiveView security](https://phoenix-live-view.hexdocs.pm/security-model.html) supports authorization across HTTP and LiveView/action boundaries. Use APIs available in the installed version.
- [OWASP authorization guidance](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html) supports default denial, repeated enforcement and policy tests. The proposed pinned-context design is our application of these principles.

Local evidence: `accrue/lib/accrue/{billable,auth,billing,processor,actor,events}.ex`; `billing/customer.ex`; checkout local session and Braintree provider handoffs; Portal `customer_session`, `auth_hook`, `auth_plug`, `authorize`, read model, router, LiveViews and controllers; canonical host User/Organization/Scope, Billing facade, Auth/UserAuth and organization-scope controller. Key anchors: `customer.ex:47,96`, `billing.ex:778,811`, `customer_session.ex:15,34`, `router.ex:173`, `auth_hook.ex:37`, host `billing.ex:93,166,193,207`.

The three specialist reviews converged on the same approach and supplied architectural counterexamples, permission/selection failure cases and ecosystem comparisons. Findings were reconciled before this note was saved. Research was read-only; no tests, application builds, source implementation or runtime captures were performed.
