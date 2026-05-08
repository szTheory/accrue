# Changelog

## Unreleased

**1.0.0 — Stable.** This release commits Accrue to v1.x API stability for the documented integration surface: generated `MyApp.Billing`, `use Accrue.Webhook.Handler`, `use Accrue.Test`, `Accrue.Auth`, and `Accrue.ConfigError`. Breaking changes on that surface go through deprecation, not silent reshuffles. Internal schemas, workers, and demo helpers are not part of the contract. See `accrue/README.md` Stability, `accrue/guides/upgrade.md`, `accrue/guides/maturity-and-maintenance.md`, and root `RELEASING.md` for the v1.x stability commitment and post-1.0 cadence.

Observability and integrator docs for **Stripe Checkout** on `Accrue.Billing` ship together: grep **`guides/telemetry.md#billing-checkout-session-create`**, re-run **`bash scripts/ci/verify_package_docs.sh`** / **`bash scripts/ci/verify_adoption_proof_matrix.sh`**, and keep **First Hour** + **`examples/accrue_host`** observability copy aligned with **`checkout_session_facade_test.exs`**.

### Billing

* Add `Accrue.Billing.create_checkout_session/2` and `create_checkout_session!/2`, delegating to `Accrue.Checkout.Session` under `[:accrue, :billing, :checkout_session, :create]` with allowlisted span metadata (no checkout URL, `client_secret`, or raw attrs); see `guides/telemetry.md#billing-checkout-session-create` and `test/accrue/billing/checkout_session_facade_test.exs`.
* Add `Accrue.Billing.create_billing_portal_session/2` and `create_billing_portal_session!/2`, delegating to `Accrue.BillingPortal.Session` with `[:accrue, :billing, :billing_portal, :create]` telemetry; see `guides/telemetry.md`.
* Add `Accrue.Billing.list_payment_methods/2` and `list_payment_methods!/2` for processor-backed payment method listing (with optional validated list filters); installer `billing.ex.eex` delegates the same surface for host facades.

### Telemetry

* **`meter_reporting_failed` metadata `source`:** rename `:inline` to `:sync` for synchronous `report_usage/3` failures so the closed set is `:sync | :reconciler | :webhook` everywhere (code, docs, default metrics). Update host dashboards or attach handlers that matched on `:inline`.

### Documentation

* **INT-13:** extend **First Hour**, **`examples/accrue_host/README.md`**, and **`examples/accrue_host/docs/adoption-proof-matrix.md`** with **`Accrue.Billing.create_billing_portal_session/2`**, **`[:accrue, :billing, :billing_portal, :create]`**, anchor **`guides/telemetry.md#billing-billing-portal-create`**, and **`billing_portal_session_facade_test.exs`** — Customer Portal facade parity alongside checkout in the integrator spine.
* Align **First Hour**, **`examples/accrue_host/README.md`**, **`examples/accrue_host/docs/adoption-proof-matrix.md`**, **`guides/telemetry.md`**, and **`guides/operator-runbooks.md`** with **`Accrue.Billing.create_checkout_session/2`** and the **`[:accrue, :billing, :checkout_session, :create]`** span (anchor **`#billing-checkout-session-create`**); operator Stripe triage stays pointer-depth only (no Checkout error matrix).
* Harden the telemetry guide ops catalog (evergreen heading, Primary owner column, Hex vs `main` doc contract), correct OpenTelemetry examples (including meter reporting + ops failure cross-link), add an ops event contract test, and emit `[:accrue, :ops, :webhook_dlq, :dead_lettered]` when webhook dispatch exhausts retries.

### CI

* Extend **`verify_package_docs.sh`** and **`verify_adoption_proof_matrix.sh`** merge-blocking needles for **billing portal** facade literals (**`create_billing_portal_session/2`**, **`[:accrue, :billing, :billing_portal, :create]`**, **`billing-billing-portal-create`** / **`billing_portal_session_facade_test.exs`**) alongside checkout.
* Extend **`verify_package_docs.sh`** and **`verify_adoption_proof_matrix.sh`** merge-blocking needles for checkout facade + billing-span literals co-evolving with golden-path docs.

## [1.1.1](https://github.com/szTheory/accrue/compare/accrue-v1.1.0...accrue-v1.1.1) (2026-05-08)


### Miscellaneous Chores

* **accrue:** Synchronize accrue-monorepo versions

## [1.1.0](https://github.com/szTheory/accrue/compare/accrue-v1.0.0...accrue-v1.1.0) (2026-05-08)


### Features

* **098-01:** implement payment method CRUD for braintree ([717e7d7](https://github.com/szTheory/accrue/commit/717e7d7178e9d835195aef9881ba3ea67a45ac8f))
* **099-01:** implement canonical refund facade and Braintree callbacks ([9f3d081](https://github.com/szTheory/accrue/commit/9f3d08126c0a2fc6c991c9f96db599c6e9b29fb2))
* **099-02:** implement braintree refund convergence and narrow proration support ([b1df372](https://github.com/szTheory/accrue/commit/b1df372f2ddba3d111b98ec6750747a25a1295f3))
* **100-01:** disable braintree portal capability ([47e8ce3](https://github.com/szTheory/accrue/commit/47e8ce34d24b6feefaa940533c186dc86c0506d9))
* **100-01:** fail cleanly in billing facade on unsupported gateways ([10410e2](https://github.com/szTheory/accrue/commit/10410e2b5c5b2a1006bfe2813b939aba3d171e21))
* **101-01:** lock local checkout session contract ([e3fc56a](https://github.com/szTheory/accrue/commit/e3fc56ab0cbc336445de19b6fc1e4ef55bf2319a))
* **101-03:** align braintree local portal adapter contract ([b6791f9](https://github.com/szTheory/accrue/commit/b6791f98bc228afb2ce55c5cb91823b7d5c71dda))
* **101-08:** wire portal checkout completion pipeline ([ce86b7b](https://github.com/szTheory/accrue/commit/ce86b7bb9352baf48a6fb79dd13da990cf01e450))
* **102-01:** add local discount mapping domain ([a64d25c](https://github.com/szTheory/accrue/commit/a64d25c08a933595a9861ce75d6a5888294d8ac7))
* **102-02:** emit discount mapping drift telemetry ([125151a](https://github.com/szTheory/accrue/commit/125151a60a0a06d2ec158f12e5c941a60f028208))
* **102-02:** enforce braintree discount mappings in subscribe ([a74e931](https://github.com/szTheory/accrue/commit/a74e931ed2101a76eb0262f19babae063a587462))
* **103-01:** add metering definition and renewal contracts ([c80a83c](https://github.com/szTheory/accrue/commit/c80a83c9fa1ab95187a26afc81303b1b9e698d60))
* **103-02:** implement metered renewal invoice authoring ([bc77e2d](https://github.com/szTheory/accrue/commit/bc77e2d9f94eb2db65d0292e7a4d83011ef5acc4))
* **103-03:** implement metered renewal settlement ([6c668b1](https://github.com/szTheory/accrue/commit/6c668b10ed43bf05e0c84dca585a48c7fe98dda1))
* **103-04:** implement metered renewal backstop telemetry ([aabda22](https://github.com/szTheory/accrue/commit/aabda22831bfd5ecfb8c1618dd3b11f2f74d0ba8))
* **112-01:** promote bounded customer update contract ([1b4f623](https://github.com/szTheory/accrue/commit/1b4f62352b4dd61d2cddcd6aff7c9eb4cf0ed4ca))
* **112-02:** promote customer update support truth ([12ae9ac](https://github.com/szTheory/accrue/commit/12ae9ac4fbabafe66970caaa1f095d9606806bd1))
* **112-03:** add host customer update helper ([a64b259](https://github.com/szTheory/accrue/commit/a64b259efa1f469f564f77b49d1bac80703576f3))
* **113-01:** promote immediate cancellation support truth ([1c55f1e](https://github.com/szTheory/accrue/commit/1c55f1ef48ebe74a48e2342a2aef62c896290578))
* **118-01:** promote quantity and item support contract ([3cb03fc](https://github.com/szTheory/accrue/commit/3cb03fc02f184dcc931705eada906ed8cc40b71b))
* **118-03:** add thin host plan change seam ([3e84edd](https://github.com/szTheory/accrue/commit/3e84edd765c82e7ff5215ab5ac0cc72d9a958f06))
* **119:** close subscription change support contract ([03e6c9b](https://github.com/szTheory/accrue/commit/03e6c9b9ae2520f9566fba43e3adb3b9513bdf8a))
* **94-01:** lock processor support posture ([5cedca6](https://github.com/szTheory/accrue/commit/5cedca6741180ce9a4b8b3e0c38e2e29d5f8a1ca))
* **96-01:** branch subscribe/3 for braintree at processor seam ([85e44f6](https://github.com/szTheory/accrue/commit/85e44f687b952a1b8b50aee60b7f85c62132e459))
* **processor:** harden phase 95 support contract ([1ca55ec](https://github.com/szTheory/accrue/commit/1ca55ecffacf811e584b9f8ce583ae9a4fa3e9b6))


### Bug Fixes

* **092-01:** keep package changelogs at package root ([ee8792f](https://github.com/szTheory/accrue/commit/ee8792ff7632252958ae2fee82aa8ba2faeff38c))
* **098:** close review findings and normalize locks ([e277987](https://github.com/szTheory/accrue/commit/e2779872e11443bf1036c92904159cd66c18dc3a))
* **098:** support braintree host customer flow ([7b8275d](https://github.com/szTheory/accrue/commit/7b8275d9789e8267008e05958b7c77579238e1ca))
* **102:** compensate reserved mappings on gateway failure ([e34c795](https://github.com/szTheory/accrue/commit/e34c795f611db52ff7f0bc1a3de81d66048d510a))
* **102:** release reservations on pre-gateway failures ([a6fbee7](https://github.com/szTheory/accrue/commit/a6fbee75f283ca5a8f8249a7c4a475831a940f42))
* **102:** reserve discount mappings before braintree create ([22db22c](https://github.com/szTheory/accrue/commit/22db22c76f5b46d277185b4ce29a70a1ba9bd825))
* **112-02:** lock customer update proof bundle ([29528fa](https://github.com/szTheory/accrue/commit/29528fa292707e3d2710f03bfab60135524d0279))
* **112:** preserve metadata merge semantics ([63fa708](https://github.com/szTheory/accrue/commit/63fa708cb65ee63e74dd1dc7619c61cf511e392d))
* **113-01:** lock cancellation semantics behind facade and adapter proof ([fca2dff](https://github.com/szTheory/accrue/commit/fca2dffdf1677a6e87e509856b15d7f1061bb56e))

## [0.3.1](https://github.com/szTheory/accrue/compare/accrue-v0.3.0...accrue-v0.3.1) (2026-04-22)

### Miscellaneous Chores

* **accrue:** Synchronize accrue-monorepo versions

## [0.3.0](https://github.com/szTheory/accrue/compare/accrue-v0.2.0...accrue-v0.3.0) (2026-04-20)

### Bug Fixes

* **ci:** keep package `mix.exs` `@version` aligned with published Hex ([13bfece](https://github.com/szTheory/accrue/commit/13bfece3a7325ace974bc119b3699321781e9d51))
* **ci:** restore accrue and accrue_admin `mix.exs` `@version` to 0.2.0 ([2d15aa8](https://github.com/szTheory/accrue/commit/2d15aa84641da2bdd947b8ba1b1b59ef32c3c792))
* **monorepo:** align accrue 0.3.0 with accrue_admin for CI lockstep ([017b38b](https://github.com/szTheory/accrue/commit/017b38bf73b7725b5da6fb6b26cebc8c2a3a7d6a))

## [0.2.0](https://github.com/szTheory/accrue/compare/accrue-v0.1.2...accrue-v0.2.0) (2026-04-19)


### Features

* **12-05:** add installer preflight diagnostics ([d2f55a5](https://github.com/szTheory/accrue/commit/d2f55a5890ca81f73708fcd3a2d36562519e1b48))
* **12-05:** add shared setup diagnostics for boot and webhook failures ([47bc87c](https://github.com/szTheory/accrue/commit/47bc87cb162142d3c91603acf29245c09104fb1b))
* **13-02:** enforce canonical demo docs parity ([dff967a](https://github.com/szTheory/accrue/commit/dff967a9c19355e2568afb90225e4d27c09b90d7))
* **13-02:** narrow package docs shell invariants ([d8058fa](https://github.com/szTheory/accrue/commit/d8058fa0fd397eb1a9506a537678eb99a4754016))
* **15-01:** add trust leakage and release gate guardrails ([7de4df6](https://github.com/szTheory/accrue/commit/7de4df6a9efb10c0e83d7d082c285ba33758f1de))
* **18-01:** add subscription automatic tax option ([0eb7c00](https://github.com/szTheory/accrue/commit/0eb7c003b6da9d9a643254c8a4cfbb3030d11f2d))
* **18-02:** add fake automatic tax payload parity ([4fcb736](https://github.com/szTheory/accrue/commit/4fcb736a8579f64046086a22c07a22cf70933a43))
* **18-03:** add automatic tax billing columns ([a4d6b19](https://github.com/szTheory/accrue/commit/a4d6b19e1d13bdb845a47119691f47504f35d2f0))
* **18-03:** project automatic tax billing state ([d04e7dc](https://github.com/szTheory/accrue/commit/d04e7dcf647d58b3e5acb271d674d8f4d08e6ce4))
* **18-04:** add checkout automatic tax contract ([ce4b5cb](https://github.com/szTheory/accrue/commit/ce4b5cbe832231dcb72e159c370ef47d70b1ece3))
* **19-01:** add deterministic fake tax location failures ([2cd27d8](https://github.com/szTheory/accrue/commit/2cd27d8cd6df2cf35076f5e48f892da80e95069d))
* **19-01:** add stable stripe tax location errors ([50ad8d2](https://github.com/szTheory/accrue/commit/50ad8d2173bb602a6f140d918c6f8ec40f73387d))
* **19-02:** add public customer tax location update API ([f87de8c](https://github.com/szTheory/accrue/commit/f87de8c7fc7c173747542de75e10d0353d2f44a4))
* **19-03:** add tax rollout safety observability columns ([f896f3a](https://github.com/szTheory/accrue/commit/f896f3ab6bc63d9890d59e6b37d4d644d196dcfd))
* **19-03:** reconcile tax rollout failure state ([06a96b6](https://github.com/szTheory/accrue/commit/06a96b6cb94a7bcac80df60c416b77e817c4140e))
* **accrue:** refine config, Connect, webhooks, telemetry; fix Hex smoke ([8fef57d](https://github.com/szTheory/accrue/commit/8fef57d8c3ac6a8ea5e197f0f1f33d05110f774a))
* **host,docs,ci:** adoption proof matrix and VERIFY-01 clarity ([10b5e20](https://github.com/szTheory/accrue/commit/10b5e2032b8f63c3b833311b010e838ce894dbb5))
* v1.4 ecosystem stability, demo visuals, and admin browser bundle ([647e683](https://github.com/szTheory/accrue/commit/647e68308857d6e1e82422afd783b177e55be7d8))


### Bug Fixes

* **10-04:** prove generated billing facade and installer idempotence ([57ba5be](https://github.com/szTheory/accrue/commit/57ba5be0967b78cf99c6ee16c0cab72b02a51b0d))
* **12-03:** implement installer rerun conflict contract ([00356b0](https://github.com/szTheory/accrue/commit/00356b0df2bbefe6a0837d22cbdd24fb75491267))
* **12-07:** activate strict package docs verifier ([68e300a](https://github.com/szTheory/accrue/commit/68e300acae1187b44ff1d41880c63da954a25d8d))
* **12-09:** let preflight honor runtime auth adapter config ([0b3692c](https://github.com/szTheory/accrue/commit/0b3692c5c3f27310caf8ea61531a186d00f7f0e3))
* **12-09:** scope webhook preflight to the mounted route ([e01207f](https://github.com/szTheory/accrue/commit/e01207fa5b82f3e3463bbdcec74842c3dcb4c506))
* **12-09:** surface migration inspection failures as setup diagnostics ([31c673f](https://github.com/szTheory/accrue/commit/31c673ff3db4cc09c62d91697f0c1a22914c072e))
* **12-10:** align webhook config guidance with runtime contract ([e40cc9e](https://github.com/szTheory/accrue/commit/e40cc9eceb3cc426246aed9c77d493bd1b051b16))
* **13-01:** delegate host uat wrapper to verify.full ([65a0205](https://github.com/szTheory/accrue/commit/65a02054a0deee6c7cbfda70e054e17a6b64ee05))
* **13:** remove docs helper default warnings ([c792ecc](https://github.com/szTheory/accrue/commit/c792ecc9d40f6a05d06f352d2ffd91cd3c7a4c9b))
* **13:** WR-02 guard docs order helpers against missing labels ([41e4344](https://github.com/szTheory/accrue/commit/41e43442e12804c23c24a5e6d6aedcdac986837b))
* **19:** resolve tax rollout review findings ([a36d0ea](https://github.com/szTheory/accrue/commit/a36d0ea3b2177fcbc5c5b42ecc0699630868859c))
* **test:** preserve Fake connect state across BillingCase resets ([9189d7d](https://github.com/szTheory/accrue/commit/9189d7d3722b5764907f758bca701e6e83f423e8))

## [0.1.2](https://github.com/szTheory/accrue/compare/accrue-v0.1.1...accrue-v0.1.2) (2026-04-16)


### Bug Fixes

* correct hexdocs package readmes ([066483d](https://github.com/szTheory/accrue/commit/066483d236b415579a178827a4cdd45bfb5911f9))

## [0.1.1](https://github.com/szTheory/accrue/compare/accrue-v0.1.0...accrue-v0.1.1) (2026-04-16)


### Bug Fixes

* clear ci release blockers ([4dd3382](https://github.com/szTheory/accrue/commit/4dd33823c926831ef4650a7106d72c5072cac278))
* stabilize ci release gate ([edc639d](https://github.com/szTheory/accrue/commit/edc639d7027b58658991d705f4f6764beeac8ce8))
