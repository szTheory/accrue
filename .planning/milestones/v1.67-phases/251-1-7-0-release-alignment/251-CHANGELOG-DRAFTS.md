# Phase 251: curated 1.7.0 drafts (UNVERIFIED planning input)

Copied verbatim from the 251-RESEARCH session scratch drafts (Appendix A). They passed `verify_release_notes_contract.sh`, `verify_release_manifest_alignment.sh` and `verify_package_docs.sh` on a scratch export, but every claim is derived from commit subjects and diff stats. Plan 251-05 must verify each bullet against code or tests before it is pushed, keep the release-please heading line (compare URL and date) of the live release commit instead of the heading shown here, and record a claim-to-evidence table in 251-05-SUMMARY.md. This file is a planning input; it is never copied wholesale.

## Draft: core CHANGELOG `## [1.7.0]` section

````markdown
## [1.7.0](https://github.com/szTheory/accrue/compare/accrue-v1.6.0...accrue-v1.7.0) (2026-10-26)

### Release highlights

* Checkout is steadier under retries, double submits and provider returns: hosted checkout returns are reconciled against authoritative provider state, selected-checkout retries stay stable, eligibility and promotions are decided in one place, and Braintree declines keep their decline outcome.
* Webhook replay is safer: a replay is claimed atomically so two operators cannot dispatch the same delivery, and bulk replay revalidates owner scope inside the same step.
* Payment-method and subscription actions are gated on what the active processor (Fake, Stripe or Braintree) will currently honor.
* Manual invoice items are validated when the action is dispatched, not only when the form is rendered.
* Recovery analytics report evidence-based amounts and keep their scope when you navigate.
* `config :accrue, :admin_branding` accepts `theme: :system | :light | :dark`; `:light` or `:dark` locks the mounted Admin UI to that theme and hides the picker.
* The generated billing context from `mix accrue.install` includes a self-only default for the optional Portal policy hooks `portal_organization_for/2` and `authorize_portal_action/5`; organization-billing hosts replace them with their own membership policy.

### Known issues

* `accrue_events.inserted_at` is stored as `timestamp without time zone` with `DEFAULT now()`, so it follows the database session time zone. On a non-UTC database, UTC-windowed event queries can select the wrong rows. A fix is planned for the next release and needs a migration.
````

## Draft: admin CHANGELOG `## [1.7.0]` section

````markdown
## [1.7.0](https://github.com/szTheory/accrue/compare/accrue_admin-v1.6.0...accrue_admin-v1.7.0) (2026-10-26)

### Notes

* Compatibility only: the linked 1.7.0 release asks nothing further of the core `accrue` billing contracts beyond the entries in its own changelog. The core `accrue` package owns billing capability; this package owns only its existing UI surface, refined as listed below.

### Release highlights

* Journeys keep their place: customer, subscription, invoice, payment, coupon, promotion code, Connect, webhook and recovery pages preserve the list, filters and owner scope you came from, and return links name and validate their destination.
* Actions recheck before they run: subscription, invoice, refund, payment-method and webhook-replay reviews revalidate eligibility and ownership after step-up, and an outcome the provider has not confirmed is shown as unconfirmed.
* Lists read faster: labeled filters with removable chips, bounded global search with matching pointer and keyboard selection, quieter copyable record IDs, resource-specific counts, and infinite lists that keep every loaded row and say when the list ends.
* One time convention: the Local or UTC preference is shared across pages, and clicking a timestamp copies its exact UTC value with a confirmation that names what was copied.
* Events and webhooks are easier to investigate: readable event labels, exact scoped links to event detail, clearer replay acceptance and read-recovery states, and raw payloads that wrap on narrow screens.
* Accessibility and small screens: 320px reflow fixes for the top bar and webhook detail header, a shared keyboard focus ring on quiet table links, and larger touch targets.
* The Admin theme can be locked from host config with the core `:admin_branding` `theme` option.
````

## Draft: portal CHANGELOG `## [1.7.0]` section

````markdown
## [1.7.0](https://github.com/szTheory/accrue/compare/accrue_portal-v1.6.0...accrue_portal-v1.7.0) (2026-10-26)

### Notes

* Compatibility only: the linked 1.7.0 release asks nothing further of the core `accrue` billing contracts beyond the entries in its own changelog. The core `accrue` package owns billing capability; this package owns only its existing self-service surface, refined as listed below.

### Release highlights

* Personal, organization and mixed billing contexts are resolved through your host policy and rechecked on every action; a signed context pin locates the account but never expands what an actor may do.
* Adding, defaulting and deleting payment methods, changing or cancelling subscriptions, and completing checkout are each authorized against the pinned context, and a denied or revoked context blocks safely.
* Checkout is more dependable: Braintree Hosted Fields submit to the server, POST completion is guarded, expired checkouts offer a validated recovery action, return destinations are validated, and decline outcomes are preserved.
* Hosted invoices open within the billable's scope, and an unavailable read is distinguished from an empty one.
* Host branding carries through: Hosted Fields colors follow the Portal theme, and status and accent colors are consistent.
````

## Draft: accrue/guides/release-notes.md `### 1.7.0` under `## accrue`

````markdown
### 1.7.0

**Admin and Portal refinement, steadier checkout, and safer webhook replay.**

`1.7.0` is mostly about the screens your operators and customers use. `accrue_admin` and `accrue_portal` carry most of the visible change: journeys that keep list and owner context, actions that recheck eligibility before they run, one Local/UTC time convention, and per-action authorization in the Portal. The core `accrue` package adds steadier checkout handling (authoritative return reconciliation, stable retries, preserved declines), atomic webhook replay claims, dispatch-time validation of manual invoice items, an `:admin_branding` `theme` option, and a self-only default for the optional Portal policy hooks in the generated billing context.

Known issue: `accrue_events.inserted_at` follows the database session time zone, so UTC-windowed event queries can be wrong on a non-UTC database. It is tracked for the next release.

````

## Draft: accrue/guides/release-notes.md `### 1.7.0` under `## accrue_admin`

````markdown
### 1.7.0

Matches **accrue 1.7.0** and carries most of its operator-facing change. Billing journeys keep your place and owner scope, actions revalidate before dispatch, lists and search are quieter and more consistent, and timestamps follow one Local/UTC convention with exact-value copy. `accrue_portal` 1.7.0 refines the customer self-service surface the same way: per-action authorization against a pinned billing context, steadier checkout, and scoped hosted invoices. Neither package changes how core decides entitlements or grants.

````
